-- Migration: 20261123000002_m4_inventory_and_costing.sql
-- Milestone M4: Inventory & Cost Management
-- Tables: parts, inventory_balances, inventory_transactions, part_requests,
--         service_task_part_consumptions, mechanic_compensation_profiles,
--         mechanic_earnings, mechanic_earning_allocations, mechanic_payroll_adjustments

-- 1. Enums
DO $$ BEGIN
  CREATE TYPE public.inventory_transaction_type AS ENUM (
    'receiving', 'adjustment', 'reservation', 'reservation_release', 'issue', 'consumption', 'return', 'damaged'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE public.part_request_status AS ENUM (
    'pending', 'fulfilled', 'partially_fulfilled', 'rejected', 'unavailable'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE public.earning_status AS ENUM (
    'accrued', 'approved', 'paid', 'adjusted'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- 2. Tables

-- 2.1 Part Catalog
CREATE TABLE IF NOT EXISTS public.parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  unit_of_measurement TEXT NOT NULL DEFAULT 'pcs',
  purchase_cost_cents BIGINT NOT NULL DEFAULT 0 CHECK (purchase_cost_cents >= 0),
  selling_price_cents BIGINT NOT NULL DEFAULT 0 CHECK (selling_price_cents >= 0),
  minimum_stock INT NOT NULL DEFAULT 0 CHECK (minimum_stock >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_parts_category ON public.parts(category);
CREATE INDEX IF NOT EXISTS idx_parts_sku ON public.parts(sku);

-- 2.2 Inventory Balances (Enforces Negative Stock Invariant at DB level)
CREATE TABLE IF NOT EXISTS public.inventory_balances (
  part_id UUID PRIMARY KEY REFERENCES public.parts(id) ON DELETE CASCADE,
  quantity_on_hand INT NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
  quantity_reserved INT NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0),
  quantity_available INT GENERATED ALWAYS AS (quantity_on_hand - quantity_reserved) STORED CHECK (quantity_on_hand - quantity_reserved >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2.3 Immutable Movement Ledger
CREATE TABLE IF NOT EXISTS public.inventory_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  part_id UUID NOT NULL REFERENCES public.parts(id) ON DELETE RESTRICT,
  transaction_type public.inventory_transaction_type NOT NULL,
  quantity_change INT NOT NULL,
  balance_after_on_hand INT NOT NULL,
  balance_after_reserved INT NOT NULL,
  unit_cost_cents BIGINT NOT NULL DEFAULT 0,
  total_cost_cents BIGINT NOT NULL DEFAULT 0,
  reason TEXT,
  reference_id TEXT,
  performed_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inv_tx_part ON public.inventory_transactions(part_id);
CREATE INDEX IF NOT EXISTS idx_inv_tx_type ON public.inventory_transactions(transaction_type);

-- 2.4 Part Requests
CREATE TABLE IF NOT EXISTS public.part_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  task_id UUID REFERENCES public.service_order_tasks(id) ON DELETE SET NULL,
  part_id UUID NOT NULL REFERENCES public.parts(id) ON DELETE RESTRICT,
  requested_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  quantity_requested INT NOT NULL CHECK (quantity_requested > 0),
  quantity_fulfilled INT NOT NULL DEFAULT 0 CHECK (quantity_fulfilled >= 0),
  status public.part_request_status NOT NULL DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_part_req_order ON public.part_requests(service_order_id);
CREATE INDEX IF NOT EXISTS idx_part_req_task ON public.part_requests(task_id);
CREATE INDEX IF NOT EXISTS idx_part_req_status ON public.part_requests(status);

-- 2.5 Service Task Consumptions
CREATE TABLE IF NOT EXISTS public.service_task_part_consumptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  task_id UUID NOT NULL REFERENCES public.service_order_tasks(id) ON DELETE CASCADE,
  part_id UUID NOT NULL REFERENCES public.parts(id) ON DELETE RESTRICT,
  quantity_issued INT NOT NULL DEFAULT 0 CHECK (quantity_issued >= 0),
  quantity_consumed INT NOT NULL DEFAULT 0 CHECK (quantity_consumed >= 0),
  quantity_returned INT NOT NULL DEFAULT 0 CHECK (quantity_returned >= 0),
  unit_cost_cents BIGINT NOT NULL,
  total_cost_cents BIGINT NOT NULL,
  recorded_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_part_cons_task ON public.service_task_part_consumptions(task_id);

-- 2.6 Mechanic Compensation Profiles
CREATE TABLE IF NOT EXISTS public.mechanic_compensation_profiles (
  mechanic_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  monthly_base_salary_cents BIGINT NOT NULL DEFAULT 0 CHECK (monthly_base_salary_cents >= 0),
  standard_incentive_percent NUMERIC(5,2) NOT NULL DEFAULT 10.00 CHECK (standard_incentive_percent >= 0),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2.7 Mechanic Earnings (Accrued from completed tasks)
CREATE TABLE IF NOT EXISTS public.mechanic_earnings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  task_id UUID NOT NULL REFERENCES public.service_order_tasks(id) ON DELETE CASCADE,
  total_eligible_labor_cents BIGINT NOT NULL CHECK (total_eligible_labor_cents >= 0),
  total_incentive_pool_cents BIGINT NOT NULL CHECK (total_incentive_pool_cents >= 0),
  status public.earning_status NOT NULL DEFAULT 'accrued',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mech_earn_task ON public.mechanic_earnings(task_id);

-- 2.8 Mechanic Earning Allocations (Split distribution)
CREATE TABLE IF NOT EXISTS public.mechanic_earning_allocations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  earning_id UUID NOT NULL REFERENCES public.mechanic_earnings(id) ON DELETE CASCADE,
  mechanic_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  split_percentage NUMERIC(5,2) NOT NULL CHECK (split_percentage > 0 AND split_percentage <= 100),
  allocated_cents BIGINT NOT NULL CHECK (allocated_cents >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_earn_alloc_mech ON public.mechanic_earning_allocations(mechanic_id);

-- 2.9 Mechanic Payroll Adjustments
CREATE TABLE IF NOT EXISTS public.mechanic_payroll_adjustments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mechanic_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  amount_cents BIGINT NOT NULL,
  reason TEXT NOT NULL,
  adjusted_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payroll_adj_mech ON public.mechanic_payroll_adjustments(mechanic_id);

-- 3. Triggers for updated_at
DROP TRIGGER IF EXISTS on_parts_updated ON public.parts;
CREATE TRIGGER on_parts_updated BEFORE UPDATE ON public.parts FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS on_part_requests_updated ON public.part_requests;
CREATE TRIGGER on_part_requests_updated BEFORE UPDATE ON public.part_requests FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS on_part_consumptions_updated ON public.service_task_part_consumptions;
CREATE TRIGGER on_part_consumptions_updated BEFORE UPDATE ON public.service_task_part_consumptions FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 4. Enable Row Level Security
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.part_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_task_part_consumptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mechanic_compensation_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mechanic_earnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mechanic_earning_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mechanic_payroll_adjustments ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies

-- Admins: full access
DROP POLICY IF EXISTS "Admins full access on parts" ON public.parts;
CREATE POLICY "Admins full access on parts" ON public.parts FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Admins full access on inventory_balances" ON public.inventory_balances;
CREATE POLICY "Admins full access on inventory_balances" ON public.inventory_balances FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Admins full access on inventory_transactions" ON public.inventory_transactions;
CREATE POLICY "Admins full access on inventory_transactions" ON public.inventory_transactions FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Admins full access on part_requests" ON public.part_requests;
CREATE POLICY "Admins full access on part_requests" ON public.part_requests FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Admins full access on service_task_part_consumptions" ON public.service_task_part_consumptions;
CREATE POLICY "Admins full access on service_task_part_consumptions" ON public.service_task_part_consumptions FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Admins full access on mechanic_compensation_profiles" ON public.mechanic_compensation_profiles;
CREATE POLICY "Admins full access on mechanic_compensation_profiles" ON public.mechanic_compensation_profiles FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Admins full access on mechanic_earnings" ON public.mechanic_earnings;
CREATE POLICY "Admins full access on mechanic_earnings" ON public.mechanic_earnings FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Admins full access on mechanic_earning_allocations" ON public.mechanic_earning_allocations;
CREATE POLICY "Admins full access on mechanic_earning_allocations" ON public.mechanic_earning_allocations FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Admins full access on mechanic_payroll_adjustments" ON public.mechanic_payroll_adjustments;
CREATE POLICY "Admins full access on mechanic_payroll_adjustments" ON public.mechanic_payroll_adjustments FOR ALL USING (public.current_user_role() = 'admin');

-- Mechanics: read-only on parts and balances
DROP POLICY IF EXISTS "Mechanics view parts" ON public.parts;
CREATE POLICY "Mechanics view parts" ON public.parts FOR SELECT USING (public.current_user_role() = 'mechanic');

DROP POLICY IF EXISTS "Mechanics view inventory_balances" ON public.inventory_balances;
CREATE POLICY "Mechanics view inventory_balances" ON public.inventory_balances FOR SELECT USING (public.current_user_role() = 'mechanic');

-- Mechanics: manage own part requests
DROP POLICY IF EXISTS "Mechanics view own part requests" ON public.part_requests;
CREATE POLICY "Mechanics view own part requests" ON public.part_requests FOR SELECT USING (requested_by = auth.uid() OR public.current_user_role() = 'mechanic');

DROP POLICY IF EXISTS "Mechanics create part requests" ON public.part_requests;
CREATE POLICY "Mechanics create part requests" ON public.part_requests FOR INSERT WITH CHECK (public.current_user_role() = 'mechanic');

-- Mechanics: view & record task consumptions
DROP POLICY IF EXISTS "Mechanics view task consumptions" ON public.service_task_part_consumptions;
CREATE POLICY "Mechanics view task consumptions" ON public.service_task_part_consumptions FOR SELECT USING (public.current_user_role() = 'mechanic');

DROP POLICY IF EXISTS "Mechanics record task consumptions" ON public.service_task_part_consumptions;
CREATE POLICY "Mechanics record task consumptions" ON public.service_task_part_consumptions FOR INSERT WITH CHECK (public.current_user_role() = 'mechanic');

-- Mechanics: view own compensation, allocations, and payroll adjustments
DROP POLICY IF EXISTS "Mechanics view own compensation profile" ON public.mechanic_compensation_profiles;
CREATE POLICY "Mechanics view own compensation profile" ON public.mechanic_compensation_profiles FOR SELECT USING (mechanic_id = auth.uid());

DROP POLICY IF EXISTS "Mechanics view own earnings allocations" ON public.mechanic_earning_allocations;
CREATE POLICY "Mechanics view own earnings allocations" ON public.mechanic_earning_allocations FOR SELECT USING (mechanic_id = auth.uid());

DROP POLICY IF EXISTS "Mechanics view own payroll adjustments" ON public.mechanic_payroll_adjustments;
CREATE POLICY "Mechanics view own payroll adjustments" ON public.mechanic_payroll_adjustments FOR SELECT USING (mechanic_id = auth.uid());

-- 6. Stored Procedures / RPCs

-- 6.1 Receive Stock (with Weighted-Average Purchase Cost recalculation)
CREATE OR REPLACE FUNCTION public.receive_stock(
  p_part_id UUID,
  p_quantity INT,
  p_unit_cost_cents BIGINT,
  p_supplier_ref TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_part public.parts;
  v_balance public.inventory_balances;
  v_new_avg BIGINT;
  v_user_id UUID;
BEGIN
  IF p_quantity <= 0 THEN
    RAISE EXCEPTION 'Received quantity must be greater than zero';
  END IF;

  SELECT * INTO v_part FROM public.parts WHERE id = p_part_id;
  IF v_part.id IS NULL THEN
    RAISE EXCEPTION 'Part not found';
  END IF;

  SELECT * INTO v_balance FROM public.inventory_balances WHERE part_id = p_part_id;
  IF v_balance.part_id IS NULL THEN
    INSERT INTO public.inventory_balances (part_id, quantity_on_hand, quantity_reserved)
    VALUES (p_part_id, 0, 0)
    RETURNING * INTO v_balance;
  END IF;

  -- Weighted-Average Cost formula:
  -- ((on_hand * old_cost) + (new_qty * new_cost)) / (on_hand + new_qty)
  IF (v_balance.quantity_on_hand + p_quantity) > 0 THEN
    v_new_avg := ((v_balance.quantity_on_hand * v_part.purchase_cost_cents) + (p_quantity * p_unit_cost_cents)) / (v_balance.quantity_on_hand + p_quantity);
  ELSE
    v_new_avg := p_unit_cost_cents;
  END IF;

  -- Update part purchase cost
  UPDATE public.parts
  SET purchase_cost_cents = v_new_avg,
      updated_at = NOW()
  WHERE id = p_part_id;

  -- Update balance
  UPDATE public.inventory_balances
  SET quantity_on_hand = quantity_on_hand + p_quantity,
      updated_at = NOW()
  WHERE part_id = p_part_id
  RETURNING * INTO v_balance;

  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    SELECT id INTO v_user_id FROM public.profiles WHERE role = 'admin' LIMIT 1;
  END IF;

  -- Record in ledger
  INSERT INTO public.inventory_transactions (
    part_id,
    transaction_type,
    quantity_change,
    balance_after_on_hand,
    balance_after_reserved,
    unit_cost_cents,
    total_cost_cents,
    reason,
    reference_id,
    performed_by
  ) VALUES (
    p_part_id,
    'receiving',
    p_quantity,
    v_balance.quantity_on_hand,
    v_balance.quantity_reserved,
    p_unit_cost_cents,
    (p_quantity * p_unit_cost_cents),
    COALESCE(p_notes, 'Stock receipt from supplier'),
    p_supplier_ref,
    v_user_id
  );

  RETURN jsonb_build_object(
    'success', true,
    'part_id', p_part_id,
    'new_on_hand', v_balance.quantity_on_hand,
    'new_available', v_balance.quantity_available,
    'new_average_cost_cents', v_new_avg
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.2 Adjust Stock (Audit correction with mandatory reason)
CREATE OR REPLACE FUNCTION public.adjust_stock(
  p_part_id UUID,
  p_quantity_change INT,
  p_reason TEXT
)
RETURNS JSONB AS $$
DECLARE
  v_part public.parts;
  v_balance public.inventory_balances;
  v_user_id UUID;
  v_tx_type public.inventory_transaction_type;
BEGIN
  IF p_reason IS NULL OR TRIM(p_reason) = '' THEN
    RAISE EXCEPTION 'A specific reason is mandatory for stock adjustment';
  END IF;

  SELECT * INTO v_part FROM public.parts WHERE id = p_part_id;
  IF v_part.id IS NULL THEN
    RAISE EXCEPTION 'Part not found';
  END IF;

  SELECT * INTO v_balance FROM public.inventory_balances WHERE part_id = p_part_id;
  IF v_balance.part_id IS NULL THEN
    RAISE EXCEPTION 'Inventory balance record not found';
  END IF;

  IF (v_balance.quantity_on_hand + p_quantity_change) < v_balance.quantity_reserved THEN
    RAISE EXCEPTION 'Cannot adjust stock: result would cause negative available stock (reserved: % units)', v_balance.quantity_reserved;
  END IF;

  IF (v_balance.quantity_on_hand + p_quantity_change) < 0 THEN
    RAISE EXCEPTION 'Cannot adjust stock: result would cause negative physical on-hand stock';
  END IF;

  UPDATE public.inventory_balances
  SET quantity_on_hand = quantity_on_hand + p_quantity_change,
      updated_at = NOW()
  WHERE part_id = p_part_id
  RETURNING * INTO v_balance;

  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    SELECT id INTO v_user_id FROM public.profiles WHERE role = 'admin' LIMIT 1;
  END IF;

  v_tx_type := CASE WHEN p_quantity_change < 0 AND LOWER(p_reason) LIKE '%damage%' THEN 'damaged'::public.inventory_transaction_type ELSE 'adjustment'::public.inventory_transaction_type END;

  INSERT INTO public.inventory_transactions (
    part_id,
    transaction_type,
    quantity_change,
    balance_after_on_hand,
    balance_after_reserved,
    unit_cost_cents,
    total_cost_cents,
    reason,
    performed_by
  ) VALUES (
    p_part_id,
    v_tx_type,
    p_quantity_change,
    v_balance.quantity_on_hand,
    v_balance.quantity_reserved,
    v_part.purchase_cost_cents,
    ABS(p_quantity_change * v_part.purchase_cost_cents),
    p_reason,
    v_user_id
  );

  RETURN jsonb_build_object(
    'success', true,
    'part_id', p_part_id,
    'new_on_hand', v_balance.quantity_on_hand,
    'new_available', v_balance.quantity_available
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.3 Request Part For Task (Floor mechanic request)
CREATE OR REPLACE FUNCTION public.request_part_for_task(
  p_task_id UUID,
  p_part_id UUID,
  p_quantity INT,
  p_notes TEXT DEFAULT NULL
)
RETURNS public.part_requests AS $$
DECLARE
  v_task public.service_order_tasks;
  v_req public.part_requests;
  v_user_id UUID;
BEGIN
  IF p_quantity <= 0 THEN
    RAISE EXCEPTION 'Requested quantity must be greater than zero';
  END IF;

  SELECT * INTO v_task FROM public.service_order_tasks WHERE id = p_task_id;
  IF v_task.id IS NULL THEN
    RAISE EXCEPTION 'Task not found';
  END IF;

  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    v_user_id := v_task.assigned_mechanic_id;
  END IF;
  IF v_user_id IS NULL THEN
    SELECT id INTO v_user_id FROM public.profiles WHERE role = 'mechanic' LIMIT 1;
  END IF;

  INSERT INTO public.part_requests (
    service_order_id,
    task_id,
    part_id,
    requested_by,
    quantity_requested,
    quantity_fulfilled,
    status,
    notes
  ) VALUES (
    v_task.service_order_id,
    p_task_id,
    p_part_id,
    v_user_id,
    p_quantity,
    0,
    'pending',
    p_notes
  )
  RETURNING * INTO v_req;

  RETURN v_req;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.4 Fulfill Part Request (Admin issues requested parts)
CREATE OR REPLACE FUNCTION public.fulfill_part_request(
  p_request_id UUID,
  p_quantity_to_fulfill INT
)
RETURNS public.part_requests AS $$
DECLARE
  v_req public.part_requests;
  v_part public.parts;
  v_balance public.inventory_balances;
  v_user_id UUID;
  v_new_fulfilled INT;
  v_status public.part_request_status;
BEGIN
  SELECT * INTO v_req FROM public.part_requests WHERE id = p_request_id;
  IF v_req.id IS NULL THEN
    RAISE EXCEPTION 'Part request not found';
  END IF;

  IF v_req.status = 'fulfilled' THEN
    RAISE EXCEPTION 'Request is already completely fulfilled';
  END IF;

  IF p_quantity_to_fulfill <= 0 THEN
    RAISE EXCEPTION 'Fulfillment quantity must be greater than zero';
  END IF;

  SELECT * INTO v_balance FROM public.inventory_balances WHERE part_id = v_req.part_id;
  IF v_balance.quantity_available < p_quantity_to_fulfill THEN
    RAISE EXCEPTION 'Insufficient stock: only % available, but % requested for fulfillment', v_balance.quantity_available, p_quantity_to_fulfill;
  END IF;

  SELECT * INTO v_part FROM public.parts WHERE id = v_req.part_id;

  -- Reserve the fulfilled stock for the task
  UPDATE public.inventory_balances
  SET quantity_reserved = quantity_reserved + p_quantity_to_fulfill,
      updated_at = NOW()
  WHERE part_id = v_req.part_id
  RETURNING * INTO v_balance;

  v_new_fulfilled := v_req.quantity_fulfilled + p_quantity_to_fulfill;
  IF v_new_fulfilled >= v_req.quantity_requested THEN
    v_status := 'fulfilled';
  ELSE
    v_status := 'partially_fulfilled';
  END IF;

  UPDATE public.part_requests
  SET quantity_fulfilled = v_new_fulfilled,
      status = v_status,
      updated_at = NOW()
  WHERE id = p_request_id
  RETURNING * INTO v_req;

  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    SELECT id INTO v_user_id FROM public.profiles WHERE role = 'admin' LIMIT 1;
  END IF;

  -- Log ledger issue
  INSERT INTO public.inventory_transactions (
    part_id,
    transaction_type,
    quantity_change,
    balance_after_on_hand,
    balance_after_reserved,
    unit_cost_cents,
    total_cost_cents,
    reason,
    reference_id,
    performed_by
  ) VALUES (
    v_req.part_id,
    'issue',
    p_quantity_to_fulfill,
    v_balance.quantity_on_hand,
    v_balance.quantity_reserved,
    v_part.purchase_cost_cents,
    (p_quantity_to_fulfill * v_part.purchase_cost_cents),
    'Issued for task part request',
    v_req.id::text,
    v_user_id
  );

  RETURN v_req;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.5 Consume & Return Parts (Record actual usage on task)
CREATE OR REPLACE FUNCTION public.consume_and_return_parts(
  p_task_id UUID,
  p_part_id UUID,
  p_consumed_qty INT,
  p_returned_qty INT
)
RETURNS JSONB AS $$
DECLARE
  v_task public.service_order_tasks;
  v_part public.parts;
  v_balance public.inventory_balances;
  v_user_id UUID;
  v_total_released INT;
  v_unit_cost BIGINT;
  v_total_cost BIGINT;
BEGIN
  IF p_consumed_qty < 0 OR p_returned_qty < 0 THEN
    RAISE EXCEPTION 'Consumed and returned quantities cannot be negative';
  END IF;

  v_total_released := p_consumed_qty + p_returned_qty;
  IF v_total_released = 0 THEN
    RAISE EXCEPTION 'At least one unit must be consumed or returned';
  END IF;

  SELECT * INTO v_task FROM public.service_order_tasks WHERE id = p_task_id;
  IF v_task.id IS NULL THEN
    RAISE EXCEPTION 'Task not found';
  END IF;

  SELECT * INTO v_part FROM public.parts WHERE id = p_part_id;
  IF v_part.id IS NULL THEN
    RAISE EXCEPTION 'Part not found';
  END IF;

  SELECT * INTO v_balance FROM public.inventory_balances WHERE part_id = p_part_id;
  IF v_balance.quantity_reserved < v_total_released THEN
    -- If not enough reserved, check if enough on hand to consume directly
    IF v_balance.quantity_on_hand < p_consumed_qty THEN
      RAISE EXCEPTION 'Insufficient stock to consume (on hand: %, requested: %)', v_balance.quantity_on_hand, p_consumed_qty;
    END IF;
  END IF;

  -- Decrement on_hand by consumed units, decrement reserved by total units (clamped to available reserved)
  UPDATE public.inventory_balances
  SET quantity_on_hand = quantity_on_hand - p_consumed_qty,
      quantity_reserved = GREATEST(0, quantity_reserved - v_total_released),
      updated_at = NOW()
  WHERE part_id = p_part_id
  RETURNING * INTO v_balance;

  v_unit_cost := v_part.purchase_cost_cents;
  v_total_cost := p_consumed_qty * v_unit_cost;

  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    v_user_id := v_task.assigned_mechanic_id;
  END IF;
  IF v_user_id IS NULL THEN
    SELECT id INTO v_user_id FROM public.profiles WHERE role = 'mechanic' LIMIT 1;
  END IF;

  -- Record service task part consumption
  INSERT INTO public.service_task_part_consumptions (
    service_order_id,
    task_id,
    part_id,
    quantity_issued,
    quantity_consumed,
    quantity_returned,
    unit_cost_cents,
    total_cost_cents,
    recorded_by
  ) VALUES (
    v_task.service_order_id,
    p_task_id,
    p_part_id,
    v_total_released,
    p_consumed_qty,
    p_returned_qty,
    v_unit_cost,
    v_total_cost,
    v_user_id
  );

  -- Ledger entries
  IF p_consumed_qty > 0 THEN
    INSERT INTO public.inventory_transactions (
      part_id,
      transaction_type,
      quantity_change,
      balance_after_on_hand,
      balance_after_reserved,
      unit_cost_cents,
      total_cost_cents,
      reason,
      reference_id,
      performed_by
    ) VALUES (
      p_part_id,
      'consumption',
      -p_consumed_qty,
      v_balance.quantity_on_hand,
      v_balance.quantity_reserved,
      v_unit_cost,
      v_total_cost,
      'Operation execution consumption',
      p_task_id::text,
      v_user_id
    );
  END IF;

  IF p_returned_qty > 0 THEN
    INSERT INTO public.inventory_transactions (
      part_id,
      transaction_type,
      quantity_change,
      balance_after_on_hand,
      balance_after_reserved,
      unit_cost_cents,
      total_cost_cents,
      reason,
      reference_id,
      performed_by
    ) VALUES (
      p_part_id,
      'return',
      p_returned_qty,
      v_balance.quantity_on_hand,
      v_balance.quantity_reserved,
      v_unit_cost,
      (p_returned_qty * v_unit_cost),
      'Unused units returned from task',
      p_task_id::text,
      v_user_id
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'consumed_qty', p_consumed_qty,
    'returned_qty', p_returned_qty,
    'total_cost_cents', v_total_cost,
    'new_on_hand', v_balance.quantity_on_hand,
    'new_available', v_balance.quantity_available
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.6 Generate Task Mechanic Incentives (Triggered on task completion)
CREATE OR REPLACE FUNCTION public.generate_task_mechanic_incentives(
  p_task_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_task public.service_order_tasks;
  v_estimate_item public.estimate_items;
  v_labor_cents BIGINT := 0;
  v_earning public.mechanic_earnings;
  v_assignments RECORD;
  v_total_assigned INT := 0;
  v_lead_id UUID := NULL;
  v_helper_count INT := 0;
  v_pool_cents BIGINT;
  v_allocated BIGINT;
BEGIN
  SELECT * INTO v_task FROM public.service_order_tasks WHERE id = p_task_id;
  IF v_task.id IS NULL THEN
    RAISE EXCEPTION 'Task not found';
  END IF;

  -- Determine labor value: from linked estimate item or duration * standard rate ($50/hr = 5000 cents/hr = ~83 cents/min)
  IF v_task.estimate_item_id IS NOT NULL THEN
    SELECT * INTO v_estimate_item FROM public.estimate_items WHERE id = v_task.estimate_item_id;
    IF v_estimate_item.id IS NOT NULL AND v_estimate_item.item_type = 'labor' THEN
      v_labor_cents := v_estimate_item.total_price_cents;
    END IF;
  END IF;

  IF v_labor_cents = 0 THEN
    v_labor_cents := GREATEST(500000, v_task.estimated_duration_minutes * 15000); -- default baseline labor charge
  END IF;

  -- 15% incentive pool
  v_pool_cents := (v_labor_cents * 15) / 100;

  -- Record master earning event
  INSERT INTO public.mechanic_earnings (
    service_order_id,
    task_id,
    total_eligible_labor_cents,
    total_incentive_pool_cents,
    status
  ) VALUES (
    v_task.service_order_id,
    p_task_id,
    v_labor_cents,
    v_pool_cents,
    'accrued'
  )
  RETURNING * INTO v_earning;

  -- Count assigned mechanics
  SELECT COUNT(*) INTO v_total_assigned
  FROM public.mechanic_assignments
  WHERE task_id = p_task_id OR (task_id IS NULL AND service_order_id = v_task.service_order_id);

  IF v_total_assigned = 0 AND v_task.assigned_mechanic_id IS NOT NULL THEN
    -- Assign 100% to assigned mechanic
    INSERT INTO public.mechanic_earning_allocations (
      earning_id,
      mechanic_id,
      split_percentage,
      allocated_cents
    ) VALUES (
      v_earning.id,
      v_task.assigned_mechanic_id,
      100.00,
      v_pool_cents
    );
  ELSE
    -- Find lead mechanic
    SELECT mechanic_id INTO v_lead_id
    FROM public.mechanic_assignments
    WHERE (task_id = p_task_id OR service_order_id = v_task.service_order_id) AND is_lead = true
    LIMIT 1;

    IF v_lead_id IS NULL THEN
      v_lead_id := v_task.assigned_mechanic_id;
    END IF;

    -- Allocate: Lead gets 65%, other helpers split 35%
    FOR v_assignments IN
      SELECT DISTINCT mechanic_id, is_lead
      FROM public.mechanic_assignments
      WHERE task_id = p_task_id OR (task_id IS NULL AND service_order_id = v_task.service_order_id)
    LOOP
      IF v_assignments.mechanic_id = v_lead_id THEN
        v_allocated := (v_pool_cents * 65) / 100;
        INSERT INTO public.mechanic_earning_allocations (
          earning_id, mechanic_id, split_percentage, allocated_cents
        ) VALUES (
          v_earning.id, v_lead_id, 65.00, v_allocated
        );
      ELSE
        v_allocated := (v_pool_cents * 35) / 100;
        INSERT INTO public.mechanic_earning_allocations (
          earning_id, mechanic_id, split_percentage, allocated_cents
        ) VALUES (
          v_earning.id, v_assignments.mechanic_id, 35.00, v_allocated
        );
      END IF;
    END LOOP;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'earning_id', v_earning.id,
    'labor_cents', v_labor_cents,
    'pool_cents', v_pool_cents
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.7 Adjust Mechanic Compensation
CREATE OR REPLACE FUNCTION public.adjust_mechanic_compensation(
  p_mechanic_id UUID,
  p_amount_cents BIGINT,
  p_reason TEXT
)
RETURNS public.mechanic_payroll_adjustments AS $$
DECLARE
  v_adj public.mechanic_payroll_adjustments;
  v_admin_id UUID;
BEGIN
  IF p_reason IS NULL OR TRIM(p_reason) = '' THEN
    RAISE EXCEPTION 'A specific reason is required for payroll adjustment';
  END IF;

  v_admin_id := auth.uid();
  IF v_admin_id IS NULL THEN
    SELECT id INTO v_admin_id FROM public.profiles WHERE role = 'admin' LIMIT 1;
  END IF;

  INSERT INTO public.mechanic_payroll_adjustments (
    mechanic_id,
    amount_cents,
    reason,
    adjusted_by
  ) VALUES (
    p_mechanic_id,
    p_amount_cents,
    p_reason,
    v_admin_id
  )
  RETURNING * INTO v_adj;

  RETURN v_adj;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7. Seed Initial Parts and Balances
INSERT INTO public.parts (sku, name, category, unit_of_measurement, purchase_cost_cents, selling_price_cents, minimum_stock)
VALUES
  ('OIL-5W30-SYN', 'Motul 300V 5W-30 Full Synthetic 1L', 'lubricants', 'liter', 210000, 295000, 15),
  ('FLT-HND-15400', 'Honda OEM Oil Filter (15400-PLM-A02)', 'filters', 'pcs', 75000, 125000, 8),
  ('BRK-PAD-FR01', 'Brembo Front Ceramic Brake Pads Set', 'brakes', 'set', 1450000, 2150000, 4),
  ('FLU-DOT4-500', 'Castrol React Performance DOT 4 500ml', 'fluids', 'bottle', 95000, 150000, 10),
  ('NGK-SILZKR7B11', 'NGK Laser Iridium Spark Plug', 'ignition', 'pcs', 120000, 185000, 8),
  ('FLT-AIR-K20C1', 'K&N High-Flow Air Filter Drop-in', 'filters', 'pcs', 850000, 1200000, 3)
ON CONFLICT (sku) DO UPDATE SET
  name = EXCLUDED.name,
  purchase_cost_cents = EXCLUDED.purchase_cost_cents,
  selling_price_cents = EXCLUDED.selling_price_cents;

-- Seed inventory balances for initial parts
INSERT INTO public.inventory_balances (part_id, quantity_on_hand, quantity_reserved)
SELECT id, 40, 5 FROM public.parts WHERE sku = 'OIL-5W30-SYN'
ON CONFLICT (part_id) DO NOTHING;

INSERT INTO public.inventory_balances (part_id, quantity_on_hand, quantity_reserved)
SELECT id, 25, 4 FROM public.parts WHERE sku = 'FLT-HND-15400'
ON CONFLICT (part_id) DO NOTHING;

INSERT INTO public.inventory_balances (part_id, quantity_on_hand, quantity_reserved)
SELECT id, 12, 2 FROM public.parts WHERE sku = 'BRK-PAD-FR01'
ON CONFLICT (part_id) DO NOTHING;

INSERT INTO public.inventory_balances (part_id, quantity_on_hand, quantity_reserved)
SELECT id, 30, 0 FROM public.parts WHERE sku = 'FLU-DOT4-500'
ON CONFLICT (part_id) DO NOTHING;

INSERT INTO public.inventory_balances (part_id, quantity_on_hand, quantity_reserved)
SELECT id, 24, 0 FROM public.parts WHERE sku = 'NGK-SILZKR7B11'
ON CONFLICT (part_id) DO NOTHING;

INSERT INTO public.inventory_balances (part_id, quantity_on_hand, quantity_reserved)
SELECT id, 10, 1 FROM public.parts WHERE sku = 'FLT-AIR-K20C1'
ON CONFLICT (part_id) DO NOTHING;

-- Seed Mechanic Compensation Profiles
INSERT INTO public.mechanic_compensation_profiles (mechanic_id, monthly_base_salary_cents, standard_incentive_percent)
SELECT id, 850000000, 15.00 FROM public.profiles WHERE role = 'mechanic'
ON CONFLICT (mechanic_id) DO NOTHING;
