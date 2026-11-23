# PitMate — Database Schema Specification

> **Document:** DATABASE_SCHEMA.md  
> **Status:** Active — Clean Slate  
> **Version:** 2.0  
> **Backend:** Supabase PostgreSQL 17 (`Cars-Workshop-App` / `kxvoeqwelcmcvdfwxduu`)  
> **Region:** Southeast Asia (Singapore, `ap-southeast-1`)  
> **Related:** PRD.md, ARCHITECTURE.md, DESIGN.md  

---

# 1. Overview and Design Principles

This document specifies the database design and conventions for the fresh PitMate v2.0 implementation.
Tables and schema migrations are introduced incrementally per milestone based on `PRD.md` and the verified prototype UI in `screens/`.

## 1.1 Core Principles

1. **Relational Integrity**: Foreign keys, check constraints, unique constraints, and non-null guarantees enforce business invariants at the PostgreSQL layer.
2. **Strict Row Level Security (RLS)**: Every table in `public` has Row Level Security enabled. Unauthenticated or cross-role access is denied by default.
3. **Monetary Precision**: All monetary values are represented as integers (`BIGINT`) in cents (minor currency units) to avoid floating-point calculation issues.
4. **Separation of Auth and Profiles**: `auth.users` handles authentication credentials; `public.profiles` contains user roles and application metadata linked via `profiles.id -> auth.users.id ON DELETE CASCADE`.
5. **Auditable Ledgers**: Inventory stock movements, payments, and workflow transitions maintain immutable historical audit trails.
6. **Clean Migrations**: All DDL changes are tracked via timestamped version-controlled migration files in `supabase/migrations/`.

---

# 2. Schema Roadmap by Milestone

| Milestone | Target Domain | Key Tables / Objects | Status |
|---|---|---|---|
| **M1** | Auth & Identity | `user_role` enum, `profiles`, `customer_type` enum, `customers`, `vehicles`, RLS policies, auth trigger | **Implemented** |
| **M2** | Customer Intake & Diagnosis | `bookings`, `service_orders`, `inspections`, `inspection_findings`, `estimates`, `estimate_items`, `estimate_authorizations` | **Implemented** |
| **M3** | Workshop Operations | `workshop_bays`, `service_order_tasks`, `mechanic_assignments`, `task_checklists`, `task_assistance_requests`, `service_order_additional_findings` | **Implemented** |
| **M4** | Inventory & Costing | `parts`, `inventory_balances`, `inventory_transactions`, `part_requests`, `service_task_part_consumptions`, `mechanic_compensation_profiles`, `mechanic_earnings`, `mechanic_earning_allocations`, `mechanic_payroll_adjustments` | **Implemented & Migrated** |
| **M5** | Invoicing & Finance | `invoices`, `invoice_items`, `payments` | Planned |
| **M6** | Customer Portal & Notifications | `notifications`, `maintenance_reminders` | Planned |

---

# 3. Environment & Connection

- **Project Ref:** `kxvoeqwelcmcvdfwxduu`
- **Host:** `db.kxvoeqwelcmcvdfwxduu.supabase.co`
- **PostgreSQL Version:** 17.11 (GA)
- **Tooling:** Supabase CLI linked via `supabase link --project-ref kxvoeqwelcmcvdfwxduu` and Antigravity Supabase MCP.

---

# 4. Milestone M1: Core Schema Specification

## 4.1 Enums

### `public.user_role`
Defines the three authorization personas:
- `'admin'`: Workshop owner, service advisors, cashiers with full administrative access.
- `'mechanic'`: Workshop floor mechanics and technicians.
- `'customer'`: Vehicle owners and fleet managers.

```sql
CREATE TYPE public.user_role AS ENUM ('admin', 'mechanic', 'customer');
```

### `public.customer_type`
Distinguishes individual car owners from corporate fleet accounts:
- `'individual'`: Retail customer.
- `'company'`: Corporate fleet or B2B account.

```sql
CREATE TYPE public.customer_type AS ENUM ('individual', 'company');
```

---

## 4.2 Tables

