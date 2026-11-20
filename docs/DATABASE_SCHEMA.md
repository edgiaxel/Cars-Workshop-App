# PitMate — Database Schema Specification

> **Document:** DATABASE_SCHEMA.md  
> **Status:** Approved — 2026-11-20  
> **Version:** 2.0  
> **Last updated:** 2026-11-20  
> **Platform:** Supabase PostgreSQL 17  
> **Related:** ARCHITECTURE.md, PRD.md, DESIGN.md, MILESTONE.md  

---

# 1. Overview and Design Principles

This document specifies the canonical PostgreSQL database schema for PitMate Version 2.0.
The backend is powered by Supabase PostgreSQL, Supabase Auth, and Row Level Security (RLS).

## 1.1 Core Principles

1. **Relational Integrity**: Foreign keys, check constraints, unique constraints, and non-null guarantees enforce business invariants at the database layer.
2. **Strict RLS Enforcement**: Every table in `public` has Row Level Security enabled. Unauthenticated or cross-role access is denied by default.
3. **Auditability**: Critical domains (inventory movements, financial records, status histories, compensation allocations) use append-only or immutable ledger records.
4. **Monetary Precision**: All monetary values are represented as exact numeric minor currency units (`BIGINT` in cents / IDR cents) or fixed-precision `NUMERIC(14,2)` to prevent floating-point calculation errors.
5. **Separation of Auth and Profiles**: `auth.users` handles credential authentication; `public.profiles` contains role and user metadata linked via `profiles.id -> auth.users.id ON DELETE CASCADE`.
6. **Isolated Guest Intake**: Guest customers and walk-in intakes exist as database records in `public.customers` without requiring an immediate `auth.users` account until officially claimed or linked.

---

# 2. Enumerations

```sql
-- Application user roles
CREATE TYPE user_role AS ENUM (
  'admin',
  'mechanic',
  'customer'
);

-- Customer classification
CREATE TYPE customer_type AS ENUM (
  'individual',
  'company'
);

-- Service intake origin
CREATE TYPE intake_origin AS ENUM (
  'booking',
  'walk_in',
  'emergency'
);

-- Booking lifecycle
CREATE TYPE booking_status AS ENUM (
  'requested',
  'approved',
  'rejected',
  'scheduled',
  'checked_in',
  'cancelled',
  'completed'
);

-- Service order overall lifecycle
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

-- Individual service operation status
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

-- Quality inspection status
CREATE TYPE qc_status AS ENUM (
  'pending',
  'in_review',
  'passed',
  'failed'
);

-- Inventory transaction type (immutable ledger)
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

-- Part request status from mechanics
CREATE TYPE part_request_status AS ENUM (
  'requested',
  'approved',
  'rejected',
  'fulfilled',
  'cancelled'
);

-- Invoice status
CREATE TYPE invoice_status AS ENUM (
  'draft',
  'issued',
  'partially_paid',
  'paid',
  'voided',
  'refunded'
);

-- Payment methods
CREATE TYPE payment_method AS ENUM (
  'cash',
  'credit_card',
  'debit_card',
  'bank_transfer',
  'qris',
  'corporate_account'
);

-- Notification types and priorities
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

-- Service reminder types and statuses
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
```

---

# 3. Domain Table Specifications

## 3.1 Identity Domain

