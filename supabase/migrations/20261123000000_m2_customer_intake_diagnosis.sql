-- Migration: 20261123000000_m2_customer_intake_diagnosis.sql
-- Milestone: M2 - Customer Intake & Diagnosis
-- Description: Bookings, Service Orders, Inspections, Findings, Estimates, Items, Authorizations, RPCs, and RLS

-- 1. Enums
DROP TYPE IF EXISTS public.booking_status CASCADE;
CREATE TYPE public.booking_status AS ENUM ('pending', 'confirmed', 'cancelled', 'rescheduled', 'checked_in', 'rejected');

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'service_order_status') THEN
    CREATE TYPE public.service_order_status AS ENUM (
      'intake_pending', 'inspection_pending', 'inspection_in_progress', 'inspection_completed',
      'estimate_pending', 'estimate_approved', 'estimate_rejected',
      'in_progress', 'qc_pending', 'completed', 'closed', 'cancelled'
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'intake_type') THEN
    CREATE TYPE public.intake_type AS ENUM ('walk_in', 'booking');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'inspection_status') THEN
    CREATE TYPE public.inspection_status AS ENUM ('assigned', 'in_progress', 'completed', 'reviewed');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'finding_condition') THEN
    CREATE TYPE public.finding_condition AS ENUM ('good', 'fair', 'critical');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'severity_level') THEN
    CREATE TYPE public.severity_level AS ENUM ('low', 'medium', 'urgent');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estimate_status') THEN
    CREATE TYPE public.estimate_status AS ENUM ('draft', 'sent', 'approved', 'partially_approved', 'rejected', 'superseded');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'authorization_status') THEN
    CREATE TYPE public.authorization_status AS ENUM ('pending', 'approved', 'rejected', 'deferred');
  END IF;
END $$;

-- 2. Tables

-- 2.1 Bookings
CREATE TABLE IF NOT EXISTS public.bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  booking_date DATE NOT NULL,
  time_slot TEXT NOT NULL,
  service_type TEXT NOT NULL,
  customer_notes TEXT,
  admin_notes TEXT,
  status public.booking_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bookings_customer_id ON public.bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_date_status ON public.bookings(booking_date, status);

-- 2.2 Service Orders
CREATE TABLE IF NOT EXISTS public.service_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number TEXT NOT NULL UNIQUE,
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT,
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE RESTRICT,
  booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
  intake_type public.intake_type NOT NULL DEFAULT 'walk_in',
  odometer INT NOT NULL,
  customer_complaint TEXT NOT NULL,
  fuel_level TEXT,
  initial_notes TEXT,
  status public.service_order_status NOT NULL DEFAULT 'inspection_pending',
  assigned_bay TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_service_orders_customer_id ON public.service_orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_service_orders_status ON public.service_orders(status);

-- Single active order per vehicle constraint
CREATE UNIQUE INDEX IF NOT EXISTS idx_service_orders_single_active_vehicle
  ON public.service_orders (vehicle_id)
  WHERE status NOT IN ('completed', 'closed', 'cancelled');

-- 2.3 Inspections
CREATE TABLE IF NOT EXISTS public.inspections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  mechanic_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  status public.inspection_status NOT NULL DEFAULT 'assigned',
  summary TEXT,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inspections_order_id ON public.inspections(service_order_id);
CREATE INDEX IF NOT EXISTS idx_inspections_mechanic_id ON public.inspections(mechanic_id);

-- 2.4 Inspection Findings
CREATE TABLE IF NOT EXISTS public.inspection_findings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_id UUID NOT NULL REFERENCES public.inspections(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  item_name TEXT NOT NULL,
  condition public.finding_condition NOT NULL DEFAULT 'good',
  severity public.severity_level NOT NULL DEFAULT 'low',
  notes TEXT,
  photo_urls TEXT[] DEFAULT '{}',
  recommended_action TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_findings_inspection_id ON public.inspection_findings(inspection_id);

-- 2.5 Estimates
CREATE TABLE IF NOT EXISTS public.estimates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  inspection_id UUID REFERENCES public.inspections(id) ON DELETE SET NULL,
  revision_number INT NOT NULL DEFAULT 1,
  status public.estimate_status NOT NULL DEFAULT 'draft',
  subtotal_cents BIGINT NOT NULL DEFAULT 0,
  tax_cents BIGINT NOT NULL DEFAULT 0,
  discount_cents BIGINT NOT NULL DEFAULT 0,
  total_cents BIGINT NOT NULL DEFAULT 0,
  notes TEXT,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_service_order_revision UNIQUE (service_order_id, revision_number)
);