### 4.2.1 `public.profiles`
Extends `auth.users` with application-level identity, display information, and role assignments.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE` | Auth user ID |
| `role` | `public.user_role` | `NOT NULL DEFAULT 'customer'` | Role badge determining application access |
| `full_name` | `TEXT` | `NOT NULL` | Display name of the user |
| `phone_number` | `TEXT` | `UNIQUE` | Contact phone number |
| `avatar_url` | `TEXT` | `NULL` | Public avatar URL |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Record creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Automatic last-updated timestamp |

**Indexes:**
- `idx_profiles_role` ON `public.profiles(role)`

**Triggers:**
- `on_profiles_updated`: `BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();`
- `on_auth_user_created`: `AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();`

---

### 4.2.2 `public.customers`
Central customer registry supporting both authenticated app users (`profile_id IS NOT NULL`) and guest / walk-in clients (`is_guest = TRUE` or corporate contacts).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Unique customer ID |
| `profile_id` | `UUID` | `REFERENCES public.profiles(id) ON DELETE SET NULL` | Linked auth profile (if registered) |
| `full_name` | `TEXT` | `NOT NULL` | Customer or representative full name |
| `phone_number` | `TEXT` | `NOT NULL UNIQUE` | Normalized primary phone number |
| `email` | `TEXT` | `NULL` | Customer contact email |
| `customer_type` | `public.customer_type` | `NOT NULL DEFAULT 'individual'` | Account classification |
| `company_name` | `TEXT` | `NULL` | Company name if `customer_type = 'company'` |
| `is_guest` | `BOOLEAN` | `NOT NULL DEFAULT FALSE` | Flag for walk-in or unregistered customers |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Record creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Automatic last-updated timestamp |

**Indexes:**
- `idx_customers_profile_id` ON `public.customers(profile_id)`
- `idx_customers_phone_number` ON `public.customers(phone_number)`

**Triggers:**
- `on_customers_updated`: `BEFORE UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();`

---

### 4.2.3 `public.vehicles`
Vehicle registry tracking all customer automobiles serviced by the workshop.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Unique vehicle ID |
| `customer_id` | `UUID` | `NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT` | Vehicle owner customer reference |
| `license_plate` | `TEXT` | `NOT NULL`, `CONSTRAINT uq_license_plate_normalized UNIQUE` | Normalized vehicle license plate |
| `make` | `TEXT` | `NOT NULL` | Vehicle manufacturer (e.g. Toyota, Honda) |
| `model` | `TEXT` | `NOT NULL` | Vehicle model (e.g. Innova, Civic) |
| `year` | `INT` | `NOT NULL` | Manufacturing year |
| `vin` | `TEXT` | `NULL` | Vehicle Identification Number (chassis number) |
| `engine_type` | `TEXT` | `NULL` | Engine code or displacement |
| `transmission` | `TEXT` | `NULL` | Transmission type (Manual, Automatic, CVT) |
| `mileage` | `INT` | `NULL` | Last known odometer reading in kilometers |
| `color` | `TEXT` | `NULL` | Vehicle exterior color |
| `notes` | `TEXT` | `NULL` | Internal workshop notes or preferences |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Record creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Automatic last-updated timestamp |

**Indexes:**
- `idx_vehicles_customer_id` ON `public.vehicles(customer_id)`
- `idx_vehicles_license_plate` ON `public.vehicles(license_plate)`

**Triggers:**
- `on_vehicles_updated`: `BEFORE UPDATE ON public.vehicles FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();`

---

## 4.3 Database Functions & Triggers

### 4.3.1 `public.current_user_role()`
Helper function returning the current authenticated user's role from `public.profiles`.
Used inside RLS policies. Defined as `SECURITY DEFINER` with fixed `search_path = public` to ensure reliable resolution without search path hijacking.

```sql
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS public.user_role AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;
```

### 4.3.2 `public.handle_new_user()`
Trigger function executed upon `auth.users` insert. Automatically populates `public.profiles` using registration metadata.
Crucially defaults `role` strictly to `'customer'` so that users cannot self-escalate to `'admin'` or `'mechanic'` via client registration payload.

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone_number, avatar_url, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1), 'User'),
    NEW.raw_user_meta_data->>'phone_number',
    NEW.raw_user_meta_data->>'avatar_url',
    'customer'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

### 4.3.3 `public.handle_updated_at()`
Generic timestamp maintenance trigger executed on `BEFORE UPDATE`.

```sql
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## 4.4 Row Level Security (RLS) Policies

All tables have RLS enabled:
```sql
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
```

### 4.4.1 Policies for `public.profiles`
- **Users can view own profile**: `SELECT USING (auth.uid() = id)`
- **Users can update own profile**: `UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id AND role = (SELECT role FROM public.profiles WHERE id = auth.uid()))`
- **Admins can view and manage all profiles**: `ALL USING (public.current_user_role() = 'admin')`

### 4.4.2 Policies for `public.customers`
- **Admins full access on customers**: `ALL USING (public.current_user_role() = 'admin')`
- **Customers view own customer record**: `SELECT USING (profile_id = auth.uid())`
- **Customers update own customer record**: `UPDATE USING (profile_id = auth.uid())`
- **Mechanics view customers**: `SELECT USING (public.current_user_role() = 'mechanic')`

### 4.4.3 Policies for `public.vehicles`
- **Admins full access on vehicles**: `ALL USING (public.current_user_role() = 'admin')`
- **Customers view own vehicles**: `SELECT USING (customer_id IN (SELECT id FROM public.customers WHERE profile_id = auth.uid()))`
- **Customers insert own vehicles**: `INSERT WITH CHECK (customer_id IN (SELECT id FROM public.customers WHERE profile_id = auth.uid()))`
- **Customers update own vehicles**: `UPDATE USING (customer_id IN (SELECT id FROM public.customers WHERE profile_id = auth.uid()))`
- **Mechanics view vehicles**: `SELECT USING (public.current_user_role() = 'mechanic')`

---

## 4.5 Seed Data Contract

Development and testing environments are seeded via `supabase/seed.sql` with predictable test IDs:

