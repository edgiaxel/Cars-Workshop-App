-- ============================================================
-- Cars Workshop App
-- Initial Database Schema
-- Schema Version: 1.0
-- ============================================================

-- ============================================================
-- 1. ENUM TYPES
-- ============================================================

CREATE TYPE public.user_role AS ENUM (
    'ADMIN',
    'MECHANIC',
    'CUSTOMER'
);

CREATE TYPE public.customer_type AS ENUM (
    'COMPANY',
    'INDIVIDUAL'
);

CREATE TYPE public.mechanic_status AS ENUM (
    'ACTIVE',
    'INACTIVE'
);

CREATE TYPE public.vehicle_type AS ENUM (
    'PASSENGER',
    'SUV',
    'TRUCK',
    'VAN',
    'MOTORSPORT',
    'OTHER'
);

CREATE TYPE public.vehicle_status AS ENUM (
    'ACTIVE',
    'IN_SERVICE',
    'INACTIVE'
);

CREATE TYPE public.service_priority AS ENUM (
    'LOW',
    'NORMAL',
    'HIGH',
    'URGENT'
);

CREATE TYPE public.service_order_status AS ENUM (
    'REQUESTED',
    'INSPECTION',
    'DIAGNOSIS',
    'WAITING_PARTS',
    'IN_PROGRESS',
    'QUALITY_CHECK',
    'COMPLETED',
    'CANCELLED'
);

CREATE TYPE public.service_task_status AS ENUM (
    'PENDING',
    'IN_PROGRESS',
    'COMPLETED'
);

CREATE TYPE public.part_status AS ENUM (
    'ACTIVE',
    'INACTIVE'
);


-- ============================================================
-- 2. PROFILES
-- ============================================================

CREATE TABLE public.profiles (
    id uuid PRIMARY KEY
        REFERENCES auth.users(id)
        ON DELETE RESTRICT,

    full_name text NOT NULL,
    email text NOT NULL,
    role public.user_role NOT NULL,

    phone text,
    avatar_url text,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT profiles_full_name_not_empty
        CHECK (btrim(full_name) <> ''),

    CONSTRAINT profiles_email_not_empty
        CHECK (btrim(email) <> '')
);


-- ============================================================
-- 3. CUSTOMERS
-- ============================================================

CREATE TABLE public.customers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL UNIQUE
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    customer_type public.customer_type NOT NULL,

    company_name text,
    contact_person text,

    phone text NOT NULL,
    email text,
    address text,
    notes text,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT customers_phone_not_empty
        CHECK (btrim(phone) <> ''),

    CONSTRAINT customers_company_name_required
        CHECK (
            customer_type <> 'COMPANY'
            OR (
                company_name IS NOT NULL
                AND btrim(company_name) <> ''
            )
        )
);


-- ============================================================
-- 4. MECHANICS
-- ============================================================

CREATE TABLE public.mechanics (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL UNIQUE
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    employee_code text NOT NULL UNIQUE,
    specialization text,
    phone text,
    hire_date date,

    status public.mechanic_status NOT NULL DEFAULT 'ACTIVE',

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT mechanics_employee_code_not_empty
        CHECK (btrim(employee_code) <> '')
);


-- ============================================================
-- 5. VEHICLES
-- ============================================================

CREATE TABLE public.vehicles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    customer_id uuid NOT NULL
        REFERENCES public.customers(id)
        ON DELETE RESTRICT,

    brand text NOT NULL,
    model text NOT NULL,
    year smallint,

    vehicle_type public.vehicle_type NOT NULL,

    registration_number text,
    unit_number text,

    mileage numeric NOT NULL DEFAULT 0,

    status public.vehicle_status NOT NULL DEFAULT 'ACTIVE',

    notes text,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT vehicles_brand_not_empty
        CHECK (btrim(brand) <> ''),

    CONSTRAINT vehicles_model_not_empty
        CHECK (btrim(model) <> ''),

    CONSTRAINT vehicles_year_valid
        CHECK (year IS NULL OR year >= 1886),

    CONSTRAINT vehicles_mileage_valid
        CHECK (mileage >= 0)
);


-- ============================================================
-- 6. SERVICE ORDERS
-- ============================================================

