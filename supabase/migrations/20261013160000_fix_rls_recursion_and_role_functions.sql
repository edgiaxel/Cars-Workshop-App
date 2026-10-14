-- ============================================================
-- Migration: 20261013160000_fix_rls_recursion_and_role_functions
-- Description:
--   1. Provide security definer helper functions (DB-SCHEMA.md Section 29):
--      - public.is_admin()
--      - public.is_mechanic()
--      - public.current_customer_id()
--      - public.current_mechanic_id()
--   2. Break mutual RLS recursion between vehicles, service_orders,
--      and service_assignments.
--   3. Ensure admin role defined in public.profiles grants full
--      administrative access even when auth.jwt() app_metadata is omitted.
-- ============================================================

-- 1. Helper Functions
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and role = 'admin'::public.user_role
      and is_active = true
  ) or (
    (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );
$$;

create or replace function public.is_mechanic()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and role = 'mechanic'::public.user_role
      and is_active = true
  ) or (
    (select auth.jwt() -> 'app_metadata' ->> 'role') = 'mechanic'
  );
$$;

create or replace function public.current_customer_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id
  from public.customers
  where profile_id = (select auth.uid())
  limit 1;
$$;

create or replace function public.current_mechanic_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id
  from public.mechanics
  where profile_id = (select auth.uid())
  limit 1;
$$;

-- 2. Update Profiles Policies
drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin"
on public.profiles
for select
to authenticated
using (
  id = (select auth.uid())
  or public.is_admin()
);

drop policy if exists "profiles_update_own_or_admin" on public.profiles;
create policy "profiles_update_own_or_admin"
on public.profiles
for update
to authenticated
using (
  id = (select auth.uid())
  or public.is_admin()
)
with check (
  id = (select auth.uid())
  or public.is_admin()
);

drop policy if exists "profiles_insert_admin" on public.profiles;
create policy "profiles_insert_admin"
on public.profiles
for insert
to authenticated
with check (
  public.is_admin()
);

drop policy if exists "profiles_delete_admin" on public.profiles;
create policy "profiles_delete_admin"
on public.profiles
for delete
to authenticated
using (
  public.is_admin()
);

-- 3. Update Customers Policies
drop policy if exists "customers_select_own_or_admin" on public.customers;
create policy "customers_select_own_or_admin"
on public.customers
for select
to authenticated
using (
  profile_id = (select auth.uid())
  or public.is_admin()
);

drop policy if exists "customers_insert_self_or_admin" on public.customers;
create policy "customers_insert_self_or_admin"
on public.customers
for insert
to authenticated
with check (
  profile_id = (select auth.uid())
  or public.is_admin()
);

drop policy if exists "customers_update_own_or_admin" on public.customers;
create policy "customers_update_own_or_admin"
on public.customers
for update
to authenticated
using (
  profile_id = (select auth.uid())
  or public.is_admin()
)
with check (
  profile_id = (select auth.uid())
  or public.is_admin()
);

drop policy if exists "customers_delete_admin" on public.customers;
create policy "customers_delete_admin"
on public.customers
for delete
to authenticated
using (
  public.is_admin()
);

-- 4. Update Mechanics Policies
drop policy if exists "mechanics_select_own_or_admin" on public.mechanics;
create policy "mechanics_select_own_or_admin"
on public.mechanics
for select
to authenticated
using (
  profile_id = (select auth.uid())
  or public.is_admin()
);

drop policy if exists "mechanics_insert_admin" on public.mechanics;
create policy "mechanics_insert_admin"
on public.mechanics
for insert
to authenticated
with check (
  public.is_admin()
);

drop policy if exists "mechanics_update_own_or_admin" on public.mechanics;
create policy "mechanics_update_own_or_admin"
on public.mechanics
for update
to authenticated
using (
  profile_id = (select auth.uid())
  or public.is_admin()
)
with check (
  profile_id = (select auth.uid())
  or public.is_admin()
);

drop policy if exists "mechanics_delete_admin" on public.mechanics;
create policy "mechanics_delete_admin"
on public.mechanics
for delete
to authenticated
using (
  public.is_admin()
);

-- 5. Update Vehicles Policies (Breaking mutual recursion with service_orders)
drop policy if exists "vehicles_select_owner_mechanic_admin" on public.vehicles;
create policy "vehicles_select_owner_mechanic_admin"
on public.vehicles
for select
to authenticated
using (
  customer_id = public.current_customer_id()
  or exists (
    select 1
    from public.service_orders so
    join public.service_assignments sa
      on sa.service_order_id = so.id
    where so.vehicle_id = vehicles.id
      and sa.mechanic_id = public.current_mechanic_id()
  )
  or public.is_admin()
);