- **Admin Account**: `admin@pitmate.com` (UUID: `00000000-0000-0000-0000-000000000001`)
- **Mechanic Account**: `mechanic@pitmate.com` (UUID: `00000000-0000-0000-0000-000000000002`)
- **Customer Account**: `customer@pitmate.com` (UUID: `00000000-0000-0000-0000-000000000003`)
- **Individual Customer 2**: `sarah.tan@example.com` (UUID: `00000000-0000-0000-0000-000000000004`)
- **Company Fleet Customer**: `PT Logistik Nusantara Prima`
- **Guest Walk-in Customer**: `Joko Walk-in Guest`
- **Vehicles**: Toyota Innova Reborn, Honda HR-V, Mitsubishi Pajero Sport, Isuzu Elf NMR 71, Suzuki Ertiga.

---

# 5. Milestone M2: Customer Intake & Diagnosis Schema Specification

## 5.1 Enums

### `public.booking_status`
```sql
CREATE TYPE public.booking_status AS ENUM (
  'pending', 'confirmed', 'cancelled', 'rescheduled', 'checked_in', 'rejected'
);
```

### `public.service_order_status`
```sql
CREATE TYPE public.service_order_status AS ENUM (
  'intake_pending', 'inspection_pending', 'inspection_in_progress', 'inspection_completed',
  'estimate_pending', 'estimate_approved', 'estimate_rejected',
  'in_progress', 'qc_pending', 'completed', 'closed', 'cancelled'
);
```

### `public.intake_type`
```sql
CREATE TYPE public.intake_type AS ENUM ('walk_in', 'booking');
```

### `public.inspection_status`
```sql
CREATE TYPE public.inspection_status AS ENUM ('assigned', 'in_progress', 'completed', 'reviewed');
```

### `public.finding_condition`
```sql
CREATE TYPE public.finding_condition AS ENUM ('good', 'fair', 'critical');
```

### `public.severity_level`
```sql
CREATE TYPE public.severity_level AS ENUM ('low', 'medium', 'urgent');
```

### `public.estimate_status`
```sql
CREATE TYPE public.estimate_status AS ENUM (
  'draft', 'sent', 'approved', 'partially_approved', 'rejected', 'superseded'
);
```

### `public.authorization_status`
```sql
CREATE TYPE public.authorization_status AS ENUM ('pending', 'approved', 'rejected', 'deferred');
```

---

## 5.2 Tables

### 5.2.1 `public.bookings`
Manages customer appointment reservations before vehicle arrival.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Booking ID |
| `customer_id` | `UUID` | `NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE` | Customer reference |
| `vehicle_id` | `UUID` | `NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE` | Vehicle reference |
| `booking_date` | `DATE` | `NOT NULL` | Requested service date |
| `time_slot` | `TEXT` | `NOT NULL` | Slot (e.g. 08:00 - 10:00) |
| `service_type` | `TEXT` | `NOT NULL` | Requested service (e.g. Periodic Service) |
| `customer_notes` | `TEXT` | `NULL` | Customer symptoms / remarks |
| `admin_notes` | `TEXT` | `NULL` | Internal workshop notes |
| `status` | `public.booking_status` | `NOT NULL DEFAULT 'pending'` | Current booking status |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Update timestamp |

**Indexes:**
- `idx_bookings_customer_id` ON `public.bookings(customer_id)`
- `idx_bookings_date` ON `public.bookings(booking_date, status)`

---

### 5.2.2 `public.service_orders`
The central workshop visit record created at vehicle arrival.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Service Order ID |
| `order_number` | `TEXT` | `NOT NULL UNIQUE` | Human-readable sequential ID (e.g. `SO-202611-0001`) |
| `customer_id` | `UUID` | `NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT` | Customer reference |
| `vehicle_id` | `UUID` | `NOT NULL REFERENCES public.vehicles(id) ON DELETE RESTRICT` | Vehicle reference |
| `booking_id` | `UUID` | `NULL REFERENCES public.bookings(id) ON DELETE SET NULL` | Origin booking (if appointment) |
| `intake_type` | `public.intake_type` | `NOT NULL DEFAULT 'walk_in'` | Intake origin |
| `odometer` | `INT` | `NOT NULL` | Odometer reading in KM at check-in |
| `customer_complaint` | `TEXT` | `NOT NULL` | Customer reported symptoms / requests |
| `fuel_level` | `TEXT` | `NULL` | Fuel gauge level (e.g. 1/2, Full) |
| `initial_notes` | `TEXT` | `NULL` | Exterior condition / damage observations |
| `status` | `public.service_order_status` | `NOT NULL DEFAULT 'inspection_pending'` | Lifecycle stage |
| `assigned_bay` | `TEXT` | `NULL` | Assigned service bay identifier |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Update timestamp |

**Invariants & Constraints:**
- **Single Active Order Invariant**: A vehicle cannot have multiple active service orders concurrently.
  ```sql
  CREATE UNIQUE INDEX idx_service_orders_single_active_vehicle
    ON public.service_orders (vehicle_id)
    WHERE status NOT IN ('completed', 'closed', 'cancelled');
  ```

---