CREATE INDEX IF NOT EXISTS idx_estimates_order_id ON public.estimates(service_order_id);

-- 2.6 Estimate Items
CREATE TABLE IF NOT EXISTS public.estimate_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  estimate_id UUID NOT NULL REFERENCES public.estimates(id) ON DELETE CASCADE,
  item_type TEXT NOT NULL DEFAULT 'labor',
  description TEXT NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  unit_price_cents BIGINT NOT NULL,
  total_price_cents BIGINT NOT NULL,
  is_optional BOOLEAN NOT NULL DEFAULT FALSE,
  authorization_status public.authorization_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_estimate_items_estimate_id ON public.estimate_items(estimate_id);

-- 2.7 Estimate Authorizations
CREATE TABLE IF NOT EXISTS public.estimate_authorizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  estimate_id UUID NOT NULL REFERENCES public.estimates(id) ON DELETE CASCADE,
  authorized_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  status public.estimate_status NOT NULL,
  signature_token TEXT,
  notes TEXT,
  authorized_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_authorizations_estimate_id ON public.estimate_authorizations(estimate_id);

-- 3. Triggers for updated_at
DROP TRIGGER IF EXISTS on_bookings_updated ON public.bookings;
CREATE TRIGGER on_bookings_updated BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS on_service_orders_updated ON public.service_orders;
CREATE TRIGGER on_service_orders_updated BEFORE UPDATE ON public.service_orders FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS on_inspections_updated ON public.inspections;
CREATE TRIGGER on_inspections_updated BEFORE UPDATE ON public.inspections FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS on_estimates_updated ON public.estimates;
CREATE TRIGGER on_estimates_updated BEFORE UPDATE ON public.estimates FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspection_findings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estimates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estimate_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estimate_authorizations ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies

-- Bookings
DROP POLICY IF EXISTS "Admins full access on bookings" ON public.bookings;
CREATE POLICY "Admins full access on bookings" ON public.bookings FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Customers view own bookings" ON public.bookings;
CREATE POLICY "Customers view own bookings" ON public.bookings FOR SELECT
  USING (customer_id IN (SELECT id FROM public.customers WHERE profile_id = auth.uid()));

DROP POLICY IF EXISTS "Customers insert own bookings" ON public.bookings;
CREATE POLICY "Customers insert own bookings" ON public.bookings FOR INSERT
  WITH CHECK (customer_id IN (SELECT id FROM public.customers WHERE profile_id = auth.uid()));

DROP POLICY IF EXISTS "Customers update own bookings" ON public.bookings;
CREATE POLICY "Customers update own bookings" ON public.bookings FOR UPDATE
  USING (customer_id IN (SELECT id FROM public.customers WHERE profile_id = auth.uid()));

-- Service Orders
DROP POLICY IF EXISTS "Admins full access on service_orders" ON public.service_orders;
CREATE POLICY "Admins full access on service_orders" ON public.service_orders FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Mechanics view service_orders" ON public.service_orders;
CREATE POLICY "Mechanics view service_orders" ON public.service_orders FOR SELECT USING (public.current_user_role() = 'mechanic');

DROP POLICY IF EXISTS "Customers view own service_orders" ON public.service_orders;
CREATE POLICY "Customers view own service_orders" ON public.service_orders FOR SELECT
  USING (customer_id IN (SELECT id FROM public.customers WHERE profile_id = auth.uid()));

-- Inspections
DROP POLICY IF EXISTS "Admins full access on inspections" ON public.inspections;
CREATE POLICY "Admins full access on inspections" ON public.inspections FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Mechanics manage inspections" ON public.inspections;
CREATE POLICY "Mechanics manage inspections" ON public.inspections FOR ALL USING (public.current_user_role() = 'mechanic');

DROP POLICY IF EXISTS "Customers view own inspections" ON public.inspections;
CREATE POLICY "Customers view own inspections" ON public.inspections FOR SELECT
  USING (service_order_id IN (SELECT id FROM public.service_orders WHERE customer_id IN (SELECT id FROM public.customers WHERE profile_id = auth.uid())));