### `public.profiles`
User profile extension linked to Supabase Auth.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK, REFERENCES auth.users(id) ON DELETE CASCADE` | Auth user ID |
| `role` | `user_role` | `NOT NULL DEFAULT 'customer'` | User application role |
| `full_name` | `TEXT` | `NOT NULL` | Display name |
| `phone_number` | `TEXT` | `UNIQUE` | Contact phone |
| `avatar_url` | `TEXT` | `NULL` | Profile photo storage path |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Last update timestamp |

---

## 3.2 Fleet Domain

### `public.customers`
Workshop customer accounts (includes registered users and guest accounts).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Customer ID |
| `profile_id` | `UUID` | `NULL, REFERENCES public.profiles(id) ON DELETE SET NULL` | Linked auth profile |
| `customer_type` | `customer_type` | `NOT NULL DEFAULT 'individual'` | Account type |
| `name` | `TEXT` | `NOT NULL` | Full customer or corporate name |
| `email` | `TEXT` | `NULL` | Contact email |
| `phone` | `TEXT` | `NOT NULL` | Contact phone |
| `address` | `TEXT` | `NULL` | Physical address |
| `tax_number` | `TEXT` | `NULL` | Corporate tax identification |
| `is_guest` | `BOOLEAN` | `NOT NULL DEFAULT FALSE` | Flag for unregistered walk-in guest |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Record creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Last update timestamp |

### `public.vehicles`
Customer vehicles serviced at the workshop.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Vehicle ID |
| `customer_id` | `UUID` | `NOT NULL, REFERENCES public.customers(id) ON DELETE RESTRICT` | Vehicle owner |
| `license_plate` | `TEXT` | `NOT NULL UNIQUE` | Vehicle registration plate |
| `vin` | `TEXT` | `NULL UNIQUE` | Vehicle Identification Number |
| `make` | `TEXT` | `NOT NULL` | Manufacturer (e.g. BMW, Toyota) |
| `model` | `TEXT` | `NOT NULL` | Model name (e.g. M3, Innova) |
| `year` | `INT` | `NOT NULL CHECK (year BETWEEN 1900 AND 2100)` | Manufacturing year |
| `transmission` | `TEXT` | `NULL` | Automatic / Manual / Dual-Clutch |
| `color` | `TEXT` | `NULL` | Vehicle exterior color |
| `current_mileage` | `INT` | `NOT NULL DEFAULT 0 CHECK (current_mileage >= 0)` | Last recorded odometer reading |
| `notes` | `TEXT` | `NULL` | Vehicle-specific notes |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Record creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Last update timestamp |

---

## 3.3 Booking Domain

### `public.bookings`
Customer appointment bookings.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Booking ID |
| `booking_number` | `TEXT` | `NOT NULL UNIQUE` | Human-readable identifier (e.g. `BK-202611-001`) |
| `customer_id` | `UUID` | `NOT NULL, REFERENCES public.customers(id) ON DELETE RESTRICT` | Booking customer |
| `vehicle_id` | `UUID` | `NOT NULL, REFERENCES public.vehicles(id) ON DELETE RESTRICT` | Target vehicle |
| `scheduled_date` | `DATE` | `NOT NULL` | Requested service date |
| `scheduled_time` | `TIME` | `NOT NULL` | Requested service time |
| `service_type` | `TEXT` | `NOT NULL` | Requested primary service |
| `customer_notes` | `TEXT` | `NULL` | Customer problem description |
| `admin_notes` | `TEXT` | `NULL` | Internal workshop notes |
| `status` | `booking_status` | `NOT NULL DEFAULT 'requested'` | Booking state |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Last update timestamp |

---

## 3.4 Workshop Domain

### `public.workshop_bays`
Physical workshop bays (default: 5 bays).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `INT` | `PK` | Bay number (1 to 5) |
| `name` | `TEXT` | `NOT NULL` | Bay label (e.g. "Bay 1 - Quick Service") |
| `bay_type` | `TEXT` | `NOT NULL` | Lift 2-Post, Lift 4-Post, Diagnostic, Alignment |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT TRUE` | Active/operational status |
| `current_service_order_id`| `UUID` | `NULL` | Current occupying service order |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Status update timestamp |

