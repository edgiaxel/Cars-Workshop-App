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
| **M2** | Customer Intake & Diagnosis | `bookings`, `service_orders`, `inspections`, `estimates` | Planned |
| **M3** | Workshop Operations | `workshop_bays`, `service_order_tasks`, `mechanic_assignments` | Planned |
| **M4** | Inventory & Costing | `parts`, `inventory_transactions`, `part_requests` | Planned |
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
