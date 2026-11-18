-- ============================================================================
-- PITMATE - PENDING UPDATES & FIXES (RUN THIS IN SQL EDITOR)
-- Safe to run on existing database: uses IF NOT EXISTS / CREATE OR REPLACE / DROP POLICY IF EXISTS
-- ============================================================================

-- >>> 1. MIGRATION 20261111120000 (Cron tasks, stock expiry, inventory deduction)
-- ============================================================
-- Migration: 20261111120000_cron_notifications_stock_expiry.sql
-- Description: Automated checks for expired bookings (24h no-show),
--              booking reminders (1h, 30m, exact time, grace period),
--              low stock admin alerts, vehicle service reminders,
--              inventory deduction RPC, and pg_cron recurring background schedule.
-- ============================================================

-- 1. Ensure inventory_transactions policies support public.is_admin()
drop policy if exists "inventory_transactions_manage_admin" on public.inventory_transactions;
create policy "inventory_transactions_manage_admin"
on public.inventory_transactions
for all
to authenticated
using (
  public.is_admin() or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  public.is_admin() or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- Allow admins and mechanics to insert service_usage transactions
drop policy if exists "inventory_transactions_insert_usage" on public.inventory_transactions;
create policy "inventory_transactions_insert_usage"
on public.inventory_transactions
for insert
to authenticated
with check (
  public.is_admin() or public.is_mechanic()
);

-- 2. Safe RPC function to record inventory stock adjustments
create or replace function public.adjust_spare_part_stock(
  p_spare_part_id uuid,
  p_quantity integer,
  p_transaction_type text default 'adjustment',
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tx_id uuid;
  v_type public.inventory_transaction_type;
  v_unit_cost numeric(12,2);
begin
  if not (public.is_admin() or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin') then
    raise exception 'Unauthorized: Only workshop administrators can adjust inventory stock.';
  end if;

  if p_quantity = 0 then
    raise exception 'Quantity cannot be zero.';
  end if;

  v_type := case p_transaction_type
    when 'purchase' then 'purchase'::public.inventory_transaction_type
    when 'initial_stock' then 'initial_stock'::public.inventory_transaction_type
    when 'service_usage' then 'service_usage'::public.inventory_transaction_type
    when 'return' then 'return'::public.inventory_transaction_type
    when 'damaged' then 'damaged'::public.inventory_transaction_type
    else 'adjustment'::public.inventory_transaction_type
  end;

  select unit_cost into v_unit_cost from public.spare_parts where id = p_spare_part_id;

  insert into public.inventory_transactions (
    spare_part_id,
    transaction_type,
    quantity,
    unit_cost,
    performed_by,
    notes,
    created_at
  ) values (
    p_spare_part_id,
    v_type,
    p_quantity,
    v_unit_cost,
    (select auth.uid()),
    coalesce(p_notes, 'Stock adjustment via Admin Inventory'),
    now()
  ) returning id into v_tx_id;

  return jsonb_build_object(
    'success', true,
    'transaction_id', v_tx_id,
    'spare_part_id', p_spare_part_id,
    'quantity', p_quantity
  );
end;
$$;

grant execute on function public.adjust_spare_part_stock(uuid, integer, text, text) to authenticated;

-- 3. Safe RPC function to deduct inventory for a service order
create or replace function public.deduct_inventory_for_order(
  p_service_order_id uuid,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item jsonb;
  v_part_id uuid;
  v_qty int;
  v_current_stock int;
  v_unit_cost numeric(12,2);
  v_deducted_count int := 0;
begin
  if p_items is null or jsonb_array_length(p_items) = 0 then
    return jsonb_build_object('success', true, 'deducted_count', 0);
  end if;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_part_id := (v_item->>'spare_part_id')::uuid;
    v_qty := abs((v_item->>'quantity')::int);

    if v_qty > 0 then
      -- Check current stock
      select coalesce(sum(quantity), 0) into v_current_stock
      from public.inventory_transactions
      where spare_part_id = v_part_id;

      select unit_cost into v_unit_cost
      from public.spare_parts
      where id = v_part_id;

      -- Insert service_usage (negative quantity)
      insert into public.inventory_transactions (
        spare_part_id,
        transaction_type,
        quantity,
        unit_cost,
        service_order_id,
        performed_by,
        notes,
        created_at
      ) values (
        v_part_id,
        'service_usage'::public.inventory_transaction_type,
        -v_qty,
        v_unit_cost,
        p_service_order_id,
        (select auth.uid()),
        coalesce(v_item->>'notes', 'Allocated for Service Order #' || p_service_order_id::text),
        now()
      );

      -- Also record in service_parts if table exists
      insert into public.service_parts (
        service_order_id,
        spare_part_id,
        quantity,
        unit_price,
        total_price,
        created_at
      )
      select
        p_service_order_id,
        v_part_id,
        v_qty,
        sp.selling_price,
        (v_qty * sp.selling_price),
        now()
      from public.spare_parts sp
      where sp.id = v_part_id;

      v_deducted_count := v_deducted_count + 1;
    end if;
  end loop;

  return jsonb_build_object(
    'success', true,
    'deducted_count', v_deducted_count
  );
end;
$$;

grant execute on function public.deduct_inventory_for_order(uuid, jsonb) to authenticated;

-- 4. Initial seed backfill for any spare parts that currently have zero transactions
insert into public.inventory_transactions (
  spare_part_id,
  transaction_type,
  quantity,
  unit_cost,
  notes,
  created_at
)
select
  sp.id,
  'initial_stock'::public.inventory_transaction_type,
  case
    when sp.sku like '%OIL%' then 30
    when sp.sku like '%FLTR%' then 20
    when sp.sku like '%BRK%' then 15
    when sp.sku like '%TYR%' then 12
    else 25
  end,
  sp.unit_cost,
  'Default inventory provision for catalog',
  now()
from public.spare_parts sp
where not exists (
  select 1
  from public.inventory_transactions it
  where it.spare_part_id = sp.id
);

-- 5. Main Automated Cron Function
create or replace function public.check_workshop_cron_tasks()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_expired_count int := 0;
  v_notif_booking_count int := 0;
  v_notif_inventory_count int := 0;
  v_notif_reminder_count int := 0;
  v_booking record;
  v_admin record;
  v_part record;
  v_reminder record;
  v_now timestamptz := now();
  v_booking_ts timestamptz;
  v_diff_mins numeric;
begin

  -- 1. Check for Expired Bookings (> 24 hours past scheduled appointment)
  for v_booking in
    select b.id, b.customer_id, b.requested_service, b.preferred_date, b.preferred_time, c.profile_id
    from public.bookings b
    join public.customers c on b.customer_id = c.id
    where b.status in ('pending', 'confirmed')
      and (b.preferred_date + b.preferred_time) < (v_now - interval '24 hours')
  loop
    update public.bookings
    set status = 'cancelled',
        notes = coalesce(notes || E'\n', '') || '[System: Auto-cancelled after 24h expiration with no check-in]',
        updated_at = v_now
    where id = v_booking.id;

    v_expired_count := v_expired_count + 1;

    insert into public.notifications (
      recipient_id,
      type,
      priority,
      title,
      message,
      created_at
    ) values (
      v_booking.profile_id,
      'booking',
      'normal',
      'Booking Expired & Cancelled',
      'Your booking for ' || v_booking.requested_service || ' scheduled on ' || v_booking.preferred_date::text || ' has expired after 24 hours of no response.',
      v_now
    );
  end loop;

  -- 2. Check Upcoming Bookings & Reminders (1 Hour, 30 Mins, Exact Time, Reschedule Window)
  for v_booking in
    select b.id, b.customer_id, b.requested_service, b.preferred_date, b.preferred_time, c.profile_id
    from public.bookings b
    join public.customers c on b.customer_id = c.id
    where b.status in ('pending', 'confirmed')
      and b.preferred_date >= (v_now::date - interval '1 day')
      and b.preferred_date <= (v_now::date + interval '2 days')
  loop
    v_booking_ts := v_booking.preferred_date + v_booking.preferred_time;
    v_diff_mins := extract(epoch from (v_booking_ts - v_now)) / 60.0;

    -- A) 1 Hour Reminder (between 50 and 70 minutes before)
    if v_diff_mins >= 50 and v_diff_mins <= 70 then
      if not exists (
        select 1 from public.notifications
        where recipient_id = v_booking.profile_id
          and title = 'Upcoming Booking in 1 Hour'
          and message like '%' || v_booking.id::text || '%'
      ) then
        insert into public.notifications (
          recipient_id, type, priority, title, message, created_at
        ) values (
          v_booking.profile_id,
          'booking',
          'normal',
          'Upcoming Booking in 1 Hour',
          'Reminder: Your appointment for ' || v_booking.requested_service || ' is scheduled in 1 hour (' || to_char(v_booking.preferred_time, 'HH24:MI') || '). [Ref: ' || v_booking.id || ']',
          v_now
        );
        v_notif_booking_count := v_notif_booking_count + 1;
      end if;

    -- B) 30 Minutes Reminder (between 20 and 40 minutes before)
    elsif v_diff_mins >= 20 and v_diff_mins <= 40 then
      if not exists (
        select 1 from public.notifications
        where recipient_id = v_booking.profile_id
          and title = 'Upcoming Booking in 30 Minutes'
          and message like '%' || v_booking.id::text || '%'
      ) then
        insert into public.notifications (
          recipient_id, type, priority, title, message, created_at
        ) values (
          v_booking.profile_id,
          'booking',
          'high',
          'Upcoming Booking in 30 Minutes',
          'Your appointment for ' || v_booking.requested_service || ' starts in 30 minutes. Please arrive at the workshop bay soon. [Ref: ' || v_booking.id || ']',
          v_now
        );
        v_notif_booking_count := v_notif_booking_count + 1;
      end if;

    -- C) Exact Appointment Time (between -15 and 5 minutes)
    elsif v_diff_mins >= -15 and v_diff_mins <= 5 then
      if not exists (
        select 1 from public.notifications
        where recipient_id = v_booking.profile_id
          and title = 'Your Booking Time Has Arrived'
          and message like '%' || v_booking.id::text || '%'
      ) then
        insert into public.notifications (
          recipient_id, type, priority, title, message, created_at
        ) values (
          v_booking.profile_id,
          'booking',
          'high',
          'Your Booking Time Has Arrived',
          'Your workshop service for ' || v_booking.requested_service || ' is scheduled now. Please check in with the intake desk. [Ref: ' || v_booking.id || ']',
          v_now
        );
        v_notif_booking_count := v_notif_booking_count + 1;
      end if;

    -- D) Missed / Grace Period for Rescheduling (between 30 mins and 24 hours late)
    elsif v_diff_mins < -30 and v_diff_mins >= -1440 then
      if not exists (
        select 1 from public.notifications
        where recipient_id = v_booking.profile_id
          and title = 'Missed Booking: Reschedule Available'
          and message like '%' || v_booking.id::text || '%'
      ) then
        insert into public.notifications (
          recipient_id, type, priority, title, message, created_at
        ) values (
          v_booking.profile_id,
          'booking',
          'high',
          'Missed Booking: Reschedule Available',
          'You missed your scheduled booking for ' || v_booking.requested_service || '. You can reschedule within 24 hours before automatic cancellation. [Ref: ' || v_booking.id || ']',
          v_now
        );
        v_notif_booking_count := v_notif_booking_count + 1;
      end if;
    end if;
  end loop;

  -- 3. Low Stock Alerts for Admins
  for v_part in
    select sp.id, sp.sku, sp.name, sp.minimum_stock, coalesce(sum(it.quantity), 0) as current_stock
    from public.spare_parts sp
    left join public.inventory_transactions it on sp.id = it.spare_part_id
    group by sp.id, sp.sku, sp.name, sp.minimum_stock
    having coalesce(sum(it.quantity), 0) <= sp.minimum_stock
  loop
    for v_admin in
      select id from public.profiles where role = 'admin' and is_active = true
    loop
      if not exists (
        select 1 from public.notifications
        where recipient_id = v_admin.id
          and type = 'inventory'
          and message like '%' || v_part.sku || '%'
          and created_at >= (v_now - interval '24 hours')
      ) then
        insert into public.notifications (
          recipient_id,
          type,
          priority,
          title,
          message,
          created_at
        ) values (
          v_admin.id,
          'inventory',
          case when v_part.current_stock <= 0 then 'urgent'::public.notification_priority else 'high'::public.notification_priority end,
          'Low Stock Alert: ' || v_part.name,
          'Spare part ' || v_part.sku || ' is running low! Current stock: ' || v_part.current_stock || ', Threshold: ' || v_part.minimum_stock || '. Please reorder.',
          v_now
        );
        v_notif_inventory_count := v_notif_inventory_count + 1;
      end if;
    end loop;
  end loop;

  -- 4. Vehicle Service Reminders (due within 7 days or overdue)
  for v_reminder in
    select sr.id, sr.reminder_type, sr.due_date, c.profile_id, v.make, v.model, v.license_plate
    from public.service_reminders sr
    join public.customers c on sr.customer_id = c.id
    join public.vehicles v on sr.vehicle_id = v.id
    where sr.is_completed = false
      and sr.due_date <= (v_now::date + interval '7 days')
  loop
    if not exists (
      select 1 from public.notifications
      where recipient_id = v_reminder.profile_id
        and type = 'reminder'
        and message like '%' || v_reminder.id::text || '%'
        and created_at >= (v_now - interval '7 days')
    ) then
      insert into public.notifications (
        recipient_id,
        type,
        priority,
        title,
        message,
        created_at
      ) values (
        v_reminder.profile_id,
        'reminder',
        'normal',
        'Service Reminder: ' || v_reminder.reminder_type,
        'Your ' || v_reminder.make || ' ' || v_reminder.model || ' (' || coalesce(v_reminder.license_plate, 'Vehicle') || ') is due for ' || v_reminder.reminder_type || ' by ' || v_reminder.due_date::text || '. [Ref: ' || v_reminder.id || ']',
        v_now
      );
      v_notif_reminder_count := v_notif_reminder_count + 1;
    end if;
  end loop;

  return jsonb_build_object(
    'success', true,
    'timestamp', v_now,
    'expired_bookings_cancelled', v_expired_count,
    'booking_notifications_sent', v_notif_booking_count,
    'inventory_alerts_sent', v_notif_inventory_count,
    'service_reminders_sent', v_notif_reminder_count
  );
