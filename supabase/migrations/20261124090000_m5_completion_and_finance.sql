-- Migration: M5 Completion & Finance (QC, Invoicing, Payments, Vehicle Handover)
-- Implements F-014 (Quality Control) and F-015 (Invoice and Payment, Handover)
-- Conforms to docs/PRD.md and docs/ARCHITECTURE.md sections 4.8, 6.11, 7.3

-- 1. Enums
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'qc_status') THEN
    CREATE TYPE public.qc_status AS ENUM ('in_progress', 'passed', 'failed');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'invoice_status') THEN
    CREATE TYPE public.invoice_status AS ENUM ('draft', 'issued', 'partially_paid', 'paid', 'cancelled');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method') THEN
    CREATE TYPE public.payment_method AS ENUM ('cash', 'qris', 'card', 'bank_transfer');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
    CREATE TYPE public.payment_status AS ENUM ('completed', 'pending', 'failed', 'refunded');
  END IF;
END $$;

-- 2. Quality Control Tables
CREATE TABLE IF NOT EXISTS public.qc_inspections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  inspector_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  status public.qc_status NOT NULL DEFAULT 'in_progress',
  notes TEXT,
  failure_reason TEXT,
  correction_notes TEXT,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.qc_checklist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  qc_inspection_id UUID NOT NULL REFERENCES public.qc_inspections(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  item_name TEXT NOT NULL,
  is_passed BOOLEAN NOT NULL DEFAULT FALSE,
  notes TEXT,
  checked_at TIMESTAMPTZ
);

-- 3. Invoices & Invoice Items Tables
CREATE TABLE IF NOT EXISTS public.invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number TEXT NOT NULL UNIQUE,
  service_order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE RESTRICT,
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT,
  status public.invoice_status NOT NULL DEFAULT 'draft',
  subtotal_labor_cents BIGINT NOT NULL DEFAULT 0 CHECK (subtotal_labor_cents >= 0),
  subtotal_parts_cents BIGINT NOT NULL DEFAULT 0 CHECK (subtotal_parts_cents >= 0),
  tax_percent NUMERIC(5,2) NOT NULL DEFAULT 11.00 CHECK (tax_percent >= 0),
  tax_amount_cents BIGINT NOT NULL DEFAULT 0 CHECK (tax_amount_cents >= 0),
  discount_cents BIGINT NOT NULL DEFAULT 0 CHECK (discount_cents >= 0),
  deposit_applied_cents BIGINT NOT NULL DEFAULT 0 CHECK (deposit_applied_cents >= 0),
  insurance_coverage_cents BIGINT NOT NULL DEFAULT 0 CHECK (insurance_coverage_cents >= 0),
  total_amount_cents BIGINT NOT NULL DEFAULT 0 CHECK (total_amount_cents >= 0),
  amount_paid_cents BIGINT NOT NULL DEFAULT 0 CHECK (amount_paid_cents >= 0),
  outstanding_balance_cents BIGINT GENERATED ALWAYS AS (GREATEST(0, total_amount_cents - amount_paid_cents)) STORED,
  finalized_at TIMESTAMPTZ,
  finalized_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.invoice_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
  item_type TEXT NOT NULL CHECK (item_type IN ('labor', 'part', 'fee', 'discount')),
  description TEXT NOT NULL,
  quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
  unit_price_cents BIGINT NOT NULL DEFAULT 0 CHECK (unit_price_cents >= 0),
  total_price_cents BIGINT NOT NULL DEFAULT 0 CHECK (total_price_cents >= 0),
  part_id UUID REFERENCES public.parts(id) ON DELETE SET NULL,
  task_id UUID REFERENCES public.service_order_tasks(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Payments Table
CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_number TEXT NOT NULL UNIQUE,
  invoice_id UUID NOT NULL REFERENCES public.invoices(id) ON DELETE RESTRICT,
  amount_cents BIGINT NOT NULL CHECK (amount_cents > 0),
  payment_method public.payment_method NOT NULL,
  payment_status public.payment_status NOT NULL DEFAULT 'completed',
  reference_number TEXT,
  cash_tendered_cents BIGINT CHECK (cash_tendered_cents IS NULL OR cash_tendered_cents >= amount_cents),
  change_given_cents BIGINT DEFAULT 0 CHECK (change_given_cents >= 0),
  notes TEXT,
  recorded_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Vehicle Handover Table
CREATE TABLE IF NOT EXISTS public.vehicle_handovers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_order_id UUID NOT NULL UNIQUE REFERENCES public.service_orders(id) ON DELETE RESTRICT,
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT,
  responsible_admin_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  handover_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  customer_confirmed BOOLEAN NOT NULL DEFAULT TRUE,
  payment_override_reason TEXT,
  checklist JSONB NOT NULL DEFAULT '{"vehicle_cleaned": true, "personal_items_returned": true, "old_parts_presented": true, "keys_returned": true}'::jsonb,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Indexes
CREATE INDEX IF NOT EXISTS idx_qc_inspections_order ON public.qc_inspections(service_order_id);
CREATE INDEX IF NOT EXISTS idx_qc_items_inspection ON public.qc_checklist_items(qc_inspection_id);
CREATE INDEX IF NOT EXISTS idx_invoices_order ON public.invoices(service_order_id);
CREATE INDEX IF NOT EXISTS idx_invoices_customer ON public.invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON public.invoice_items(invoice_id);
CREATE INDEX IF NOT EXISTS idx_payments_invoice ON public.payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_handovers_order ON public.vehicle_handovers(service_order_id);

-- 7. Row Level Security
ALTER TABLE public.qc_inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qc_checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicle_handovers ENABLE ROW LEVEL SECURITY;

-- Admins: full CRUD on all M5 tables
CREATE POLICY "Admins full access on qc_inspections" ON public.qc_inspections
  FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins full access on qc_checklist_items" ON public.qc_checklist_items
  FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins full access on invoices" ON public.invoices
  FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins full access on invoice_items" ON public.invoice_items
  FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins full access on payments" ON public.payments
  FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "Admins full access on vehicle_handovers" ON public.vehicle_handovers
  FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- Mechanics: view QC and update checklists
CREATE POLICY "Mechanics read qc_inspections" ON public.qc_inspections
  FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'mechanic')));