### 5.2.3 `public.inspections`
Diagnostic inspection sessions performed on a checked-in vehicle.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Inspection ID |
| `service_order_id` | `UUID` | `NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE` | Service order reference |
| `mechanic_id` | `UUID` | `NULL REFERENCES public.profiles(id) ON DELETE SET NULL` | Assigned technician |
| `status` | `public.inspection_status` | `NOT NULL DEFAULT 'assigned'` | Inspection progress |
| `summary` | `TEXT` | `NULL` | Diagnostic summary |
| `started_at` | `TIMESTAMPTZ` | `NULL` | Start timestamp |
| `completed_at` | `TIMESTAMPTZ` | `NULL` | Submission timestamp |
| `reviewed_by` | `UUID` | `NULL REFERENCES public.profiles(id) ON DELETE SET NULL` | Reviewing service advisor / admin |
| `reviewed_at` | `TIMESTAMPTZ` | `NULL` | Review timestamp |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Update timestamp |

---

### 5.2.4 `public.inspection_findings`
Detailed itemized findings and evidence recorded during vehicle diagnosis.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Finding ID |
| `inspection_id` | `UUID` | `NOT NULL REFERENCES public.inspections(id) ON DELETE CASCADE` | Inspection session reference |
| `category` | `TEXT` | `NOT NULL` | System category (e.g. Powertrain, Brakes) |
| `item_name` | `TEXT` | `NOT NULL` | Checked item (e.g. Front Brake Pads) |
| `condition` | `public.finding_condition` | `NOT NULL DEFAULT 'good'` | Condition status |
| `severity` | `public.severity_level` | `NOT NULL DEFAULT 'low'` | Finding urgency |
| `notes` | `TEXT` | `NULL` | Mechanic observations |
| `photo_urls` | `TEXT[]` | `NULL` | Uploaded evidence photos |
| `recommended_action` | `TEXT` | `NULL` | Recommended repair / maintenance |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Creation timestamp |

---

### 5.2.5 `public.estimates`
Itemized repair estimates presented to customers for authorization.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Estimate ID |
| `service_order_id` | `UUID` | `NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE` | Service order reference |
| `inspection_id` | `UUID` | `NULL REFERENCES public.inspections(id) ON DELETE SET NULL` | Source inspection reference |
| `revision_number` | `INT` | `NOT NULL DEFAULT 1` | Revision sequence (1, 2, ...) |
| `status` | `public.estimate_status` | `NOT NULL DEFAULT 'draft'` | Estimate authorization status |
| `subtotal_cents` | `BIGINT` | `NOT NULL DEFAULT 0` | Parts + Labor subtotal in cents |
| `tax_cents` | `BIGINT` | `NOT NULL DEFAULT 0` | Tax amount in cents |
| `discount_cents` | `BIGINT` | `NOT NULL DEFAULT 0` | Applied discount in cents |
| `total_cents` | `BIGINT` | `NOT NULL DEFAULT 0` | Final total in cents |
| `notes` | `TEXT` | `NULL` | Terms or additional notes |
| `created_by` | `UUID` | `NULL REFERENCES public.profiles(id) ON DELETE SET NULL` | Creator admin |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Update timestamp |

**Constraints:**
- `CONSTRAINT uq_service_order_revision UNIQUE (service_order_id, revision_number)`

---

### 5.2.6 `public.estimate_items`
Itemized parts and labor operations proposed within an estimate.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Item ID |
| `estimate_id` | `UUID` | `NOT NULL REFERENCES public.estimates(id) ON DELETE CASCADE` | Estimate reference |
| `item_type` | `TEXT` | `NOT NULL DEFAULT 'labor'` | Type (`part`, `labor`, `package`) |
| `description` | `TEXT` | `NOT NULL` | Description of item / service |
| `quantity` | `INT` | `NOT NULL DEFAULT 1` | Quantity or labor units |
| `unit_price_cents`| `BIGINT` | `NOT NULL` | Price per unit in cents |
| `total_price_cents`| `BIGINT`| `NOT NULL` | Quantity * Unit Price in cents |
| `is_optional` | `BOOLEAN` | `NOT NULL DEFAULT FALSE` | Optional recommendation flag |
| `authorization_status` | `public.authorization_status` | `NOT NULL DEFAULT 'pending'` | Individual line authorization |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Creation timestamp |

---