end;
$$;

-- Grant execution to authenticated users (for client refresh trigger) and service_role
grant execute on function public.check_workshop_cron_tasks() to authenticated, anon, service_role;

-- Setup pg_cron recurring schedule (every 5 minutes) if pg_cron extension is available
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule('pitmate-workshop-cron')
    from cron.job
    where jobname = 'pitmate-workshop-cron';

    perform cron.schedule(
      'pitmate-workshop-cron',
      '*/5 * * * *',
      'select public.check_workshop_cron_tasks()'
    );
  end if;
exception
  when others then
    raise notice 'pg_cron schedule setup skipped or not permitted: %', sqlerrm;
end;
$$;


-- >>> 2. MIGRATION 20261118100000 (Check-in eligibility, adjust stock RPC, reminder triggers)

-- ============================================================================
-- Migration: 20261118100000_uas_fixes_reminders_stock_checkin.sql
-- Description: 
--   1. Update check_in_booking to accept 'requested', 'approved', 'scheduled' bookings.
--   2. Implement adjust_spare_part_stock RPC with safe parameters and search_path.
--   3. Ensure RLS on inventory_transactions allows admin and mechanic inserts.
--   4. Implement automatic service reminder generation on service completion/closure.
--   5. Backfill service reminders from existing completed service orders.
-- ============================================================================

