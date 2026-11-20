-- ==============================================================================
-- PitMate v2.0 Customers & Vehicles Migration
-- Milestone: M1.1 (Database Foundation & Schema)
-- Generated: 2026-11-20
-- Scope: Customers, Vehicles, Anti-Recursion Helper Functions, Triggers & RLS
-- ==============================================================================

-- 1. Anti-Recursion Helper Functions (SECURITY DEFINER STABLE SET search_path = public)

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_mechanic()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'mechanic'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- 2. Customers Table
CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
  customer_type customer_type NOT NULL DEFAULT 'individual',
  name TEXT NOT NULL,
  email TEXT NULL,
  phone TEXT NOT NULL,
  address TEXT NULL,
  tax_number TEXT NULL,
  is_guest BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Performance and Integrity Indexes for Customers
CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_profile_id 
  ON public.customers (profile_id) 
  WHERE profile_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_customers_phone ON public.customers (phone);
CREATE INDEX IF NOT EXISTS idx_customers_email ON public.customers (email);

-- Helper Function: current_customer_id() (must follow customers table creation)
CREATE OR REPLACE FUNCTION public.current_customer_id()
RETURNS UUID AS $$
  SELECT id FROM public.customers
  WHERE profile_id = auth.uid()
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- 3. Vehicles Table
CREATE TABLE IF NOT EXISTS public.vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT,
  license_plate TEXT NOT NULL UNIQUE,
  vin TEXT NULL UNIQUE,
  make TEXT NOT NULL,
  model TEXT NOT NULL,
  year INT NOT NULL CHECK (year BETWEEN 1900 AND 2100),
  transmission TEXT NULL,
  color TEXT NULL,
  current_mileage INT NOT NULL DEFAULT 0 CHECK (current_mileage >= 0),
  notes TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Performance and Integrity Indexes for Vehicles
CREATE INDEX IF NOT EXISTS idx_vehicles_customer_id ON public.vehicles (customer_id);

-- 4. Triggers & Trigger Functions

-- 4.1 updated_at synchronization
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_customers_updated_at ON public.customers;
CREATE TRIGGER trg_customers_updated_at
  BEFORE UPDATE ON public.customers
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_vehicles_updated_at ON public.vehicles;
CREATE TRIGGER trg_vehicles_updated_at
  BEFORE UPDATE ON public.vehicles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 4.2 Plate & VIN Normalization (uppercase & single space)
CREATE OR REPLACE FUNCTION public.normalize_vehicle_plate()
RETURNS TRIGGER AS $$
BEGIN
  NEW.license_plate := UPPER(TRIM(REGEXP_REPLACE(NEW.license_plate, '\s+', ' ', 'g')));
  IF NEW.vin IS NOT NULL THEN
    NEW.vin := UPPER(TRIM(NEW.vin));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_vehicles_normalize_plate ON public.vehicles;
CREATE TRIGGER trg_vehicles_normalize_plate
  BEFORE INSERT OR UPDATE ON public.vehicles
  FOR EACH ROW EXECUTE FUNCTION public.normalize_vehicle_plate();

-- 4.3 Anti-Privilege Escalation on public.profiles
CREATE OR REPLACE FUNCTION public.prevent_role_escalation()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role <> OLD.role AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Only administrators can modify user roles.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_profiles_role_escalation ON public.profiles;
CREATE TRIGGER trg_profiles_role_escalation
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.prevent_role_escalation();

-- 4.4 Auth Signup Trigger on auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_full_name TEXT;
  v_phone TEXT;
BEGIN
  v_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email);
  v_phone := COALESCE(NEW.phone, NEW.raw_user_meta_data->>'phone', '');

  -- 1. Insert Profile (Enforce role = 'customer' to prevent privilege escalation)
  INSERT INTO public.profiles (id, role, full_name, phone_number, created_at, updated_at)
  VALUES (
    NEW.id,
    'customer'::public.user_role,
    v_full_name,
    NULLIF(v_phone, ''),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  -- 2. Automatically create corresponding Customer record
  INSERT INTO public.customers (profile_id, customer_type, name, email, phone, is_guest, created_at, updated_at)
  VALUES (
    NEW.id,
    'individual'::public.customer_type,
    v_full_name,
    NEW.email,
    COALESCE(v_phone, ''),
    FALSE,
    NOW(),
    NOW()
  )
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. Row Level Security (RLS)

ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;

-- 5.1 Policies on public.customers
DROP POLICY IF EXISTS "Admins have full access to customers" ON public.customers;
CREATE POLICY "Admins have full access to customers"
  ON public.customers FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Mechanics can view customer info" ON public.customers;
CREATE POLICY "Mechanics can view customer info"
  ON public.customers FOR SELECT TO authenticated
  USING (public.is_mechanic());

DROP POLICY IF EXISTS "Customers can view own profile" ON public.customers;
CREATE POLICY "Customers can view own profile"
  ON public.customers FOR SELECT TO authenticated
  USING (profile_id = auth.uid());

DROP POLICY IF EXISTS "Customers can update own profile" ON public.customers;
CREATE POLICY "Customers can update own profile"
  ON public.customers FOR UPDATE TO authenticated
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

-- 5.2 Policies on public.vehicles
DROP POLICY IF EXISTS "Admins have full access to vehicles" ON public.vehicles;
CREATE POLICY "Admins have full access to vehicles"
  ON public.vehicles FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Mechanics can view vehicles" ON public.vehicles;
CREATE POLICY "Mechanics can view vehicles"
  ON public.vehicles FOR SELECT TO authenticated
  USING (public.is_mechanic());

DROP POLICY IF EXISTS "Customers can view own vehicles" ON public.vehicles;
CREATE POLICY "Customers can view own vehicles"
  ON public.vehicles FOR SELECT TO authenticated
  USING (customer_id = public.current_customer_id());

DROP POLICY IF EXISTS "Customers can insert own vehicles" ON public.vehicles;
CREATE POLICY "Customers can insert own vehicles"
  ON public.vehicles FOR INSERT TO authenticated
  WITH CHECK (customer_id = public.current_customer_id());

DROP POLICY IF EXISTS "Customers can update own vehicles" ON public.vehicles;
CREATE POLICY "Customers can update own vehicles"
  ON public.vehicles FOR UPDATE TO authenticated
  USING (customer_id = public.current_customer_id())
  WITH CHECK (customer_id = public.current_customer_id());