### `public.service_orders`
Authoritative workshop job card / service order.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Service order ID |
| `order_number` | `TEXT` | `NOT NULL UNIQUE` | Order code (e.g. `SO-202611-001`) |
| `booking_id` | `UUID` | `NULL UNIQUE, REFERENCES public.bookings(id)` | Linked booking if origin is booking |
| `customer_id` | `UUID` | `NOT NULL, REFERENCES public.customers(id) ON DELETE RESTRICT` | Customer |
| `vehicle_id` | `UUID` | `NOT NULL, REFERENCES public.vehicles(id) ON DELETE RESTRICT` | Vehicle |
| `bay_id` | `INT` | `NULL, REFERENCES public.workshop_bays(id)` | Current physical bay |
| `intake_origin` | `intake_origin` | `NOT NULL DEFAULT 'walk_in'` | Booking or walk-in |
| `intake_mileage` | `INT` | `NOT NULL CHECK (intake_mileage >= 0)` | Mileage recorded at check-in |
| `fuel_level` | `TEXT` | `NULL` | Fuel gauge at intake (e.g. "1/2", "Full") |
| `intake_notes` | `TEXT` | `NULL` | Initial customer complaint notes |
| `status` | `service_order_status` | `NOT NULL DEFAULT 'intake'` | Current lifecycle stage |
| `arrived_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Physical arrival timestamp |
| `started_at` | `TIMESTAMPTZ` | `NULL` | Work commencement timestamp |
| `completed_at` | `TIMESTAMPTZ` | `NULL` | Technical completion timestamp |
| `closed_at` | `TIMESTAMPTZ` | `NULL` | Order closed / vehicle handed over |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Record creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Last update timestamp |

### `public.service_order_status_history`
Append-only state audit trail for service orders.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `BIGSERIAL` | `PK` | Audit ID |
| `service_order_id` | `UUID` | `NOT NULL, REFERENCES public.service_orders(id) ON DELETE CASCADE` | Target order |
| `from_status` | `service_order_status` | `NULL` | Previous status |
| `to_status` | `service_order_status` | `NOT NULL` | New status |
| `changed_by` | `UUID` | `NULL, REFERENCES public.profiles(id)` | Acting user |
| `reason` | `TEXT` | `NULL` | Transition reason / notes |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Timestamp of transition |

---

## 3.5 Inspection Domain

### `public.inspections`
Vehicle check-in and diagnostic inspection records.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Inspection ID |
| `service_order_id` | `UUID` | `NOT NULL, REFERENCES public.service_orders(id) ON DELETE CASCADE` | Service order |
| `mechanic_id` | `UUID` | `NOT NULL, REFERENCES public.profiles(id)` | Inspecting mechanic |
| `overall_condition`| `TEXT` | `NOT NULL` | Good, Fair, Urgent Attention |
| `inspector_notes` | `TEXT` | `NULL` | Diagnostic summary notes |
| `customer_visible` | `BOOLEAN` | `NOT NULL DEFAULT TRUE` | Visibility flag for customer |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Inspection timestamp |

### `public.inspection_findings`
Specific items identified during inspection.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Finding ID |
| `inspection_id` | `UUID` | `NOT NULL, REFERENCES public.inspections(id) ON DELETE CASCADE` | Parent inspection |
| `system_category` | `TEXT` | `NOT NULL` | Brakes, Suspension, Engine, Electrical, Fluids |
| `item_name` | `TEXT` | `NOT NULL` | Specific component (e.g. "Front Brake Pads") |
| `condition` | `TEXT` | `NOT NULL` | Pass, Advisory, Fail |
| `severity` | `TEXT` | `NOT NULL` | Minor, Moderate, Critical |
| `description` | `TEXT` | `NOT NULL` | Finding description |
| `photo_storage_path`| `TEXT` | `NULL` | Storage bucket path for evidence photo |
| `estimated_cost` | `BIGINT` | `NULL` | Estimated fix cost in minor currency units |
| `recommended_action`| `TEXT` | `NULL` | Repair recommendation |

---

## 3.6 Estimate & Authorization Domain

### `public.estimates`
Cost proposals submitted to customers.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Estimate ID |
| `service_order_id` | `UUID` | `NOT NULL, REFERENCES public.service_orders(id) ON DELETE CASCADE` | Service order |
| `revision_number` | `INT` | `NOT NULL DEFAULT 1` | Revision sequence |
| `labor_subtotal` | `BIGINT` | `NOT NULL DEFAULT 0` | Total labor cost in cents |
| `parts_subtotal` | `BIGINT` | `NOT NULL DEFAULT 0` | Total parts cost in cents |
| `tax_amount` | `BIGINT` | `NOT NULL DEFAULT 0` | Applied tax in cents |
| `discount_amount`| `BIGINT` | `NOT NULL DEFAULT 0` | Discount applied |
| `total_amount` | `BIGINT` | `NOT NULL CHECK (total_amount >= 0)` | Net payable total in cents |
| `status` | `TEXT` | `NOT NULL DEFAULT 'pending'` | pending, approved, rejected, revised |
| `notes` | `TEXT` | `NULL` | Terms or explanatory notes |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Created timestamp |
| `expires_at` | `TIMESTAMPTZ` | `NULL` | Validity expiration |

### `public.estimate_items`
Individual line items in an estimate.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Item ID |
| `estimate_id` | `UUID` | `NOT NULL, REFERENCES public.estimates(id) ON DELETE CASCADE` | Parent estimate |
| `item_type` | `TEXT` | `NOT NULL` | 'labor' or 'part' |
| `description` | `TEXT` | `NOT NULL` | Description of operation or part |
| `quantity` | `NUMERIC(10,2)` | `NOT NULL DEFAULT 1 CHECK (quantity > 0)` | Quantity |
| `unit_price` | `BIGINT` | `NOT NULL CHECK (unit_price >= 0)` | Price per unit in cents |
| `total_price` | `BIGINT` | `NOT NULL CHECK (total_price >= 0)` | Line total in cents |
| `is_mandatory` | `BOOLEAN` | `NOT NULL DEFAULT TRUE` | Safety critical vs optional |
| `customer_approved`| `BOOLEAN` | `NULL` | True if authorized by customer |

### `public.estimate_authorizations`
Customer approval or rejection records.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Authorization ID |
| `estimate_id` | `UUID` | `NOT NULL, REFERENCES public.estimates(id) ON DELETE RESTRICT` | Target estimate |
| `authorized_by` | `UUID` | `NOT NULL, REFERENCES public.profiles(id)` | Authorizing user |
| `approved` | `BOOLEAN` | `NOT NULL` | True = approved, False = rejected |
| `signature_data` | `TEXT` | `NULL` | Digital signature representation |
| `notes` | `TEXT` | `NULL` | Customer feedback or conditions |
| `authorized_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Decision timestamp |

