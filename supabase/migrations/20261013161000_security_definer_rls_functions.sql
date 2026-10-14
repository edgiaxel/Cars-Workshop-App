-- ============================================================
-- Migration: 20261013161000_security_definer_rls_functions
-- Description:
--   Break cross-table RLS recursion by using security definer
--   lookup functions for service order and vehicle assignments.
-- ============================================================

-- 1. Helper Security Definer Functions that query without triggering circular RLS
create or replace function public.is_order_assigned_to_current_mechanic(p_order_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.service_assignments sa
    where sa.service_order_id = p_order_id
      and sa.mechanic_id = (
        select m.id from public.mechanics m where m.profile_id = (select auth.uid()) limit 1
      )
  );
$$;

create or replace function public.is_assignment_for_current_customer(p_order_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.service_orders so
    where so.id = p_order_id
      and so.customer_id = (
        select c.id from public.customers c where c.profile_id = (select auth.uid()) limit 1
      )
  );
$$;

create or replace function public.is_vehicle_assigned_to_current_mechanic(p_vehicle_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.service_orders so
    join public.service_assignments sa on sa.service_order_id = so.id
    where so.vehicle_id = p_vehicle_id
      and sa.mechanic_id = (
        select m.id from public.mechanics m where m.profile_id = (select auth.uid()) limit 1
      )
  );
$$;

-- 2. Update Vehicles policy
drop policy if exists "vehicles_select_owner_mechanic_admin" on public.vehicles;
create policy "vehicles_select_owner_mechanic_admin"
on public.vehicles
for select
to authenticated
using (
  public.is_admin()
  or customer_id = public.current_customer_id()
  or public.is_vehicle_assigned_to_current_mechanic(id)
);

-- 3. Update Service Orders policies
drop policy if exists "service_orders_select_customer_mechanic_admin" on public.service_orders;
create policy "service_orders_select_customer_mechanic_admin"
on public.service_orders
for select
to authenticated
using (
  public.is_admin()
  or customer_id = public.current_customer_id()
  or public.is_order_assigned_to_current_mechanic(id)
);

drop policy if exists "service_orders_update_assigned_or_admin" on public.service_orders;
create policy "service_orders_update_assigned_or_admin"
on public.service_orders
for update
to authenticated
using (
  public.is_admin()
  or public.is_order_assigned_to_current_mechanic(id)
)
with check (
  public.is_admin()
  or public.is_order_assigned_to_current_mechanic(id)
);

-- 4. Update Service Assignments policy
drop policy if exists "service_assignments_select_related" on public.service_assignments;
create policy "service_assignments_select_related"
on public.service_assignments
for select
to authenticated
using (
  public.is_admin()
  or mechanic_id = public.current_mechanic_id()
  or public.is_assignment_for_current_customer(service_order_id)
);
