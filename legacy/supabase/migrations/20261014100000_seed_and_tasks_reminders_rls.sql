-- ============================================================
-- PitMate Migration: Service Tasks, Reminders & Notifications RLS
-- ============================================================

-- 1. Fix RLS on public.service_reminders
drop policy if exists "reminders_select_own_or_admin" on public.service_reminders;
drop policy if exists "reminders_insert_own_or_admin" on public.service_reminders;
drop policy if exists "reminders_update_own_or_admin" on public.service_reminders;
drop policy if exists "reminders_delete_admin" on public.service_reminders;

create policy "reminders_select_own_or_staff"
on public.service_reminders
for select
to authenticated
using (
  customer_id = public.current_customer_id()
  or public.is_admin()
  or public.is_mechanic()
);

create policy "reminders_manage_own_or_admin"
on public.service_reminders
for all
to authenticated
using (
  customer_id = public.current_customer_id()
  or public.is_admin()
)
with check (
  customer_id = public.current_customer_id()
  or public.is_admin()
);

-- 2. Fix RLS on public.notifications
drop policy if exists "notifications_select_own_or_admin" on public.notifications;
drop policy if exists "notifications_update_own_or_admin" on public.notifications;
drop policy if exists "notifications_insert_admin" on public.notifications;

create policy "notifications_select_own_or_admin"
on public.notifications
for select
to authenticated
using (
  recipient_id = auth.uid()
  or public.is_admin()
);

create policy "notifications_update_own_or_admin"
on public.notifications
for update
to authenticated
using (
  recipient_id = auth.uid()
  or public.is_admin()
)
with check (
  recipient_id = auth.uid()
  or public.is_admin()
);

create policy "notifications_insert_staff_or_self"
on public.notifications
for insert
to authenticated
with check (
  recipient_id = auth.uid()
  or public.is_admin()
  or public.is_mechanic()
);

-- 3. Fix RLS on public.service_tasks
drop policy if exists "service_tasks_select_related" on public.service_tasks;
drop policy if exists "service_tasks_manage_assigned_or_admin" on public.service_tasks;

create policy "service_tasks_select_related"
on public.service_tasks
for select
to authenticated
using (
  public.is_admin()
  or public.is_mechanic()
  or exists (
    select 1
    from public.service_orders so
    where so.id = service_tasks.service_order_id
      and so.customer_id = public.current_customer_id()
  )
);

create policy "service_tasks_manage_assigned_or_admin"
on public.service_tasks
for all
to authenticated
using (
  public.is_admin()
  or assigned_mechanic_id = public.current_mechanic_id()
)
with check (
  public.is_admin()
  or assigned_mechanic_id = public.current_mechanic_id()
);
