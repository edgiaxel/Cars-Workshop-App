-- ============================================================
-- Cars Workshop App
-- RLS Policies Migration
-- ============================================================

-- ============================================================
-- 1. PRIVATE SCHEMA FOR RLS HELPER FUNCTIONS
-- ============================================================

CREATE SCHEMA IF NOT EXISTS private;


-- ============================================================
-- 2. RLS HELPER FUNCTIONS
-- ============================================================

-- Returns the application role of the currently authenticated user.
CREATE OR REPLACE FUNCTION private.current_user_role()
RETURNS public.user_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT p.role
    FROM public.profiles AS p
    WHERE p.id = (SELECT auth.uid())
$$;


-- Returns the customer ID belonging to the current authenticated user.
CREATE OR REPLACE FUNCTION private.current_customer_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT c.id
    FROM public.customers AS c
    WHERE c.profile_id = (SELECT auth.uid())
$$;


-- Returns the mechanic ID belonging to the current authenticated user.
CREATE OR REPLACE FUNCTION private.current_mechanic_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT m.id
    FROM public.mechanics AS m
    WHERE m.profile_id = (SELECT auth.uid())
$$;


-- Role helper functions.
CREATE OR REPLACE FUNCTION private.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT private.current_user_role() = 'ADMIN'::public.user_role
$$;


CREATE OR REPLACE FUNCTION private.is_mechanic()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT private.current_user_role() = 'MECHANIC'::public.user_role
$$;


CREATE OR REPLACE FUNCTION private.is_customer()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT private.current_user_role() = 'CUSTOMER'::public.user_role
$$;


-- ============================================================
-- 3. LOCK DOWN HELPER FUNCTIONS
-- ============================================================

REVOKE ALL ON SCHEMA private FROM PUBLIC;
GRANT USAGE ON SCHEMA private TO authenticated;

REVOKE ALL ON FUNCTION private.current_user_role() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.current_customer_id() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.current_mechanic_id() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.is_admin() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.is_mechanic() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.is_customer() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION private.current_user_role() TO authenticated;
GRANT EXECUTE ON FUNCTION private.current_customer_id() TO authenticated;
GRANT EXECUTE ON FUNCTION private.current_mechanic_id() TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_customer() TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_mechanic() TO authenticated;


-- ============================================================
-- 4. CLIENT TABLE GRANTS
-- ============================================================

-- No application data is exposed to unauthenticated users.
REVOKE ALL ON TABLE public.profiles FROM anon;
REVOKE ALL ON TABLE public.customers FROM anon;
REVOKE ALL ON TABLE public.mechanics FROM anon;
REVOKE ALL ON TABLE public.vehicles FROM anon;
REVOKE ALL ON TABLE public.service_orders FROM anon;
REVOKE ALL ON TABLE public.service_tasks FROM anon;
REVOKE ALL ON TABLE public.parts FROM anon;
REVOKE ALL ON TABLE public.service_order_parts FROM anon;
REVOKE ALL ON TABLE public.service_records FROM anon;
REVOKE ALL ON TABLE public.service_order_status_history FROM anon;


-- Authenticated users can reach the tables.
-- RLS below determines which rows and operations are actually allowed.
GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE public.profiles,
           public.customers,
           public.mechanics,
           public.vehicles,
           public.service_orders,
           public.service_tasks,
           public.parts,
           public.service_order_parts,
           public.service_records,
           public.service_order_status_history
TO authenticated;


-- ============================================================
-- 5. PROFILES
-- ============================================================

CREATE POLICY "profiles_select"
ON public.profiles
FOR SELECT
TO authenticated
USING (
    private.is_admin()
    OR id = (SELECT auth.uid())
    OR id IN (
        SELECT m.profile_id
        FROM public.mechanics AS m
        WHERE m.id IN (
            SELECT so.assigned_mechanic_id
            FROM public.service_orders AS so
            WHERE so.customer_id = private.current_customer_id()
        )
    )
);


CREATE POLICY "profiles_insert"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (
    private.is_admin()
);


CREATE POLICY "profiles_update"
ON public.profiles
FOR UPDATE
TO authenticated
USING (
    private.is_admin()
    OR id = (SELECT auth.uid())
)
WITH CHECK (
    private.is_admin()
    OR id = (SELECT auth.uid())
);


CREATE POLICY "profiles_delete"
ON public.profiles
FOR DELETE
TO authenticated
USING (
    private.is_admin()
);


-- ============================================================
-- 6. CUSTOMERS
-- ============================================================

CREATE POLICY "customers_select"
ON public.customers
FOR SELECT
TO authenticated
USING (
    private.is_admin()
    OR profile_id = (SELECT auth.uid())
    OR id IN (
        SELECT so.customer_id
        FROM public.service_orders AS so
        WHERE so.assigned_mechanic_id = private.current_mechanic_id()
    )
);


