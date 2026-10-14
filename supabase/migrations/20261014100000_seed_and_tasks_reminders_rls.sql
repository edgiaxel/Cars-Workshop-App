-- ============================================================
-- PitMate Migration: Service Tasks, Reminders & Notifications RLS + Core Seeds
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

-- ============================================================
-- 4. ENSURE LICENSE PLATES AND VEHICLE NUMBERS
-- ============================================================

update public.vehicles
set license_plate = 'D 1999 AZ',
    vehicle_number = 'G81-01'
where model = 'M3 Touring' and (license_plate is null or license_plate = '');

update public.vehicles
set license_plate = 'D 1234 ZEN',
    vehicle_number = 'ZEN-01'
where model = 'Innova Zenix' and (license_plate is null or license_plate = '');

update public.vehicles
set license_plate = 'D 9999 RAP',
    vehicle_number = 'F150-01'
where model = 'Raptor' and (license_plate is null or license_plate = '');

update public.vehicles
set license_plate = 'WEC-15-HY',
    vehicle_number = '#15'
where model = 'M Hybrid V8' and (vehicle_number = '#15' or vehicle_number is null)
  and (license_plate is null or license_plate = '');

update public.vehicles
set license_plate = 'WEC-20-HY',
    vehicle_number = '#20'
where model = 'M Hybrid V8' and vehicle_number = '#20'
  and (license_plate is null or license_plate = '');

update public.vehicles
set license_plate = 'GT3-32-EVO',
    vehicle_number = '#32'
where model = 'M4 GT3' and vehicle_number = '#32'
  and (license_plate is null or license_plate = '');

update public.vehicles
set license_plate = 'GT3-46-EVO',
    vehicle_number = '#46'
where model = 'M4 GT3' and vehicle_number = '#46'
  and (license_plate is null or license_plate = '');

update public.vehicles
set license_plate = 'AMR-007-PRO',
    vehicle_number = '#007'
where model = 'Valkyrie' and vehicle_number = '#007'
  and (license_plate is null or license_plate = '');

update public.vehicles
set license_plate = 'AMR-009-PRO',
    vehicle_number = '#009'
where model = 'Valkyrie' and vehicle_number = '#009'
  and (license_plate is null or license_plate = '');

-- Fallback for any other vehicle with empty license_plate
update public.vehicles
set license_plate = coalesce(vehicle_number, 'B 1000 PIT')
where license_plate is null or license_plate = '';

-- ============================================================
-- 5. SEED BOOKINGS
-- ============================================================

insert into public.bookings (
  customer_id,
  vehicle_id,
  requested_service,
  description,
  preferred_date,
  preferred_time,
  status,
  admin_notes
)
select
  c.id,
  v.id,
  '30,000 KM Annual Maintenance: Castrol 5W-40 & Filters',
  'Routine 30k maintenance, oil change, brake check, and overall inspection.',
  current_date + interval '1 day',
  '13:00',
  'approved'::public.booking_status,
  'Technician Max Verstappen pre-allocated.'
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'Axel Zeed'
  and v.model = 'M3 Touring'
  and not exists (
    select 1 from public.bookings b
    where b.customer_id = c.id and b.vehicle_id = v.id
      and b.requested_service like '%30,000 KM Annual Maintenance%'
  );

insert into public.bookings (
  customer_id,
  vehicle_id,
  requested_service,
  description,
  preferred_date,
  preferred_time,
  status,
  admin_notes
)
select
  c.id,
  v.id,
  'Hybrid Drive Battery Cooling Duct Inspection',
  'Routine 20,000 KM hybrid drive battery cooling duct inspection and tire rotation.',
  current_date + interval '11 days',
  '10:00',
  'requested'::public.booking_status,
  'Awaiting customer drop-off confirmation.'
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'Axel Zeed'
  and v.model = 'Innova Zenix'
  and not exists (
    select 1 from public.bookings b
    where b.customer_id = c.id and b.vehicle_id = v.id
      and b.requested_service like '%Hybrid Drive Battery%'
  );