### 5.2.7 `public.estimate_authorizations`
Immutable audit record of customer approval, rejection, or deferral.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Authorization ID |
| `estimate_id` | `UUID` | `NOT NULL REFERENCES public.estimates(id) ON DELETE CASCADE` | Estimate reference |
| `authorized_by` | `UUID` | `NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT` | Authorizing customer profile |
| `status` | `public.estimate_status` | `NOT NULL` | Decision (`approved`, `partially_approved`, `rejected`) |
| `signature_token`| `TEXT` | `NULL` | Verification / signature token |
| `notes` | `TEXT` | `NULL` | Customer feedback / rejection reason |
| `authorized_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Timestamp of authorization |

---

## 5.3 Database Functions & RPCs

### 5.3.1 `public.create_service_order_intake(...)`
Atomic vehicle intake transaction:
- Validates that the vehicle has no active service order.
- Generates sequential order number `SO-YYYYMM-XXXX`.
- If booking is provided, marks booking status as `'checked_in'`.
- Updates vehicle current mileage.
- Inserts `service_orders` record.
- Automatically inserts an initial `inspections` record in `'assigned'` status.

### 5.3.2 `public.submit_inspection(...)`
Atomic inspection submission:
- Verifies all mandatory checklist categories are addressed.
- Sets inspection status to `'completed'` and records `completed_at`.
- Updates service order status to `'estimate_pending'`.

### 5.3.3 `public.authorize_estimate(...)`
Atomic customer authorization:
- Validates authorizing customer owns the vehicle linked to the service order.
- Records immutable `estimate_authorizations` entry.
- Updates estimate status (`'approved'`, `'partially_approved'`, `'rejected'`).
- If approved, updates service order status to `'estimate_approved'`.

---

# 6. Milestone M3: Workshop Operations Schema Specification

## 6.1 Enums

### `public.bay_status`
Defines operational physical bay states:
- `'available'`: Ready to receive vehicle.
- `'occupied'`: Active vehicle currently positioned in bay.
- `'maintenance'`: Bay equipment undergoing calibration or repair.

### `public.task_status`
Defines operation lifecycle status:
- `'pending'`: Created, waiting for assignment or prerequisite.
- `'assigned'`: Mechanic assigned, ready to start.
- `'in_progress'`: Mechanic currently executing operation.
- `'paused'`: Temporarily suspended (waiting for parts, tools, assistance).
- `'completed'`: All tasks and checklists finished.
- `'blocked'`: Blocked by dependency or reported issue.

### `public.task_priority`
- `'low'`, `'medium'`, `'high'`, `'urgent'`

### `public.assistance_status`
- `'pending'`, `'accepted'`, `'resolved'`

---

## 6.2 Tables

### 6.2.1 `public.workshop_bays`
Physical service bays (5 fixed bays in workshop MVP).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Bay ID |
| `bay_number` | `INT` | `NOT NULL UNIQUE CHECK (bay_number BETWEEN 1 AND 5)` | Physical bay number (1-5) |
| `name` | `TEXT` | `NOT NULL` | Bay label (e.g., 'Bay 01 - Express') |
| `status` | `public.bay_status` | `NOT NULL DEFAULT 'available'` | Operational status |
| `current_service_order_id` | `UUID` | `REFERENCES public.service_orders(id) ON DELETE SET NULL` | Occupying service order |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Last updated timestamp |

### 6.2.2 `public.service_order_tasks`
Discrete executable operations attached to a service order.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Task ID |
| `service_order_id` | `UUID` | `NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE` | Service order reference |
| `estimate_item_id` | `UUID` | `REFERENCES public.estimate_items(id) ON DELETE SET NULL` | Originating authorized estimate line |
| `title` | `TEXT` | `NOT NULL` | Operation title (e.g., 'Front Brake Pad Replacement') |
| `description` | `TEXT` | `NULL` | Work instructions and torque specifications |
| `estimated_duration_minutes` | `INT` | `NOT NULL DEFAULT 60` | Estimated execution time in minutes |
| `actual_duration_minutes` | `INT` | `NOT NULL DEFAULT 0` | Elapsed execution time in minutes |
| `priority` | `public.task_priority` | `NOT NULL DEFAULT 'medium'` | Priority level |
| `status` | `public.task_status` | `NOT NULL DEFAULT 'pending'` | Current task status |
| `sequence_order` | `INT` | `NOT NULL DEFAULT 1` | Execution sequence |
| `depends_on_task_id` | `UUID` | `REFERENCES public.service_order_tasks(id) ON DELETE SET NULL` | Prerequisite task dependency |
| `assigned_mechanic_id` | `UUID` | `REFERENCES public.profiles(id) ON DELETE SET NULL` | Assigned lead technician |
| `pause_reason` | `TEXT` | `NULL` | Reason when status = `'paused'` |
| `started_at` | `TIMESTAMPTZ` | `NULL` | Time work started |
| `paused_at` | `TIMESTAMPTZ` | `NULL` | Time work was paused |
| `completed_at` | `TIMESTAMPTZ` | `NULL` | Time work was completed |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Record creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Last updated timestamp |

### 6.2.3 `public.task_checklists`
Step-by-step technical items required to complete an operation.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Checklist item ID |
| `task_id` | `UUID` | `NOT NULL REFERENCES public.service_order_tasks(id) ON DELETE CASCADE` | Task reference |
| `item_description` | `TEXT` | `NOT NULL` | Action description (e.g. 'Torque lug nuts to 108 Nm') |
| `is_completed` | `BOOLEAN` | `NOT NULL DEFAULT FALSE` | Completion checkbox state |
| `completed_at` | `TIMESTAMPTZ` | `NULL` | Completion timestamp |
| `completed_by` | `UUID` | `REFERENCES public.profiles(id) ON DELETE SET NULL` | Profile ID of completing mechanic |

### 6.2.4 `public.mechanic_assignments`
Assignment ledger linking mechanics to service orders and tasks.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Assignment ID |
| `service_order_id` | `UUID` | `NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE` | Service order reference |
| `task_id` | `UUID` | `REFERENCES public.service_order_tasks(id) ON DELETE CASCADE` | Specific task (if task-level) |
| `mechanic_id` | `UUID` | `NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT` | Assigned mechanic profile |
| `is_lead` | `BOOLEAN` | `NOT NULL DEFAULT FALSE` | Whether designated lead for the vehicle/order |
| `role_description` | `TEXT` | `NULL` | Operational notes or incentive share notes |
| `assigned_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Assignment timestamp |