CREATE TABLE public.service_orders (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    customer_id uuid NOT NULL
        REFERENCES public.customers(id)
        ON DELETE RESTRICT,

    vehicle_id uuid NOT NULL
        REFERENCES public.vehicles(id)
        ON DELETE RESTRICT,

    assigned_mechanic_id uuid
        REFERENCES public.mechanics(id)
        ON DELETE SET NULL,

    service_type text NOT NULL,
    description text,

    priority public.service_priority NOT NULL DEFAULT 'NORMAL',

    status public.service_order_status NOT NULL DEFAULT 'REQUESTED',

    estimated_labor_cost numeric(12,2) NOT NULL DEFAULT 0,
    estimated_parts_cost numeric(12,2) NOT NULL DEFAULT 0,
    estimated_additional_cost numeric(12,2) NOT NULL DEFAULT 0,
    estimated_total numeric(12,2) NOT NULL DEFAULT 0,

    final_labor_cost numeric(12,2) NOT NULL DEFAULT 0,
    final_parts_cost numeric(12,2) NOT NULL DEFAULT 0,
    final_additional_cost numeric(12,2) NOT NULL DEFAULT 0,
    final_total numeric(12,2) NOT NULL DEFAULT 0,

    requested_at timestamptz NOT NULL DEFAULT now(),
    started_at timestamptz,
    completed_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT service_orders_service_type_not_empty
        CHECK (btrim(service_type) <> ''),

    CONSTRAINT service_orders_estimated_labor_non_negative
        CHECK (estimated_labor_cost >= 0),

    CONSTRAINT service_orders_estimated_parts_non_negative
        CHECK (estimated_parts_cost >= 0),

    CONSTRAINT service_orders_estimated_additional_non_negative
        CHECK (estimated_additional_cost >= 0),

    CONSTRAINT service_orders_estimated_total_non_negative
        CHECK (estimated_total >= 0),

    CONSTRAINT service_orders_final_labor_non_negative
        CHECK (final_labor_cost >= 0),

    CONSTRAINT service_orders_final_parts_non_negative
        CHECK (final_parts_cost >= 0),

    CONSTRAINT service_orders_final_additional_non_negative
        CHECK (final_additional_cost >= 0),

    CONSTRAINT service_orders_final_total_non_negative
        CHECK (final_total >= 0),

    CONSTRAINT service_orders_estimated_total_correct
        CHECK (
            estimated_total =
            estimated_labor_cost
            + estimated_parts_cost
            + estimated_additional_cost
        ),

    CONSTRAINT service_orders_final_total_correct
        CHECK (
            final_total =
            final_labor_cost
            + final_parts_cost
            + final_additional_cost
        )
);


-- ============================================================
-- 7. SERVICE TASKS
-- ============================================================

CREATE TABLE public.service_tasks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    service_order_id uuid NOT NULL
        REFERENCES public.service_orders(id)
        ON DELETE RESTRICT,

    assigned_mechanic_id uuid
        REFERENCES public.mechanics(id)
        ON DELETE SET NULL,

    title text NOT NULL,
    description text,

    status public.service_task_status NOT NULL DEFAULT 'PENDING',

    completed_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT service_tasks_title_not_empty
        CHECK (btrim(title) <> '')
);


-- ============================================================
-- 8. PARTS
-- ============================================================

CREATE TABLE public.parts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    part_number text NOT NULL UNIQUE,
    name text NOT NULL,
    category text NOT NULL,

    brand text,
    description text,

    stock_quantity numeric NOT NULL DEFAULT 0,
    minimum_stock numeric NOT NULL DEFAULT 0,

    unit_price numeric(12,2) NOT NULL DEFAULT 0,

    supplier text,

    status public.part_status NOT NULL DEFAULT 'ACTIVE',

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT parts_part_number_not_empty
        CHECK (btrim(part_number) <> ''),

    CONSTRAINT parts_name_not_empty
        CHECK (btrim(name) <> ''),

    CONSTRAINT parts_category_not_empty
        CHECK (btrim(category) <> ''),

    CONSTRAINT parts_stock_non_negative
        CHECK (stock_quantity >= 0),

    CONSTRAINT parts_minimum_stock_non_negative
        CHECK (minimum_stock >= 0),

    CONSTRAINT parts_unit_price_non_negative
        CHECK (unit_price >= 0)
);