---

## 3.7 Service Execution Domain

### `public.service_operations`
Authorized work items to be executed on a vehicle.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Operation ID |
| `service_order_id` | `UUID` | `NOT NULL, REFERENCES public.service_orders(id) ON DELETE CASCADE` | Parent service order |
| `operation_name` | `TEXT` | `NOT NULL` | Task title (e.g. "Brake Pad Replacement") |
| `description` | `TEXT` | `NULL` | Technical instruction details |
| `estimated_minutes`| `INT` | `NOT NULL DEFAULT 60 CHECK (estimated_minutes > 0)` | Expected duration |
| `actual_minutes` | `INT` | `NULL CHECK (actual_minutes >= 0)` | Actual recorded duration |
| `status` | `operation_status` | `NOT NULL DEFAULT 'pending'` | Operation state |
| `depends_on_operation_id`| `UUID` | `NULL, REFERENCES public.service_operations(id)` | Prerequisite dependency |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Creation timestamp |
| `started_at` | `TIMESTAMPTZ` | `NULL` | Execution start timestamp |
| `completed_at` | `TIMESTAMPTZ` | `NULL` | Execution completion timestamp |

### `public.operation_assignments`
Mechanic assignment mapping for operations.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Assignment ID |
| `operation_id` | `UUID` | `NOT NULL, REFERENCES public.service_operations(id) ON DELETE CASCADE` | Service operation |
| `mechanic_id` | `UUID` | `NOT NULL, REFERENCES public.profiles(id)` | Assigned mechanic |
| `assigned_by` | `UUID` | `NOT NULL, REFERENCES public.profiles(id)` | Admin who dispatched work |
| `contribution_percentage`| `NUMERIC(5,2)` | `NOT NULL DEFAULT 100.00 CHECK (contribution_percentage BETWEEN 1 AND 100)` | Split allocation |
| `assigned_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Assignment timestamp |

---

## 3.8 Inventory Domain

### `public.spare_parts`
Catalog of workshop spare parts and materials.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Part ID |
| `part_sku` | `TEXT` | `NOT NULL UNIQUE` | Stock Keeping Unit |
| `name` | `TEXT` | `NOT NULL` | Item description |
| `category` | `TEXT` | `NOT NULL` | Lubricants, Brakes, Filters, Tires, Electrical |
| `unit_of_measure` | `TEXT` | `NOT NULL DEFAULT 'pcs'` | pcs, liters, sets, meters |
| `cost_price` | `BIGINT` | `NOT NULL CHECK (cost_price >= 0)` | Purchase cost in cents |
| `selling_price` | `BIGINT` | `NOT NULL CHECK (selling_price >= cost_price)` | Customer retail price in cents |
| `min_stock_level` | `INT` | `NOT NULL DEFAULT 5 CHECK (min_stock_level >= 0)` | Low-stock alert threshold |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT TRUE` | Active inventory item |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Created timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Last updated |