### 6.2.5 `public.task_assistance_requests`
Mechanic assistance coordination.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Request ID |
| `task_id` | `UUID` | `NOT NULL REFERENCES public.service_order_tasks(id) ON DELETE CASCADE` | Task requesting assistance |
| `requested_by` | `UUID` | `NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE` | Initiating mechanic |
| `helper_mechanic_id` | `UUID` | `REFERENCES public.profiles(id) ON DELETE SET NULL` | Assigned helper |
| `reason` | `TEXT` | `NOT NULL` | Assistance reason (e.g. 'Two-person bleeder operation') |
| `status` | `public.assistance_status` | `NOT NULL DEFAULT 'pending'` | Request status |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Creation timestamp |
| `resolved_at` | `TIMESTAMPTZ` | `NULL` | Resolution timestamp |

### 6.2.6 `public.service_order_additional_findings`
Mechanic discovery during active repair execution.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Finding ID |
| `service_order_id` | `UUID` | `NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE` | Service order reference |
| `task_id` | `UUID` | `REFERENCES public.service_order_tasks(id) ON DELETE SET NULL` | Related operation |
| `reported_by` | `UUID` | `NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE` | Reporting mechanic |
| `title` | `TEXT` | `NOT NULL` | Finding title |
| `description` | `TEXT` | `NOT NULL` | Finding details and observations |
| `severity` | `public.severity_level` | `NOT NULL DEFAULT 'medium'` | Severity level |
| `status` | `TEXT` | `NOT NULL DEFAULT 'reported'` | Status (`reported`, `reviewed`, `approved`) |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Creation timestamp |

---

## 6.3 Database Functions & RPCs

### 6.3.1 `public.assign_vehicle_bay(...)`
Atomic bay allocation with conflict prevention:
- Verifies target bay exists and is not occupied by another active order.
- Releases previous bay held by the service order.
- Sets bay status to `'occupied'` and updates `service_orders.assigned_bay`.

### 6.3.2 `public.dispatch_order_operations(...)`
Dispatches service order from `estimate_approved` to `in_progress`:
- Generates `service_order_tasks` and child `task_checklists`.
- Records lead and supporting mechanic assignments in `mechanic_assignments`.
- Sets service order status to `'in_progress'`.

### 6.3.3 `public.start_task_operation(...)`
Atomic operation start with dependency validation:
- Checks `depends_on_task_id`: if present, verifies dependency status is `'completed'`. Raises exception if prerequisite is incomplete.
- Sets task status to `'in_progress'`, records `started_at`.

### 6.3.4 `public.pause_task_operation(...)` & `resume_task_operation(...)`
Transitions task status between `'in_progress'` and `'paused'` with audit reason.

### 6.3.5 `public.complete_task_operation(...)`
Atomic task completion:
- Verifies all checklist items for the task are marked completed.
- Sets task status to `'completed'` and records `completed_at`.
- Checks if all tasks for the service order are finished. If all complete, updates `service_orders.status = 'qc_pending'`.

### 6.3.6 `public.request_task_assistance(...)` & `report_additional_finding(...)`
Records assistance requests and active repair discoveries.

---

# 7. Milestone M4: Inventory & Costing Schema Specification

## 7.1 Enums

### `public.inventory_transaction_type`
Stock movement ledger classifications:
- `'receiving'`: Physical stock intake from supplier with purchase cost recalculation.
- `'adjustment'`: Manual stock reconciliation or audit correction.
- `'reservation'`: Holding stock for an approved or in-progress service order task.
- `'reservation_release'`: Canceling or modifying reserved allocation.
- `'issue'`: Dispatching parts from inventory storage to workshop floor.
- `'consumption'`: Actual parts installed/consumed into customer vehicle.
- `'return'`: Unused parts returned to stock balance.
- `'damaged'`: Scrapped or damaged inventory write-off.

```sql
CREATE TYPE public.inventory_transaction_type AS ENUM (
  'receiving',
  'adjustment',
  'reservation',
  'reservation_release',
  'issue',
  'consumption',
  'return',
  'damaged'
);
```

### `public.part_request_status`
Lifecycle states for mechanic-initiated part requests:
- `'pending'`: Submitted by mechanic, awaiting admin action.
- `'fulfilled'`: Fulfilled in full.
- `'partially_fulfilled'`: Available stock allocated partially.
- `'rejected'`: Request rejected by workshop administration.
- `'unavailable'`: Stock out of inventory, required supplier procurement.

```sql
CREATE TYPE public.part_request_status AS ENUM (
  'pending',
  'fulfilled',
  'partially_fulfilled',
  'rejected',
  'unavailable'
);
```

