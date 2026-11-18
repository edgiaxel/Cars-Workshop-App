-- ============================================================
-- Migration: 20261030110100_uas_queue_intake_theme_foundations.sql
-- Description:
--   1. Profiles theme_mode column & role modification protection
--   2. Service orders arrived_at & intake_origin columns with backfill
--   3. Correct customer service_orders direct insert policy (Admin only)
--   4. Service status transition validation & automated history logging
--   5. Transaction-safe check_in_booking and admit_walk_in RPC functions
--   6. Queue and intake performance indexes
-- ============================================================

-- 1. Profiles Theme Mode & Role Security
alter table public.profiles
  add column if not exists theme_mode text not null default 'dark';

alter table public.profiles
  drop constraint if exists profiles_theme_mode_check;

alter table public.profiles
  add constraint profiles_theme_mode_check
  check (theme_mode in ('dark', 'light', 'system'));

create or replace function public.check_profile_role_protection()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (old.role is distinct from new.role) and not public.is_admin() then
    raise exception 'Unauthorized: Only administrators can modify user roles.';
  end if;
  return new;
end;
$$;

drop trigger if exists tr_check_profile_role_protection on public.profiles;
create trigger tr_check_profile_role_protection
before update on public.profiles
for each row
execute function public.check_profile_role_protection();

-- 2. Service Orders Intake Origin & Arrived At
alter table public.service_orders
  add column if not exists arrived_at timestamptz;

alter table public.service_orders
  add column if not exists intake_origin text not null default 'legacy_unknown';

alter table public.service_orders
  drop constraint if exists service_orders_intake_origin_check;

alter table public.service_orders
  add constraint service_orders_intake_origin_check
  check (intake_origin in ('booking', 'walk_in', 'legacy_unknown'));

-- Backfill legacy records: booking if relationship exists, legacy_unknown otherwise
update public.service_orders
set intake_origin = 'booking'
where booking_id is not null;

update public.service_orders
set intake_origin = 'legacy_unknown'
where booking_id is null and (intake_origin is null or intake_origin != 'walk_in');

-- 3. Correct Service Orders Insert Policy (Admin Only; Customers use Bookings)
drop policy if exists "service_orders_insert_customer_or_admin" on public.service_orders;
drop policy if exists "service_orders_insert_admin" on public.service_orders;
create policy "service_orders_insert_admin"
on public.service_orders
for insert
to authenticated
with check (
  public.is_admin()
);

-- 4. Status History Policies
drop policy if exists "service_status_history_select_related" on public.service_status_history;
create policy "service_status_history_select_related"
on public.service_status_history
for select
to authenticated
using (
  exists (
    select 1
    from public.service_orders so
    join public.customers c on c.id = so.customer_id
    where so.id = service_status_history.service_order_id
      and c.profile_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.service_assignments sa
    join public.mechanics m on m.id = sa.mechanic_id
    where sa.service_order_id = service_status_history.service_order_id
      and m.profile_id = (select auth.uid())
  )
  or public.is_admin()
);

drop policy if exists "service_status_history_insert_admin_or_mechanic" on public.service_status_history;
create policy "service_status_history_insert_admin_or_mechanic"
on public.service_status_history
for insert
to authenticated
with check (
  public.is_admin() or public.is_mechanic()
);

-- 5. Order Number Sequence Generator Function
create or replace function public.generate_service_order_number()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  current_yr text;
  max_suffix integer;
  next_seq integer;
begin
  current_yr := to_char(now(), 'YYYY');

  select coalesce(max(
    nullif(substring(order_number from '^SO-[0-9]{4}-([0-9]+)$'), '')::integer
  ), 0)
  into max_suffix
  from public.service_orders
  where order_number like ('SO-' || current_yr || '-%');

  next_seq := max_suffix + 1;
  return 'SO-' || current_yr || '-' || lpad(next_seq::text, 3, '0');
end;
$$;

-- 6. Status Transition Validation & Automated History Logging
create or replace function public.validate_service_order_status_transition(
  p_old_status public.service_status,
  p_new_status public.service_status
)
returns boolean
language plpgsql
immutable
as $$
begin
  if p_old_status = p_new_status then
    return true;
  end if;

  if p_old_status in ('closed', 'cancelled') then
    return false;
  end if;

  if p_new_status = 'cancelled' then
    return true;
  end if;

  case p_old_status
    when 'requested' then
      return p_new_status in ('approved', 'scheduled', 'inspection');
    when 'approved' then
      return p_new_status in ('scheduled', 'inspection', 'in_progress');
    when 'scheduled' then
      return p_new_status in ('inspection', 'diagnosis', 'in_progress');
    when 'inspection' then
      return p_new_status in ('diagnosis', 'waiting_for_approval', 'waiting_for_parts', 'in_progress');
    when 'diagnosis' then
      return p_new_status in ('waiting_for_approval', 'waiting_for_parts', 'in_progress');
    when 'waiting_for_approval' then
      return p_new_status in ('waiting_for_parts', 'in_progress', 'diagnosis');
    when 'waiting_for_parts' then
      return p_new_status in ('in_progress', 'waiting_for_approval');
    when 'in_progress' then
      return p_new_status in ('completion_review', 'waiting_for_parts', 'waiting_for_approval', 'completed');
    when 'completion_review' then
      return p_new_status in ('in_progress', 'completed');
    when 'completed' then
      return p_new_status in ('payment', 'closed');
    when 'payment' then
      return p_new_status in ('closed');
    else
      return false;
  end case;