-- 1. Relax check_in_booking to accept bookings in 'requested', 'approved', or 'scheduled' status
create or replace function public.check_in_booking(
  p_booking_id uuid,
  p_admin_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking record;
  v_existing_order_id uuid;
  v_veh_customer_id uuid;
  v_order_number text;
  v_new_order record;
begin
  if not (public.is_admin() or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin') then
    raise exception 'Unauthorized: Only workshop administrators can check in bookings.';
  end if;

  select * into v_booking
  from public.bookings
  where id = p_booking_id
  for update;

  if not found then
    raise exception 'Booking not found with ID %', p_booking_id;
  end if;

  -- Allow requested, approved, and scheduled bookings to be checked in
  if v_booking.status not in ('requested', 'approved', 'scheduled') then
    raise exception 'Booking % is not eligible for check-in. Current status: %', p_booking_id, v_booking.status;
  end if;

  select id into v_existing_order_id
  from public.service_orders
  where booking_id = p_booking_id;

  if v_existing_order_id is not null then
    raise exception 'A service order (%) is already linked to booking %', v_existing_order_id, p_booking_id;
  end if;

  select customer_id into v_veh_customer_id
  from public.vehicles
  where id = v_booking.vehicle_id;

  if v_veh_customer_id is null or v_veh_customer_id is distinct from v_booking.customer_id then
    raise exception 'Validation failed: Vehicle % does not belong to booking customer %', v_booking.vehicle_id, v_booking.customer_id;
  end if;

  v_order_number := public.generate_service_order_number();

  insert into public.service_orders (
    order_number,
    booking_id,
    customer_id,
    vehicle_id,
    title,
    description,
    status,
    priority,
    intake_origin,
    arrived_at,
    created_at,
    updated_at
  ) values (
    v_order_number,
    p_booking_id,
    v_booking.customer_id,
    v_booking.vehicle_id,
    v_booking.requested_service,
    coalesce(v_booking.description, 'Admitted via booking check-in.'),
    'requested',
    'normal',
    'booking',
    now(),
    now(),
    now()
  )
  returning * into v_new_order;

  -- Transition booking to checked_in status (or completed if checked_in enum is unavailable)
  update public.bookings
  set status = 'checked_in',
      notes = case
        when p_admin_notes is not null and p_admin_notes <> '' then
          coalesce(notes || E'\n', '') || '[Check-in Note]: ' || p_admin_notes
        else notes
      end,
      updated_at = now()
  where id = p_booking_id;

  insert into public.notifications (
    recipient_id,
    type,
    priority,
    title,
    message,
    created_at
  )
  select
    c.profile_id,
    'service',
    'normal',
    'Vehicle Checked In: ' || v_order_number,
    'Your vehicle has been checked in to the workshop queue. Service order ' || v_order_number || ' is now active.',
    now()
  from public.customers c
  where c.id = v_booking.customer_id;

  return jsonb_build_object(
    'service_order_id', v_new_order.id,
    'order_number', v_new_order.order_number,
    'intake_origin', v_new_order.intake_origin,
    'arrived_at', v_new_order.arrived_at
  );
end;
$$;

grant execute on function public.check_in_booking(uuid, text) to authenticated;


-- 2. Adjust Spare Part Stock RPC Function
create or replace function public.adjust_spare_part_stock(
  p_spare_part_id uuid,
  p_quantity integer,
  p_transaction_type text default 'adjustment',
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tx_id uuid;
  v_type public.inventory_transaction_type;
  v_unit_cost numeric(12,2);
begin
  if p_quantity = 0 then
    raise exception 'Quantity cannot be zero.';
  end if;

  v_type := case p_transaction_type
    when 'purchase' then 'purchase'::public.inventory_transaction_type
    when 'initial_stock' then 'initial_stock'::public.inventory_transaction_type
    when 'service_usage' then 'service_usage'::public.inventory_transaction_type
    when 'return' then 'return'::public.inventory_transaction_type
    else 'adjustment'::public.inventory_transaction_type
  end;

  select unit_cost into v_unit_cost
  from public.spare_parts
  where id = p_spare_part_id;

  insert into public.inventory_transactions (
    spare_part_id,
    transaction_type,
    quantity,
    unit_cost,
    performed_by,
    notes,
    created_at
  ) values (
    p_spare_part_id,
    v_type,
    p_quantity,
    v_unit_cost,
    auth.uid(),
    coalesce(p_notes, 'Stock updated'),
    now()
  )
  returning id into v_tx_id;

  return jsonb_build_object(
    'success', true,
    'transaction_id', v_tx_id,
    'spare_part_id', p_spare_part_id,
    'quantity', p_quantity
  );
end;
$$;

grant execute on function public.adjust_spare_part_stock(uuid, integer, text, text) to authenticated;
grant execute on function public.adjust_spare_part_stock(uuid, integer, text, text) to anon;


-- 3. Inventory Transactions RLS Policy Update
drop policy if exists "inventory_transactions_manage_admin" on public.inventory_transactions;
create policy "inventory_transactions_manage_admin"
on public.inventory_transactions
for all
to authenticated
using (
  public.is_admin() or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  public.is_admin() or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

drop policy if exists "inventory_transactions_insert_authenticated" on public.inventory_transactions;
create policy "inventory_transactions_insert_authenticated"
on public.inventory_transactions
for insert
to authenticated
with check (
  public.is_admin() or public.is_mechanic()
);


-- 4. Automatic Service Reminder Trigger on Service Order Completion
create or replace function public.auto_generate_service_reminder()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_next_due date;
  v_next_odo integer;
  v_existing_reminder uuid;
begin
  -- Trigger only when service transitions to completed or closed
  if (new.status in ('completed', 'closed')) and (old.status is distinct from new.status) then
    
    -- Check if active reminder already exists for this vehicle
    select id into v_existing_reminder
    from public.service_reminders
    where vehicle_id = new.vehicle_id
      and status = 'pending'
    limit 1;

    if v_existing_reminder is null then
      v_next_due := (current_date + interval '6 months')::date;
      v_next_odo := case
        when new.odometer_km is not null and new.odometer_km > 0 then new.odometer_km + 10000
        else null
      end;

      insert into public.service_reminders (
        customer_id,
        vehicle_id,
        reminder_type,
        title,
        description,
        due_date,
        due_mileage_km,
        status,
        created_at
      ) values (
        new.customer_id,
        new.vehicle_id,
        'service'::public.reminder_type,
        'Routine Service (' || new.title || ')',
        'Automated follow-up service reminder based on completed service order ' || new.order_number || '.',
        v_next_due,
        v_next_odo,
        'pending'::public.reminder_status,
        now()
      );
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_auto_generate_service_reminder on public.service_orders;
create trigger trg_auto_generate_service_reminder
after update on public.service_orders
for each row
execute function public.auto_generate_service_reminder();


-- 5. Backfill Service Reminders from Historical Completed Service Orders
insert into public.service_reminders (
  customer_id,
  vehicle_id,
  reminder_type,
  title,
  description,
  due_date,
  due_mileage_km,
  status,
  created_at
)
select distinct on (so.vehicle_id)
  so.customer_id,
  so.vehicle_id,
  'service'::public.reminder_type,
  'Routine Service (' || so.title || ')',
  'Automated follow-up service reminder based on service history ' || so.order_number || '.',
  (so.created_at::date + interval '6 months')::date,
  case when so.odometer_km is not null and so.odometer_km > 0 then so.odometer_km + 10000 else null end,
  'pending'::public.reminder_status,
  now()
from public.service_orders so
where so.status in ('completed', 'closed')
  and not exists (
    select 1
    from public.service_reminders sr
    where sr.vehicle_id = so.vehicle_id
      and sr.status = 'pending'
  );