CREATE POLICY "Mechanics modify qc_checklist_items" ON public.qc_checklist_items
  FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'mechanic')));

-- Customers: view their own invoices, invoice_items, payments, vehicle_handovers
CREATE POLICY "Customers view own invoices" ON public.invoices
  FOR SELECT TO authenticated USING (
    customer_id IN (SELECT id FROM public.customers WHERE profile_id = auth.uid())
  );

CREATE POLICY "Customers view own invoice_items" ON public.invoice_items
  FOR SELECT TO authenticated USING (
    invoice_id IN (
      SELECT id FROM public.invoices WHERE customer_id IN (
        SELECT id FROM public.customers WHERE profile_id = auth.uid()
      )
    )
  );

CREATE POLICY "Customers view own payments" ON public.payments
  FOR SELECT TO authenticated USING (
    invoice_id IN (
      SELECT id FROM public.invoices WHERE customer_id IN (
        SELECT id FROM public.customers WHERE profile_id = auth.uid()
      )
    )
  );

CREATE POLICY "Customers view own vehicle_handovers" ON public.vehicle_handovers
  FOR SELECT TO authenticated USING (
    customer_id IN (SELECT id FROM public.customers WHERE profile_id = auth.uid())
  );

-- 8. Transactional Database RPCs

-- 8.1 submit_order_for_qc
CREATE OR REPLACE FUNCTION public.submit_order_for_qc(
  p_service_order_id UUID,
  p_inspector_id UUID
) RETURNS UUID AS $$
DECLARE
  v_qc_id UUID;
  v_order_status public.service_order_status;
