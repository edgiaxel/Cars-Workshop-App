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