-- Inspection Findings
DROP POLICY IF EXISTS "Admins full access on findings" ON public.inspection_findings;
CREATE POLICY "Admins full access on findings" ON public.inspection_findings FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Mechanics manage findings" ON public.inspection_findings;
CREATE POLICY "Mechanics manage findings" ON public.inspection_findings FOR ALL USING (public.current_user_role() = 'mechanic');

DROP POLICY IF EXISTS "Customers view own findings" ON public.inspection_findings;
CREATE POLICY "Customers view own findings" ON public.inspection_findings FOR SELECT
  USING (inspection_id IN (
    SELECT i.id FROM public.inspections i
    JOIN public.service_orders so ON i.service_order_id = so.id
    WHERE so.customer_id IN (SELECT id FROM public.customers WHERE profile_id = auth.uid())
  ));

-- Estimates
DROP POLICY IF EXISTS "Admins full access on estimates" ON public.estimates;
CREATE POLICY "Admins full access on estimates" ON public.estimates FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Mechanics view estimates" ON public.estimates;
CREATE POLICY "Mechanics view estimates" ON public.estimates FOR SELECT USING (public.current_user_role() = 'mechanic');

DROP POLICY IF EXISTS "Customers view own estimates" ON public.estimates;
CREATE POLICY "Customers view own estimates" ON public.estimates FOR SELECT
  USING (service_order_id IN (SELECT id FROM public.service_orders WHERE customer_id IN (SELECT id FROM public.customers WHERE profile_id = auth.uid())));

-- Estimate Items
DROP POLICY IF EXISTS "Admins full access on estimate_items" ON public.estimate_items;
CREATE POLICY "Admins full access on estimate_items" ON public.estimate_items FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Customers view own estimate_items" ON public.estimate_items;
CREATE POLICY "Customers view own estimate_items" ON public.estimate_items FOR SELECT
  USING (estimate_id IN (
    SELECT e.id FROM public.estimates e
    JOIN public.service_orders so ON e.service_order_id = so.id
    WHERE so.customer_id IN (SELECT id FROM public.customers WHERE profile_id = auth.uid())
  ));

-- Estimate Authorizations
DROP POLICY IF EXISTS "Admins full access on authorizations" ON public.estimate_authorizations;
CREATE POLICY "Admins full access on authorizations" ON public.estimate_authorizations FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Customers view and insert own authorizations" ON public.estimate_authorizations;
CREATE POLICY "Customers view and insert own authorizations" ON public.estimate_authorizations FOR ALL
  USING (authorized_by = auth.uid())
  WITH CHECK (authorized_by = auth.uid());

-- 6. RPC Functions

-- 6.1 Atomic Service Order Intake
CREATE OR REPLACE FUNCTION public.create_service_order_intake(
  p_customer_id UUID,
  p_vehicle_id UUID,
  p_odometer INT,
  p_customer_complaint TEXT,
  p_intake_type public.intake_type DEFAULT 'walk_in',
  p_booking_id UUID DEFAULT NULL,
  p_fuel_level TEXT DEFAULT NULL,
  p_initial_notes TEXT DEFAULT NULL,
  p_assigned_bay TEXT DEFAULT 'Bay 01'
)
RETURNS public.service_orders AS $$
DECLARE
  v_order_number TEXT;
  v_seq INT;
  v_year_month TEXT;
  v_new_order public.service_orders;
  v_inspection_id UUID;
BEGIN
  -- Check vehicle not already in active service
  IF EXISTS (
    SELECT 1 FROM public.service_orders
    WHERE vehicle_id = p_vehicle_id
      AND status NOT IN ('completed', 'closed', 'cancelled')
  ) THEN
    RAISE EXCEPTION 'Vehicle already has an active service order';
  END IF;

  -- Generate order number: SO-YYYYMM-XXXX
  v_year_month := to_char(NOW(), 'YYYYMM');
  SELECT COALESCE(COUNT(*), 0) + 1 INTO v_seq
  FROM public.service_orders
  WHERE order_number LIKE 'SO-' || v_year_month || '-%';

  v_order_number := 'SO-' || v_year_month || '-' || LPAD(v_seq::text, 4, '0');

  -- Update vehicle mileage
  UPDATE public.vehicles
  SET mileage = GREATEST(COALESCE(mileage, 0), p_odometer),
      updated_at = NOW()
  WHERE id = p_vehicle_id;

  -- Update booking if present
  IF p_booking_id IS NOT NULL THEN
    UPDATE public.bookings
    SET status = 'checked_in',
        updated_at = NOW()
    WHERE id = p_booking_id;
  END IF;

  -- Insert service order
  INSERT INTO public.service_orders (
    order_number, customer_id, vehicle_id, booking_id, intake_type,
    odometer, customer_complaint, fuel_level, initial_notes,
    status, assigned_bay
  ) VALUES (
    v_order_number, p_customer_id, p_vehicle_id, p_booking_id, p_intake_type,
    p_odometer, p_customer_complaint, p_fuel_level, p_initial_notes,
    'inspection_pending', p_assigned_bay
  ) RETURNING * INTO v_new_order;

  -- Automatically spawn initial inspection session
  INSERT INTO public.inspections (
    service_order_id, status, created_at, updated_at
  ) VALUES (
    v_new_order.id, 'assigned', NOW(), NOW()
  ) RETURNING id INTO v_inspection_id;

  RETURN v_new_order;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.2 Submit Inspection