-- ============================================================
-- 9. SERVICE ORDER PARTS
-- ============================================================

CREATE TABLE public.service_order_parts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    service_order_id uuid NOT NULL
        REFERENCES public.service_orders(id)
        ON DELETE RESTRICT,

    part_id uuid NOT NULL
        REFERENCES public.parts(id)
        ON DELETE RESTRICT,

    quantity numeric NOT NULL DEFAULT 1,
    unit_price numeric(12,2) NOT NULL,

    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT service_order_parts_quantity_positive
        CHECK (quantity > 0),

    CONSTRAINT service_order_parts_unit_price_non_negative
        CHECK (unit_price >= 0),

    CONSTRAINT service_order_parts_unique_part
        UNIQUE (service_order_id, part_id)
);


-- ============================================================
-- 10. SERVICE RECORDS
-- ============================================================

CREATE TABLE public.service_records (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    service_order_id uuid NOT NULL UNIQUE
        REFERENCES public.service_orders(id)
        ON DELETE RESTRICT,

    vehicle_id uuid NOT NULL
        REFERENCES public.vehicles(id)
        ON DELETE RESTRICT,

    mechanic_id uuid
        REFERENCES public.mechanics(id)
        ON DELETE SET NULL,

    summary text NOT NULL,
    diagnosis text,
    work_performed text NOT NULL,
    recommendations text,

    final_cost numeric(12,2) NOT NULL DEFAULT 0,

    completed_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT service_records_summary_not_empty
        CHECK (btrim(summary) <> ''),

    CONSTRAINT service_records_work_performed_not_empty
        CHECK (btrim(work_performed) <> ''),

    CONSTRAINT service_records_final_cost_non_negative
        CHECK (final_cost >= 0)
);


-- ============================================================
-- 11. SERVICE ORDER STATUS HISTORY
-- ============================================================

CREATE TABLE public.service_order_status_history (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    service_order_id uuid NOT NULL
        REFERENCES public.service_orders(id)
        ON DELETE RESTRICT,

    status public.service_order_status NOT NULL,

    changed_by uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    notes text,

    created_at timestamptz NOT NULL DEFAULT now()
);


-- ============================================================
-- 12. INDEXES
-- ============================================================

CREATE INDEX idx_customers_profile_id
    ON public.customers(profile_id);

CREATE INDEX idx_mechanics_profile_id
    ON public.mechanics(profile_id);

CREATE INDEX idx_vehicles_customer_id
    ON public.vehicles(customer_id);

CREATE INDEX idx_service_orders_customer_id
    ON public.service_orders(customer_id);

CREATE INDEX idx_service_orders_vehicle_id
    ON public.service_orders(vehicle_id);

CREATE INDEX idx_service_orders_mechanic_id
    ON public.service_orders(assigned_mechanic_id);

CREATE INDEX idx_service_orders_status
    ON public.service_orders(status);

CREATE INDEX idx_service_tasks_service_order_id
    ON public.service_tasks(service_order_id);

CREATE INDEX idx_service_tasks_mechanic_id
    ON public.service_tasks(assigned_mechanic_id);

CREATE INDEX idx_parts_status
    ON public.parts(status);

CREATE INDEX idx_service_order_parts_service_order_id
    ON public.service_order_parts(service_order_id);

CREATE INDEX idx_service_order_parts_part_id
    ON public.service_order_parts(part_id);

CREATE INDEX idx_service_records_vehicle_id
    ON public.service_records(vehicle_id);

CREATE INDEX idx_service_records_mechanic_id
    ON public.service_records(mechanic_id);

CREATE INDEX idx_status_history_service_order_id
    ON public.service_order_status_history(service_order_id);

CREATE INDEX idx_status_history_changed_by
    ON public.service_order_status_history(changed_by);

CREATE INDEX idx_status_history_created_at
    ON public.service_order_status_history(created_at);


-- ============================================================
-- 13. ROW LEVEL SECURITY
-- ============================================================
--
-- RLS is explicitly enabled on application tables.
-- Policies are created separately after the schema is verified.
--
-- This separates:
--
--   database structure
--          from
--   authorization rules
--
-- so the initial schema can be verified before implementing
-- role-specific access policies.
-- ============================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mechanics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_order_parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_order_status_history ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- END OF INITIAL SCHEMA
-- ============================================================