end;
$$;

create or replace function public.tr_service_orders_status_check()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (old.status is distinct from new.status) then
    if not public.validate_service_order_status_transition(old.status, new.status) then
      raise exception 'Invalid service order status transition from % to %', old.status, new.status;
    end if;

    if new.status = 'completed' and new.completed_at is null then
      new.completed_at := now();
    elsif new.status = 'closed' and new.closed_at is null then
      new.closed_at := now();
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists tr_service_orders_status_check on public.service_orders;
create trigger tr_service_orders_status_check
before update on public.service_orders
for each row
execute function public.tr_service_orders_status_check();

create or replace function public.tr_service_orders_status_history()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (old.status is distinct from new.status) then
    insert into public.service_status_history (
      service_order_id,
      previous_status,
      new_status,
      changed_by,
      notes,
      created_at
    ) values (
      new.id,
      old.status,
      new.status,
      auth.uid(),
      'Status transitioned from ' || old.status::text || ' to ' || new.status::text,
      now()
    );
  end if;
  return new;
end;
$$;

drop trigger if exists tr_service_orders_status_history on public.service_orders;
create trigger tr_service_orders_status_history
after update on public.service_orders
for each row
when (old.status is distinct from new.status)
execute function public.tr_service_orders_status_history();

-- 7. Transaction-Safe Check-in & Walk-in Admission RPCs
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
  if not public.is_admin() then
    raise exception 'Unauthorized: Only workshop administrators can check in bookings.';
  end if;

  select * into v_booking
  from public.bookings
  where id = p_booking_id
  for update;

  if not found then
    raise exception 'Booking not found with ID %', p_booking_id;
  end if;

  if v_booking.status not in ('approved', 'scheduled') then
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
    estimated_total,
    intake_origin,
    arrived_at,
    created_at,
    updated_at
  ) values (
    v_order_number,
    v_booking.id,
    v_booking.customer_id,
    v_booking.vehicle_id,
    v_booking.requested_service,
    coalesce(p_admin_notes, v_booking.description),
    'requested'::public.service_status,
    0.0,
    'booking',
    now(),
    now(),
    now()
  ) returning * into v_new_order;

  update public.bookings
  set status = 'checked_in'::public.booking_status,
      admin_notes = coalesce(p_admin_notes, admin_notes),
      updated_at = now()
  where id = v_booking.id;

  insert into public.service_status_history (
    service_order_id,
    previous_status,
    new_status,
    changed_by,
    notes,
    created_at
  ) values (
    v_new_order.id,
    null,
    'requested'::public.service_status,
    auth.uid(),
    'Vehicle admitted from booking check-in',
    now()
  );

  return jsonb_build_object(
    'success', true,
    'service_order_id', v_new_order.id,
    'order_number', v_new_order.order_number,
    'booking_id', v_booking.id,
    'intake_origin', v_new_order.intake_origin,
    'arrived_at', v_new_order.arrived_at
  );
end;
$$;

create or replace function public.admit_walk_in(
  p_customer_id uuid,
  p_vehicle_id uuid,
  p_title text,
  p_description text default null,
  p_estimated_total numeric default 0.0,
  p_odometer_km integer default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_veh_customer_id uuid;
  v_order_number text;
  v_new_order record;
begin
  if not public.is_admin() then
    raise exception 'Unauthorized: Only workshop administrators can admit walk-in vehicles.';
  end if;

  if not exists (select 1 from public.customers where id = p_customer_id) then
    raise exception 'Customer not found with ID %', p_customer_id;
  end if;

  select customer_id into v_veh_customer_id
  from public.vehicles
  where id = p_vehicle_id;

  if v_veh_customer_id is null or v_veh_customer_id is distinct from p_customer_id then
    raise exception 'Validation failed: Vehicle % does not belong to customer %', p_vehicle_id, p_customer_id;
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
    estimated_total,
    odometer_km,
    intake_origin,
    arrived_at,
    created_at,
    updated_at
  ) values (
    v_order_number,
    null,
    p_customer_id,
    p_vehicle_id,
    p_title,
    p_description,
    'requested'::public.service_status,
    coalesce(p_estimated_total, 0.0),
    p_odometer_km,
    'walk_in',
    now(),
    now(),
    now()
  ) returning * into v_new_order;

  insert into public.service_status_history (
    service_order_id,
    previous_status,
    new_status,
    changed_by,
    notes,
    created_at
  ) values (
    v_new_order.id,
    null,
    'requested'::public.service_status,
    auth.uid(),
    'Vehicle admitted as walk-in intake',
    now()
  );

  return jsonb_build_object(
    'success', true,
    'service_order_id', v_new_order.id,
    'order_number', v_new_order.order_number,
    'intake_origin', v_new_order.intake_origin,
    'arrived_at', v_new_order.arrived_at
  );
end;
$$;

grant execute on function public.check_in_booking(uuid, text) to authenticated;
grant execute on function public.admit_walk_in(uuid, uuid, text, text, numeric, integer) to authenticated;

-- 8. Performance and Queue Indexes
create index if not exists service_orders_queue_active_idx
  on public.service_orders (arrived_at asc, created_at asc, id)
  where arrived_at is not null and status not in ('completed', 'closed', 'cancelled');

create index if not exists service_orders_intake_origin_idx
  on public.service_orders (intake_origin);

create index if not exists service_orders_arrived_at_idx
  on public.service_orders (arrived_at);

create index if not exists bookings_status_idx
  on public.bookings (status);
