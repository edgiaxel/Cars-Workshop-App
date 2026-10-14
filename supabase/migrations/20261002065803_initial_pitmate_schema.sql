-- ============================================================
-- PitMate Initial Database Schema
-- Migration: 20261002065803_initial_pitmate_schema
-- ============================================================

create extension if not exists pgcrypto;

-- ============================================================
-- ENUMS
-- ============================================================

create type public.user_role as enum (
  'admin',
  'mechanic',
  'customer'
);

create type public.customer_type as enum (
  'individual',
  'company'
);

create type public.booking_status as enum (
  'requested',
  'approved',
  'rejected',
  'scheduled',
  'cancelled',
  'completed'
);

create type public.service_status as enum (
  'requested',
  'approved',
  'scheduled',
  'inspection',
  'diagnosis',
  'waiting_for_approval',
  'waiting_for_parts',
  'in_progress',
  'completion_review',
  'completed',
  'payment',
  'closed',
  'cancelled'
);

create type public.task_status as enum (
  'pending',
  'in_progress',
  'completed',
  'blocked',
  'cancelled'
);

create type public.part_request_status as enum (
  'requested',
  'approved',
  'rejected',
  'fulfilled',
  'cancelled'
);

create type public.inventory_transaction_type as enum (
  'initial_stock',
  'purchase',
  'service_usage',
  'adjustment',
  'return',
  'damaged'
);

create type public.notification_type as enum (
  'booking',
  'service',
  'inventory',
  'payment',
  'reminder',
  'system'
);

create type public.notification_priority as enum (
  'low',
  'normal',
  'high',
  'urgent'
);

create type public.reminder_type as enum (
  'service',
  'maintenance',
  'inspection',
  'custom'
);

create type public.reminder_status as enum (
  'pending',
  'completed',
  'dismissed',
  'cancelled'
);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============================================================
-- PROFILES
-- ============================================================

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.user_role not null,
  full_name text not null,
  phone text,
  avatar_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- CUSTOMERS
-- ============================================================

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references public.profiles(id) on delete cascade,
  customer_type public.customer_type not null,
  company_name text,
  address text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint customers_company_name_check
    check (
      (customer_type = 'company' and company_name is not null)
      or
      (customer_type = 'individual')
    )
);

-- ============================================================
-- MECHANICS
-- ============================================================