CREATE POLICY "customers_insert"
ON public.customers
FOR INSERT
TO authenticated
WITH CHECK (
    private.is_admin()
);


CREATE POLICY "customers_update"
ON public.customers
FOR UPDATE
TO authenticated
USING (
    private.is_admin()
    OR profile_id = (SELECT auth.uid())
)
WITH CHECK (
    private.is_admin()
    OR profile_id = (SELECT auth.uid())
);


CREATE POLICY "customers_delete"
ON public.customers
FOR DELETE
TO authenticated
USING (
    private.is_admin()
);


-- ============================================================
-- 7. MECHANICS
-- ============================================================

CREATE POLICY "mechanics_select"
ON public.mechanics
FOR SELECT
TO authenticated
USING (
    private.is_admin()
    OR profile_id = (SELECT auth.uid())
    OR id IN (
        SELECT so.assigned_mechanic_id
        FROM public.service_orders AS so
        WHERE so.customer_id = private.current_customer_id()
    )
);


CREATE POLICY "mechanics_insert"
ON public.mechanics
FOR INSERT
TO authenticated
WITH CHECK (
    private.is_admin()
);


CREATE POLICY "mechanics_update"
ON public.mechanics
FOR UPDATE
TO authenticated
USING (
    private.is_admin()
    OR profile_id = (SELECT auth.uid())
)
WITH CHECK (
    private.is_admin()
    OR profile_id = (SELECT auth.uid())
);


CREATE POLICY "mechanics_delete"
ON public.mechanics
FOR DELETE
TO authenticated
USING (
    private.is_admin()
);


-- ============================================================
-- 8. VEHICLES
-- ============================================================

CREATE POLICY "vehicles_select"
ON public.vehicles
FOR SELECT
TO authenticated
USING (
    private.is_admin()
    OR customer_id = private.current_customer_id()
    OR id IN (
        SELECT so.vehicle_id
        FROM public.service_orders AS so
        WHERE so.assigned_mechanic_id = private.current_mechanic_id()
    )
);


CREATE POLICY "vehicles_insert"
ON public.vehicles
FOR INSERT
TO authenticated
WITH CHECK (
    private.is_admin()
    OR customer_id = private.current_customer_id()
);


CREATE POLICY "vehicles_update"
ON public.vehicles
FOR UPDATE
TO authenticated
USING (
    private.is_admin()
    OR customer_id = private.current_customer_id()
)
WITH CHECK (
    private.is_admin()
    OR customer_id = private.current_customer_id()
);


CREATE POLICY "vehicles_delete"
ON public.vehicles
FOR DELETE
TO authenticated
USING (
    private.is_admin()
);


-- ============================================================
-- 9. SERVICE ORDERS
-- ============================================================

CREATE POLICY "service_orders_select"
ON public.service_orders
FOR SELECT
TO authenticated
USING (
    private.is_admin()
    OR customer_id = private.current_customer_id()
    OR assigned_mechanic_id = private.current_mechanic_id()
);


CREATE POLICY "service_orders_insert"
ON public.service_orders
FOR INSERT
TO authenticated
WITH CHECK (
    private.is_admin()
    OR customer_id = private.current_customer_id()
);


CREATE POLICY "service_orders_update_admin"
ON public.service_orders
FOR UPDATE
TO authenticated
USING (
    private.is_admin()
)
WITH CHECK (
    private.is_admin()
);


CREATE POLICY "service_orders_update_mechanic"
ON public.service_orders
FOR UPDATE
TO authenticated
USING (
    assigned_mechanic_id = private.current_mechanic_id()
)
WITH CHECK (
    assigned_mechanic_id = private.current_mechanic_id()
);


CREATE POLICY "service_orders_update_customer"
ON public.service_orders
FOR UPDATE
TO authenticated
USING (
    customer_id = private.current_customer_id()
)
WITH CHECK (
    customer_id = private.current_customer_id()
);


CREATE POLICY "service_orders_delete"
ON public.service_orders
FOR DELETE
TO authenticated
USING (
    private.is_admin()
);


-- ============================================================
-- 10. SERVICE TASKS
-- ============================================================

CREATE POLICY "service_tasks_select"
ON public.service_tasks
FOR SELECT
TO authenticated
USING (
    private.is_admin()
    OR assigned_mechanic_id = private.current_mechanic_id()
    OR service_order_id IN (
        SELECT so.id
        FROM public.service_orders AS so
        WHERE so.customer_id = private.current_customer_id()
    )
);


CREATE POLICY "service_tasks_insert"
ON public.service_tasks
FOR INSERT
TO authenticated
WITH CHECK (
    private.is_admin()
    OR assigned_mechanic_id = private.current_mechanic_id()
);


CREATE POLICY "service_tasks_update_admin"
ON public.service_tasks
FOR UPDATE
TO authenticated
USING (
    private.is_admin()
)
WITH CHECK (
    private.is_admin()
);


