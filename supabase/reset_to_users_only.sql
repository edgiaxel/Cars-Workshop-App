-- ============================================================================
-- Manual Reset Script: reset_to_users_only.sql
-- Purpose: Wipe all transactional and seed data from public tables while
--          keeping auth.users, auth.identities, public.profiles, and
--          registered public.customers (profile_id IS NOT NULL).
-- Run this in Supabase Dashboard -> SQL Editor.
-- ============================================================================

BEGIN;

-- 1. Clear operational, financial, inventory, notification, and vehicle data
TRUNCATE TABLE
  public.maintenance_reminders,
  public.notifications,
  public.notification_events,
  public.vehicle_handovers,
  public.payments,
  public.invoice_items,
  public.invoices,
  public.qc_checklist_items,
  public.qc_inspections,
  public.mechanic_payroll_adjustments,
  public.mechanic_earning_allocations,
  public.mechanic_earnings,
  public.mechanic_compensation_profiles,
  public.service_task_part_consumptions,
  public.part_requests,
  public.inventory_transactions,
  public.inventory_balances,
  public.parts,
  public.service_order_additional_findings,
  public.task_assistance_requests,
  public.mechanic_assignments,
  public.task_checklists,
  public.service_order_tasks,
  public.estimate_authorizations,
  public.estimate_items,
  public.estimates,
  public.inspection_findings,
  public.inspections,
  public.service_order_status_history,
  public.service_orders,
  public.bookings,
  public.vehicles
RESTART IDENTITY CASCADE;

-- 2. Reset workshop bays to available (clear any service order reference)
UPDATE public.workshop_bays
SET status = 'available',
    current_service_order_id = NULL,
    updated_at = NOW();

-- 3. Remove walk-in/guest customers, keep registered user customer records
DELETE FROM public.customers
WHERE profile_id IS NULL;

COMMIT;
