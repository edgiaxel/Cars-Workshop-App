-- Migration: 20261123000001_m3_workshop_operations.sql
-- Milestone: M3 - Workshop Operations
-- Description: Workshop Bays, Service Order Tasks, Checklists, Assignments, Assistance Requests, Additional Findings, RPCs, and RLS

-- 1. Enums
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'bay_status') THEN
    CREATE TYPE public.bay_status AS ENUM ('available', 'occupied', 'maintenance');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_status') THEN
    CREATE TYPE public.task_status AS ENUM ('pending', 'assigned', 'in_progress', 'paused', 'completed', 'blocked');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_priority') THEN
    CREATE TYPE public.task_priority AS ENUM ('low', 'medium', 'high', 'urgent');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'assistance_status') THEN
    CREATE TYPE public.assistance_status AS ENUM ('pending', 'accepted', 'resolved');
  END IF;
END $$;

-- 2. Tables

-- 2.1 Workshop Bays
CREATE TABLE IF NOT EXISTS public.workshop_bays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bay_number INT NOT NULL UNIQUE CHECK (bay_number BETWEEN 1 AND 5),
  name TEXT NOT NULL,
  status public.bay_status NOT NULL DEFAULT 'available',
  current_service_order_id UUID REFERENCES public.service_orders(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workshop_bays_status ON public.workshop_bays(status);
CREATE INDEX IF NOT EXISTS idx_workshop_bays_order ON public.workshop_bays(current_service_order_id);

-- Seed initial 5 bays if not present
INSERT INTO public.workshop_bays (bay_number, name, status)
VALUES
  (1, 'Bay 01 - Quick Service', 'available'),
  (2, 'Bay 02 - Diagnostic & Performance', 'available'),
  (3, 'Bay 03 - Heavy Repair', 'available'),
  (4, 'Bay 04 - Electrical & Electronics', 'available'),
  (5, 'Bay 05 - Suspension & Brakes', 'available')
ON CONFLICT (bay_number) DO NOTHING;

-- 2.2 Service Order Tasks
CREATE TABLE IF NOT EXISTS public.service_order_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  estimate_item_id UUID REFERENCES public.estimate_items(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  estimated_duration_minutes INT NOT NULL DEFAULT 60,
  actual_duration_minutes INT NOT NULL DEFAULT 0,
  priority public.task_priority NOT NULL DEFAULT 'medium',
  status public.task_status NOT NULL DEFAULT 'pending',
  sequence_order INT NOT NULL DEFAULT 1,
  depends_on_task_id UUID REFERENCES public.service_order_tasks(id) ON DELETE SET NULL,
  assigned_mechanic_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  pause_reason TEXT,
  started_at TIMESTAMPTZ,
  paused_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tasks_order_id ON public.service_order_tasks(service_order_id);
CREATE INDEX IF NOT EXISTS idx_tasks_mechanic ON public.service_order_tasks(assigned_mechanic_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.service_order_tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_dependency ON public.service_order_tasks(depends_on_task_id);

-- 2.3 Task Checklists
CREATE TABLE IF NOT EXISTS public.task_checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES public.service_order_tasks(id) ON DELETE CASCADE,
  item_description TEXT NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  completed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_task_checklists_task ON public.task_checklists(task_id);

-- 2.4 Mechanic Assignments
CREATE TABLE IF NOT EXISTS public.mechanic_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  task_id UUID REFERENCES public.service_order_tasks(id) ON DELETE CASCADE,
  mechanic_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  is_lead BOOLEAN NOT NULL DEFAULT FALSE,
  role_description TEXT,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mech_assign_order ON public.mechanic_assignments(service_order_id);
CREATE INDEX IF NOT EXISTS idx_mech_assign_mech ON public.mechanic_assignments(mechanic_id);

-- 2.5 Task Assistance Requests
CREATE TABLE IF NOT EXISTS public.task_assistance_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES public.service_order_tasks(id) ON DELETE CASCADE,
  requested_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  helper_mechanic_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  reason TEXT NOT NULL,
  status public.assistance_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_assistance_task ON public.task_assistance_requests(task_id);

-- 2.6 Additional Findings
CREATE TABLE IF NOT EXISTS public.service_order_additional_findings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  task_id UUID REFERENCES public.service_order_tasks(id) ON DELETE SET NULL,
  reported_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  severity public.severity_level NOT NULL DEFAULT 'medium',
  status TEXT NOT NULL DEFAULT 'reported',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_add_findings_order ON public.service_order_additional_findings(service_order_id);

-- 3. Triggers for updated_at
DROP TRIGGER IF EXISTS on_workshop_bays_updated ON public.workshop_bays;
CREATE TRIGGER on_workshop_bays_updated BEFORE UPDATE ON public.workshop_bays FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS on_service_order_tasks_updated ON public.service_order_tasks;
CREATE TRIGGER on_service_order_tasks_updated BEFORE UPDATE ON public.service_order_tasks FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.workshop_bays ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_order_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mechanic_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_assistance_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_order_additional_findings ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies

-- Workshop Bays
DROP POLICY IF EXISTS "Admins full access on workshop_bays" ON public.workshop_bays;
CREATE POLICY "Admins full access on workshop_bays" ON public.workshop_bays FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Anyone view workshop_bays" ON public.workshop_bays;
CREATE POLICY "Anyone view workshop_bays" ON public.workshop_bays FOR SELECT TO authenticated USING (true);

-- Service Order Tasks
DROP POLICY IF EXISTS "Admins full access on tasks" ON public.service_order_tasks;
CREATE POLICY "Admins full access on tasks" ON public.service_order_tasks FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Mechanics view and update tasks" ON public.service_order_tasks;
CREATE POLICY "Mechanics view and update tasks" ON public.service_order_tasks FOR ALL USING (public.current_user_role() = 'mechanic');

DROP POLICY IF EXISTS "Customers view own tasks" ON public.service_order_tasks;
CREATE POLICY "Customers view own tasks" ON public.service_order_tasks FOR SELECT
  USING (service_order_id IN (
    SELECT so.id FROM public.service_orders so
    JOIN public.customers c ON so.customer_id = c.id
    WHERE c.profile_id = auth.uid()
  ));

-- Task Checklists
DROP POLICY IF EXISTS "Admins full access on checklists" ON public.task_checklists;
CREATE POLICY "Admins full access on checklists" ON public.task_checklists FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Mechanics manage checklists" ON public.task_checklists;
CREATE POLICY "Mechanics manage checklists" ON public.task_checklists FOR ALL USING (public.current_user_role() = 'mechanic');

DROP POLICY IF EXISTS "Customers view own checklists" ON public.task_checklists;
CREATE POLICY "Customers view own checklists" ON public.task_checklists FOR SELECT
  USING (task_id IN (
    SELECT t.id FROM public.service_order_tasks t
    JOIN public.service_orders so ON t.service_order_id = so.id
    JOIN public.customers c ON so.customer_id = c.id
    WHERE c.profile_id = auth.uid()
  ));

-- Mechanic Assignments
DROP POLICY IF EXISTS "Admins full access on mechanic_assignments" ON public.mechanic_assignments;
CREATE POLICY "Admins full access on mechanic_assignments" ON public.mechanic_assignments FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Mechanics view mechanic_assignments" ON public.mechanic_assignments;
CREATE POLICY "Mechanics view mechanic_assignments" ON public.mechanic_assignments FOR SELECT USING (public.current_user_role() = 'mechanic');

-- Task Assistance Requests
DROP POLICY IF EXISTS "Admins full access on assistance_requests" ON public.task_assistance_requests;
CREATE POLICY "Admins full access on assistance_requests" ON public.task_assistance_requests FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Mechanics manage assistance_requests" ON public.task_assistance_requests;
CREATE POLICY "Mechanics manage assistance_requests" ON public.task_assistance_requests FOR ALL USING (public.current_user_role() = 'mechanic');

-- Additional Findings
DROP POLICY IF EXISTS "Admins full access on additional_findings" ON public.service_order_additional_findings;
CREATE POLICY "Admins full access on additional_findings" ON public.service_order_additional_findings FOR ALL USING (public.current_user_role() = 'admin');

DROP POLICY IF EXISTS "Mechanics manage additional_findings" ON public.service_order_additional_findings;
CREATE POLICY "Mechanics manage additional_findings" ON public.service_order_additional_findings FOR ALL USING (public.current_user_role() = 'mechanic');

-- 6. RPC Functions

-- 6.1 Assign Vehicle to Bay (with Conflict Detection)
CREATE OR REPLACE FUNCTION public.assign_vehicle_bay(
  p_service_order_id UUID,
  p_bay_number INT
)
RETURNS public.workshop_bays AS $$
DECLARE
  v_target_bay public.workshop_bays;
  v_existing_bay public.workshop_bays;
  v_order public.service_orders;
BEGIN
  SELECT * INTO v_order FROM public.service_orders WHERE id = p_service_order_id;
  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'Service order % not found', p_service_order_id;
  END IF;

  SELECT * INTO v_target_bay FROM public.workshop_bays WHERE bay_number = p_bay_number;
  IF v_target_bay.id IS NULL THEN
    RAISE EXCEPTION 'Bay % does not exist', p_bay_number;
  END IF;

  IF v_target_bay.status = 'occupied' AND v_target_bay.current_service_order_id IS NOT NULL AND v_target_bay.current_service_order_id != p_service_order_id THEN
    RAISE EXCEPTION 'Bay conflict: Bay % is currently occupied by another vehicle', p_bay_number;
  END IF;

  -- Clear previous bay holding this service order
  UPDATE public.workshop_bays
  SET status = 'available',
      current_service_order_id = NULL,
      updated_at = NOW()
  WHERE current_service_order_id = p_service_order_id
    AND id != v_target_bay.id;

  -- Assign to target bay
  UPDATE public.workshop_bays
  SET status = 'occupied',
      current_service_order_id = p_service_order_id,
      updated_at = NOW()
  WHERE id = v_target_bay.id
  RETURNING * INTO v_target_bay;

  -- Update service order assigned bay label
  UPDATE public.service_orders
  SET assigned_bay = v_target_bay.name,
      updated_at = NOW()
  WHERE id = p_service_order_id;

  RETURN v_target_bay;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.2 Dispatch Order Operations
CREATE OR REPLACE FUNCTION public.dispatch_order_operations(
  p_service_order_id UUID,
  p_tasks JSONB,
  p_lead_mechanic_id UUID DEFAULT NULL,
  p_bay_number INT DEFAULT NULL
)
RETURNS public.service_orders AS $$
DECLARE
  v_order public.service_orders;
  v_task JSONB;
  v_task_id UUID;
  v_checklist_item TEXT;
  v_seq INT := 1;
BEGIN
  SELECT * INTO v_order FROM public.service_orders WHERE id = p_service_order_id;
  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'Service order not found';
  END IF;

  IF p_bay_number IS NOT NULL THEN
    PERFORM public.assign_vehicle_bay(p_service_order_id, p_bay_number);
  END IF;

  -- Record Lead Mechanic Assignment if provided
  IF p_lead_mechanic_id IS NOT NULL THEN
    INSERT INTO public.mechanic_assignments (
      service_order_id, mechanic_id, is_lead, role_description
    ) VALUES (
      p_service_order_id, p_lead_mechanic_id, true, 'Lead Performance Technician'
    );
  END IF;

  -- Insert Tasks
  FOR v_task IN SELECT * FROM jsonb_array_elements(p_tasks)
  LOOP
    INSERT INTO public.service_order_tasks (
      service_order_id,
      title,
      description,
      estimated_duration_minutes,
      priority,
      status,
      sequence_order,
      depends_on_task_id,
      assigned_mechanic_id
    ) VALUES (
      p_service_order_id,
      v_task->>'title',
      v_task->>'description',
      COALESCE((v_task->>'estimated_duration_minutes')::int, 60),
      COALESCE((v_task->>'priority')::public.task_priority, 'medium'::public.task_priority),
      COALESCE((v_task->>'status')::public.task_status, 'assigned'::public.task_status),
      v_seq,
      (v_task->>'depends_on_task_id')::uuid,
      COALESCE((v_task->>'assigned_mechanic_id')::uuid, p_lead_mechanic_id)
    ) RETURNING id INTO v_task_id;

    -- Insert Checklists if provided
    IF v_task ? 'checklists' AND jsonb_typeof(v_task->'checklists') = 'array' THEN
      FOR v_checklist_item IN SELECT * FROM jsonb_array_elements_text(v_task->'checklists')
      LOOP
        INSERT INTO public.task_checklists (task_id, item_description)
        VALUES (v_task_id, v_checklist_item);
      END LOOP;
    END IF;

    v_seq := v_seq + 1;
  END LOOP;

  -- Update Service Order status to in_progress
  UPDATE public.service_orders
  SET status = 'in_progress',
      updated_at = NOW()
  WHERE id = p_service_order_id
  RETURNING * INTO v_order;

  RETURN v_order;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.3 Start Task Operation (with Sequential Dependency Enforcement)
CREATE OR REPLACE FUNCTION public.start_task_operation(
  p_task_id UUID,
  p_mechanic_id UUID DEFAULT NULL
)
RETURNS public.service_order_tasks AS $$
DECLARE
  v_task public.service_order_tasks;
  v_dep public.service_order_tasks;
BEGIN
  SELECT * INTO v_task FROM public.service_order_tasks WHERE id = p_task_id;
  IF v_task.id IS NULL THEN
    RAISE EXCEPTION 'Task not found';
  END IF;

  -- Sequential Dependency Check
  IF v_task.depends_on_task_id IS NOT NULL THEN
    SELECT * INTO v_dep FROM public.service_order_tasks WHERE id = v_task.depends_on_task_id;
    IF v_dep.id IS NOT NULL AND v_dep.status != 'completed' THEN
      RAISE EXCEPTION 'Cannot start task: prerequisite task "%" is not completed (status: %)', v_dep.title, v_dep.status;
    END IF;
  END IF;

  -- Update task state
  UPDATE public.service_order_tasks
  SET status = 'in_progress',
      started_at = COALESCE(started_at, NOW()),
      assigned_mechanic_id = COALESCE(p_mechanic_id, auth.uid(), assigned_mechanic_id),
      pause_reason = NULL,
      updated_at = NOW()
  WHERE id = p_task_id
  RETURNING * INTO v_task;

  -- Ensure service order is in_progress
  UPDATE public.service_orders
  SET status = 'in_progress',
      updated_at = NOW()
  WHERE id = v_task.service_order_id
    AND status != 'in_progress';

  RETURN v_task;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.4 Pause Task Operation
CREATE OR REPLACE FUNCTION public.pause_task_operation(
  p_task_id UUID,
  p_reason TEXT
)
RETURNS public.service_order_tasks AS $$
DECLARE
  v_task public.service_order_tasks;
BEGIN
  UPDATE public.service_order_tasks
  SET status = 'paused',
      paused_at = NOW(),
      pause_reason = p_reason,
      updated_at = NOW()
  WHERE id = p_task_id
  RETURNING * INTO v_task;

  IF v_task.id IS NULL THEN
    RAISE EXCEPTION 'Task not found';
  END IF;

  RETURN v_task;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.5 Resume Task Operation
CREATE OR REPLACE FUNCTION public.resume_task_operation(
  p_task_id UUID
)
RETURNS public.service_order_tasks AS $$
DECLARE
  v_task public.service_order_tasks;
BEGIN
  UPDATE public.service_order_tasks
  SET status = 'in_progress',
      pause_reason = NULL,
      updated_at = NOW()
  WHERE id = p_task_id
  RETURNING * INTO v_task;

  IF v_task.id IS NULL THEN
    RAISE EXCEPTION 'Task not found';
  END IF;

  RETURN v_task;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.6 Complete Task Operation
CREATE OR REPLACE FUNCTION public.complete_task_operation(
  p_task_id UUID
)
RETURNS public.service_order_tasks AS $$
DECLARE
  v_task public.service_order_tasks;
  v_remaining_tasks INT;
  v_incomplete_checks INT;
BEGIN
  SELECT * INTO v_task FROM public.service_order_tasks WHERE id = p_task_id;
  IF v_task.id IS NULL THEN
    RAISE EXCEPTION 'Task not found';
  END IF;

  -- Verify all checklists are checked
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

  -- Check if all tasks for the order are complete
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

-- 6.7 Request Task Assistance
CREATE OR REPLACE FUNCTION public.request_task_assistance(
  p_task_id UUID,
  p_reason TEXT,
  p_helper_id UUID DEFAULT NULL
)
RETURNS public.task_assistance_requests AS $$
DECLARE
  v_request public.task_assistance_requests;
BEGIN
  INSERT INTO public.task_assistance_requests (
    task_id, requested_by, helper_mechanic_id, reason, status
  ) VALUES (
    p_task_id, auth.uid(), p_helper_id, p_reason, 'pending'
  ) RETURNING * INTO v_request;

  RETURN v_request;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6.8 Report Additional Finding
CREATE OR REPLACE FUNCTION public.report_additional_finding(
  p_service_order_id UUID,
  p_task_id UUID,
  p_title TEXT,
  p_description TEXT,
  p_severity public.severity_level DEFAULT 'medium'
)
RETURNS public.service_order_additional_findings AS $$
DECLARE
  v_finding public.service_order_additional_findings;
BEGIN
  INSERT INTO public.service_order_additional_findings (
    service_order_id, task_id, reported_by, title, description, severity, status
  ) VALUES (
    p_service_order_id, p_task_id, auth.uid(), p_title, p_description, p_severity, 'reported'
  ) RETURNING * INTO v_finding;

  RETURN v_finding;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