CREATE POLICY "service_tasks_update_mechanic"
ON public.service_tasks
FOR UPDATE
TO authenticated
USING (
    assigned_mechanic_id = private.current_mechanic_id()
)
WITH CHECK (
    assigned_mechanic_id = private.current_mechanic_id()
);


CREATE POLICY "service_tasks_delete"
ON public.service_tasks
FOR DELETE
TO authenticated
USING (
    private.is_admin()
);


-- ============================================================
-- 11. PARTS
-- ============================================================

CREATE POLICY "parts_select"
ON public.parts
FOR SELECT
TO authenticated
USING (
    private.is_admin()
    OR private.is_mechanic()
);


CREATE POLICY "parts_insert"
ON public.parts
FOR INSERT
TO authenticated
WITH CHECK (
    private.is_admin()
);


CREATE POLICY "parts_update"
ON public.parts
FOR UPDATE
TO authenticated
USING (
    private.is_admin()
)
WITH CHECK (
    private.is_admin()
);


CREATE POLICY "parts_delete"
ON public.parts
FOR DELETE
TO authenticated
USING (
    private.is_admin()
);


-- ============================================================
-- 12. SERVICE ORDER PARTS
-- ============================================================

CREATE POLICY "service_order_parts_select"
ON public.service_order_parts
FOR SELECT
TO authenticated
USING (
    private.is_admin()
    OR service_order_id IN (
        SELECT so.id
        FROM public.service_orders AS so
        WHERE so.customer_id = private.current_customer_id()
    )
    OR service_order_id IN (
        SELECT so.id
        FROM public.service_orders AS so
        WHERE so.assigned_mechanic_id = private.current_mechanic_id()
    )
);


CREATE POLICY "service_order_parts_insert"
ON public.service_order_parts
FOR INSERT
TO authenticated
WITH CHECK (
    private.is_admin()
    OR service_order_id IN (
        SELECT so.id
        FROM public.service_orders AS so
        WHERE so.assigned_mechanic_id = private.current_mechanic_id()
    )
);


CREATE POLICY "service_order_parts_update"
ON public.service_order_parts
FOR UPDATE
TO authenticated
USING (
    private.is_admin()
    OR service_order_id IN (
        SELECT so.id
        FROM public.service_orders AS so
        WHERE so.assigned_mechanic_id = private.current_mechanic_id()
    )
)
WITH CHECK (
    private.is_admin()
    OR service_order_id IN (
        SELECT so.id
        FROM public.service_orders AS so
        WHERE so.assigned_mechanic_id = private.current_mechanic_id()
    )
);


CREATE POLICY "service_order_parts_delete"
ON public.service_order_parts
FOR DELETE
TO authenticated
USING (
    private.is_admin()
);


-- ============================================================
-- 13. SERVICE RECORDS
-- ============================================================

CREATE POLICY "service_records_select"
ON public.service_records
FOR SELECT
TO authenticated
USING (
    private.is_admin()
    OR vehicle_id IN (
        SELECT v.id
        FROM public.vehicles AS v
        WHERE v.customer_id = private.current_customer_id()
    )
    OR mechanic_id = private.current_mechanic_id()
);


CREATE POLICY "service_records_insert"
ON public.service_records
FOR INSERT
TO authenticated
WITH CHECK (
    private.is_admin()
    OR mechanic_id = private.current_mechanic_id()
);


CREATE POLICY "service_records_update"
ON public.service_records
FOR UPDATE
TO authenticated
USING (
    private.is_admin()
    OR mechanic_id = private.current_mechanic_id()
)
WITH CHECK (
    private.is_admin()
    OR mechanic_id = private.current_mechanic_id()
);


CREATE POLICY "service_records_delete"
ON public.service_records
FOR DELETE
TO authenticated
USING (
    private.is_admin()
);


-- ============================================================
-- 14. SERVICE ORDER STATUS HISTORY
-- ============================================================

CREATE POLICY "status_history_select"
ON public.service_order_status_history
FOR SELECT
TO authenticated
USING (
    private.is_admin()
    OR service_order_id IN (
        SELECT so.id
        FROM public.service_orders AS so
        WHERE so.customer_id = private.current_customer_id()
    )
    OR service_order_id IN (
        SELECT so.id
        FROM public.service_orders AS so
        WHERE so.assigned_mechanic_id = private.current_mechanic_id()
    )
);


CREATE POLICY "status_history_insert"
ON public.service_order_status_history
FOR INSERT
TO authenticated
WITH CHECK (
    private.is_admin()
    OR changed_by = (SELECT auth.uid())
);


CREATE POLICY "status_history_update"
ON public.service_order_status_history
FOR UPDATE
TO authenticated
USING (
    private.is_admin()
)
WITH CHECK (
    private.is_admin()
);


CREATE POLICY "status_history_delete"
ON public.service_order_status_history
FOR DELETE
TO authenticated
USING (
    private.is_admin()
);