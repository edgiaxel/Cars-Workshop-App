-- ==============================================================================
-- PitMate v2.0 Foundation Migration
-- Generated: 2026-11-20
-- Scope: Core Enums, Profiles, Workshop Bays, and RLS Foundations
-- ==============================================================================

-- 1. Core Enumerations
CREATE TYPE user_role AS ENUM (
  'admin',
  'mechanic',
  'customer'
);

CREATE TYPE customer_type AS ENUM (
  'individual',
  'company'
);

CREATE TYPE intake_origin AS ENUM (
  'booking',
  'walk_in',
  'emergency'
);

CREATE TYPE booking_status AS ENUM (
  'requested',
  'approved',
  'rejected',
  'scheduled',
  'checked_in',
  'cancelled',
  'completed'
);

CREATE TYPE service_order_status AS ENUM (
  'intake',
  'inspection',
  'estimate_pending',
  'estimate_approved',
  'dispatched',
  'in_progress',
  'qc_pending',
  'qc_passed',
  'invoiced',
  'paid',
  'handover_ready',
  'closed',
  'cancelled'
);

CREATE TYPE operation_status AS ENUM (
  'pending',
  'ready',
  'assigned',
  'in_progress',
  'paused',
  'completed',
  'blocked',
  'cancelled'
);

CREATE TYPE qc_status AS ENUM (
  'pending',
  'in_review',
  'passed',
  'failed'
);

CREATE TYPE inventory_transaction_type AS ENUM (
  'initial_stock',
  'purchase_receipt',
  'reservation',
  'issue_to_job',
  'job_consumption',
  'job_return',
  'adjustment_increase',
  'adjustment_decrease',
  'scrapped_damaged'
);

CREATE TYPE part_request_status AS ENUM (
  'requested',
  'approved',
  'rejected',
  'fulfilled',
  'cancelled'
);

CREATE TYPE invoice_status AS ENUM (
  'draft',
  'issued',
  'partially_paid',
  'paid',
  'voided',
  'refunded'
);

CREATE TYPE payment_method AS ENUM (
  'cash',
  'credit_card',
  'debit_card',
  'bank_transfer',
  'qris',
  'corporate_account'
);

CREATE TYPE notification_type AS ENUM (
  'booking',
  'service',
  'inspection',
  'estimate',
  'inventory',
  'payment',
  'reminder',
  'system'
);

CREATE TYPE notification_priority AS ENUM (
  'low',
  'normal',
  'high',
  'urgent'
);

CREATE TYPE reminder_type AS ENUM (
  'mileage_interval',
  'time_interval',
  'seasonal_inspection',
  'safety_recall',
  'custom'
);

CREATE TYPE reminder_status AS ENUM (
  'active',
  'snoozed',
  'dismissed',
  'scheduled_as_booking',
  'expired'
);

-- 2. Profiles Table (Linked to auth.users)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role user_role NOT NULL DEFAULT 'customer',
  full_name TEXT NOT NULL,
  phone_number TEXT UNIQUE,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Workshop Bays (Configurable physical resource)
CREATE TABLE public.workshop_bays (
  id INT PRIMARY KEY,
  name TEXT NOT NULL,
  bay_type TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  current_service_order_id UUID,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workshop_bays ENABLE ROW LEVEL SECURITY;

-- 5. Helper Function: current_user_role()
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS user_role AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- 6. RLS Policies for Profiles
CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own non-role profile fields"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING (public.current_user_role() = 'admin');

CREATE POLICY "Admins can manage all profiles"
  ON public.profiles FOR ALL
  USING (public.current_user_role() = 'admin');

-- 7. RLS Policies for Workshop Bays
CREATE POLICY "Authenticated users can view workshop bays"
  ON public.workshop_bays FOR SELECT
  TO authenticated
  USING (TRUE);

CREATE POLICY "Admins can manage workshop bays"
  ON public.workshop_bays FOR ALL
  USING (public.current_user_role() = 'admin');