### `public.inventory_balances`
Maintained operational inventory balances (must reconcile with ledger).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `part_id` | `UUID` | `PK, REFERENCES public.spare_parts(id) ON DELETE RESTRICT` | Target part |
| `quantity_on_hand` | `NUMERIC(10,2)` | `NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0)` | Physical quantity in workshop |
| `quantity_reserved`| `NUMERIC(10,2)` | `NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0)` | Allocated to approved orders |
| `quantity_available`| `NUMERIC(10,2)` | `GENERATED ALWAYS AS (quantity_on_hand - quantity_reserved) STORED` | Net free stock |
| `last_counted_at` | `TIMESTAMPTZ` | `NULL` | Last physical audit date |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Last balance update |

### `public.inventory_transactions`
Authoritative immutable ledger of all stock movements.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `BIGSERIAL` | `PK` | Transaction sequence |
| `part_id` | `UUID` | `NOT NULL, REFERENCES public.spare_parts(id) ON DELETE RESTRICT` | Target part |
| `transaction_type` | `inventory_transaction_type`| `NOT NULL` | Ledger event type |
| `quantity_delta` | `NUMERIC(10,2)` | `NOT NULL CHECK (quantity_delta <> 0)` | Positive (in) or negative (out) |
| `unit_cost_at_time`| `BIGINT` | `NOT NULL CHECK (unit_cost_at_time >= 0)` | Cost price at event time |
| `service_order_id` | `UUID` | `NULL, REFERENCES public.service_orders(id)` | Linked service order |
| `operation_id` | `UUID` | `NULL, REFERENCES public.service_operations(id)` | Linked operation |
| `performed_by` | `UUID` | `NOT NULL, REFERENCES public.profiles(id)` | User who recorded movement |
| `notes` | `TEXT` | `NULL` | Transaction documentation |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Ledger timestamp |

### `public.part_requests`
Requests from mechanics for parts during repair.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Request ID |
| `service_order_id` | `UUID` | `NOT NULL, REFERENCES public.service_orders(id) ON DELETE CASCADE` | Service order |
| `operation_id` | `UUID` | `NOT NULL, REFERENCES public.service_operations(id) ON DELETE CASCADE` | Operation |
| `part_id` | `UUID` | `NOT NULL, REFERENCES public.spare_parts(id) ON DELETE RESTRICT` | Requested part |
| `mechanic_id` | `UUID` | `NOT NULL, REFERENCES public.profiles(id)` | Requesting mechanic |
| `quantity` | `NUMERIC(10,2)` | `NOT NULL CHECK (quantity > 0)` | Quantity needed |
| `status` | `part_request_status`| `NOT NULL DEFAULT 'requested'` | Status |
| `admin_notes` | `TEXT` | `NULL` | Admin review notes |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Request timestamp |
| `fulfilled_at` | `TIMESTAMPTZ` | `NULL` | Fulfillment timestamp |

---

## 3.9 Finance Domain