### `public.earning_status`
Lifecycle for mechanic earned compensation:
- `'accrued'`: Auto-calculated upon completed eligible task.
- `'approved'`: Verified by admin.
- `'paid'`: Disbursed in payroll period.
- `'adjusted'`: Audited manual adjustment.

```sql
CREATE TYPE public.earning_status AS ENUM (
  'accrued',
  'approved',
  'paid',
  'adjusted'
);
```

---

## 7.2 Tables

### 7.2.1 `public.parts`
Part catalog containing SKU, pricing, measurement units, and safety stock thresholds.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Unique part identifier |
| `sku` | `TEXT` | `NOT NULL UNIQUE` | Unique SKU / Part code |
| `name` | `TEXT` | `NOT NULL` | Descriptive part name |
| `category` | `TEXT` | `NOT NULL` | Category (e.g. lubricants, filters, brakes) |
| `unit_of_measurement` | `TEXT` | `NOT NULL DEFAULT 'pcs'` | Unit label (e.g. pcs, liter, bottle) |
| `purchase_cost_cents` | `BIGINT` | `NOT NULL DEFAULT 0 CHECK (purchase_cost_cents >= 0)` | Weighted-average purchase cost |
| `selling_price_cents` | `BIGINT` | `NOT NULL DEFAULT 0 CHECK (selling_price_cents >= 0)` | Customer retail billing price |
| `minimum_stock` | `INT` | `NOT NULL DEFAULT 0 CHECK (minimum_stock >= 0)` | Low-stock threshold |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Last update timestamp |

### 7.2.2 `public.inventory_balances`
Maintained operational quantities per part. Prevents negative available stock via generated column & check constraint.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `part_id` | `UUID` | `PRIMARY KEY REFERENCES public.parts(id) ON DELETE CASCADE` | Part reference |
| `quantity_on_hand` | `INT` | `NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0)` | Total physical units in warehouse |
| `quantity_reserved` | `INT` | `NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0)` | Units committed to active jobs |
| `quantity_available` | `INT` | `GENERATED ALWAYS AS (quantity_on_hand - quantity_reserved) STORED CHECK (quantity_on_hand - quantity_reserved >= 0)` | Available for new reservation |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Last updated timestamp |

### 7.2.3 `public.inventory_transactions`
Immutable, append-only stock movement ledger providing complete auditable history.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Movement transaction ID |
| `part_id` | `UUID` | `NOT NULL REFERENCES public.parts(id) ON DELETE RESTRICT` | Part reference |
| `transaction_type` | `public.inventory_transaction_type` | `NOT NULL` | Ledger event type |
| `quantity_change` | `INT` | `NOT NULL` | Net change to physical/reserved stock |
| `balance_after_on_hand` | `INT` | `NOT NULL` | Snapshot of physical stock after event |
| `balance_after_reserved` | `INT` | `NOT NULL` | Snapshot of reserved stock after event |
| `unit_cost_cents` | `BIGINT` | `NOT NULL DEFAULT 0` | Valuation unit cost at time of event |
| `total_cost_cents` | `BIGINT` | `NOT NULL DEFAULT 0` | Valuation total amount |
| `reason` | `TEXT` | `NULL` | Compulsory for adjustments and write-offs |
| `reference_id` | `TEXT` | `NULL` | Traceability ID (order ID, task ID, PO reference) |
| `performed_by` | `UUID` | `NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT` | User executing movement |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Audit timestamp |

### 7.2.4 `public.part_requests`
Coordination queue allowing mechanics on the floor to request stock for specific operations.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Part request identifier |
| `service_order_id` | `UUID` | `NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE` | Service order reference |
| `task_id` | `UUID` | `REFERENCES public.service_order_tasks(id) ON DELETE SET NULL` | Target operation |
| `part_id` | `UUID` | `NOT NULL REFERENCES public.parts(id) ON DELETE RESTRICT` | Requested part |
| `requested_by` | `UUID` | `NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT` | Requesting mechanic profile |
| `quantity_requested` | `INT` | `NOT NULL CHECK (quantity_requested > 0)` | Quantity needed |
| `quantity_fulfilled` | `INT` | `NOT NULL DEFAULT 0 CHECK (quantity_fulfilled >= 0)` | Quantity issued by admin |
| `status` | `public.part_request_status` | `NOT NULL DEFAULT 'pending'` | Current fulfillment status |
| `notes` | `TEXT` | `NULL` | Mechanic notes |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Submission timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Last update timestamp |

### 7.2.5 `public.service_task_part_consumptions`
Direct link between an operation and actual physical stock consumed and returned.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Consumption line ID |
| `service_order_id` | `UUID` | `NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE` | Service order reference |
| `task_id` | `UUID` | `NOT NULL REFERENCES public.service_order_tasks(id) ON DELETE CASCADE` | Operation reference |
| `part_id` | `UUID` | `NOT NULL REFERENCES public.parts(id) ON DELETE RESTRICT` | Part reference |
| `quantity_issued` | `INT` | `NOT NULL DEFAULT 0 CHECK (quantity_issued >= 0)` | Units issued to mechanic |
| `quantity_consumed` | `INT` | `NOT NULL DEFAULT 0 CHECK (quantity_consumed >= 0)` | Units actually consumed |
| `quantity_returned` | `INT` | `NOT NULL DEFAULT 0 CHECK (quantity_returned >= 0)` | Units returned unused |
| `unit_cost_cents` | `BIGINT` | `NOT NULL` | Historical purchase cost valuation |
| `total_cost_cents` | `BIGINT` | `NOT NULL` | Total cost attributed to operation |
| `recorded_by` | `UUID` | `NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT` | Mechanic or admin |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Record timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Last updated timestamp |

