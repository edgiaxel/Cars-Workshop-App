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

| Milestone | Target Domain | Key Tables / Objects |
|---|---|---|
| **M1** | Auth & Identity | `user_role` enum, `profiles`, role check functions, RLS policies |
| **M2** | Customer Intake & Diagnosis | `customers`, `vehicles`, `bookings`, `service_orders`, `inspections`, `estimates` |
| **M3** | Workshop Operations | `workshop_bays`, `service_order_tasks`, `mechanic_assignments` |
| **M4** | Inventory & Costing | `parts`, `inventory_transactions`, `part_requests` |
| **M5** | Invoicing & Finance | `invoices`, `invoice_items`, `payments` |
| **M6** | Customer Portal & Notifications | `notifications`, `maintenance_reminders` |

---

# 3. Environment & Connection

- **Project Ref:** `kxvoeqwelcmcvdfwxduu`
- **Host:** `db.kxvoeqwelcmcvdfwxduu.supabase.co`
- **PostgreSQL Version:** 17.11 (GA)
- **Tooling:** Supabase CLI linked via `supabase link --project-ref kxvoeqwelcmcvdfwxduu` and Antigravity Supabase MCP.