### `public.invoices`
Authoritative payable billing document snapshot.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Invoice ID |
| `invoice_number` | `TEXT` | `NOT NULL UNIQUE` | Human-readable code (e.g. `INV-202611-001`) |
| `service_order_id` | `UUID` | `NOT NULL UNIQUE, REFERENCES public.service_orders(id)` | Serviced order |
| `customer_id` | `UUID` | `NOT NULL, REFERENCES public.customers(id) ON DELETE RESTRICT` | Billed customer |
| `labor_total` | `BIGINT` | `NOT NULL DEFAULT 0 CHECK (labor_total >= 0)` | Labor sum in cents |
| `parts_total` | `BIGINT` | `NOT NULL DEFAULT 0 CHECK (parts_total >= 0)` | Parts sum in cents |
| `subtotal` | `BIGINT` | `NOT NULL CHECK (subtotal = labor_total + parts_total)` | Raw total |
| `tax_rate_percent` | `NUMERIC(5,2)` | `NOT NULL DEFAULT 11.00 CHECK (tax_rate_percent >= 0)` | Indonesian PPN or local tax |
| `tax_amount` | `BIGINT` | `NOT NULL DEFAULT 0 CHECK (tax_amount >= 0)` | Computed tax in cents |
| `discount_amount` | `BIGINT` | `NOT NULL DEFAULT 0 CHECK (discount_amount >= 0)` | Discount in cents |
| `final_total` | `BIGINT` | `NOT NULL CHECK (final_total >= 0)` | Final payable in cents |
| `paid_amount` | `BIGINT` | `NOT NULL DEFAULT 0 CHECK (paid_amount >= 0)` | Settled payments in cents |
| `status` | `invoice_status` | `NOT NULL DEFAULT 'draft'` | Current status |
| `issued_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Billing issuance timestamp |
| `due_date` | `DATE` | `NOT NULL` | Payment due date |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Creation timestamp |

### `public.invoice_items`
Snapshot line items frozen at invoice generation.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Item ID |
| `invoice_id` | `UUID` | `NOT NULL, REFERENCES public.invoices(id) ON DELETE CASCADE` | Parent invoice |
| `description` | `TEXT` | `NOT NULL` | Line title |
| `quantity` | `NUMERIC(10,2)` | `NOT NULL CHECK (quantity > 0)` | Quantity |
| `unit_price` | `BIGINT` | `NOT NULL CHECK (unit_price >= 0)` | Unit rate in cents |
| `line_total` | `BIGINT` | `NOT NULL CHECK (line_total >= 0)` | Line total in cents |

### `public.payments`
Immutable financial settlement records.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Payment ID |
| `payment_number` | `TEXT` | `NOT NULL UNIQUE` | Code (e.g. `PAY-202611-001`) |
| `invoice_id` | `UUID` | `NOT NULL, REFERENCES public.invoices(id) ON DELETE RESTRICT` | Target invoice |
| `amount` | `BIGINT` | `NOT NULL CHECK (amount > 0)` | Settled amount in cents |
| `payment_method` | `payment_method` | `NOT NULL` | Cash, Card, QRIS, Transfer |
| `reference_number`| `TEXT` | `NULL` | Bank / gateway transaction code |
| `change_returned` | `BIGINT` | `NOT NULL DEFAULT 0 CHECK (change_returned >= 0)` | Cash change returned in cents |
| `received_by` | `UUID` | `NOT NULL, REFERENCES public.profiles(id)` | Admin cashier |
| `paid_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Payment timestamp |

---

## 3.10 Workforce Domain

### `public.mechanic_compensation_rules`
Rules for calculating base salaries and operation commissions.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Rule ID |
| `mechanic_id` | `UUID` | `NOT NULL UNIQUE, REFERENCES public.profiles(id)` | Target mechanic |
| `base_salary_monthly`| `BIGINT` | `NOT NULL DEFAULT 0 CHECK (base_salary_monthly >= 0)` | Fixed base salary |
| `commission_rate_percent`| `NUMERIC(5,2)` | `NOT NULL DEFAULT 10.00 CHECK (commission_rate_percent BETWEEN 0 AND 100)` | Labor commission percentage |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT TRUE` | Active compensation rule |
| `effective_from` | `DATE` | `NOT NULL` | Effective start date |

### `public.mechanic_earnings`
Immutable ledger of earned incentives per completed operation.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `BIGSERIAL` | `PK` | Earning ID |
| `mechanic_id` | `UUID` | `NOT NULL, REFERENCES public.profiles(id)` | Beneficiary |
| `operation_id` | `UUID` | `NOT NULL, REFERENCES public.service_operations(id)` | Completed operation |
| `service_order_id`| `UUID` | `NOT NULL, REFERENCES public.service_orders(id)` | Service order |
| `labor_charge_total`| `BIGINT` | `NOT NULL CHECK (labor_charge_total >= 0)` | Labor billed |
| `contribution_percentage`| `NUMERIC(5,2)`| `NOT NULL` | Mechanic's split % |
| `commission_earned`| `BIGINT` | `NOT NULL CHECK (commission_earned >= 0)` | Calculated incentive in cents |
| `earned_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Timestamp when operation passed QC |

---

## 3.11 Quality and Handover Domain