insert into public.bookings (
  customer_id,
  vehicle_id,
  requested_service,
  description,
  preferred_date,
  preferred_time,
  status,
  admin_notes
)
select
  c.id,
  v.id,
  'Powertrain Diagnostics & Hybrid Battery Inspection',
  'WEC pre-race high voltage system check and error code scan.',
  current_date,
  '08:30',
  'scheduled'::public.booking_status,
  'Urgent competition prep for Bay 1.'
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'BMW M Motorsport'
  and v.vehicle_number = '#15'
  and not exists (
    select 1 from public.bookings b
    where b.customer_id = c.id and b.vehicle_id = v.id
      and b.requested_service like '%Powertrain Diagnostics%'
  );

-- ============================================================
-- 6. SEED SERVICE ORDERS
-- ============================================================

-- SO-2026-001 (BMW M Hybrid V8 #15 - in_progress)
insert into public.service_orders (
  order_number,
  customer_id,
  vehicle_id,
  title,
  description,
  status,
  scheduled_start,
  scheduled_end,
  odometer_km,
  estimated_total,
  customer_approved
)
select
  'SO-2026-001',
  c.id,
  v.id,
  'Powertrain Diagnostics & Hybrid Battery Inspection',
  'Full system diagnostic scan, error code clearance, and high voltage cell balancing.',
  'in_progress'::public.service_status,
  current_date + interval '8 hours 30 minutes',
  current_date + interval '16 hours 30 minutes',
  18420,
  12500000.00,
  true
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'BMW M Motorsport' and v.vehicle_number = '#15'
and not exists (
  select 1 from public.service_orders where order_number = 'SO-2026-001'
);

-- SO-2026-002 (Valkyrie #007 - inspection)
insert into public.service_orders (
  order_number,
  customer_id,
  vehicle_id,
  title,
  description,
  status,
  scheduled_start,
  odometer_km,
  estimated_total,
  customer_approved
)
select
  'SO-2026-002',
  c.id,
  v.id,
  'Endurance Track Setup & Aerodynamic Calibration',
  'Active suspension calibration, damper telemetry check, and track alignment.',
  'inspection'::public.service_status,
  current_date + interval '1 day 9 hours',
  4820,
  24000000.00,
  true
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'Aston Martin' and v.vehicle_number = '#007'
and not exists (
  select 1 from public.service_orders where order_number = 'SO-2026-002'
);

-- SO-2026-003 (Axel Zeed - BMW M3 Touring - completed)
insert into public.service_orders (
  order_number,
  customer_id,
  vehicle_id,
  title,
  description,
  status,
  scheduled_start,
  scheduled_end,
  odometer_km,
  estimated_total,
  final_total,
  customer_approved,
  completed_at,
  closed_at
)
select
  'SO-2026-003',
  c.id,
  v.id,
  '30,000 KM Annual Maintenance: Castrol 5W-40 & Filters',
  '30,000 KM Annual Maintenance: Castrol 5W-40 full synthetic oil service, oil filter replacement, air filter change, and full brake system inspection.',
  'completed'::public.service_status,
  current_date - interval '2 days',
  current_date - interval '2 days' + interval '3 hours',
  28650,
  3850000.00,
  3850000.00,
  true,
  now() - interval '2 days',
  now() - interval '2 days'
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'Axel Zeed' and v.model = 'M3 Touring'
and not exists (
  select 1 from public.service_orders where order_number = 'SO-2026-003'
);

-- SO-2026-004 (Axel Zeed - Ford Raptor - waiting_for_parts)
insert into public.service_orders (
  order_number,
  customer_id,
  vehicle_id,
  title,
  description,
  status,
  scheduled_start,
  odometer_km,
  estimated_total,
  customer_approved
)
select
  'SO-2026-004',
  c.id,
  v.id,
  'Suspension & Bushing Inspection',
  'Front Fox Racing shock absorber damper rebound inspection and control arm bushings.',
  'waiting_for_parts'::public.service_status,
  current_date + interval '2 days 10 hours',
  42100,
  4500000.00,
  true
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'Axel Zeed' and v.model = 'Raptor'
and not exists (
  select 1 from public.service_orders where order_number = 'SO-2026-004'
);

-- SO-2026-005 (BMW M Hybrid V8 #20 - scheduled)
insert into public.service_orders (
  order_number,
  customer_id,
  vehicle_id,
  title,
  description,
  status,
  scheduled_start,
  odometer_km,
  estimated_total,
  customer_approved
)
select
  'SO-2026-005',
  c.id,
  v.id,
  'Pre-Race Inspection & High-Voltage Systems Verification',
  'Perform competition vehicle inspection before track or endurance testing.',
  'scheduled'::public.service_status,
  current_date + interval '3 days 9 hours',
  16780,
  8500000.00,
  true
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'BMW M Motorsport' and v.vehicle_number = '#20'
and not exists (
  select 1 from public.service_orders where order_number = 'SO-2026-005'
);

-- SO-2026-000 (BMW M4 GT3 #46 - closed)
insert into public.service_orders (
  order_number,
  customer_id,
  vehicle_id,
  title,
  description,
  status,
  scheduled_start,
  scheduled_end,
  odometer_km,
  estimated_total,
  final_total,
  customer_approved,
  completed_at,
  closed_at
)
select
  'SO-2026-000',
  c.id,
  v.id,
  'Post-Race Telemetry Download & Caliper Bleed',
  'Post-race telemetry download, brake caliper bleed, damper inspection, and spark plug replacement (8x NGK Iridium).',
  'closed'::public.service_status,
  current_date - interval '6 days',
  current_date - interval '6 days' + interval '4 hours',
  10980,
  5200000.00,
  5200000.00,
  true,
  now() - interval '6 days',
  now() - interval '6 days'
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'BMW M Motorsport' and v.vehicle_number = '#46'
and not exists (
  select 1 from public.service_orders where order_number = 'SO-2026-000'
);

-- ============================================================
-- 7. SEED SERVICE ASSIGNMENTS
-- ============================================================

-- Assign Max Verstappen (MEC-001) to SO-2026-001
insert into public.service_assignments (
  service_order_id,
  mechanic_id,
  role_description,
  assigned_at
)
select
  so.id,
  m.id,
  'Lead Diagnostics & Powertrain Engineer',
  now()
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-001'
  and p.full_name = 'Max Verstappen'
  and not exists (
    select 1 from public.service_assignments a
    where a.service_order_id = so.id and a.mechanic_id = m.id
  );

-- Assign Max Verstappen to SO-2026-003
insert into public.service_assignments (
  service_order_id,
  mechanic_id,
  role_description,
  assigned_at,
  completed_at
)
select
  so.id,
  m.id,
  'Lead Master Technician',
  now() - interval '2 days',
  now() - interval '2 days'
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-003'
  and p.full_name = 'Max Verstappen'
  and not exists (
    select 1 from public.service_assignments a
    where a.service_order_id = so.id and a.mechanic_id = m.id
  );

-- Assign Sergio Perez (MEC-002) to SO-2026-002
insert into public.service_assignments (
  service_order_id,
  mechanic_id,
  role_description,
  assigned_at
)
select
  so.id,
  m.id,
  'Lead Chassis & Suspension Specialist',
  now()
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-002'
  and p.full_name = 'Sergio Perez'
  and not exists (
    select 1 from public.service_assignments a
    where a.service_order_id = so.id and a.mechanic_id = m.id
  );

-- Assign Sergio Perez to SO-2026-004
insert into public.service_assignments (
  service_order_id,
  mechanic_id,
  role_description,
  assigned_at
)
select
  so.id,
  m.id,
  'Off-Road Suspension Technician',
  now()
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-004'
  and p.full_name = 'Sergio Perez'
  and not exists (
    select 1 from public.service_assignments a
    where a.service_order_id = so.id and a.mechanic_id = m.id
  );

-- Assign Max Verstappen to SO-2026-005
insert into public.service_assignments (
  service_order_id,
  mechanic_id,
  role_description,
  assigned_at
)
select
  so.id,
  m.id,
  'Performance Systems Engineer',
  now()
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-005'
  and p.full_name = 'Max Verstappen'
  and not exists (
    select 1 from public.service_assignments a
    where a.service_order_id = so.id and a.mechanic_id = m.id
  );

-- Assign Max Verstappen to SO-2026-000
insert into public.service_assignments (
  service_order_id,
  mechanic_id,
  role_description,
  assigned_at,
  completed_at
)
select
  so.id,
  m.id,
  'Performance Tech',
  now() - interval '6 days',
  now() - interval '6 days'
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-000'
  and p.full_name = 'Max Verstappen'
  and not exists (
    select 1 from public.service_assignments a
    where a.service_order_id = so.id and a.mechanic_id = m.id
  );

-- ============================================================
-- 8. SEED SERVICE TASKS
-- ============================================================

-- Tasks for SO-2026-001 (assigned to Max Verstappen)
insert into public.service_tasks (
  service_order_id,
  assigned_mechanic_id,
  title,
  description,
  status,
  estimated_minutes,
  actual_minutes,
  started_at,
  completed_at
)
select
  so.id,
  m.id,
  'Engine Diagnostic Inspection',
  'Run diagnostic scan, inspect fault codes and verify engine operating parameters.',
  'completed'::public.task_status,
  60,
  55,
  now() - interval '3 hours',
  now() - interval '2 hours'
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-001' and p.full_name = 'Max Verstappen'
and not exists (
  select 1 from public.service_tasks st
  where st.service_order_id = so.id and st.title = 'Engine Diagnostic Inspection'
);

insert into public.service_tasks (
  service_order_id,
  assigned_mechanic_id,
  title,
  description,
  status,
  estimated_minutes,
  actual_minutes,
  started_at
)
select
  so.id,
  m.id,
  'High Voltage System Inspection',
  'Inspect hybrid high-voltage system status and associated diagnostic telemetry.',
  'in_progress'::public.task_status,
  90,
  45,
  now() - interval '45 minutes'
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-001' and p.full_name = 'Max Verstappen'
and not exists (
  select 1 from public.service_tasks st
  where st.service_order_id = so.id and st.title = 'High Voltage System Inspection'
);

insert into public.service_tasks (
  service_order_id,
  assigned_mechanic_id,
  title,
  description,
  status,
  estimated_minutes
)
select
  so.id,
  m.id,
  'Brake System Inspection',
  'Inspect brake discs, pads, calipers, lines and Motul racing fluid condition.',
  'pending'::public.task_status,
  45
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-001' and p.full_name = 'Max Verstappen'
and not exists (
  select 1 from public.service_tasks st
  where st.service_order_id = so.id and st.title = 'Brake System Inspection'
);

insert into public.service_tasks (
  service_order_id,
  assigned_mechanic_id,
  title,
  description,
  status,
  estimated_minutes
)
select
  so.id,
  m.id,
  'Cooling System Inspection',
  'Inspect coolant level, hoses, radiator, expansion tank and thermal leaks.',
  'pending'::public.task_status,
  40
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-001' and p.full_name = 'Max Verstappen'
and not exists (
  select 1 from public.service_tasks st
  where st.service_order_id = so.id and st.title = 'Cooling System Inspection'
);

-- Task for SO-2026-005
insert into public.service_tasks (
  service_order_id,
  assigned_mechanic_id,
  title,
  description,
  status,
  estimated_minutes
)
select
  so.id,
  m.id,
  'Pre-Race Telemetry Verification',
  'Perform competition vehicle inspection before track or endurance testing.',
  'pending'::public.task_status,
  120
from public.service_orders so
cross join public.mechanics m
join public.profiles p on p.id = m.profile_id
where so.order_number = 'SO-2026-005' and p.full_name = 'Max Verstappen'
and not exists (
  select 1 from public.service_tasks st
  where st.service_order_id = so.id and st.title = 'Pre-Race Telemetry Verification'
);

-- ============================================================
-- 9. SEED SERVICE REMINDERS
-- ============================================================

insert into public.service_reminders (
  customer_id,
  vehicle_id,
  reminder_type,
  title,
  description,
  due_date,
  due_mileage_km,
  status
)
select
  c.id,
  v.id,
  'maintenance'::public.reminder_type,
  'BMW M3 Touring Scheduled Maintenance',
  'Review engine oil, brake system, tires and vehicle inspection items.',
  current_date + interval '30 days',
  30000,
  'pending'::public.reminder_status
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'Axel Zeed' and v.model = 'M3 Touring'
and not exists (
  select 1 from public.service_reminders r
  where r.vehicle_id = v.id and r.title = 'BMW M3 Touring Scheduled Maintenance'
);

insert into public.service_reminders (
  customer_id,
  vehicle_id,
  reminder_type,
  title,
  description,
  due_date,
  due_mileage_km,
  status
)
select
  c.id,
  v.id,
  'inspection'::public.reminder_type,
  'Toyota Innova Zenix Hybrid Check',
  'Routine 20,000 KM hybrid drive battery cooling duct inspection and tire rotation.',
  current_date + interval '60 days',
  20000,
  'pending'::public.reminder_status
from public.customers c
join public.profiles p on p.id = c.profile_id
join public.vehicles v on v.customer_id = c.id
where p.full_name = 'Axel Zeed' and v.model = 'Innova Zenix'
and not exists (
  select 1 from public.service_reminders r
  where r.vehicle_id = v.id and r.title = 'Toyota Innova Zenix Hybrid Check'
);

-- ============================================================
-- 10. SEED NOTIFICATIONS
-- ============================================================

-- Notifications for Axel Zeed
insert into public.notifications (
  recipient_id,
  type,
  priority,
  title,
  message,
  is_read
)
select
  p.id,
  'booking'::public.notification_type,
  'normal'::public.notification_priority,
  'Booking Confirmed',
  'Your appointment for BMW M3 Touring on Oct 15 at 13:00 WIB has been confirmed.',
  false
from public.profiles p
where p.full_name = 'Axel Zeed'
and not exists (
  select 1 from public.notifications n
  where n.recipient_id = p.id and n.title = 'Booking Confirmed'
);

insert into public.notifications (
  recipient_id,
  type,
  priority,
  title,
  message,
  is_read
)
select
  p.id,
  'service'::public.notification_type,
  'high'::public.notification_priority,
  'Service Order Closed',
  'Work order SO-2026-003 has been completed. Your invoice receipt is now available.',
  true
from public.profiles p
where p.full_name = 'Axel Zeed'
and not exists (
  select 1 from public.notifications n
  where n.recipient_id = p.id and n.title = 'Service Order Closed'
);

insert into public.notifications (
  recipient_id,
  type,
  priority,
  title,
  message,
  is_read
)
select
  p.id,
  'reminder'::public.notification_type,
  'low'::public.notification_priority,
  'Maintenance Reminder',
  'Annual maintenance is approaching for your BMW M3 Touring (28,650 KM).',
  true
from public.profiles p
where p.full_name = 'Axel Zeed'
and not exists (
  select 1 from public.notifications n
  where n.recipient_id = p.id and n.title = 'Maintenance Reminder'
);

-- Notifications for Max Verstappen
insert into public.notifications (
  recipient_id,
  type,
  priority,
  title,
  message,
  is_read
)
select
  p.id,
  'service'::public.notification_type,
  'high'::public.notification_priority,
  'New Job Assignment',
  'Assigned as lead technician for SO-2026-001 (BMW M Hybrid V8 #15).',
  false
from public.profiles p
where p.full_name = 'Max Verstappen'
and not exists (
  select 1 from public.notifications n
  where n.recipient_id = p.id and n.title = 'New Job Assignment'
);

insert into public.notifications (
  recipient_id,
  type,
  priority,
  title,
  message,
  is_read
)
select
  p.id,
  'system'::public.notification_type,
  'normal'::public.notification_priority,
  'Parts Request Ready',
  'Castrol 5W-40 Synthetic Oil and Filters are ready in Bay 1.',
  true
from public.profiles p
where p.full_name = 'Max Verstappen'
and not exists (
  select 1 from public.notifications n
  where n.recipient_id = p.id and n.title = 'Parts Request Ready'
);

-- Notifications for Christian Horner (Admin)
insert into public.notifications (
  recipient_id,
  type,
  priority,
  title,
  message,
  is_read
)
select
  p.id,
  'inventory'::public.notification_type,
  'urgent'::public.notification_priority,
  'Low Inventory Alert',
  'Front Performance Brake Pad Set (Brembo) has dropped to minimum stock threshold.',
  false
from public.profiles p
where p.full_name = 'Christian Horner'
and not exists (
  select 1 from public.notifications n
  where n.recipient_id = p.id and n.title = 'Low Inventory Alert'
);

insert into public.notifications (
  recipient_id,
  type,
  priority,
  title,
  message,
  is_read
)
select
  p.id,
  'booking'::public.notification_type,
  'normal'::public.notification_priority,
  'New Booking Request',
  'Axel Zeed requested appointment for Toyota Innova Zenix.',
  false
from public.profiles p
where p.full_name = 'Christian Horner'
and not exists (
  select 1 from public.notifications n
  where n.recipient_id = p.id and n.title = 'New Booking Request'
);