### 7.2.6 `public.mechanic_compensation_profiles`
Monthly salary and default incentive parameters per technician.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `mechanic_id` | `UUID` | `PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE` | Mechanic profile ID |
| `monthly_base_salary_cents` | `BIGINT` | `NOT NULL DEFAULT 0 CHECK (monthly_base_salary_cents >= 0)` | Monthly guaranteed base pay |
| `standard_incentive_percent` | `NUMERIC(5,2)` | `NOT NULL DEFAULT 10.00 CHECK (standard_incentive_percent >= 0)` | Default incentive percentage |
| `is_active` | `BOOLEAN` | `NOT NULL DEFAULT TRUE` | Active employment status |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Last updated timestamp |

### 7.2.7 `public.mechanic_earnings`
Accrued incentive pool generated from completed eligible service operations.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Earning event ID |
| `service_order_id` | `UUID` | `NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE` | Service order reference |
| `task_id` | `UUID` | `NOT NULL REFERENCES public.service_order_tasks(id) ON DELETE CASCADE` | Completed task reference |
| `total_eligible_labor_cents` | `BIGINT` | `NOT NULL CHECK (total_eligible_labor_cents >= 0)` | Labor revenue snapshot |
| `total_incentive_pool_cents` | `BIGINT` | `NOT NULL CHECK (total_incentive_pool_cents >= 0)` | Total incentive generated |
| `status` | `public.earning_status` | `NOT NULL DEFAULT 'accrued'` | Earning lifecycle |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Earning timestamp |

### 7.2.8 `public.mechanic_earning_allocations`
Split distribution of task incentives among lead and contributing mechanics.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Allocation record ID |
| `earning_id` | `UUID` | `NOT NULL REFERENCES public.mechanic_earnings(id) ON DELETE CASCADE` | Parent incentive pool |
| `mechanic_id` | `UUID` | `NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT` | Earning recipient |
| `split_percentage` | `NUMERIC(5,2)` | `NOT NULL CHECK (split_percentage > 0 AND split_percentage <= 100)` | Contribution percentage |
| `allocated_cents` | `BIGINT` | `NOT NULL CHECK (allocated_cents >= 0)` | Minor currency amount |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Creation timestamp |

### 7.2.9 `public.mechanic_payroll_adjustments`
Auditable manual compensation corrections, deductions, or bonuses.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Adjustment record ID |
| `mechanic_id` | `UUID` | `NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT` | Technician recipient |
| `amount_cents` | `BIGINT` | `NOT NULL` | Positive (bonus) or negative (deduction) |
| `reason` | `TEXT` | `NOT NULL` | Audit explanation |
| `adjusted_by` | `UUID` | `NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT` | Admin profile ID |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT NOW()` | Timestamp |

---

## 7.3 Database Functions & RPCs

### 7.3.1 `public.receive_stock(...)`
Atomic stock receipt with weighted-average valuation:
- Recalculates `parts.purchase_cost_cents = ((current_on_hand * current_avg_cost) + (qty * unit_cost)) / (current_on_hand + qty)`.
- Increments `inventory_balances.quantity_on_hand`.
- Appends to `inventory_transactions`.

### 7.3.2 `public.adjust_stock(...)`
Manual stock reconciliation with required audit reason. Updates `quantity_on_hand` and inserts into `inventory_transactions`.

### 7.3.3 `public.reserve_stock_for_task(...)`
Allocates stock for an approved service task:
- Validates `quantity <= quantity_available`.
- Increments `inventory_balances.quantity_reserved`.
- Appends `reservation` ledger entry.

### 7.3.4 `public.request_part_for_task(...)`
Mechanic floor request creating a `part_requests` record.

### 7.3.5 `public.fulfill_part_request(...)`
Admin fulfillment (full or partial):
- Transfers quantity from available/reserved to issued.
- Updates `part_requests` status (`fulfilled` or `partially_fulfilled`).
- Creates consumption ledger record.

### 7.3.6 `public.consume_and_return_parts(...)`
Records actual parts used vs returned:
- Decrements physical `quantity_on_hand` by consumed units.
- Releases reserved units.
- Adds unused units back to available stock.
- Inserts `service_task_part_consumptions` and `inventory_transactions`.

### 7.3.7 `public.generate_task_mechanic_incentives(...)`
Triggered on completed eligible task:
- Validates task status is `'completed'`.
- Determines labor revenue and incentive pool.
- Splits pool among assigned mechanics (from `mechanic_assignments`).
- Inserts `mechanic_earnings` and `mechanic_earning_allocations`.

### 7.3.8 `public.adjust_mechanic_compensation(...)`
Admin adjustment creating an auditable `mechanic_payroll_adjustments` entry.