CREATE OR REPLACE FUNCTION public.submit_inspection(
  p_inspection_id UUID,
  p_summary TEXT,
  p_mechanic_id UUID DEFAULT NULL
)
RETURNS public.inspections AS $$
DECLARE
  v_inspection public.inspections;
  v_order_id UUID;
  v_findings_count INT;
BEGIN
  SELECT * INTO v_inspection FROM public.inspections WHERE id = p_inspection_id;
  IF v_inspection.id IS NULL THEN
    RAISE EXCEPTION 'Inspection session not found';
  END IF;

  -- Validate at least one finding recorded
  SELECT COUNT(*) INTO v_findings_count FROM public.inspection_findings WHERE inspection_id = p_inspection_id;
  IF v_findings_count = 0 THEN
    RAISE EXCEPTION 'Cannot submit inspection without recording diagnostic findings';
  END IF;

  -- Update inspection
  UPDATE public.inspections
  SET status = 'completed',
      summary = p_summary,
      mechanic_id = COALESCE(p_mechanic_id, auth.uid(), mechanic_id),
      completed_at = NOW(),
      updated_at = NOW()
  WHERE id = p_inspection_id
  RETURNING * INTO v_inspection;

  -- Transition service order to estimate_pending
  UPDATE public.service_orders
  SET status = 'estimate_pending',
      updated_at = NOW()
  WHERE id = v_inspection.service_order_id;

  RETURN v_inspection;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.3 Customer Authorize Estimate
CREATE OR REPLACE FUNCTION public.authorize_estimate(
  p_estimate_id UUID,
  p_decision public.estimate_status,
  p_notes TEXT DEFAULT NULL,
  p_signature_token TEXT DEFAULT NULL
)
RETURNS public.estimates AS $$
DECLARE
  v_estimate public.estimates;
  v_order public.service_orders;
  v_cust_profile UUID;
BEGIN
  SELECT * INTO v_estimate FROM public.estimates WHERE id = p_estimate_id;
  IF v_estimate.id IS NULL THEN
    RAISE EXCEPTION 'Estimate not found';
  END IF;

  SELECT * INTO v_order FROM public.service_orders WHERE id = v_estimate.service_order_id;
  SELECT profile_id INTO v_cust_profile FROM public.customers WHERE id = v_order.customer_id;

  -- Authorizer must be owner or admin
  IF auth.uid() != v_cust_profile AND public.current_user_role() != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized to approve this estimate';
  END IF;

  -- Record authorization audit
  INSERT INTO public.estimate_authorizations (
    estimate_id, authorized_by, status, signature_token, notes, authorized_at
  ) VALUES (
    p_estimate_id, auth.uid(), p_decision, p_signature_token, p_notes, NOW()
  );

  -- Update estimate status
  UPDATE public.estimates
  SET status = p_decision,
      updated_at = NOW()
  WHERE id = p_estimate_id
  RETURNING * INTO v_estimate;

  -- Update service order status
  IF p_decision = 'approved' OR p_decision = 'partially_approved' THEN
    UPDATE public.service_orders
    SET status = 'estimate_approved',
        updated_at = NOW()
    WHERE id = v_order.id;
  ELSIF p_decision = 'rejected' THEN
    UPDATE public.service_orders
    SET status = 'estimate_rejected',
        updated_at = NOW()
    WHERE id = v_order.id;
  END IF;

  RETURN v_estimate;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
