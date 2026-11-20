-- ============================================================================
-- PITMATE - COMPLETE CONSOLIDATED MIGRATIONS & SEED BUNDLE
-- Run this script in the Supabase SQL Editor (https://supabase.com/dashboard/project/kxvoeqwelcmcvdfwxduu/sql)
-- ============================================================================
-- >>> FILE: supabase/migrations/20261002065803_initial_pitmate_schema.sql
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



-- >>> FILE: supabase/migrations/20261007100000_customer_registration_policy.sql
-- ============================================================
-- Migration: 20261007100000_customer_registration_policy
-- Allow newly registered authenticated users to insert their
-- own profile as 'customer' strictly matching their auth.uid().
-- Mechanics and Admin roles cannot be self-registered.
-- ============================================================

create policy "profiles_insert_self_customer"
on public.profiles
for insert
to authenticated
with check (
  id = (select auth.uid())
  and
  role = 'customer'::public.user_role
);



-- >>> FILE: supabase/migrations/20261013160000_fix_rls_recursion_and_role_functions.sql
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



-- >>> FILE: supabase/migrations/20261013161000_security_definer_rls_functions.sql
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



-- >>> FILE: supabase/migrations/20261014100000_seed_and_tasks_reminders_rls.sql
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



-- >>> FILE: supabase/migrations/20261030110000_add_checked_in_to_booking_status.sql
-- ============================================================
-- Migration: 20261030110000_add_checked_in_to_booking_status.sql
-- Description: Add 'checked_in' value to public.booking_status enum.
-- Separated to ensure enum commit before referencing in downstream migrations.
-- ============================================================

alter type public.booking_status add value if not exists 'checked_in';



-- >>> FILE: supabase/migrations/20261030110100_uas_queue_intake_theme_foundations.sql
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



-- >>> FILE: supabase/migrations/20261106100000_uas_reports_aggregation_rpc.sql
-- ============================================================
-- Migration: 20261106100000_uas_reports_aggregation_rpc.sql
-- Description:
--   Phase 6 — UAS Reporting Backend & Aggregation Telemetry RPC
--   Provides server-side aggregation for:
--     1. Intake origin comparison (booking vs walk-in vs legacy_unknown)
--     2. Volume over time by day
--     3. Service status distribution
--     4. Mechanic workload and assignments
--     5. Financial summaries (estimated pipeline vs settled totals)
--   Enforces Admin-only authorization, safe search_path, and boundary handling.
-- ============================================================

create or replace function public.get_admin_reports_telemetry(
  p_start_date timestamptz default null,
  p_end_date timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_start timestamptz;
  v_end timestamptz;
  v_result jsonb;

  v_total_orders int;
  v_booking_count int;
  v_walk_in_count int;
  v_legacy_count int;

  v_estimated_total numeric;
  v_settled_total numeric;
  v_settled_count int;
  v_pending_settlement_count int;

  v_status_distribution jsonb;
  v_volume_timeline jsonb;
  v_mechanic_workload jsonb;
begin
  -- 1. Security Authorization Check (Admin only)
  if not public.is_admin() then
    raise exception 'Unauthorized: Only administrators can view reporting telemetry.';
  end if;

  -- 2. Date Boundary Normalization (Inclusive range)
  v_start := coalesce(p_start_date, (now() - interval '30 days'));
  v_end := coalesce(p_end_date, now());

  -- Ensure start is not after end
  if v_start > v_end then
    raise exception 'Invalid date range: start_date must be before or equal to end_date.';
  end if;

  -- 3. Intake Breakdown
  select
    count(*)::int,
    count(*) filter (where intake_origin = 'booking')::int,
    count(*) filter (where intake_origin = 'walk_in')::int,
    count(*) filter (where intake_origin = 'legacy_unknown' or intake_origin is null)::int
  into
    v_total_orders,
    v_booking_count,
    v_walk_in_count,
    v_legacy_count
  from public.service_orders
  where created_at >= v_start and created_at <= v_end;

  -- 4. Financial Summary
  select
    coalesce(sum(estimated_total), 0),
    coalesce(sum(final_total) filter (where status in ('completed', 'closed') and final_total is not null), 0),
    count(*) filter (where status in ('completed', 'closed') and final_total is not null)::int,
    count(*) filter (where status not in ('completed', 'closed', 'cancelled'))::int
  into
    v_estimated_total,
    v_settled_total,
    v_settled_count,
    v_pending_settlement_count
  from public.service_orders
  where created_at >= v_start and created_at <= v_end;

  -- 5. Service Status Distribution
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'status', status::text,
      'count', count
    ) order by count desc
  ), '[]'::jsonb)
  into v_status_distribution
  from (
    select
      status,
      count(*)::int as count
    from public.service_orders
    where created_at >= v_start and created_at <= v_end
    group by status
  ) s;

  -- 6. Volume Over Time (Grouped by Date)
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'date', to_char(day_series, 'YYYY-MM-DD'),
      'total_count', coalesce(t.total_count, 0),
      'completed_count', coalesce(t.completed_count, 0)
    ) order by day_series asc
  ), '[]'::jsonb)
  into v_volume_timeline
  from (
    select generate_series(
      date_trunc('day', v_start),
      date_trunc('day', v_end),
      interval '1 day'
    ) as day_series
  ) days
  left join (
    select
      date_trunc('day', created_at) as order_day,
      count(*)::int as total_count,
      count(*) filter (where status in ('completed', 'closed'))::int as completed_count
    from public.service_orders
    where created_at >= v_start and created_at <= v_end
    group by date_trunc('day', created_at)
  ) t on days.day_series = t.order_day;

  -- 7. Mechanic Workload
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'mechanic_id', m.id,
      'mechanic_name', p.full_name,
      'employee_code', m.employee_code,
      'specialization', m.specialization,
      'assigned_count', coalesce(w.assigned_count, 0),
      'active_count', coalesce(w.active_count, 0),
      'completed_count', coalesce(w.completed_count, 0)
    ) order by coalesce(w.assigned_count, 0) desc, p.full_name asc
  ), '[]'::jsonb)
  into v_mechanic_workload
  from public.mechanics m
  join public.profiles p on p.id = m.profile_id
  left join (
    select
      sa.mechanic_id,
      count(distinct so.id)::int as assigned_count,
      count(distinct so.id) filter (where so.status not in ('completed', 'closed', 'cancelled'))::int as active_count,
      count(distinct so.id) filter (where so.status in ('completed', 'closed'))::int as completed_count
    from public.service_assignments sa
    join public.service_orders so on so.id = sa.service_order_id
    where so.created_at >= v_start and so.created_at <= v_end
    group by sa.mechanic_id
  ) w on w.mechanic_id = m.id
  where m.id is not null;

  -- 8. Assemble Full Telemetry Response
  v_result := jsonb_build_object(
    'date_range', jsonb_build_object(
      'start_date', v_start,
      'end_date', v_end
    ),
    'intake_breakdown', jsonb_build_object(
      'total_orders', v_total_orders,
      'booking_count', v_booking_count,
      'walk_in_count', v_walk_in_count,
      'legacy_unknown_count', v_legacy_count
    ),
    'financial_summary', jsonb_build_object(
      'estimated_total', v_estimated_total,
      'settled_total', v_settled_total,
      'settled_orders_count', v_settled_count,
      'pending_settlement_count', v_pending_settlement_count
    ),
    'status_distribution', v_status_distribution,
    'volume_timeline', v_volume_timeline,
    'mechanic_workload', v_mechanic_workload
  );

  return v_result;
end;
$$;

revoke all on function public.get_admin_reports_telemetry(timestamptz, timestamptz) from public;
grant execute on function public.get_admin_reports_telemetry(timestamptz, timestamptz) to authenticated;



-- >>> FILE: supabase/migrations/20261111120000_cron_notifications_stock_expiry.sql
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



-- >>> FILE: supabase/migrations/20261118100000_uas_fixes_reminders_stock_checkin.sql
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



