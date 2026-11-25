-- Migration: 20261125000000_audit_remediation_schema_and_security.sql
-- Milestone 1: P0 Security Hardening, Broken RPC Fixes, Schema & Business Rule Alignment

-- ============================================================================
-- 1. AUTH & RLS HARDENING
-- ============================================================================

-- 1.1 Force 'customer' role on signup (prevent raw_user_meta_data role injection)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone_number, avatar_url, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1), 'User'),
    NEW.raw_user_meta_data->>'phone_number',
    NEW.raw_user_meta_data->>'avatar_url',
    'customer'::public.user_role
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    phone_number = COALESCE(EXCLUDED.phone_number, public.profiles.phone_number),
    avatar_url = COALESCE(EXCLUDED.avatar_url, public.profiles.avatar_url);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 1.2 Restrict notifications INSERT RLS to Admin only (RPCs use SECURITY DEFINER)
DROP POLICY IF EXISTS "Admins can insert notifications" ON public.notifications;
CREATE POLICY "Admins can insert notifications"
  ON public.notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_user_role() = 'admin');

-- 1.3 Restrict workshop_bays SELECT RLS to authenticated users
DROP POLICY IF EXISTS "Anyone can view workshop_bays" ON public.workshop_bays;
DROP POLICY IF EXISTS "Authenticated users can view workshop_bays" ON public.workshop_bays;
CREATE POLICY "Authenticated users can view workshop_bays"
  ON public.workshop_bays
  FOR SELECT
  TO authenticated
  USING (true);