drop policy if exists "vehicles_insert_owner_or_admin" on public.vehicles;
create policy "vehicles_insert_owner_or_admin"
on public.vehicles
for insert
to authenticated
with check (
  customer_id = public.current_customer_id()
  or public.is_admin()
);

drop policy if exists "vehicles_update_owner_or_admin" on public.vehicles;
create policy "vehicles_update_owner_or_admin"
on public.vehicles
for update
to authenticated
using (
  customer_id = public.current_customer_id()
  or public.is_admin()
)
with check (
  customer_id = public.current_customer_id()
  or public.is_admin()
);

drop policy if exists "vehicles_delete_owner_or_admin" on public.vehicles;
create policy "vehicles_delete_owner_or_admin"
on public.vehicles
for delete
to authenticated
using (
  customer_id = public.current_customer_id()
  or public.is_admin()
);

-- 6. Update Bookings Policies
drop policy if exists "bookings_select_owner_or_admin" on public.bookings;
create policy "bookings_select_owner_or_admin"
on public.bookings
for select
to authenticated
using (
  customer_id = public.current_customer_id()
  or public.is_admin()
);

drop policy if exists "bookings_insert_owner_or_admin" on public.bookings;
create policy "bookings_insert_owner_or_admin"
on public.bookings
for insert
to authenticated
with check (
  customer_id = public.current_customer_id()
  or public.is_admin()
);

drop policy if exists "bookings_update_owner_or_admin" on public.bookings;
create policy "bookings_update_owner_or_admin"
on public.bookings
for update
to authenticated
using (
  customer_id = public.current_customer_id()
  or public.is_admin()
)
with check (
  customer_id = public.current_customer_id()
  or public.is_admin()
);

drop policy if exists "bookings_delete_admin" on public.bookings;
create policy "bookings_delete_admin"
on public.bookings
for delete
to authenticated
using (
  public.is_admin()
);

-- 7. Update Service Orders Policies (Breaking mutual recursion with service_assignments)
drop policy if exists "service_orders_select_customer_mechanic_admin" on public.service_orders;
create policy "service_orders_select_customer_mechanic_admin"
on public.service_orders
for select
to authenticated
using (
  customer_id = public.current_customer_id()
  or exists (
    select 1
    from public.service_assignments sa
    where sa.service_order_id = service_orders.id
      and sa.mechanic_id = public.current_mechanic_id()
  )
  or public.is_admin()
);

drop policy if exists "service_orders_insert_customer_or_admin" on public.service_orders;
create policy "service_orders_insert_customer_or_admin"
on public.service_orders
for insert
to authenticated
with check (
  customer_id = public.current_customer_id()
  or public.is_admin()
);

drop policy if exists "service_orders_update_assigned_or_admin" on public.service_orders;
create policy "service_orders_update_assigned_or_admin"
on public.service_orders
for update
to authenticated
using (
  exists (
    select 1
    from public.service_assignments sa
    where sa.service_order_id = service_orders.id
      and sa.mechanic_id = public.current_mechanic_id()
  )
  or public.is_admin()
)
with check (
  exists (
    select 1
    from public.service_assignments sa
    where sa.service_order_id = service_orders.id
      and sa.mechanic_id = public.current_mechanic_id()
  )
  or public.is_admin()
);

drop policy if exists "service_orders_delete_admin" on public.service_orders;
create policy "service_orders_delete_admin"
on public.service_orders
for delete
to authenticated
using (
  public.is_admin()
);

-- 8. Update Service Assignments Policies
drop policy if exists "service_assignments_select_related" on public.service_assignments;
create policy "service_assignments_select_related"
on public.service_assignments
for select
to authenticated
using (
  mechanic_id = public.current_mechanic_id()
  or exists (
    select 1
    from public.service_orders so
    where so.id = service_assignments.service_order_id
      and so.customer_id = public.current_customer_id()
  )
  or public.is_admin()
);

drop policy if exists "service_assignments_manage_admin" on public.service_assignments;
create policy "service_assignments_manage_admin"
on public.service_assignments
for all
to authenticated
using (
  public.is_admin()
)
with check (
  public.is_admin()
);

-- 9. Update Spare Parts Management
drop policy if exists "spare_parts_manage_admin" on public.spare_parts;
create policy "spare_parts_manage_admin"
on public.spare_parts
for all
to authenticated
using (
  public.is_admin()
)
with check (
  public.is_admin()
);