### `public.qc_inspections`
Quality control verification before vehicle delivery.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | QC ID |
| `service_order_id` | `UUID` | `NOT NULL, REFERENCES public.service_orders(id) ON DELETE CASCADE` | Service order |
| `inspector_id` | `UUID` | `NOT NULL, REFERENCES public.profiles(id)` | QC Inspector |
| `status` | `qc_status` | `NOT NULL DEFAULT 'pending'` | QC state |
| `test_drive_performed`| `BOOLEAN` | `NOT NULL DEFAULT FALSE` | Road test verified |
| `checklist_results`| `JSONB` | `NOT NULL DEFAULT '{}'::jsonb` | Verified inspection points |
| `notes` | `TEXT` | `NULL` | Defect or approval notes |
| `inspected_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | QC timestamp |

### `public.vehicle_handovers`
Physical handover of vehicle back to customer.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Handover ID |
| `service_order_id` | `UUID` | `NOT NULL UNIQUE, REFERENCES public.service_orders(id)` | Serviced order |
| `handed_over_to` | `TEXT` | `NOT NULL` | Person receiving the vehicle |
| `handover_by` | `UUID` | `NOT NULL, REFERENCES public.profiles(id)` | Workshop staff |
| `customer_signature`| `TEXT` | `NULL` | Delivery acceptance signature |
| `delivered_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Handover timestamp |

---

## 3.12 Communication Domain

### `public.notifications`
Persistent user notifications.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Notification ID |
| `recipient_id` | `UUID` | `NOT NULL, REFERENCES public.profiles(id) ON DELETE CASCADE` | Recipient user |
| `type` | `notification_type`| `NOT NULL` | Notification category |
| `priority` | `notification_priority`| `NOT NULL DEFAULT 'normal'` | Urgency |
| `title` | `TEXT` | `NOT NULL` | Headline |
| `body` | `TEXT` | `NOT NULL` | Notification content |
| `action_url` | `TEXT` | `NULL` | Deep link route |
| `is_read` | `BOOLEAN` | `NOT NULL DEFAULT FALSE` | Read status |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Timestamp |

### `public.service_reminders`
Maintenance and scheduled checkup reminders.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PK DEFAULT gen_random_uuid()` | Reminder ID |
| `customer_id` | `UUID` | `NOT NULL, REFERENCES public.customers(id) ON DELETE CASCADE` | Target customer |
| `vehicle_id` | `UUID` | `NOT NULL, REFERENCES public.vehicles(id) ON DELETE CASCADE` | Target vehicle |
| `reminder_type` | `reminder_type` | `NOT NULL DEFAULT 'mileage_interval'` | Trigger type |
| `title` | `TEXT` | `NOT NULL` | Reminder headline |
| `due_date` | `DATE` | `NULL` | Due date for time-based reminder |
| `due_mileage` | `INT` | `NULL` | Due mileage for distance-based reminder |
| `status` | `reminder_status` | `NOT NULL DEFAULT 'active'` | Status |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Created timestamp |

---

# 4. Security Policies (Row Level Security)

RLS must be enabled on every table:
```sql
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workshop_bays ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inspection_findings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estimates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estimate_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estimate_authorizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operation_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.spare_parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.part_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mechanic_compensation_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mechanic_earnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qc_inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicle_handovers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_reminders ENABLE ROW LEVEL SECURITY;
```

### 4.1 Role Identification Helper Function
```sql
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS user_role AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;
```

### 4.2 Policy Rules Summary
1. **Admins**: Full `SELECT`, `INSERT`, `UPDATE`, `DELETE` across operational, fleet, and financial tables.
2. **Mechanics**:
   - `SELECT` assigned service orders, vehicles, operations, checklists, spare parts catalog.
   - `INSERT` inspection findings, part requests.
   - `UPDATE` operation progress and checklists assigned to them.
   - `SELECT` their own `mechanic_earnings` and notifications.
   - Strictly forbidden from modifying invoices, stock balances, or customer profiles.
3. **Customers**:
   - `SELECT` their own profile, registered vehicles, bookings, service orders, customer-facing inspections, authorized estimates, invoices, and payments.
   - `INSERT` new bookings and estimate authorizations.
   - Forbidden from viewing internal workshop notes, mechanic wages, purchase prices, or other customers' data.

---

# 5. Migration Strategy

- Supabase CLI manages migrations under `supabase/migrations/`.
- Every migration must be atomic, reproducible, and forward-compatible.
- Rollback scripts or tests accompany critical structural updates.
- All migrations are version-controlled in Git.