-- 1.4 Scope Mechanic RLS to assigned service orders and tasks
DROP POLICY IF EXISTS "Mechanics can view all service_orders" ON public.service_orders;
DROP POLICY IF EXISTS "Mechanics can view assigned service_orders" ON public.service_orders;
CREATE POLICY "Mechanics can view assigned service_orders"
  ON public.service_orders
  FOR SELECT
  TO authenticated
  USING (
    public.current_user_role() = 'mechanic' AND (
      EXISTS (
        SELECT 1 FROM public.mechanic_assignments ma
        WHERE ma.service_order_id = service_orders.id AND ma.mechanic_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.service_order_tasks t
        WHERE t.service_order_id = service_orders.id AND t.assigned_mechanic_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.inspections i
        WHERE i.service_order_id = service_orders.id AND i.mechanic_id = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS "Mechanics can manage all service_order_tasks" ON public.service_order_tasks;
DROP POLICY IF EXISTS "Mechanics can view assigned service_order_tasks" ON public.service_order_tasks;
CREATE POLICY "Mechanics can view assigned service_order_tasks"
  ON public.service_order_tasks
  FOR SELECT
  TO authenticated
  USING (
    public.current_user_role() = 'mechanic' AND (
      assigned_mechanic_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM public.mechanic_assignments ma
        WHERE ma.task_id = service_order_tasks.id AND ma.mechanic_id = auth.uid()
      )
    )
  );

-- ============================================================================
-- 2. SCHEMA ADDITIONS FOR BUSINESS RULES
-- ============================================================================

-- 2.1 Workshop-level settings (Tax & Max Discount Limit)
CREATE TABLE IF NOT EXISTS public.workshop_settings (
  id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  tax_percent NUMERIC(5,2) NOT NULL DEFAULT 11.00 CHECK (tax_percent >= 0 AND tax_percent <= 100),
  max_discount_percent NUMERIC(5,2) NOT NULL DEFAULT 10.00 CHECK (max_discount_percent >= 0 AND max_discount_percent <= 100),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL
);

INSERT INTO public.workshop_settings (id, tax_percent, max_discount_percent)
VALUES (1, 11.00, 10.00)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.workshop_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read workshop_settings" ON public.workshop_settings;
CREATE POLICY "Authenticated users can read workshop_settings"
  ON public.workshop_settings FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Admins can update workshop_settings" ON public.workshop_settings;
CREATE POLICY "Admins can update workshop_settings"
  ON public.workshop_settings FOR UPDATE TO authenticated
  USING (public.current_user_role() = 'admin')
  WITH CHECK (public.current_user_role() = 'admin');

-- 2.2 Service Order Status History
CREATE TABLE IF NOT EXISTS public.service_order_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  from_status public.service_order_status,
  to_status public.service_order_status NOT NULL,
  changed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_so_status_history_order ON public.service_order_status_history(service_order_id);
ALTER TABLE public.service_order_status_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view status history" ON public.service_order_status_history;
CREATE POLICY "Admins can view status history"
  ON public.service_order_status_history FOR SELECT TO authenticated
  USING (public.current_user_role() = 'admin');

-- 2.3 Columns on estimates, invoices, payments, part_requests, service_orders
ALTER TABLE public.estimates
  ADD COLUMN IF NOT EXISTS tax_percent NUMERIC(5,2) NOT NULL DEFAULT 11.00,
  ADD COLUMN IF NOT EXISTS discount_reason TEXT,
  ADD COLUMN IF NOT EXISTS discount_authorized_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS is_supplementary BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.invoices
  ADD COLUMN IF NOT EXISTS discount_reason TEXT,
  ADD COLUMN IF NOT EXISTS discount_authorized_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.payments
  ADD COLUMN IF NOT EXISTS refunded_payment_id UUID REFERENCES public.payments(id) ON DELETE RESTRICT,
  ADD COLUMN IF NOT EXISTS refund_reason TEXT;

ALTER TABLE public.part_requests
  ADD COLUMN IF NOT EXISTS is_special_order BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS deposit_paid_cents BIGINT NOT NULL DEFAULT 0 CHECK (deposit_paid_cents >= 0);

ALTER TABLE public.service_orders
  ADD COLUMN IF NOT EXISTS deposit_collected_cents BIGINT NOT NULL DEFAULT 0 CHECK (deposit_collected_cents >= 0);

-- 2.4 Prevent concurrent bay assignments at DB level
CREATE UNIQUE INDEX IF NOT EXISTS uq_workshop_bays_active_order
  ON public.workshop_bays(current_service_order_id)
  WHERE current_service_order_id IS NOT NULL;

-- ============================================================================
-- 3. BAY MANAGEMENT & TASK LIFECYCLE RPC FIXES
-- ============================================================================

-- 3.1 Assign Vehicle Bay (with FOR UPDATE lock & maintenance/occupancy check)
CREATE OR REPLACE FUNCTION public.assign_vehicle_bay(
  p_service_order_id UUID,
  p_bay_number INT
)
RETURNS public.workshop_bays AS $$
DECLARE
  v_order public.service_orders;
  v_target_bay public.workshop_bays;
BEGIN
  IF public.current_user_role() NOT IN ('admin', 'mechanic') THEN
    RAISE EXCEPTION 'Unauthorized: only admin or mechanic can assign bays';
  END IF;

  SELECT * INTO v_order FROM public.service_orders WHERE id = p_service_order_id;
  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'Service order % not found', p_service_order_id;
  END IF;

  SELECT * INTO v_target_bay
  FROM public.workshop_bays
  WHERE bay_number = p_bay_number
  FOR UPDATE;

  IF v_target_bay.id IS NULL THEN
    RAISE EXCEPTION 'Bay % does not exist', p_bay_number;
  END IF;

  IF v_target_bay.status = 'maintenance' THEN
    RAISE EXCEPTION 'Bay % is currently under maintenance', p_bay_number;
  END IF;

  IF v_target_bay.status = 'occupied'
     AND v_target_bay.current_service_order_id IS NOT NULL
     AND v_target_bay.current_service_order_id != p_service_order_id THEN
    RAISE EXCEPTION 'Bay conflict: Bay % is currently occupied by another vehicle', p_bay_number;
  END IF;

  UPDATE public.workshop_bays
  SET status = 'available',
      current_service_order_id = NULL,
      updated_at = NOW()
  WHERE current_service_order_id = p_service_order_id
    AND id != v_target_bay.id;

  UPDATE public.workshop_bays
  SET status = 'occupied',
      current_service_order_id = p_service_order_id,
      updated_at = NOW()
  WHERE id = v_target_bay.id
  RETURNING * INTO v_target_bay;

  UPDATE public.service_orders
  SET assigned_bay = v_target_bay.name,
      updated_at = NOW()
  WHERE id = p_service_order_id;

  RETURN v_target_bay;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3.2 Release Vehicle Bay
CREATE OR REPLACE FUNCTION public.release_vehicle_bay(
  p_service_order_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  IF public.current_user_role() NOT IN ('admin', 'mechanic') THEN
    RAISE EXCEPTION 'Unauthorized: only admin or mechanic can release bays';
  END IF;

  UPDATE public.workshop_bays
  SET status = 'available',
      current_service_order_id = NULL,
      updated_at = NOW()
  WHERE current_service_order_id = p_service_order_id;

  UPDATE public.service_orders
  SET assigned_bay = NULL,
      updated_at = NOW()
  WHERE id = p_service_order_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3.3 Start Task Operation (checks role, dependency, and supplementary approval)
CREATE OR REPLACE FUNCTION public.start_task_operation(
  p_task_id UUID,
  p_mechanic_id UUID DEFAULT NULL
)
RETURNS public.service_order_tasks AS $$
DECLARE
  v_task public.service_order_tasks;
  v_dep public.service_order_tasks;
  v_est_item public.estimate_items;
BEGIN
  IF public.current_user_role() NOT IN ('admin', 'mechanic') THEN
    RAISE EXCEPTION 'Unauthorized: only admin or mechanic can start tasks';
  END IF;

  SELECT * INTO v_task FROM public.service_order_tasks WHERE id = p_task_id;
  IF v_task.id IS NULL THEN
    RAISE EXCEPTION 'Task not found';
  END IF;

  -- Block starting unapproved supplementary/optional estimate items
  IF v_task.estimate_item_id IS NOT NULL THEN
    SELECT * INTO v_est_item FROM public.estimate_items WHERE id = v_task.estimate_item_id;
    IF v_est_item.id IS NOT NULL AND v_est_item.authorization_status != 'approved' THEN
      RAISE EXCEPTION 'Cannot start task: linked estimate item is not approved (status: %)', v_est_item.authorization_status;
    END IF;
  END IF;

  IF v_task.depends_on_task_id IS NOT NULL THEN
    SELECT * INTO v_dep FROM public.service_order_tasks WHERE id = v_task.depends_on_task_id;
    IF v_dep.id IS NOT NULL AND v_dep.status != 'completed' THEN
      RAISE EXCEPTION 'Cannot start task: prerequisite task "%" is not completed (status: %)', v_dep.title, v_dep.status;
    END IF;
  END IF;

  UPDATE public.service_order_tasks
  SET status = 'in_progress',
      started_at = COALESCE(started_at, NOW()),
      assigned_mechanic_id = COALESCE(p_mechanic_id, auth.uid(), assigned_mechanic_id),
      pause_reason = NULL,
      updated_at = NOW()
  WHERE id = p_task_id
  RETURNING * INTO v_task;

  UPDATE public.service_orders
  SET status = 'in_progress',
      updated_at = NOW()
  WHERE id = v_task.service_order_id
    AND status != 'in_progress';

  RETURN v_task;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- 4. MECHANIC COMPENSATION & TASK COMPLETION
-- ============================================================================

-- 4.1 Generate Task Mechanic Incentives (uses standard_incentive_percent & equal helper split)
CREATE OR REPLACE FUNCTION public.generate_task_mechanic_incentives(
  p_task_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_task public.service_order_tasks;
  v_estimate_item public.estimate_items;
  v_estimate public.estimates;
  v_labor_cents BIGINT := 0;
  v_discount_ratio NUMERIC := 1.0;
  v_earning public.mechanic_earnings;
  v_lead_id UUID := NULL;
  v_incentive_pct NUMERIC(5,2) := 15.00;
  v_helper_count INT := 0;
  v_pool_cents BIGINT;
  v_lead_cents BIGINT;
  v_helper_pool_cents BIGINT;
  v_each_helper_cents BIGINT;
  v_helper RECORD;
BEGIN
  IF public.current_user_role() NOT IN ('admin', 'mechanic') THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT * INTO v_task FROM public.service_order_tasks WHERE id = p_task_id;
  IF v_task.id IS NULL THEN
    RAISE EXCEPTION 'Task not found';
  END IF;

  -- Prevent duplicate earning generation for the same task
  SELECT * INTO v_earning FROM public.mechanic_earnings WHERE task_id = p_task_id LIMIT 1;
  IF v_earning.id IS NOT NULL THEN
    RETURN jsonb_build_object('success', true, 'earning_id', v_earning.id, 'already_exists', true);
  END IF;

  -- Eligible labor revenue (post-discount, excluding parts and tax)
  IF v_task.estimate_item_id IS NOT NULL THEN
    SELECT * INTO v_estimate_item FROM public.estimate_items WHERE id = v_task.estimate_item_id;
    IF v_estimate_item.id IS NOT NULL AND v_estimate_item.item_type = 'labor' THEN
      v_labor_cents := v_estimate_item.total_price_cents;
      SELECT * INTO v_estimate FROM public.estimates WHERE id = v_estimate_item.estimate_id;
      IF v_estimate.id IS NOT NULL AND v_estimate.subtotal_cents > 0 AND v_estimate.discount_cents > 0 THEN
        v_discount_ratio := GREATEST(0, (v_estimate.subtotal_cents - v_estimate.discount_cents)::NUMERIC / v_estimate.subtotal_cents::NUMERIC);
        v_labor_cents := ROUND(v_labor_cents * v_discount_ratio)::BIGINT;
      END IF;
    END IF;
  END IF;

  IF v_labor_cents = 0 THEN
    v_labor_cents := GREATEST(500000, v_task.estimated_duration_minutes * 15000);
  END IF;

  -- Determine lead mechanic
  SELECT mechanic_id INTO v_lead_id
  FROM public.mechanic_assignments
  WHERE (task_id = p_task_id OR (task_id IS NULL AND service_order_id = v_task.service_order_id))
    AND is_lead = true
  LIMIT 1;

  IF v_lead_id IS NULL THEN
    v_lead_id := v_task.assigned_mechanic_id;
  END IF;

  -- Lookup standard_incentive_percent from mechanic_compensation_profiles
  IF v_lead_id IS NOT NULL THEN
    SELECT standard_incentive_percent INTO v_incentive_pct
    FROM public.mechanic_compensation_profiles
    WHERE mechanic_id = v_lead_id AND is_active = true;
  END IF;
  v_incentive_pct := COALESCE(v_incentive_pct, 15.00);

  v_pool_cents := ROUND((v_labor_cents * v_incentive_pct) / 100.0)::BIGINT;

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

  -- Count distinct non-lead helpers
  SELECT COUNT(DISTINCT mechanic_id) INTO v_helper_count
  FROM public.mechanic_assignments
  WHERE (task_id = p_task_id OR (task_id IS NULL AND service_order_id = v_task.service_order_id))
    AND (v_lead_id IS NULL OR mechanic_id != v_lead_id);

  IF v_helper_count = 0 THEN
    IF v_lead_id IS NOT NULL THEN
      INSERT INTO public.mechanic_earning_allocations (
        earning_id, mechanic_id, split_percentage, allocated_cents
      ) VALUES (
        v_earning.id, v_lead_id, 100.00, v_pool_cents
      );
    END IF;
  ELSE
    -- 65% Lead, 35% divided equally among all helpers
    v_lead_cents := ROUND((v_pool_cents * 65.0) / 100.0)::BIGINT;
    v_helper_pool_cents := v_pool_cents - v_lead_cents;
    v_each_helper_cents := (v_helper_pool_cents / v_helper_count)::BIGINT;

    IF v_lead_id IS NOT NULL THEN
      INSERT INTO public.mechanic_earning_allocations (
        earning_id, mechanic_id, split_percentage, allocated_cents
      ) VALUES (
        v_earning.id, v_lead_id, 65.00, v_lead_cents
      );
    END IF;

    FOR v_helper IN
      SELECT DISTINCT mechanic_id
      FROM public.mechanic_assignments
      WHERE (task_id = p_task_id OR (task_id IS NULL AND service_order_id = v_task.service_order_id))
        AND (v_lead_id IS NULL OR mechanic_id != v_lead_id)
    LOOP
      INSERT INTO public.mechanic_earning_allocations (
        earning_id, mechanic_id, split_percentage, allocated_cents
      ) VALUES (
        v_earning.id, v_helper.mechanic_id, ROUND(35.0 / v_helper_count, 2), v_each_helper_cents
      );
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

-- 4.2 Complete Task Operation (auto-triggers incentive accrual)
CREATE OR REPLACE FUNCTION public.complete_task_operation(
  p_task_id UUID
)
RETURNS public.service_order_tasks AS $$
DECLARE
  v_task public.service_order_tasks;
  v_remaining_tasks INT;
  v_incomplete_checks INT;
BEGIN
  IF public.current_user_role() NOT IN ('admin', 'mechanic') THEN
    RAISE EXCEPTION 'Unauthorized: only admin or mechanic can complete tasks';
  END IF;

  SELECT * INTO v_task FROM public.service_order_tasks WHERE id = p_task_id;
  IF v_task.id IS NULL THEN
    RAISE EXCEPTION 'Task not found';
  END IF;

  SELECT COUNT(*) INTO v_incomplete_checks
  FROM public.task_checklists
  WHERE task_id = p_task_id AND is_completed = false;

  IF v_incomplete_checks > 0 THEN
    RAISE EXCEPTION 'Cannot complete task: % checklist items remain uncompleted', v_incomplete_checks;
  END IF;

  UPDATE public.service_order_tasks
  SET status = 'completed',
      completed_at = NOW(),
      updated_at = NOW()
  WHERE id = p_task_id
  RETURNING * INTO v_task;

  -- Accrue mechanic incentives on task completion
  PERFORM public.generate_task_mechanic_incentives(p_task_id);

  SELECT COUNT(*) INTO v_remaining_tasks
  FROM public.service_order_tasks
  WHERE service_order_id = v_task.service_order_id
    AND status != 'completed';

  IF v_remaining_tasks = 0 THEN
    UPDATE public.service_orders
    SET status = 'qc_pending',
        updated_at = NOW()
    WHERE id = v_task.service_order_id;
  END IF;

  RETURN v_task;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- 5. INVENTORY RESERVATION & CONSUMPTION INVARIANTS
-- ============================================================================

-- 5.1 Consume & Return Parts (strictly requires reserved stock; no unreserved consumption)
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
  IF public.current_user_role() NOT IN ('admin', 'mechanic') THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

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

  SELECT * INTO v_balance FROM public.inventory_balances WHERE part_id = p_part_id FOR UPDATE;
  IF v_balance.part_id IS NULL OR v_balance.quantity_reserved < v_total_released THEN
    RAISE EXCEPTION 'Cannot consume/return unreserved stock (reserved: %, requested: %)', COALESCE(v_balance.quantity_reserved, 0), v_total_released;
  END IF;

  IF v_balance.quantity_on_hand < p_consumed_qty THEN
    RAISE EXCEPTION 'Insufficient physical stock on hand (on hand: %, consumed: %)', v_balance.quantity_on_hand, p_consumed_qty;
  END IF;

  UPDATE public.inventory_balances
  SET quantity_on_hand = quantity_on_hand - p_consumed_qty,
      quantity_reserved = quantity_reserved - v_total_released,
      updated_at = NOW()
  WHERE part_id = p_part_id
  RETURNING * INTO v_balance;

  v_unit_cost := v_part.purchase_cost_cents;
  v_total_cost := p_consumed_qty * v_unit_cost;
  v_user_id := COALESCE(auth.uid(), v_task.assigned_mechanic_id);

  INSERT INTO public.service_task_part_consumptions (
    service_order_id, task_id, part_id, quantity_issued,
    quantity_consumed, quantity_returned, unit_cost_cents, total_cost_cents, recorded_by
  ) VALUES (
    v_task.service_order_id, p_task_id, p_part_id, v_total_released,
    p_consumed_qty, p_returned_qty, v_unit_cost, v_total_cost, v_user_id
  );

  IF p_consumed_qty > 0 THEN
    INSERT INTO public.inventory_transactions (
      part_id, transaction_type, quantity_delta, unit_cost_cents, total_cost_cents, notes, reference_id, performed_by
    ) VALUES (
      p_part_id, 'consumption', -p_consumed_qty, v_unit_cost, v_total_cost, 'Consumed on task', p_task_id::text, v_user_id
    );
  END IF;

  IF p_returned_qty > 0 THEN
    INSERT INTO public.inventory_transactions (
      part_id, transaction_type, quantity_delta, unit_cost_cents, total_cost_cents, notes, reference_id, performed_by
    ) VALUES (
      p_part_id, 'return', p_returned_qty, v_unit_cost, 0, 'Returned unused reserved part to stock', p_task_id::text, v_user_id
    );
  END IF;

  RETURN jsonb_build_object('success', true, 'quantity_on_hand', v_balance.quantity_on_hand, 'quantity_reserved', v_balance.quantity_reserved);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 5.2 Reject / Cancel Part Request (releases reserved stock if any)
CREATE OR REPLACE FUNCTION public.reject_part_request(
  p_request_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS public.part_requests AS $$
DECLARE
  v_req public.part_requests;
BEGIN
  IF public.current_user_role() != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: only admin can reject part requests';
  END IF;

  SELECT * INTO v_req FROM public.part_requests WHERE id = p_request_id FOR UPDATE;
  IF v_req.id IS NULL THEN
    RAISE EXCEPTION 'Part request not found';
  END IF;

  IF v_req.quantity_fulfilled > 0 THEN
    UPDATE public.inventory_balances
    SET quantity_reserved = GREATEST(0, quantity_reserved - v_req.quantity_fulfilled),
        updated_at = NOW()
    WHERE part_id = v_req.part_id;

    INSERT INTO public.inventory_transactions (
      part_id, transaction_type, quantity_delta, unit_cost_cents, total_cost_cents, notes, reference_id, performed_by
    ) VALUES (
      v_req.part_id, 'reservation_release', v_req.quantity_fulfilled, 0, 0,
      COALESCE(p_reason, 'Part request rejected/cancelled'), v_req.id::text, auth.uid()
    );
  END IF;

  UPDATE public.part_requests
  SET status = 'rejected',
      notes = COALESCE(p_reason, notes),
      updated_at = NOW()
  WHERE id = p_request_id
  RETURNING * INTO v_req;

  RETURN v_req;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- 6. QC, INVOICING, PAYMENTS, REFUNDS & HANDOVER
-- ============================================================================

-- 6.1 Return to Repair from QC (reopens tasks so repair can resume)
CREATE OR REPLACE FUNCTION public.return_to_repair_from_qc(
  p_qc_inspection_id UUID,
  p_correction_notes TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_order_id UUID;
BEGIN
  IF public.current_user_role() != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: only admin can fail QC';
  END IF;

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

  UPDATE public.service_order_tasks
  SET status = 'in_progress',
      completed_at = NULL,
      updated_at = NOW()
  WHERE service_order_id = v_order_id
    AND status = 'completed';

  UPDATE public.service_orders SET status = 'in_progress', updated_at = NOW() WHERE id = v_order_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.2 Generate Service Order Invoice (fixed schema, estimate source, discount guard, tax snapshot)
CREATE OR REPLACE FUNCTION public.generate_service_order_invoice(
  p_service_order_id UUID,
  p_tax_percent NUMERIC DEFAULT NULL,
  p_discount_cents BIGINT DEFAULT 0,
  p_deposit_cents BIGINT DEFAULT 0,
  p_insurance_cents BIGINT DEFAULT 0,
  p_admin_id UUID DEFAULT NULL,
  p_discount_reason TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_order public.service_orders;
  v_settings public.workshop_settings;
  v_existing_id UUID;
  v_invoice_id UUID;
  v_invoice_number TEXT;
  v_subtotal_labor BIGINT := 0;
  v_subtotal_parts BIGINT := 0;
  v_gross_subtotal BIGINT := 0;
  v_tax_pct NUMERIC(5,2);
  v_max_disc_cents BIGINT;
  v_taxable_subtotal BIGINT := 0;
  v_tax_amount BIGINT := 0;
  v_total_amount BIGINT := 0;
  v_item RECORD;
  v_task RECORD;
  v_part RECORD;
  v_est_id UUID;
BEGIN
  IF public.current_user_role() != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: only admin can generate invoices';
  END IF;

  SELECT * INTO v_order FROM public.service_orders WHERE id = p_service_order_id;
  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'Service order % not found', p_service_order_id;
  END IF;

  IF v_order.status NOT IN ('completed', 'closed') THEN
    RAISE EXCEPTION 'Service order must pass QC (status completed) before invoicing';
  END IF;

  SELECT id INTO v_existing_id FROM public.invoices
  WHERE service_order_id = p_service_order_id AND status != 'cancelled'
  LIMIT 1;
  IF v_existing_id IS NOT NULL THEN
    RAISE EXCEPTION 'An active invoice already exists for service order %', p_service_order_id;
  END IF;

  SELECT * INTO v_settings FROM public.workshop_settings WHERE id = 1;
  v_tax_pct := COALESCE(p_tax_percent, v_settings.tax_percent, 11.00);

  -- Prefer latest approved estimate items; fallback to service_order_tasks.title
  SELECT id INTO v_est_id FROM public.estimates
  WHERE service_order_id = p_service_order_id AND status IN ('approved', 'partially_approved')
  ORDER BY revision_number DESC LIMIT 1;

  IF v_est_id IS NOT NULL THEN
    SELECT COALESCE(SUM(total_price_cents), 0) INTO v_subtotal_labor
    FROM public.estimate_items
    WHERE estimate_id = v_est_id AND item_type = 'labor' AND authorization_status = 'approved';

    SELECT COALESCE(SUM(total_price_cents), 0) INTO v_subtotal_parts
    FROM public.estimate_items
    WHERE estimate_id = v_est_id AND item_type = 'part' AND authorization_status = 'approved';
  ELSE
    SELECT COALESCE(SUM(GREATEST(500000, COALESCE(estimated_duration_minutes, 60) * 15000)), 0)
    INTO v_subtotal_labor
    FROM public.service_order_tasks
    WHERE service_order_id = p_service_order_id;

    SELECT COALESCE(SUM(c.quantity_consumed * p.selling_price_cents), 0)
    INTO v_subtotal_parts
    FROM public.service_task_part_consumptions c
    JOIN public.parts p ON c.part_id = p.id
    WHERE c.service_order_id = p_service_order_id AND c.quantity_consumed > 0;
  END IF;

  v_gross_subtotal := v_subtotal_labor + v_subtotal_parts;

  -- Enforce discount limit & reason
  IF COALESCE(p_discount_cents, 0) > 0 THEN
    IF p_discount_reason IS NULL OR TRIM(p_discount_reason) = '' THEN
      RAISE EXCEPTION 'Discount reason is required when applying a discount';
    END IF;
    v_max_disc_cents := FLOOR((v_gross_subtotal * COALESCE(v_settings.max_discount_percent, 10.00)) / 100.0)::BIGINT;
    IF p_discount_cents > v_max_disc_cents THEN
      RAISE EXCEPTION 'Discount % exceeds maximum allowed limit (% percent = %)', p_discount_cents, v_settings.max_discount_percent, v_max_disc_cents;
    END IF;
  END IF;

  v_taxable_subtotal := GREATEST(0, v_gross_subtotal - COALESCE(p_discount_cents, 0));
  v_tax_amount := ROUND((v_taxable_subtotal * v_tax_pct) / 100.0)::BIGINT;
  v_total_amount := GREATEST(0, (v_taxable_subtotal + v_tax_amount) - COALESCE(p_insurance_cents, 0));
  v_invoice_number := 'INV-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 9000 + 1000)::TEXT, 4, '0');

  INSERT INTO public.invoices (
    invoice_number, service_order_id, customer_id, status,
    subtotal_labor_cents, subtotal_parts_cents, tax_percent, tax_amount_cents,
    discount_cents, discount_reason, discount_authorized_by,
    deposit_applied_cents, insurance_coverage_cents,
    total_amount_cents, amount_paid_cents, finalized_at, finalized_by
  ) VALUES (
    v_invoice_number, p_service_order_id, v_order.customer_id, 'issued',
    v_subtotal_labor, v_subtotal_parts, v_tax_pct, v_tax_amount,
    COALESCE(p_discount_cents, 0), p_discount_reason,
    CASE WHEN COALESCE(p_discount_cents, 0) > 0 THEN COALESCE(p_admin_id, auth.uid()) ELSE NULL END,
    COALESCE(p_deposit_cents, 0), COALESCE(p_insurance_cents, 0),
    v_total_amount, COALESCE(p_deposit_cents, 0), NOW(), COALESCE(p_admin_id, auth.uid())
  ) RETURNING id INTO v_invoice_id;

  IF v_est_id IS NOT NULL THEN
    FOR v_item IN
      SELECT * FROM public.estimate_items
      WHERE estimate_id = v_est_id AND authorization_status = 'approved'
    LOOP
      INSERT INTO public.invoice_items (invoice_id, item_type, description, quantity, unit_price_cents, total_price_cents)
      VALUES (v_invoice_id, v_item.item_type, v_item.description, v_item.quantity, v_item.unit_price_cents, v_item.total_price_cents);
    END LOOP;
  ELSE
    FOR v_task IN
      SELECT id, title, GREATEST(500000, COALESCE(estimated_duration_minutes, 60) * 15000) AS labor_cents
      FROM public.service_order_tasks WHERE service_order_id = p_service_order_id
    LOOP
      INSERT INTO public.invoice_items (invoice_id, item_type, description, quantity, unit_price_cents, total_price_cents, task_id)
      VALUES (v_invoice_id, 'labor', v_task.title, 1, v_task.labor_cents, v_task.labor_cents, v_task.id);
    END LOOP;

    FOR v_part IN
      SELECT p.id AS part_id, p.name AS part_name, c.quantity_consumed, p.selling_price_cents
      FROM public.service_task_part_consumptions c
      JOIN public.parts p ON c.part_id = p.id
      WHERE c.service_order_id = p_service_order_id AND c.quantity_consumed > 0
    LOOP
      INSERT INTO public.invoice_items (invoice_id, item_type, description, quantity, unit_price_cents, total_price_cents, part_id)
      VALUES (v_invoice_id, 'part', v_part.part_name, v_part.quantity_consumed, v_part.selling_price_cents, (v_part.quantity_consumed * v_part.selling_price_cents), v_part.part_id);
    END LOOP;
  END IF;

  RETURN v_invoice_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.3 Record Invoice Payment (prevents overpayment, blocks customer cash, marks incentives payable when paid)
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
  v_inv public.invoices;
  v_payment_id UUID;
  v_payment_number TEXT;
  v_recorded_by UUID;
  v_role public.user_role;
BEGIN
  v_role := public.current_user_role();
  IF v_role = 'mechanic' THEN
    RAISE EXCEPTION 'Unauthorized: mechanics cannot record payments';
  END IF;
  IF v_role = 'customer' AND p_payment_method = 'cash' THEN
    RAISE EXCEPTION 'Unauthorized: only admin can record cash payments';
  END IF;

  SELECT * INTO v_inv FROM public.invoices WHERE id = p_invoice_id FOR UPDATE;
  IF v_inv.id IS NULL THEN
    RAISE EXCEPTION 'Invoice % not found', p_invoice_id;
  END IF;

  IF p_amount_cents <= 0 THEN
    RAISE EXCEPTION 'Payment amount must be positive';
  END IF;

  IF p_amount_cents > v_inv.outstanding_balance_cents THEN
    RAISE EXCEPTION 'Overpayment rejected: amount (%) exceeds outstanding balance (%)', p_amount_cents, v_inv.outstanding_balance_cents;
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

  UPDATE public.invoices
  SET amount_paid_cents = amount_paid_cents + p_amount_cents,
      status = CASE
        WHEN (amount_paid_cents + p_amount_cents) >= total_amount_cents THEN 'paid'::public.invoice_status
        ELSE 'partially_paid'::public.invoice_status
      END,
      updated_at = NOW()
  WHERE id = p_invoice_id
  RETURNING * INTO v_inv;

  -- Incentives become payable only after invoice is fully paid
  IF v_inv.status = 'paid' THEN
    UPDATE public.mechanic_earnings
    SET status = 'approved'
    WHERE service_order_id = v_inv.service_order_id
      AND status = 'accrued';
  END IF;

  RETURN v_payment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.4 Record Invoice Refund (Admin-only, preserves original payment)
CREATE OR REPLACE FUNCTION public.record_invoice_refund(
  p_payment_id UUID,
  p_refund_amount_cents BIGINT,
  p_refund_reason TEXT
) RETURNS UUID AS $$
DECLARE
  v_orig public.payments;
  v_already_refunded BIGINT;
  v_remaining_refundable BIGINT;
  v_refund_id UUID;
  v_refund_number TEXT;
BEGIN
  IF public.current_user_role() != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: only admin can issue refunds';
  END IF;

  IF p_refund_reason IS NULL OR TRIM(p_refund_reason) = '' THEN
    RAISE EXCEPTION 'Refund reason is required';
  END IF;

  SELECT * INTO v_orig FROM public.payments WHERE id = p_payment_id FOR UPDATE;
  IF v_orig.id IS NULL OR v_orig.payment_status != 'completed' THEN
    RAISE EXCEPTION 'Original completed payment not found';
  END IF;

  SELECT COALESCE(SUM(amount_cents), 0) INTO v_already_refunded
  FROM public.payments
  WHERE refunded_payment_id = p_payment_id AND payment_status = 'refunded';

  v_remaining_refundable := v_orig.amount_cents - v_already_refunded;
  IF p_refund_amount_cents <= 0 OR p_refund_amount_cents > v_remaining_refundable THEN
    RAISE EXCEPTION 'Refund amount (%) exceeds remaining refundable balance (%)', p_refund_amount_cents, v_remaining_refundable;
  END IF;

  v_refund_number := 'REF-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 9000 + 1000)::TEXT, 4, '0');

  INSERT INTO public.payments (
    payment_number, invoice_id, amount_cents, payment_method, payment_status,
    refunded_payment_id, refund_reason, recorded_by
  ) VALUES (
    v_refund_number, v_orig.invoice_id, p_refund_amount_cents, v_orig.payment_method, 'refunded',
    p_payment_id, p_refund_reason, auth.uid()
  ) RETURNING id INTO v_refund_id;

  UPDATE public.invoices
  SET amount_paid_cents = GREATEST(0, amount_paid_cents - p_refund_amount_cents),
      status = CASE
        WHEN GREATEST(0, amount_paid_cents - p_refund_amount_cents) = 0 THEN 'issued'::public.invoice_status
        ELSE 'partially_paid'::public.invoice_status
      END,
      updated_at = NOW()
  WHERE id = v_orig.invoice_id;

  RETURN v_refund_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.5 Record Vehicle Handover (releases workshop bay)
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
  IF public.current_user_role() != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: only admin can record handover';
  END IF;

  SELECT customer_id INTO v_customer_id FROM public.service_orders WHERE id = p_service_order_id;
  IF v_customer_id IS NULL THEN
    RAISE EXCEPTION 'Service order % not found', p_service_order_id;
  END IF;

  SELECT outstanding_balance_cents INTO v_outstanding
  FROM public.invoices
  WHERE service_order_id = p_service_order_id AND status != 'cancelled'
  ORDER BY created_at DESC LIMIT 1;

  IF v_outstanding IS NOT NULL AND v_outstanding > 0 AND (p_payment_override_reason IS NULL OR TRIM(p_payment_override_reason) = '') THEN
    RAISE EXCEPTION 'Cannot handover vehicle with outstanding balance of % cents without authorized override reason', v_outstanding;
  END IF;

  INSERT INTO public.vehicle_handovers (
    service_order_id, customer_id, responsible_admin_id,
    payment_override_reason, checklist, notes
  ) VALUES (
    p_service_order_id, v_customer_id, COALESCE(p_admin_id, auth.uid()),
    p_payment_override_reason,
    COALESCE(p_checklist, '{"vehicle_cleaned": true, "personal_items_returned": true, "old_parts_presented": true, "keys_returned": true}'::jsonb),
    p_notes
  ) RETURNING id INTO v_handover_id;

  UPDATE public.service_orders
  SET status = 'closed', assigned_bay = NULL, updated_at = NOW()
  WHERE id = p_service_order_id;

  UPDATE public.workshop_bays
  SET status = 'available', current_service_order_id = NULL, updated_at = NOW()
  WHERE current_service_order_id = p_service_order_id;

  RETURN v_handover_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- 7. REPORTING & CUSTOMER TRACKING RPC FIXES
-- ============================================================================

-- 7.1 Daily Metrics (uses updated_at, workshop_bays, valid enums)
CREATE OR REPLACE FUNCTION public.get_workshop_daily_metrics(report_date DATE DEFAULT CURRENT_DATE)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_active_orders INT;
  v_completed_today INT;
  v_bays_occupied INT;
  v_settled_cents BIGINT;
  v_outstanding_cents BIGINT;
BEGIN
  IF public.current_user_role() != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: only admin can view daily metrics';
  END IF;

  SELECT COUNT(*) INTO v_active_orders
  FROM public.service_orders
  WHERE status NOT IN ('closed', 'cancelled');

  SELECT COUNT(*) INTO v_completed_today
  FROM public.service_orders
  WHERE status IN ('completed', 'closed')
    AND updated_at::date = report_date;

  SELECT COUNT(*) INTO v_bays_occupied
  FROM public.workshop_bays
  WHERE status = 'occupied';

  SELECT COALESCE(SUM(amount_cents), 0) INTO v_settled_cents
  FROM public.payments
  WHERE payment_status = 'completed'
    AND created_at::date = report_date;

  SELECT COALESCE(SUM(outstanding_balance_cents), 0) INTO v_outstanding_cents
  FROM public.invoices
  WHERE status IN ('issued', 'partially_paid');

  RETURN jsonb_build_object(
    'report_date', report_date,
    'active_orders_count', v_active_orders,
    'completed_today_count', v_completed_today,
    'total_bays', 5,
    'bays_occupied', v_bays_occupied,
    'bay_occupancy_rate', ROUND((v_bays_occupied::numeric / 5.0) * 100, 1),
    'settled_revenue_cents', v_settled_cents,
    'outstanding_receivables_cents', v_outstanding_cents
  );
END;
$$;

-- 7.2 Monthly Metrics (fixes completed_at & Cartesian join)
CREATE OR REPLACE FUNCTION public.get_workshop_monthly_metrics(report_month DATE DEFAULT CURRENT_DATE)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_month_start DATE := DATE_TRUNC('month', report_month)::DATE;
  v_month_end DATE := (DATE_TRUNC('month', report_month) + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
  v_total_completed INT;
  v_gross_revenue_cents BIGINT;
  v_parts_cogs_cents BIGINT;
  v_labor_revenue_cents BIGINT;
  v_gross_margin_cents BIGINT;
  v_top_parts JSONB;
  v_mechanic_workload JSONB;
BEGIN
  IF public.current_user_role() != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: only admin can view monthly metrics';
  END IF;

  SELECT COUNT(*) INTO v_total_completed
  FROM public.service_orders
  WHERE status IN ('completed', 'closed')
    AND updated_at::date >= v_month_start
    AND updated_at::date <= v_month_end;

  SELECT COALESCE(SUM(amount_cents), 0) INTO v_gross_revenue_cents
  FROM public.payments
  WHERE payment_status = 'completed'
    AND created_at::date >= v_month_start
    AND created_at::date <= v_month_end;

  SELECT COALESCE(SUM(total_cost_cents), 0) INTO v_parts_cogs_cents
  FROM public.service_task_part_consumptions
  WHERE created_at::date >= v_month_start
    AND created_at::date <= v_month_end;

  SELECT COALESCE(SUM(subtotal_labor_cents), 0) INTO v_labor_revenue_cents
  FROM public.invoices
  WHERE status IN ('issued', 'partially_paid', 'paid')
    AND finalized_at::date >= v_month_start
    AND finalized_at::date <= v_month_end;

  v_gross_margin_cents := GREATEST(0, v_gross_revenue_cents - v_parts_cogs_cents);

  SELECT jsonb_agg(sub) INTO v_top_parts FROM (
    SELECT p.sku, p.name, SUM(c.quantity_consumed) AS units_consumed, SUM(c.total_cost_cents) AS total_cogs_cents
    FROM public.service_task_part_consumptions c
    JOIN public.parts p ON p.id = c.part_id
    WHERE c.created_at::date >= v_month_start AND c.created_at::date <= v_month_end
    GROUP BY p.sku, p.name
    ORDER BY units_consumed DESC
    LIMIT 5
  ) sub;

  SELECT jsonb_agg(m_sub) INTO v_mechanic_workload FROM (
    SELECT
      prof.id AS mechanic_id,
      prof.full_name,
      COALESCE((
        SELECT COUNT(DISTINCT t.id)
        FROM public.service_order_tasks t
        WHERE t.assigned_mechanic_id = prof.id
          AND t.status = 'completed'
          AND t.completed_at::date >= v_month_start
          AND t.completed_at::date <= v_month_end
      ), 0) AS completed_tasks_count,
      COALESCE((
        SELECT SUM(alloc.allocated_cents)
        FROM public.mechanic_earning_allocations alloc
        WHERE alloc.mechanic_id = prof.id
          AND alloc.created_at::date >= v_month_start
          AND alloc.created_at::date <= v_month_end
      ), 0) AS total_incentive_cents
    FROM public.profiles prof
    WHERE prof.role = 'mechanic'
    ORDER BY completed_tasks_count DESC
  ) m_sub;

  RETURN jsonb_build_object(
    'month_start', v_month_start,
    'month_end', v_month_end,
    'total_orders_completed', v_total_completed,
    'gross_revenue_cents', v_gross_revenue_cents,
    'parts_cogs_cents', v_parts_cogs_cents,
    'labor_revenue_cents', v_labor_revenue_cents,
    'gross_margin_cents', v_gross_margin_cents,
    'top_consumed_parts', COALESCE(v_top_parts, '[]'::jsonb),
    'mechanic_workload', COALESCE(v_mechanic_workload, '[]'::jsonb)
  );
END;
$$;

-- 7.3 Customer Service Tracking (fixes valid enum values, t.title, f.notes)
CREATE OR REPLACE FUNCTION public.get_customer_service_tracking(
  p_customer_id UUID,
  p_order_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order RECORD;
  v_vehicle RECORD;
  v_tasks JSONB;
  v_findings JSONB;
  v_invoice RECORD;
  v_timeline JSONB;
  v_stage_index INT := 0;
BEGIN
  IF p_order_id IS NOT NULL THEN
    SELECT * INTO v_order FROM public.service_orders
    WHERE id = p_order_id AND customer_id = p_customer_id;
  ELSE
    SELECT * INTO v_order FROM public.service_orders
    WHERE customer_id = p_customer_id
    ORDER BY CASE WHEN status NOT IN ('closed', 'cancelled') THEN 0 ELSE 1 END, created_at DESC
    LIMIT 1;
  END IF;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('has_active_order', false);
  END IF;

  SELECT make, model, year, license_plate, mileage INTO v_vehicle
  FROM public.vehicles WHERE id = v_order.vehicle_id;

  CASE v_order.status
    WHEN 'intake_pending' THEN v_stage_index := 0;
    WHEN 'inspection_pending' THEN v_stage_index := 1;
    WHEN 'inspection_in_progress' THEN v_stage_index := 2;
    WHEN 'inspection_completed' THEN v_stage_index := 2;
    WHEN 'estimate_pending' THEN v_stage_index := 3;
    WHEN 'estimate_rejected' THEN v_stage_index := 3;
    WHEN 'estimate_approved' THEN v_stage_index := 4;
    WHEN 'in_progress' THEN v_stage_index := 4;
    WHEN 'qc_pending' THEN v_stage_index := 5;
    WHEN 'completed' THEN v_stage_index := 6;
    WHEN 'closed' THEN v_stage_index := 7;
    ELSE v_stage_index := 1;
  END CASE;

  v_timeline := jsonb_build_array(
    jsonb_build_object('stage', 'Booking Intake', 'completed', v_stage_index >= 1, 'active', v_stage_index = 0),
    jsonb_build_object('stage', 'Vehicle Intake & Bay Arrival', 'completed', v_stage_index >= 2, 'active', v_stage_index = 1),
    jsonb_build_object('stage', 'Multi-Point Inspection', 'completed', v_stage_index >= 3, 'active', v_stage_index = 2),
    jsonb_build_object('stage', 'Estimate & Authorization', 'completed', v_stage_index >= 4, 'active', v_stage_index = 3),
    jsonb_build_object('stage', 'Active Workshop Repair', 'completed', v_stage_index >= 5, 'active', v_stage_index = 4),
    jsonb_build_object('stage', 'Quality Control Inspection', 'completed', v_stage_index >= 6, 'active', v_stage_index = 5),
    jsonb_build_object('stage', 'Ready for Delivery & Invoice', 'completed', v_stage_index >= 7, 'active', v_stage_index = 6),
    jsonb_build_object('stage', 'Delivered & Order Closed', 'completed', v_stage_index >= 7, 'active', v_stage_index = 7)
  );

  SELECT jsonb_agg(t_sub) INTO v_tasks FROM (
    SELECT t.id, t.title AS task_name, t.status, t.description
    FROM public.service_order_tasks t
    WHERE t.service_order_id = v_order.id
    ORDER BY t.created_at ASC
  ) t_sub;

  SELECT jsonb_agg(f_sub) INTO v_findings FROM (
    SELECT f.id, f.category, f.item_name, f.severity, f.notes AS description, f.recommended_action
    FROM public.inspection_findings f
    JOIN public.inspections i ON i.id = f.inspection_id
    WHERE i.service_order_id = v_order.id
    ORDER BY f.created_at ASC
  ) f_sub;

  SELECT id, invoice_number, status, total_amount_cents, amount_paid_cents, outstanding_balance_cents
  INTO v_invoice
  FROM public.invoices
  WHERE service_order_id = v_order.id
  ORDER BY created_at DESC LIMIT 1;

  RETURN jsonb_build_object(
    'has_active_order', true,
    'order_id', v_order.id,
    'order_number', v_order.order_number,
    'status', v_order.status,
    'current_stage_index', v_stage_index,
    'created_at', v_order.created_at,
    'vehicle', jsonb_build_object(
      'make', v_vehicle.make,
      'model', v_vehicle.model,
      'year', v_vehicle.year,
      'license_plate', v_vehicle.license_plate,
      'mileage', v_vehicle.mileage
    ),
    'timeline', v_timeline,
    'tasks', COALESCE(v_tasks, '[]'::jsonb),
    'findings', COALESCE(v_findings, '[]'::jsonb),
    'invoice', CASE WHEN v_invoice.id IS NOT NULL THEN jsonb_build_object(
      'id', v_invoice.id,
      'invoice_number', v_invoice.invoice_number,
      'status', v_invoice.status,
      'total_amount_cents', v_invoice.total_amount_cents,
      'amount_paid_cents', v_invoice.amount_paid_cents,
      'outstanding_balance_cents', v_invoice.outstanding_balance_cents
    ) ELSE NULL END
  );
END;
$$;

-- ============================================================================
-- 8. SUPPLEMENTARY ESTIMATES & PER-ITEM OPTIONAL AUTHORIZATION
-- ============================================================================

CREATE OR REPLACE FUNCTION public.authorize_estimate_items(
  p_estimate_id UUID,
  p_approved_item_ids UUID[],
  p_rejected_item_ids UUID[],
  p_notes TEXT DEFAULT NULL
)
RETURNS public.estimates AS $$
DECLARE
  v_est public.estimates;
  v_new_status public.estimate_status;
  v_pending_or_rejected INT;
  v_approved_count INT;
BEGIN
  SELECT * INTO v_est FROM public.estimates WHERE id = p_estimate_id FOR UPDATE;
  IF v_est.id IS NULL THEN
    RAISE EXCEPTION 'Estimate not found';
  END IF;

  UPDATE public.estimate_items
  SET authorization_status = 'approved'
  WHERE estimate_id = p_estimate_id AND id = ANY(p_approved_item_ids);

  UPDATE public.estimate_items
  SET authorization_status = 'rejected'
  WHERE estimate_id = p_estimate_id AND id = ANY(p_rejected_item_ids);

  SELECT COUNT(*) FILTER (WHERE authorization_status = 'approved'),
         COUNT(*) FILTER (WHERE authorization_status != 'approved')
  INTO v_approved_count, v_pending_or_rejected
  FROM public.estimate_items
  WHERE estimate_id = p_estimate_id;

  IF v_approved_count = 0 THEN
    v_new_status := 'rejected';
  ELSIF v_pending_or_rejected > 0 THEN
    v_new_status := 'partially_approved';
  ELSE
    v_new_status := 'approved';
  END IF;

  UPDATE public.estimates
  SET status = v_new_status, updated_at = NOW()
  WHERE id = p_estimate_id
  RETURNING * INTO v_est;

  INSERT INTO public.estimate_authorizations (estimate_id, authorized_by, status, notes)
  VALUES (p_estimate_id, auth.uid(), v_new_status, p_notes);

  IF NOT v_est.is_supplementary THEN
    UPDATE public.service_orders
    SET status = CASE
      WHEN v_new_status IN ('approved', 'partially_approved') THEN 'estimate_approved'::public.service_order_status
      ELSE 'estimate_rejected'::public.service_order_status
    END,
    updated_at = NOW()
    WHERE id = v_est.service_order_id;
  END IF;

  RETURN v_est;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