BEGIN
  SELECT status INTO v_order_status FROM public.service_orders WHERE id = p_service_order_id;
  IF v_order_status IS NULL THEN
    RAISE EXCEPTION 'Service order % not found', p_service_order_id;
  END IF;

  INSERT INTO public.qc_inspections (service_order_id, inspector_id, status)
  VALUES (p_service_order_id, p_inspector_id, 'in_progress')
  RETURNING id INTO v_qc_id;

  -- Populate default 5-category checklist
  INSERT INTO public.qc_checklist_items (qc_inspection_id, category, item_name, is_passed) VALUES
    (v_qc_id, 'Mechanical', 'Braking system test & pedal firmness', false),
    (v_qc_id, 'Fluids', 'Engine oil, coolant & brake fluid levels', false),
    (v_qc_id, 'Electrical', 'Headlights, indicators & battery terminals', false),
    (v_qc_id, 'Safety', 'Torque spec verification on wheel nuts', false),
    (v_qc_id, 'Cosmetics', 'Vehicle clean, floor mats & protective film removed', false);

  UPDATE public.service_orders SET status = 'qc_pending', updated_at = NOW() WHERE id = p_service_order_id;

  RETURN v_qc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8.2 record_qc_result
CREATE OR REPLACE FUNCTION public.record_qc_result(
  p_qc_inspection_id UUID,
  p_status public.qc_status,
  p_notes TEXT DEFAULT NULL,
  p_failure_reason TEXT DEFAULT NULL,
  p_items JSONB DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
  v_order_id UUID;
  v_item JSONB;
BEGIN
  SELECT service_order_id INTO v_order_id FROM public.qc_inspections WHERE id = p_qc_inspection_id;
  IF v_order_id IS NULL THEN
    RAISE EXCEPTION 'QC inspection % not found', p_qc_inspection_id;
  END IF;

  UPDATE public.qc_inspections
  SET status = p_status,
      notes = COALESCE(p_notes, notes),
      failure_reason = CASE WHEN p_status = 'failed' THEN p_failure_reason ELSE NULL END,
      completed_at = CASE WHEN p_status IN ('passed', 'failed') THEN NOW() ELSE completed_at END,
      updated_at = NOW()
  WHERE id = p_qc_inspection_id;

  -- Update checklist items if provided
  IF p_items IS NOT NULL AND jsonb_array_length(p_items) > 0 THEN
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
      UPDATE public.qc_checklist_items
      SET is_passed = (v_item->>'is_passed')::boolean,
          notes = v_item->>'notes',
          checked_at = NOW()
      WHERE id = (v_item->>'id')::uuid AND qc_inspection_id = p_qc_inspection_id;
    END LOOP;
  END IF;

  -- Update service order status
  IF p_status = 'passed' THEN
    UPDATE public.service_orders SET status = 'completed', updated_at = NOW() WHERE id = v_order_id;
  ELSIF p_status = 'failed' THEN
    UPDATE public.service_orders SET status = 'in_progress', updated_at = NOW() WHERE id = v_order_id;
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8.3 return_to_repair_from_qc
CREATE OR REPLACE FUNCTION public.return_to_repair_from_qc(
  p_qc_inspection_id UUID,
  p_correction_notes TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_order_id UUID;
BEGIN
  SELECT service_order_id INTO v_order_id FROM public.qc_inspections WHERE id = p_qc_inspection_id;
  IF v_order_id IS NULL THEN
    RAISE EXCEPTION 'QC inspection % not found', p_qc_inspection_id;
  END IF;

  UPDATE public.qc_inspections
  SET status = 'failed',
      failure_reason = p_correction_notes,
      correction_notes = p_correction_notes,
      completed_at = NOW(),
      updated_at = NOW()
  WHERE id = p_qc_inspection_id;

  UPDATE public.service_orders SET status = 'in_progress', updated_at = NOW() WHERE id = v_order_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8.4 generate_service_order_invoice
CREATE OR REPLACE FUNCTION public.generate_service_order_invoice(
  p_service_order_id UUID,
  p_tax_percent NUMERIC DEFAULT 11.00,
  p_discount_cents BIGINT DEFAULT 0,
  p_deposit_cents BIGINT DEFAULT 0,
  p_insurance_cents BIGINT DEFAULT 0,
  p_admin_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_customer_id UUID;
  v_invoice_id UUID;
  v_invoice_number TEXT;
  v_subtotal_labor BIGINT := 0;
  v_subtotal_parts BIGINT := 0;
  v_taxable_subtotal BIGINT := 0;
  v_tax_amount BIGINT := 0;
  v_total_amount BIGINT := 0;
  v_task RECORD;
  v_part RECORD;
BEGIN
  SELECT customer_id INTO v_customer_id FROM public.service_orders WHERE id = p_service_order_id;
  IF v_customer_id IS NULL THEN
    RAISE EXCEPTION 'Service order % not found', p_service_order_id;
  END IF;

  -- Generate invoice number: INV-YYYYMMDD-XXXX
  v_invoice_number := 'INV-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 9000 + 1000)::TEXT, 4, '0');

  -- Calculate labor lines from completed service_order_tasks
  FOR v_task IN
    SELECT id, task_name, (standard_hours * 25000000)::BIGINT AS labor_cents -- default Rp 250k/hr
    FROM public.service_order_tasks
    WHERE service_order_id = p_service_order_id
  LOOP
    v_subtotal_labor := v_subtotal_labor + COALESCE(v_task.labor_cents, 0);
  END LOOP;

  -- If no tasks found, provide standard inspection/service base fee of 15000000 (Rp 150.000)
  IF v_subtotal_labor = 0 THEN
    v_subtotal_labor := 15000000;
  END IF;

  -- Calculate parts lines from consumed parts
  FOR v_part IN
    SELECT p.id AS part_id, p.name AS part_name, c.quantity_consumed, p.selling_price_cents
    FROM public.service_task_part_consumptions c
    JOIN public.parts p ON c.part_id = p.id
    WHERE c.service_order_id = p_service_order_id AND c.quantity_consumed > 0
  LOOP
    v_subtotal_parts := v_subtotal_parts + (v_part.quantity_consumed * v_part.selling_price_cents);
  END LOOP;

  -- Calculate tax and total
  v_taxable_subtotal := GREATEST(0, (v_subtotal_labor + v_subtotal_parts) - COALESCE(p_discount_cents, 0));
  v_tax_amount := ((v_taxable_subtotal * COALESCE(p_tax_percent, 11.00)) / 100)::BIGINT;
  v_total_amount := GREATEST(0, (v_taxable_subtotal + v_tax_amount) - COALESCE(p_insurance_cents, 0));

  -- Insert invoice
  INSERT INTO public.invoices (
    invoice_number, service_order_id, customer_id, status,
    subtotal_labor_cents, subtotal_parts_cents, tax_percent, tax_amount_cents,
    discount_cents, deposit_applied_cents, insurance_coverage_cents,
    total_amount_cents, amount_paid_cents, finalized_at, finalized_by
  ) VALUES (
    v_invoice_number, p_service_order_id, v_customer_id, 'issued',
    v_subtotal_labor, v_subtotal_parts, COALESCE(p_tax_percent, 11.00), v_tax_amount,
    COALESCE(p_discount_cents, 0), COALESCE(p_deposit_cents, 0), COALESCE(p_insurance_cents, 0),
    v_total_amount, COALESCE(p_deposit_cents, 0), NOW(), p_admin_id
  ) RETURNING id INTO v_invoice_id;

  -- Insert task labor lines
  FOR v_task IN
    SELECT id, task_name, (standard_hours * 25000000)::BIGINT AS labor_cents
    FROM public.service_order_tasks
    WHERE service_order_id = p_service_order_id
  LOOP
    INSERT INTO public.invoice_items (invoice_id, item_type, description, quantity, unit_price_cents, total_price_cents, task_id)
    VALUES (v_invoice_id, 'labor', v_task.task_name, 1, v_task.labor_cents, v_task.labor_cents, v_task.id);
  END LOOP;

  -- If no tasks, insert base service line
  IF NOT EXISTS (SELECT 1 FROM public.invoice_items WHERE invoice_id = v_invoice_id AND item_type = 'labor') THEN
    INSERT INTO public.invoice_items (invoice_id, item_type, description, quantity, unit_price_cents, total_price_cents)
    VALUES (v_invoice_id, 'labor', 'Comprehensive Service & Inspection Operations', 1, 15000000, 15000000);
  END IF;

  -- Insert parts lines
  FOR v_part IN
    SELECT p.id AS part_id, p.name AS part_name, c.quantity_consumed, p.selling_price_cents
    FROM public.service_task_part_consumptions c
    JOIN public.parts p ON c.part_id = p.id
    WHERE c.service_order_id = p_service_order_id AND c.quantity_consumed > 0
  LOOP
    INSERT INTO public.invoice_items (invoice_id, item_type, description, quantity, unit_price_cents, total_price_cents, part_id)
    VALUES (
      v_invoice_id, 'part', v_part.part_name, v_part.quantity_consumed,
      v_part.selling_price_cents, (v_part.quantity_consumed * v_part.selling_price_cents), v_part.part_id
    );
  END LOOP;

  RETURN v_invoice_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8.5 record_invoice_payment
CREATE OR REPLACE FUNCTION public.record_invoice_payment(
  p_invoice_id UUID,
  p_amount_cents BIGINT,
  p_payment_method public.payment_method,
  p_reference_number TEXT DEFAULT NULL,
  p_cash_tendered_cents BIGINT DEFAULT NULL,
  p_change_cents BIGINT DEFAULT 0,
  p_admin_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_payment_id UUID;
  v_payment_number TEXT;
  v_total_amount BIGINT;
  v_amount_paid BIGINT;
  v_recorded_by UUID;
BEGIN
  SELECT total_amount_cents, amount_paid_cents INTO v_total_amount, v_amount_paid
  FROM public.invoices WHERE id = p_invoice_id;

  IF v_total_amount IS NULL THEN
    RAISE EXCEPTION 'Invoice % not found', p_invoice_id;
  END IF;

  v_recorded_by := COALESCE(p_admin_id, auth.uid());
  v_payment_number := 'PAY-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 9000 + 1000)::TEXT, 4, '0');

  INSERT INTO public.payments (
    payment_number, invoice_id, amount_cents, payment_method, payment_status,
    reference_number, cash_tendered_cents, change_given_cents, recorded_by
  ) VALUES (
    v_payment_number, p_invoice_id, p_amount_cents, p_payment_method, 'completed',
    COALESCE(p_reference_number, 'SIM-' || LPAD(FLOOR(RANDOM() * 900000 + 100000)::TEXT, 6, '0')),
    p_cash_tendered_cents, COALESCE(p_change_cents, 0), v_recorded_by
  ) RETURNING id INTO v_payment_id;

  -- Update invoice paid status
  UPDATE public.invoices
  SET amount_paid_cents = amount_paid_cents + p_amount_cents,
      status = CASE
        WHEN (amount_paid_cents + p_amount_cents) >= total_amount_cents THEN 'paid'::public.invoice_status
        ELSE 'partially_paid'::public.invoice_status
      END,
      updated_at = NOW()
  WHERE id = p_invoice_id;

  RETURN v_payment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8.6 record_vehicle_handover
CREATE OR REPLACE FUNCTION public.record_vehicle_handover(
  p_service_order_id UUID,
  p_admin_id UUID,
  p_checklist JSONB DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_payment_override_reason TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_handover_id UUID;
  v_customer_id UUID;
  v_outstanding BIGINT;
BEGIN
  SELECT customer_id INTO v_customer_id FROM public.service_orders WHERE id = p_service_order_id;
  IF v_customer_id IS NULL THEN
    RAISE EXCEPTION 'Service order % not found', p_service_order_id;
  END IF;

  -- Check outstanding balance on latest invoice if any
  SELECT outstanding_balance_cents INTO v_outstanding
  FROM public.invoices
  WHERE service_order_id = p_service_order_id
  ORDER BY created_at DESC LIMIT 1;

  IF v_outstanding IS NOT NULL AND v_outstanding > 0 AND (p_payment_override_reason IS NULL OR TRIM(p_payment_override_reason) = '') THEN
    RAISE EXCEPTION 'Cannot handover vehicle with outstanding balance of % cents without authorized override reason', v_outstanding;
  END IF;

  INSERT INTO public.vehicle_handovers (
    service_order_id, customer_id, responsible_admin_id,
    payment_override_reason, checklist, notes
  ) VALUES (
    p_service_order_id, v_customer_id, p_admin_id,
    p_payment_override_reason,
    COALESCE(p_checklist, '{"vehicle_cleaned": true, "personal_items_returned": true, "old_parts_presented": true, "keys_returned": true}'::jsonb),
    p_notes
  ) RETURNING id INTO v_handover_id;

  -- Mark service order closed
  UPDATE public.service_orders SET status = 'closed', updated_at = NOW() WHERE id = p_service_order_id;

  RETURN v_handover_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
