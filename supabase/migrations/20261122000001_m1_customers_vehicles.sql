-- ============================================================================
-- Migration: 20261122000001_m1_customers_vehicles.sql
-- Milestone: M1 - Customers & Vehicles
-- Description: Customer type enum, customers and vehicles tables, constraints, and RLS policies
-- ============================================================================

-- 1. Create customer_type enum
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'customer_type') THEN
    CREATE TYPE public.customer_type AS ENUM ('individual', 'company');
  END IF;
END $$;

-- 2. Create public.customers table
CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  full_name TEXT NOT NULL,
  phone_number TEXT UNIQUE,
  email TEXT,
  customer_type public.customer_type NOT NULL DEFAULT 'individual',
  company_name TEXT,
  is_guest BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for customers
CREATE INDEX IF NOT EXISTS idx_customers_profile_id ON public.customers(profile_id);
CREATE INDEX IF NOT EXISTS idx_customers_phone_number ON public.customers(phone_number);

-- 3. Create public.vehicles table
CREATE TABLE IF NOT EXISTS public.vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT,
  license_plate TEXT NOT NULL,
  make TEXT NOT NULL,
  model TEXT NOT NULL,
  year INT NOT NULL,
  vin TEXT,
  engine_type TEXT,
  transmission TEXT,
  mileage INT,
  color TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_license_plate_normalized UNIQUE (license_plate)
);

-- Indexes for vehicles
CREATE INDEX IF NOT EXISTS idx_vehicles_customer_id ON public.vehicles(customer_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_license_plate ON public.vehicles(license_plate);

-- 4. Automatic updated_at triggers
DROP TRIGGER IF EXISTS on_customers_updated ON public.customers;
CREATE TRIGGER on_customers_updated
  BEFORE UPDATE ON public.customers
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS on_vehicles_updated ON public.vehicles;
CREATE TRIGGER on_vehicles_updated
  BEFORE UPDATE ON public.vehicles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies for public.customers

-- Admins full access on customers
DROP POLICY IF EXISTS "Admins full access on customers" ON public.customers;
CREATE POLICY "Admins full access on customers"
  ON public.customers
  FOR ALL
  USING (public.current_user_role() = 'admin');

-- Customers view own customer record
DROP POLICY IF EXISTS "Customers view own customer record" ON public.customers;
CREATE POLICY "Customers view own customer record"
  ON public.customers
  FOR SELECT
  USING (profile_id = auth.uid());

-- Customers insert own customer record
DROP POLICY IF EXISTS "Customers insert own customer record" ON public.customers;
CREATE POLICY "Customers insert own customer record"
  ON public.customers
  FOR INSERT
  WITH CHECK (profile_id = auth.uid());

-- Customers update own customer record
DROP POLICY IF EXISTS "Customers update own customer record" ON public.customers;
CREATE POLICY "Customers update own customer record"
  ON public.customers
  FOR UPDATE
  USING (profile_id = auth.uid());

-- Mechanics view customers
DROP POLICY IF EXISTS "Mechanics view customers" ON public.customers;
CREATE POLICY "Mechanics view customers"
  ON public.customers
  FOR SELECT
  USING (public.current_user_role() = 'mechanic');

-- 7. RLS Policies for public.vehicles

-- Admins full access on vehicles
DROP POLICY IF EXISTS "Admins full access on vehicles" ON public.vehicles;
CREATE POLICY "Admins full access on vehicles"
  ON public.vehicles
  FOR ALL
  USING (public.current_user_role() = 'admin');

-- Customers view own vehicles
DROP POLICY IF EXISTS "Customers view own vehicles" ON public.vehicles;
CREATE POLICY "Customers view own vehicles"
  ON public.vehicles
  FOR SELECT
  USING (customer_id IN (SELECT id FROM public.customers WHERE profile_id = auth.uid()));

-- Customers insert own vehicles
DROP POLICY IF EXISTS "Customers insert own vehicles" ON public.vehicles;
CREATE POLICY "Customers insert own vehicles"
  ON public.vehicles
  FOR INSERT
  WITH CHECK (customer_id IN (SELECT id FROM public.customers WHERE profile_id = auth.uid()));

-- Customers update own vehicles
DROP POLICY IF EXISTS "Customers update own vehicles" ON public.vehicles;
CREATE POLICY "Customers update own vehicles"
  ON public.vehicles
  FOR UPDATE
  USING (customer_id IN (SELECT id FROM public.customers WHERE profile_id = auth.uid()));

-- Mechanics view vehicles
DROP POLICY IF EXISTS "Mechanics view vehicles" ON public.vehicles;
CREATE POLICY "Mechanics view vehicles"
  ON public.vehicles
  FOR SELECT
  USING (public.current_user_role() = 'mechanic');
