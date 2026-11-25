-- Fix infinite recursion (42P17) in service_orders RLS policy
-- Use SECURITY DEFINER helper so checking assignments/tasks/inspections does not re-trigger RLS on service_orders.

CREATE OR REPLACE FUNCTION public.is_mechanic_assigned_to_order(p_order_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.mechanic_assignments ma
    WHERE ma.service_order_id = p_order_id AND ma.mechanic_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.service_order_tasks t
    WHERE t.service_order_id = p_order_id AND t.assigned_mechanic_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.inspections i
    WHERE i.service_order_id = p_order_id AND i.mechanic_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

DROP POLICY IF EXISTS "Mechanics can view assigned service_orders" ON public.service_orders;
CREATE POLICY "Mechanics can view assigned service_orders"
  ON public.service_orders
  FOR SELECT
  TO authenticated
  USING (
    public.current_user_role() = 'mechanic'
    AND public.is_mechanic_assigned_to_order(id)
  );
