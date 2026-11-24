-- Migration: M6 Communication, Customer Tracking, Reminders & Reporting
-- Implements F-017 (Notifications), F-002/F-017 (Service Tracking), F-018 (Maintenance Reminders), F-019 (Reporting)
-- Conforms to docs/PRD.md and docs/ARCHITECTURE.md sections 4.9, 6.12, 7.3

-- 1. Enums
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
    CREATE TYPE public.notification_type AS ENUM (
      'service_status',
      'assignment',
      'estimate_ready',
      'qc_result',
      'invoice_issued',
      'payment_received',
      'handover_ready',
      'reminder',
      'system'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_entity_type') THEN
    CREATE TYPE public.notification_entity_type AS ENUM (
      'service_order',
      'booking',
      'estimate',
      'invoice',
      'reminder',
      'qc_inspection',
      'part_request'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'reminder_type') THEN
    CREATE TYPE public.reminder_type AS ENUM (
      'scheduled_date',
      'mileage_odometer',
      'seasonal',
      'inspection_followup'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'reminder_status') THEN
    CREATE TYPE public.reminder_status AS ENUM (
      'pending',
      'notified',
      'completed',
      'dismissed'
    );
  END IF;
END $$;

-- 2. Notification Tables
CREATE TABLE IF NOT EXISTS public.notification_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  idempotency_key TEXT NOT NULL UNIQUE,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('admin', 'mechanic', 'customer')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type public.notification_type NOT NULL DEFAULT 'service_status',
  entity_type public.notification_entity_type,
  entity_id UUID,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexing for performance and low-latency realtime reads
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_role ON public.notifications(role, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_entity ON public.notifications(entity_type, entity_id);

-- 3. Maintenance Reminders Table
CREATE TABLE IF NOT EXISTS public.maintenance_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  service_order_id UUID REFERENCES public.service_orders(id) ON DELETE SET NULL,
  reminder_type public.reminder_type NOT NULL DEFAULT 'scheduled_date',
  title TEXT NOT NULL,
  description TEXT,
  due_date DATE,
  due_odometer_km INT CHECK (due_odometer_km IS NULL OR due_odometer_km > 0),
  status public.reminder_status NOT NULL DEFAULT 'pending',
  last_notified_at TIMESTAMPTZ,
  dismissed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reminders_customer ON public.maintenance_reminders(customer_id, status, due_date ASC);
CREATE INDEX IF NOT EXISTS idx_reminders_vehicle ON public.maintenance_reminders(vehicle_id);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.notification_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_reminders ENABLE ROW LEVEL SECURITY;

-- Notification Events RLS (Admin Only)
DROP POLICY IF EXISTS "Admins can view and manage notification events" ON public.notification_events;
CREATE POLICY "Admins can view and manage notification events"
  ON public.notification_events
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- Notifications RLS
DROP POLICY IF EXISTS "Users can read own notifications" ON public.notifications;
CREATE POLICY "Users can read own notifications"
  ON public.notifications
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Users can update read status of own notifications" ON public.notifications;
CREATE POLICY "Users can update read status of own notifications"
  ON public.notifications
  FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can insert notifications" ON public.notifications;
CREATE POLICY "Admins can insert notifications"
  ON public.notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Maintenance Reminders RLS
DROP POLICY IF EXISTS "Customers can view own vehicle reminders" ON public.maintenance_reminders;
CREATE POLICY "Customers can view own vehicle reminders"
  ON public.maintenance_reminders
  FOR SELECT
  TO authenticated
  USING (
    customer_id IN (
      SELECT id FROM public.customers WHERE profile_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role IN ('admin', 'mechanic')
    )
  );

DROP POLICY IF EXISTS "Customers can update/dismiss own reminders" ON public.maintenance_reminders;
CREATE POLICY "Customers can update/dismiss own reminders"
  ON public.maintenance_reminders
  FOR UPDATE
  TO authenticated
  USING (
    customer_id IN (
      SELECT id FROM public.customers WHERE profile_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    customer_id IN (
      SELECT id FROM public.customers WHERE profile_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can insert and manage reminders" ON public.maintenance_reminders;
CREATE POLICY "Admins can insert and manage reminders"
  ON public.maintenance_reminders
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- 5. RPC Functions

-- 5.1 Create Notification Event (with deduplication)
CREATE OR REPLACE FUNCTION public.create_notification_event(
  p_idempotency_key TEXT,
  p_recipient_user_id UUID,
  p_recipient_role TEXT,
  p_title TEXT,
  p_message TEXT,
  p_type public.notification_type DEFAULT 'service_status',
  p_entity_type public.notification_entity_type DEFAULT NULL,
  p_entity_id UUID DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  -- Deduplication check
  IF EXISTS (SELECT 1 FROM public.notification_events WHERE idempotency_key = p_idempotency_key) THEN
    -- Already created, return existing
    SELECT id INTO v_notification_id FROM public.notifications
    WHERE user_id = p_recipient_user_id
      AND title = p_title
      AND entity_id = p_entity_id
    ORDER BY created_at DESC LIMIT 1;
    RETURN v_notification_id;
  END IF;

  -- Record event
  INSERT INTO public.notification_events (idempotency_key, event_type, payload)
  VALUES (
    p_idempotency_key,
    p_type::text,
    jsonb_build_object(
      'recipient_user_id', p_recipient_user_id,
      'recipient_role', p_recipient_role,
      'title', p_title,
      'message', p_message,
      'metadata', p_metadata
    )
  );

  -- Insert notification
  INSERT INTO public.notifications (
    user_id,
    role,
    title,
    message,
    type,
    entity_type,
    entity_id,
    metadata
  ) VALUES (
    p_recipient_user_id,
    p_recipient_role,
    p_title,
    p_message,
    p_type,
    p_entity_type,
    p_entity_id,
    p_metadata
  ) RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$$;

-- 5.2 Mark Notification Read
CREATE OR REPLACE FUNCTION public.mark_notification_read(p_notification_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.notifications
  SET is_read = TRUE,
      read_at = NOW()
  WHERE id = p_notification_id;
  RETURN FOUND;
END;
$$;

-- 5.3 Mark All Notifications Read
CREATE OR REPLACE FUNCTION public.mark_all_notifications_read(p_user_id UUID)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INT;
BEGIN
  WITH updated AS (
    UPDATE public.notifications
    SET is_read = TRUE,
        read_at = NOW()
    WHERE user_id = p_user_id AND is_read = FALSE
    RETURNING id
  )
  SELECT COUNT(*) INTO v_count FROM updated;
  RETURN v_count;
END;
$$;

-- 5.4 Generate Service Order Maintenance Reminders
CREATE OR REPLACE FUNCTION public.generate_service_order_reminders(p_service_order_id UUID)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_order RECORD;
  v_vehicle RECORD;
  v_customer_id UUID;
  v_created_count INT := 0;
  v_due_date DATE;
  v_due_km INT;
BEGIN
  -- Lookup service order and vehicle
  SELECT * INTO v_order FROM public.service_orders WHERE id = p_service_order_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Service order % not found', p_service_order_id;
  END IF;

  SELECT * INTO v_vehicle FROM public.vehicles WHERE id = v_order.vehicle_id;
  v_customer_id := v_order.customer_id;

  -- 1. Date-based reminder: 6 months after order completion / current date
  v_due_date := (CURRENT_DATE + INTERVAL '6 months')::DATE;
  IF NOT EXISTS (
    SELECT 1 FROM public.maintenance_reminders
    WHERE vehicle_id = v_vehicle.id
      AND service_order_id = p_service_order_id
      AND reminder_type = 'scheduled_date'
  ) THEN
    INSERT INTO public.maintenance_reminders (
      customer_id,
      vehicle_id,
      service_order_id,
      reminder_type,
      title,
      description,
      due_date,
      status
    ) VALUES (
      v_customer_id,
      v_vehicle.id,
      p_service_order_id,
      'scheduled_date',
      '6-Month Routine Maintenance Check',
      'Regular fluid levels, brake wear, and multi-point inspection for ' || v_vehicle.make || ' ' || v_vehicle.model,
      v_due_date,
      'pending'
    );
    v_created_count := v_created_count + 1;
  END IF;

  -- 2. Mileage-based reminder: current mileage + 10,000 km
  IF v_vehicle.mileage IS NOT NULL AND v_vehicle.mileage > 0 THEN
    v_due_km := v_vehicle.mileage + 10000;
  ELSE
    v_due_km := 10000;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.maintenance_reminders
    WHERE vehicle_id = v_vehicle.id
      AND service_order_id = p_service_order_id
      AND reminder_type = 'mileage_odometer'
  ) THEN
    INSERT INTO public.maintenance_reminders (
      customer_id,
      vehicle_id,
      service_order_id,
      reminder_type,
      title,
      description,
      due_odometer_km,
      status
    ) VALUES (
      v_customer_id,
      v_vehicle.id,
      p_service_order_id,
      'mileage_odometer',
      'Periodic 10,000 KM Engine & Filter Service',
      'Scheduled synthetic engine oil replacement and oil filter replacement at ' || v_due_km || ' KM.',
      v_due_km,
      'pending'
    );
    v_created_count := v_created_count + 1;
  END IF;

  RETURN v_created_count;
END;
$$;

-- 5.5 Dismiss Maintenance Reminder
CREATE OR REPLACE FUNCTION public.dismiss_maintenance_reminder(p_reminder_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.maintenance_reminders
  SET status = 'dismissed',
      dismissed_at = NOW(),
      updated_at = NOW()
  WHERE id = p_reminder_id;
  RETURN FOUND;
END;
$$;

-- 5.6 Process Due Reminders (Batch notification trigger)
CREATE OR REPLACE FUNCTION public.process_due_reminders()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rec RECORD;
  v_cust RECORD;
  v_count INT := 0;
  v_idempotency TEXT;
BEGIN
  FOR v_rec IN
    SELECT r.*, v.make, v.model, v.license_plate
    FROM public.maintenance_reminders r
    JOIN public.vehicles v ON v.id = r.vehicle_id
    WHERE r.status = 'pending'
      AND (
        (r.reminder_type = 'scheduled_date' AND r.due_date <= CURRENT_DATE)
        OR (r.reminder_type = 'mileage_odometer' AND r.due_odometer_km <= COALESCE(v.mileage, 0))
      )
  LOOP
    -- Lookup customer profile
    SELECT c.profile_id INTO v_cust FROM public.customers c WHERE c.id = v_rec.customer_id;
    IF v_cust.profile_id IS NOT NULL THEN
      v_idempotency := 'reminder_' || v_rec.id || '_' || TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD');
      PERFORM public.create_notification_event(
        v_idempotency,
        v_cust.profile_id,
        'customer',
        'Service Due: ' || v_rec.title,
        'Your ' || v_rec.make || ' ' || v_rec.model || ' (' || v_rec.license_plate || ') has reached its scheduled maintenance interval.',
        'reminder'::public.notification_type,
        'reminder'::public.notification_entity_type,
        v_rec.id,
        jsonb_build_object('vehicle_id', v_rec.vehicle_id, 'reminder_id', v_rec.id)
      );

      UPDATE public.maintenance_reminders
      SET status = 'notified',
          last_notified_at = NOW(),
          updated_at = NOW()
      WHERE id = v_rec.id;

      v_count := v_count + 1;
    END IF;
  END LOOP;

  RETURN v_count;
END;
$$;

-- 5.7 Get Workshop Daily Metrics
CREATE OR REPLACE FUNCTION public.get_workshop_daily_metrics(report_date DATE DEFAULT CURRENT_DATE)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_active_orders INT;
  v_completed_today INT;
  v_bays_occupied INT;
  v_settled_cents BIGINT;
  v_outstanding_cents BIGINT;
BEGIN
  -- Active orders
  SELECT COUNT(*) INTO v_active_orders
  FROM public.service_orders
  WHERE status NOT IN ('closed', 'cancelled');

  -- Completed today
  SELECT COUNT(*) INTO v_completed_today
  FROM public.service_orders
  WHERE status IN ('completed', 'closed')
    AND completed_at::date = report_date;

  -- Occupied bays
  SELECT COUNT(DISTINCT bay_id) INTO v_bays_occupied
  FROM public.service_orders
  WHERE status IN ('in_progress', 'qc_pending', 'inspection')
    AND bay_id IS NOT NULL;

  -- Settled revenue today
  SELECT COALESCE(SUM(amount_cents), 0) INTO v_settled_cents
  FROM public.payments
  WHERE payment_status = 'completed'
    AND created_at::date = report_date;

  -- Total outstanding balance across all non-closed/unpaid invoices
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

-- 5.8 Get Workshop Monthly Metrics
CREATE OR REPLACE FUNCTION public.get_workshop_monthly_metrics(report_month DATE DEFAULT CURRENT_DATE)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
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
  -- Total orders completed in month
  SELECT COUNT(*) INTO v_total_completed
  FROM public.service_orders
  WHERE status IN ('completed', 'closed')
    AND completed_at::date >= v_month_start
    AND completed_at::date <= v_month_end;

  -- Gross settled revenue in month
  SELECT COALESCE(SUM(amount_cents), 0) INTO v_gross_revenue_cents
  FROM public.payments
  WHERE payment_status = 'completed'
    AND created_at::date >= v_month_start
    AND created_at::date <= v_month_end;

  -- Parts COGS consumed in month
  SELECT COALESCE(SUM(total_cost_cents), 0) INTO v_parts_cogs_cents
  FROM public.service_task_part_consumptions
  WHERE created_at::date >= v_month_start
    AND created_at::date <= v_month_end;

  -- Labor revenue snapshot from finalized invoices in month
  SELECT COALESCE(SUM(subtotal_labor_cents), 0) INTO v_labor_revenue_cents
  FROM public.invoices
  WHERE status IN ('issued', 'partially_paid', 'paid')
    AND finalized_at::date >= v_month_start
    AND finalized_at::date <= v_month_end;

  v_gross_margin_cents := GREATEST(0, v_gross_revenue_cents - v_parts_cogs_cents);

  -- Top consumed parts
  SELECT jsonb_agg(sub) INTO v_top_parts FROM (
    SELECT
      p.sku,
      p.name,
      SUM(c.quantity_consumed) AS units_consumed,
      SUM(c.total_cost_cents) AS total_cogs_cents
    FROM public.service_task_part_consumptions c
    JOIN public.parts p ON p.id = c.part_id
    WHERE c.created_at::date >= v_month_start
      AND c.created_at::date <= v_month_end
    GROUP BY p.sku, p.name
    ORDER BY units_consumed DESC
    LIMIT 5
  ) sub;

  -- Mechanic workload & earnings
  SELECT jsonb_agg(m_sub) INTO v_mechanic_workload FROM (
    SELECT
      prof.id AS mechanic_id,
      prof.full_name,
      COUNT(DISTINCT a.task_id) AS completed_tasks_count,
      COALESCE(SUM(alloc.allocated_cents), 0) AS total_incentive_cents
    FROM public.profiles prof
    LEFT JOIN public.mechanic_assignments a ON a.mechanic_id = prof.id
    LEFT JOIN public.mechanic_earning_allocations alloc ON alloc.mechanic_id = prof.id
    WHERE prof.role = 'mechanic'
    GROUP BY prof.id, prof.full_name
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

-- 5.9 Get Customer Service Tracking Summary (Sanitized for customer visibility)
CREATE OR REPLACE FUNCTION public.get_customer_service_tracking(
  p_customer_id UUID,
  p_order_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
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
  -- If order ID provided, select that; otherwise select latest active or completed order
  IF p_order_id IS NOT NULL THEN
    SELECT * INTO v_order FROM public.service_orders
    WHERE id = p_order_id AND customer_id = p_customer_id;
  ELSE
    SELECT * INTO v_order FROM public.service_orders
    WHERE customer_id = p_customer_id
    ORDER BY CASE
      WHEN status NOT IN ('closed', 'cancelled') THEN 0
      ELSE 1
    END, created_at DESC
    LIMIT 1;
  END IF;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('has_active_order', false);
  END IF;

  -- Vehicle info
  SELECT make, model, year, license_plate, mileage INTO v_vehicle
  FROM public.vehicles WHERE id = v_order.vehicle_id;

  -- Determine stage index (0 to 7) based on order status
  CASE v_order.status
    WHEN 'draft' THEN v_stage_index := 0;
    WHEN 'confirmed' THEN v_stage_index := 1;
    WHEN 'intake' THEN v_stage_index := 1;
    WHEN 'inspection' THEN v_stage_index := 2;
    WHEN 'estimate_pending' THEN v_stage_index := 3;
    WHEN 'estimate_approved' THEN v_stage_index := 4;
    WHEN 'in_progress' THEN v_stage_index := 4;
    WHEN 'qc_pending' THEN v_stage_index := 5;
    WHEN 'completed' THEN v_stage_index := 6;
    WHEN 'ready_for_handover' THEN v_stage_index := 6;
    WHEN 'closed' THEN v_stage_index := 7;
    ELSE v_stage_index := 1;
  END CASE;

  -- Timeline array
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

  -- Customer-visible tasks (task name, status only - NO internal hourly rate or compensation)
  SELECT jsonb_agg(t_sub) INTO v_tasks FROM (
    SELECT
      t.id,
      t.task_name,
      t.status,
      t.description
    FROM public.service_order_tasks t
    WHERE t.service_order_id = v_order.id
    ORDER BY t.created_at ASC
  ) t_sub;

  -- Customer-visible findings
  SELECT jsonb_agg(f_sub) INTO v_findings FROM (
    SELECT
      f.id,
      f.category,
      f.item_name,
      f.severity,
      f.description,
      f.recommended_action
    FROM public.inspection_findings f
    JOIN public.inspections i ON i.id = f.inspection_id
    WHERE i.service_order_id = v_order.id
    ORDER BY f.created_at ASC
  ) f_sub;

  -- Latest invoice if exists
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
    'invoice', CASE
      WHEN v_invoice.id IS NOT NULL THEN jsonb_build_object(
        'id', v_invoice.id,
        'invoice_number', v_invoice.invoice_number,
        'status', v_invoice.status,
        'total_amount_cents', v_invoice.total_amount_cents,
        'amount_paid_cents', v_invoice.amount_paid_cents,
        'outstanding_balance_cents', v_invoice.outstanding_balance_cents
      )
      ELSE NULL
    END
  );
END;
$$;

-- 6. Add to Realtime Publication
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.maintenance_reminders;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;