create table public.mechanics (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references public.profiles(id) on delete cascade,
  employee_code text not null unique,
  specialization text,
  hourly_rate numeric(12,2) not null default 0 check (hourly_rate >= 0),
  compensation_percentage numeric(5,2) not null default 30
    check (compensation_percentage >= 0 and compensation_percentage <= 100),
  hire_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- VEHICLES
-- ============================================================

create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  make text not null,
  model text not null,
  variant text,
  model_year integer,
  license_plate text,
  vin text,
  vehicle_number text,
  mileage_km integer not null default 0 check (mileage_km >= 0),
  color text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- BOOKINGS
-- ============================================================

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete restrict,
  vehicle_id uuid not null references public.vehicles(id) on delete restrict,
  requested_service text not null,
  description text,
  preferred_date date,
  preferred_time time,
  status public.booking_status not null default 'requested',
  admin_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- SERVICE ORDERS
-- ============================================================

create table public.service_orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  booking_id uuid unique references public.bookings(id) on delete set null,
  customer_id uuid not null references public.customers(id) on delete restrict,
  vehicle_id uuid not null references public.vehicles(id) on delete restrict,
  title text not null,
  description text,
  status public.service_status not null default 'requested',
  scheduled_start timestamptz,
  scheduled_end timestamptz,
  odometer_km integer check (odometer_km >= 0),
  estimated_total numeric(12,2) not null default 0 check (estimated_total >= 0),
  final_total numeric(12,2) check (final_total >= 0),
  customer_approved boolean not null default false,
  completed_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- SERVICE STATUS HISTORY
-- ============================================================

create table public.service_status_history (
  id uuid primary key default gen_random_uuid(),
  service_order_id uuid not null references public.service_orders(id) on delete cascade,
  previous_status public.service_status,
  new_status public.service_status not null,
  changed_by uuid references public.profiles(id) on delete set null,
  notes text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- SERVICE ASSIGNMENTS
-- ============================================================

create table public.service_assignments (
  id uuid primary key default gen_random_uuid(),
  service_order_id uuid not null references public.service_orders(id) on delete cascade,
  mechanic_id uuid not null references public.mechanics(id) on delete restrict,
  assigned_by uuid references public.profiles(id) on delete set null,
  role_description text,
  assigned_at timestamptz not null default now(),
  completed_at timestamptz,

  unique(service_order_id, mechanic_id)
);

-- ============================================================
-- TASK TEMPLATES
-- ============================================================

create table public.task_templates (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  category text,
  estimated_minutes integer check (estimated_minutes >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- ============================================================
-- SERVICE TASKS
-- ============================================================

create table public.service_tasks (
  id uuid primary key default gen_random_uuid(),
  service_order_id uuid not null references public.service_orders(id) on delete cascade,
  assigned_mechanic_id uuid references public.mechanics(id) on delete set null,
  template_id uuid references public.task_templates(id) on delete set null,
  title text not null,
  description text,
  status public.task_status not null default 'pending',
  estimated_minutes integer check (estimated_minutes >= 0),
  actual_minutes integer check (actual_minutes >= 0),
  started_at timestamptz,
  completed_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- TASK CHECKLISTS
-- ============================================================

create table public.task_checklists (
  id uuid primary key default gen_random_uuid(),
  service_task_id uuid not null references public.service_tasks(id) on delete cascade,
  item_text text not null,
  is_completed boolean not null default false,
  completed_by uuid references public.profiles(id) on delete set null,
  completed_at timestamptz,
  sort_order integer not null default 0
);

-- ============================================================
-- SPARE PARTS
-- ============================================================

create table public.spare_parts (
  id uuid primary key default gen_random_uuid(),
  sku text not null unique,
  name text not null,
  category text not null,
  brand text,
  description text,
  unit text not null default 'pcs',
  unit_cost numeric(12,2) not null check (unit_cost >= 0),
  selling_price numeric(12,2) not null check (selling_price >= 0),
  minimum_stock integer not null default 0 check (minimum_stock >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- INVENTORY TRANSACTIONS
-- ============================================================

create table public.inventory_transactions (
  id uuid primary key default gen_random_uuid(),
  spare_part_id uuid not null references public.spare_parts(id) on delete restrict,
  transaction_type public.inventory_transaction_type not null,
  quantity integer not null check (quantity <> 0),
  unit_cost numeric(12,2) check (unit_cost >= 0),
  service_order_id uuid references public.service_orders(id) on delete set null,
  performed_by uuid references public.profiles(id) on delete set null,
  notes text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- PART REQUESTS
-- ============================================================

create table public.part_requests (
  id uuid primary key default gen_random_uuid(),
  service_order_id uuid not null references public.service_orders(id) on delete cascade,
  requested_by uuid not null references public.mechanics(id) on delete restrict,
  spare_part_id uuid not null references public.spare_parts(id) on delete restrict,
  quantity integer not null check (quantity > 0),
  status public.part_request_status not null default 'requested',
  approved_by uuid references public.profiles(id) on delete set null,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- SERVICE PARTS
-- ============================================================

create table public.service_parts (
  id uuid primary key default gen_random_uuid(),
  service_order_id uuid not null references public.service_orders(id) on delete cascade,
  spare_part_id uuid not null references public.spare_parts(id) on delete restrict,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  added_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

-- ============================================================
-- SERVICE COSTS
-- ============================================================

create table public.service_costs (
  id uuid primary key default gen_random_uuid(),
  service_order_id uuid not null references public.service_orders(id) on delete cascade,
  category text not null,
  description text not null,
  quantity numeric(12,2) not null default 1 check (quantity >= 0),
  unit_price numeric(12,2) not null,
  total_amount numeric(12,2) not null,
  is_estimate boolean not null default true,
  created_at timestamptz not null default now()
);

-- ============================================================
-- MECHANIC EARNINGS
-- ============================================================

create table public.mechanic_earnings (
  id uuid primary key default gen_random_uuid(),
  mechanic_id uuid not null references public.mechanics(id) on delete restrict,
  service_order_id uuid not null references public.service_orders(id) on delete restrict,
  labor_amount numeric(12,2) not null check (labor_amount >= 0),
  compensation_percentage numeric(5,2) not null
    check (compensation_percentage >= 0 and compensation_percentage <= 100),
  earnings_amount numeric(12,2) not null check (earnings_amount >= 0),
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  paid_at timestamptz,

  unique(mechanic_id, service_order_id)
);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  type public.notification_type not null,
  priority public.notification_priority not null default 'normal',
  title text not null,
  message text not null,
  service_order_id uuid references public.service_orders(id) on delete cascade,
  is_read boolean not null default false,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

-- ============================================================
-- SERVICE REMINDERS
-- ============================================================

create table public.service_reminders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  reminder_type public.reminder_type not null,
  title text not null,
  description text,
  due_date date,
  due_mileage_km integer check (due_mileage_km >= 0),
  status public.reminder_status not null default 'pending',
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

-- ============================================================
-- UPDATED_AT TRIGGERS
-- ============================================================

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger customers_set_updated_at
before update on public.customers
for each row execute function public.set_updated_at();

create trigger mechanics_set_updated_at
before update on public.mechanics
for each row execute function public.set_updated_at();

create trigger vehicles_set_updated_at
before update on public.vehicles
for each row execute function public.set_updated_at();

create trigger bookings_set_updated_at
before update on public.bookings
for each row execute function public.set_updated_at();

create trigger service_orders_set_updated_at
before update on public.service_orders
for each row execute function public.set_updated_at();

create trigger service_tasks_set_updated_at
before update on public.service_tasks
for each row execute function public.set_updated_at();

create trigger spare_parts_set_updated_at
before update on public.spare_parts
for each row execute function public.set_updated_at();

create trigger part_requests_set_updated_at
before update on public.part_requests
for each row execute function public.set_updated_at();

-- ============================================================
-- INDEXES
-- ============================================================

create index profiles_role_idx
  on public.profiles(role);

create index customers_profile_id_idx
  on public.customers(profile_id);

create index mechanics_profile_id_idx
  on public.mechanics(profile_id);

create index vehicles_customer_id_idx
  on public.vehicles(customer_id);

create index bookings_customer_id_idx
  on public.bookings(customer_id);

create index bookings_vehicle_id_idx
  on public.bookings(vehicle_id);

create index bookings_status_idx
  on public.bookings(status);

create index service_orders_customer_id_idx
  on public.service_orders(customer_id);

create index service_orders_vehicle_id_idx
  on public.service_orders(vehicle_id);

create index service_orders_status_idx
  on public.service_orders(status);

create index service_status_history_order_idx
  on public.service_status_history(service_order_id);

create index service_assignments_order_idx
  on public.service_assignments(service_order_id);

create index service_assignments_mechanic_idx
  on public.service_assignments(mechanic_id);

create index service_tasks_order_idx
  on public.service_tasks(service_order_id);

create index service_tasks_mechanic_idx
  on public.service_tasks(assigned_mechanic_id);

create index task_checklists_task_idx
  on public.task_checklists(service_task_id);

create index inventory_transactions_part_idx
  on public.inventory_transactions(spare_part_id);

create index inventory_transactions_order_idx
  on public.inventory_transactions(service_order_id);

create index part_requests_order_idx
  on public.part_requests(service_order_id);

create index part_requests_mechanic_idx
  on public.part_requests(requested_by);

create index service_parts_order_idx
  on public.service_parts(service_order_id);

create index service_costs_order_idx
  on public.service_costs(service_order_id);

create index mechanic_earnings_mechanic_idx
  on public.mechanic_earnings(mechanic_id);

create index notifications_recipient_idx
  on public.notifications(recipient_id);

create index notifications_unread_idx
  on public.notifications(recipient_id, is_read);

create index reminders_customer_idx
  on public.service_reminders(customer_id);

create index reminders_vehicle_idx
  on public.service_reminders(vehicle_id);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.profiles enable row level security;
alter table public.customers enable row level security;
alter table public.mechanics enable row level security;
alter table public.vehicles enable row level security;
alter table public.bookings enable row level security;
alter table public.service_orders enable row level security;
alter table public.service_status_history enable row level security;
alter table public.service_assignments enable row level security;
alter table public.task_templates enable row level security;
alter table public.service_tasks enable row level security;
alter table public.task_checklists enable row level security;
alter table public.spare_parts enable row level security;
alter table public.inventory_transactions enable row level security;
alter table public.part_requests enable row level security;
alter table public.service_parts enable row level security;
alter table public.service_costs enable row level security;
alter table public.mechanic_earnings enable row level security;
alter table public.notifications enable row level security;
alter table public.service_reminders enable row level security;

-- ============================================================
-- PROFILES POLICIES
-- ============================================================

create policy "profiles_select_own_or_admin"
on public.profiles
for select
to authenticated
using (
  id = (select auth.uid())
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "profiles_update_own_or_admin"
on public.profiles
for update
to authenticated
using (
  id = (select auth.uid())
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  id = (select auth.uid())
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "profiles_insert_admin"
on public.profiles
for insert
to authenticated
with check (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "profiles_delete_admin"
on public.profiles
for delete
to authenticated
using (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- CUSTOMER POLICIES
-- ============================================================

create policy "customers_select_own_or_admin"
on public.customers
for select
to authenticated
using (
  profile_id = (select auth.uid())
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "customers_insert_self_or_admin"
on public.customers
for insert
to authenticated
with check (
  profile_id = (select auth.uid())
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "customers_update_own_or_admin"
on public.customers
for update
to authenticated
using (
  profile_id = (select auth.uid())
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  profile_id = (select auth.uid())
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "customers_delete_admin"
on public.customers
for delete
to authenticated
using (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- MECHANIC POLICIES
-- ============================================================

create policy "mechanics_select_own_or_admin"
on public.mechanics
for select
to authenticated
using (
  profile_id = (select auth.uid())
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "mechanics_insert_admin"
on public.mechanics
for insert
to authenticated
with check (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "mechanics_update_own_or_admin"
on public.mechanics
for update
to authenticated
using (
  profile_id = (select auth.uid())
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  profile_id = (select auth.uid())
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "mechanics_delete_admin"
on public.mechanics
for delete
to authenticated
using (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- VEHICLE POLICIES
-- ============================================================

create policy "vehicles_select_owner_mechanic_admin"
on public.vehicles
for select
to authenticated
using (
  exists (
    select 1
    from public.customers c
    where c.id = vehicles.customer_id
      and c.profile_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.service_orders so
    join public.service_assignments sa
      on sa.service_order_id = so.id
    join public.mechanics m
      on m.id = sa.mechanic_id
    where so.vehicle_id = vehicles.id
      and m.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "vehicles_insert_owner_or_admin"
on public.vehicles
for insert
to authenticated
with check (
  exists (
    select 1
    from public.customers c
    where c.id = vehicles.customer_id
      and c.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "vehicles_update_owner_or_admin"
on public.vehicles
for update
to authenticated
using (
  exists (
    select 1
    from public.customers c
    where c.id = vehicles.customer_id
      and c.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  exists (
    select 1
    from public.customers c
    where c.id = vehicles.customer_id
      and c.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "vehicles_delete_owner_or_admin"
on public.vehicles
for delete
to authenticated
using (
  exists (
    select 1
    from public.customers c
    where c.id = vehicles.customer_id
      and c.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- BOOKING POLICIES
-- ============================================================

create policy "bookings_select_owner_or_admin"
on public.bookings
for select
to authenticated
using (
  exists (
    select 1
    from public.customers c
    where c.id = bookings.customer_id
      and c.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "bookings_insert_owner_or_admin"
on public.bookings
for insert
to authenticated
with check (
  exists (
    select 1
    from public.customers c
    where c.id = bookings.customer_id
      and c.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "bookings_update_owner_or_admin"
on public.bookings
for update
to authenticated
using (
  exists (
    select 1
    from public.customers c
    where c.id = bookings.customer_id
      and c.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  exists (
    select 1
    from public.customers c
    where c.id = bookings.customer_id
      and c.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "bookings_delete_admin"
on public.bookings
for delete
to authenticated
using (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- SERVICE ORDER POLICIES
-- ============================================================

create policy "service_orders_select_customer_mechanic_admin"
on public.service_orders
for select
to authenticated
using (
  exists (
    select 1
    from public.customers c
    where c.id = service_orders.customer_id
      and c.profile_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.service_assignments sa
    join public.mechanics m
      on m.id = sa.mechanic_id
    where sa.service_order_id = service_orders.id
      and m.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "service_orders_insert_customer_or_admin"
on public.service_orders
for insert
to authenticated
with check (
  exists (
    select 1
    from public.customers c
    where c.id = service_orders.customer_id
      and c.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "service_orders_update_assigned_or_admin"
on public.service_orders
for update
to authenticated
using (
  exists (
    select 1
    from public.service_assignments sa
    join public.mechanics m
      on m.id = sa.mechanic_id
    where sa.service_order_id = service_orders.id
      and m.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  exists (
    select 1
    from public.service_assignments sa
    join public.mechanics m
      on m.id = sa.mechanic_id
    where sa.service_order_id = service_orders.id
      and m.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "service_orders_delete_admin"
on public.service_orders
for delete
to authenticated
using (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- SERVICE ASSIGNMENTS
-- ============================================================

create policy "service_assignments_select_related"
on public.service_assignments
for select
to authenticated
using (
  exists (
    select 1
    from public.mechanics m
    where m.id = service_assignments.mechanic_id
      and m.profile_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.service_orders so
    join public.customers c
      on c.id = so.customer_id
    where so.id = service_assignments.service_order_id
      and c.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "service_assignments_manage_admin"
on public.service_assignments
for all
to authenticated
using (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- TASK TEMPLATE POLICIES
-- ============================================================

create policy "task_templates_select_authenticated"
on public.task_templates
for select
to authenticated
using (true);

create policy "task_templates_manage_admin"
on public.task_templates
for all
to authenticated
using (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- SERVICE TASK POLICIES
-- ============================================================

create policy "service_tasks_select_related"
on public.service_tasks
for select
to authenticated
using (
  exists (
    select 1
    from public.mechanics m
    where m.id = service_tasks.assigned_mechanic_id
      and m.profile_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.service_orders so
    join public.customers c
      on c.id = so.customer_id
    where so.id = service_tasks.service_order_id
      and c.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "service_tasks_manage_assigned_or_admin"
on public.service_tasks
for all
to authenticated
using (
  exists (
    select 1
    from public.mechanics m
    where m.id = service_tasks.assigned_mechanic_id
      and m.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  exists (
    select 1
    from public.mechanics m
    where m.id = service_tasks.assigned_mechanic_id
      and m.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- CHECKLIST POLICIES
-- ============================================================

create policy "task_checklists_select_related"
on public.task_checklists
for select
to authenticated
using (
  exists (
    select 1
    from public.service_tasks st
    join public.mechanics m
      on m.id = st.assigned_mechanic_id
    where st.id = task_checklists.service_task_id
      and m.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "task_checklists_manage_assigned_or_admin"
on public.task_checklists
for all
to authenticated
using (
  exists (
    select 1
    from public.service_tasks st
    join public.mechanics m
      on m.id = st.assigned_mechanic_id
    where st.id = task_checklists.service_task_id
      and m.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  exists (
    select 1
    from public.service_tasks st
    join public.mechanics m
      on m.id = st.assigned_mechanic_id
    where st.id = task_checklists.service_task_id
      and m.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- SPARE PART POLICIES
-- ============================================================

create policy "spare_parts_select_authenticated"
on public.spare_parts
for select
to authenticated
using (true);

create policy "spare_parts_manage_admin"
on public.spare_parts
for all
to authenticated
using (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- INVENTORY POLICIES
-- ============================================================

create policy "inventory_transactions_select_admin_or_mechanic"
on public.inventory_transactions
for select
to authenticated
using (
  (select auth.jwt() -> 'app_metadata' ->> 'role') in ('admin', 'mechanic')
);

create policy "inventory_transactions_manage_admin"
on public.inventory_transactions
for all
to authenticated
using (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- PART REQUEST POLICIES
-- ============================================================

create policy "part_requests_select_related"
on public.part_requests
for select
to authenticated
using (
  exists (
    select 1
    from public.mechanics m
    where m.id = part_requests.requested_by
      and m.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "part_requests_insert_mechanic_or_admin"
on public.part_requests
for insert
to authenticated
with check (
  exists (
    select 1
    from public.mechanics m
    where m.id = part_requests.requested_by
      and m.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "part_requests_update_admin"
on public.part_requests
for update
to authenticated
using (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- SERVICE PARTS
-- ============================================================

create policy "service_parts_select_related"
on public.service_parts
for select
to authenticated
using (
  exists (
    select 1
    from public.service_orders so
    join public.customers c
      on c.id = so.customer_id
    where so.id = service_parts.service_order_id
      and c.profile_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.service_assignments sa
    join public.mechanics m
      on m.id = sa.mechanic_id
    where sa.service_order_id = service_parts.service_order_id
      and m.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "service_parts_manage_admin_or_mechanic"
on public.service_parts
for all
to authenticated
using (
  (select auth.jwt() -> 'app_metadata' ->> 'role') in ('admin', 'mechanic')
)
with check (
  (select auth.jwt() -> 'app_metadata' ->> 'role') in ('admin', 'mechanic')
);

-- ============================================================
-- SERVICE COSTS
-- ============================================================

create policy "service_costs_select_related"
on public.service_costs
for select
to authenticated
using (
  exists (
    select 1
    from public.service_orders so
    join public.customers c
      on c.id = so.customer_id
    where so.id = service_costs.service_order_id
      and c.profile_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.service_assignments sa
    join public.mechanics m
      on m.id = sa.mechanic_id
    where sa.service_order_id = service_costs.service_order_id
      and m.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "service_costs_manage_admin"
on public.service_costs
for all
to authenticated
using (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- MECHANIC EARNINGS
-- ============================================================

create policy "mechanic_earnings_select_own_or_admin"
on public.mechanic_earnings
for select
to authenticated
using (
  exists (
    select 1
    from public.mechanics m
    where m.id = mechanic_earnings.mechanic_id
      and m.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "mechanic_earnings_manage_admin"
on public.mechanic_earnings
for all
to authenticated
using (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

create policy "notifications_select_own_or_admin"
on public.notifications
for select
to authenticated
using (
  recipient_id = (select auth.uid())
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "notifications_update_own_or_admin"
on public.notifications
for update
to authenticated
using (
  recipient_id = (select auth.uid())
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  recipient_id = (select auth.uid())
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "notifications_insert_admin"
on public.notifications
for insert
to authenticated
with check (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- REMINDERS
-- ============================================================

create policy "reminders_select_own_or_admin"
on public.service_reminders
for select
to authenticated
using (
  exists (
    select 1
    from public.customers c
    where c.id = service_reminders.customer_id
      and c.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "reminders_insert_own_or_admin"
on public.service_reminders
for insert
to authenticated
with check (
  exists (
    select 1
    from public.customers c
    where c.id = service_reminders.customer_id
      and c.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "reminders_update_own_or_admin"
on public.service_reminders
for update
to authenticated
using (
  exists (
    select 1
    from public.customers c
    where c.id = service_reminders.customer_id
      and c.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  exists (
    select 1
    from public.customers c
    where c.id = service_reminders.customer_id
      and c.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "reminders_delete_admin"
on public.service_reminders
for delete
to authenticated
using (
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

-- ============================================================
-- STATUS HISTORY
-- ============================================================

create policy "service_status_history_select_related"
on public.service_status_history
for select
to authenticated
using (
  exists (
    select 1
    from public.service_orders so
    join public.customers c
      on c.id = so.customer_id
    where so.id = service_status_history.service_order_id
      and c.profile_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.service_assignments sa
    join public.mechanics m
      on m.id = sa.mechanic_id
    where sa.service_order_id = service_status_history.service_order_id
      and m.profile_id = (select auth.uid())
  )
  or
  (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);

create policy "service_status_history_insert_admin_or_mechanic"
on public.service_status_history
for insert
to authenticated
with check (
  (select auth.jwt() -> 'app_metadata' ->> 'role') in ('admin', 'mechanic')
);
