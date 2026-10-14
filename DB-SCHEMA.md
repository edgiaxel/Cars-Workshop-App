# PitMate — Database Schema

## 1. Purpose

This document defines the PostgreSQL database schema for PitMate.

The database is implemented using:

- Supabase PostgreSQL
- Supabase Auth
- PostgreSQL Row Level Security (RLS)

The database is designed around a single physical workshop and three application roles:

```text
admin
mechanic
customer
```

This document is the database source of truth for:

- Tables
- Columns
- Relationships
- Constraints
- Enumerations
- Indexes
- Security policies
- Operational workflows
- Seed-data expectations

Database changes must be implemented through Supabase migrations.

---

# 2. Database Design Principles

## 2.0 Seed Data Reference 

Admin - Christian Horner - admin@pitmate.co
Mechanic1 - Max Verstappen - verstappen@pitmate.co
Mechanic2 - Sergio Perez - perez@pitmate.co
Probably few customer
BMW M Motorsport - company - motorsport@bmw-m.com
Cars - BMW M Hybrid V8 number 15 and 20; BMW M4 GT3 Evo Number 32 and 46
Hmm Aston Martin - company - motorsport@astonmartin.com 
Cars - Valkyrie number 007 and 009
Axel Zeed - individual - lexazeed@gmail.com - here is my actual email, we need to test either reset password or real email stuff later so keep this real
Cars - BMW M3 Touring Competition G81; Toyota Innova Zenix , Ford Raptor
 
Password (All users): 000000

## 2.1 Auth and Application Data Are Separate

Supabase Auth owns authentication information.

Application-specific user information is stored in:

```text
public.profiles
```

The relationship is:

```text
auth.users.id
      │
      └── public.profiles.id
```

`profiles.id` must reference `auth.users.id` with `ON DELETE CASCADE`.

---

## 2.2 Roles

PitMate supports:

```text
admin
mechanic
customer
```

The user's application role is stored in `profiles.role`.

Authorization must ultimately be enforced through PostgreSQL RLS.

The Flutter UI may hide features based on role, but UI restrictions are not considered a security boundary.

---

# 3. Enumerations

## user_role

```text
admin
mechanic
customer
```

## customer_type

```text
individual
company
```

## booking_status

```text
requested
approved
rejected
scheduled
cancelled
completed
```

## service_status

```text
requested
approved
scheduled
inspection
diagnosis
waiting_for_approval
waiting_for_parts
in_progress
completion_review
completed
payment
closed
cancelled
```

## task_status

```text
pending
in_progress
completed
blocked
cancelled
```

## part_request_status

```text
requested
approved
rejected
fulfilled
cancelled
```

## inventory_transaction_type

```text
initial_stock
purchase
service_usage
adjustment
return
damaged
```

## notification_type

```text
booking
service
inventory
payment
reminder
system
```

## notification_priority

```text
low
normal
high
urgent
```

## reminder_type

```text
service
maintenance
inspection
custom
```

## reminder_status

```text
pending
completed
dismissed
cancelled
```

---

# 4. `profiles`

Stores application-level information about authenticated users.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK, references auth.users |
| role | user_role | NOT NULL |
| full_name | text | NOT NULL |
| phone | text | nullable |
| avatar_url | text | nullable |
| is_active | boolean | NOT NULL, default true |
| created_at | timestamptz | NOT NULL |
| updated_at | timestamptz | NOT NULL |

The user's email remains owned by Supabase Auth.

---

# 5. `customers`

Stores customer-specific information.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| profile_id | uuid | UNIQUE, FK profiles |
| customer_type | customer_type | NOT NULL |
| company_name | text | nullable |
| address | text | nullable |
| notes | text | nullable |
| created_at | timestamptz | NOT NULL |
| updated_at | timestamptz | NOT NULL |

For individual customers, `company_name` is NULL.

For company customers, `company_name` is required.

---

# 6. `mechanics`

Stores mechanic-specific information.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| profile_id | uuid | UNIQUE, FK profiles |
| employee_code | text | UNIQUE, NOT NULL |
| specialization | text | nullable |
| hourly_rate | numeric | NOT NULL |
| compensation_percentage | numeric | NOT NULL |
| hire_date | date | nullable |
| created_at | timestamptz | NOT NULL |
| updated_at | timestamptz | NOT NULL |

`compensation_percentage` represents the percentage of applicable labor assigned as mechanic earnings.

---

# 7. `vehicles`

Stores customer vehicles.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| customer_id | uuid | FK customers |
| make | text | NOT NULL |
| model | text | NOT NULL |
| variant | text | nullable |
| model_year | integer | nullable |
| license_plate | text | nullable |
| vin | text | nullable |
| vehicle_number | text | nullable |
| mileage_km | integer | default 0 |
| color | text | nullable |
| notes | text | nullable |
| created_at | timestamptz | NOT NULL |
| updated_at | timestamptz | NOT NULL |

`vehicle_number` is useful for motorsport vehicles such as:

```text
BMW M Hybrid V8 #15
BMW M Hybrid V8 #20
BMW M4 GT3 Evo #32
```

---

# 8. `bookings`

Represents customer service requests before or during conversion into service orders.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| customer_id | uuid | FK customers |
| vehicle_id | uuid | FK vehicles |
| requested_service | text | NOT NULL |
| description | text | nullable |
| preferred_date | date | nullable |
| preferred_time | time | nullable |
| status | booking_status | NOT NULL |
| admin_notes | text | nullable |
| created_at | timestamptz | NOT NULL |
| updated_at | timestamptz | NOT NULL |

---

# 9. `service_orders`

Central operational entity for workshop work.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| order_number | text | UNIQUE, NOT NULL |
| booking_id | uuid | nullable, FK bookings |
| customer_id | uuid | FK customers |
| vehicle_id | uuid | FK vehicles |
| title | text | NOT NULL |
| description | text | nullable |
| status | service_status | NOT NULL |
| scheduled_start | timestamptz | nullable |
| scheduled_end | timestamptz | nullable |
| odometer_km | integer | nullable |
| estimated_total | numeric | default 0 |
| final_total | numeric | nullable |
| customer_approved | boolean | default false |
| completed_at | timestamptz | nullable |
| closed_at | timestamptz | nullable |
| created_at | timestamptz | NOT NULL |
| updated_at | timestamptz | NOT NULL |

---

# 10. `service_status_history`

Stores every service-status transition.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| service_order_id | uuid | FK service_orders |
| previous_status | service_status | nullable |
| new_status | service_status | NOT NULL |
| changed_by | uuid | FK profiles |
| notes | text | nullable |
| created_at | timestamptz | NOT NULL |

This allows the application to display a service timeline.

---

# 11. `service_assignments`

Connects mechanics to service orders.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| service_order_id | uuid | FK service_orders |
| mechanic_id | uuid | FK mechanics |
| assigned_by | uuid | FK profiles |
| role_description | text | nullable |
| assigned_at | timestamptz | NOT NULL |
| completed_at | timestamptz | nullable |

One service order may have multiple mechanics.

---

# 12. `task_templates`

Reusable task definitions.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| name | text | NOT NULL |
| description | text | nullable |
| category | text | nullable |
| estimated_minutes | integer | nullable |
| is_active | boolean | default true |
| created_at | timestamptz | NOT NULL |

Examples:

```text
Engine Oil Inspection
Brake System Inspection
Brake Pad Replacement
Tire Pressure Check
Wheel Alignment
Engine Diagnostic Inspection
Cooling System Inspection
```

---

# 13. `service_tasks`

Tasks belonging to a specific service order.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| service_order_id | uuid | FK service_orders |
| assigned_mechanic_id | uuid | nullable, FK mechanics |
| template_id | uuid | nullable, FK task_templates |
| title | text | NOT NULL |
| description | text | nullable |
| status | task_status | NOT NULL |
| estimated_minutes | integer | nullable |
| actual_minutes | integer | nullable |
| started_at | timestamptz | nullable |
| completed_at | timestamptz | nullable |
| notes | text | nullable |
| created_at | timestamptz | NOT NULL |
| updated_at | timestamptz | NOT NULL |

Tasks may originate from templates or be created specifically for one service.

---

# 14. `task_checklists`

Checklist items belonging to service tasks.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| service_task_id | uuid | FK service_tasks |
| item_text | text | NOT NULL |
| is_completed | boolean | default false |
| completed_by | uuid | nullable, FK profiles |
| completed_at | timestamptz | nullable |
| sort_order | integer | default 0 |

---

# 15. `spare_parts`

Master definitions of workshop parts.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| sku | text | UNIQUE, NOT NULL |
| name | text | NOT NULL |
| category | text | NOT NULL |
| brand | text | nullable |
| description | text | nullable |
| unit | text | NOT NULL |
| unit_cost | numeric | NOT NULL |
| selling_price | numeric | NOT NULL |
| minimum_stock | integer | default 0 |
| is_active | boolean | default true |
| created_at | timestamptz | NOT NULL |
| updated_at | timestamptz | NOT NULL |

---

# 16. `inventory_transactions`

Inventory is represented through transactions rather than storing only a mutable quantity.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| spare_part_id | uuid | FK spare_parts |
| transaction_type | inventory_transaction_type | NOT NULL |
| quantity | integer | NOT NULL |
| unit_cost | numeric | nullable |
| service_order_id | uuid | nullable, FK service_orders |
| performed_by | uuid | FK profiles |
| notes | text | nullable |
| created_at | timestamptz | NOT NULL |

Current stock is derived from inventory transactions.

Positive quantities increase stock.

Negative quantities decrease stock.

---

# 17. `part_requests`

Mechanics can request parts for a service.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| service_order_id | uuid | FK service_orders |
| requested_by | uuid | FK mechanics |
| spare_part_id | uuid | FK spare_parts |
| quantity | integer | NOT NULL |
| status | part_request_status | NOT NULL |
| approved_by | uuid | nullable, FK profiles |
| notes | text | nullable |
| created_at | timestamptz | NOT NULL |
| updated_at | timestamptz | NOT NULL |

---

# 18. `service_parts`

Records actual parts consumed by a service order.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| service_order_id | uuid | FK service_orders |
| spare_part_id | uuid | FK spare_parts |
| quantity | integer | NOT NULL |
| unit_price | numeric | NOT NULL |
| added_by | uuid | FK profiles |
| created_at | timestamptz | NOT NULL |

This represents parts actually charged to the customer.

---

# 19. `service_costs`

Stores individual cost components.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| service_order_id | uuid | FK service_orders |
| category | text | NOT NULL |
| description | text | NOT NULL |
| quantity | numeric | default 1 |
| unit_price | numeric | NOT NULL |
| total_amount | numeric | NOT NULL |
| is_estimate | boolean | default true |
| created_at | timestamptz | NOT NULL |

Typical categories:

```text
labor
parts
additional
discount
```

---

# 20. `mechanic_earnings`

Records mechanic compensation associated with completed work.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| mechanic_id | uuid | FK mechanics |
| service_order_id | uuid | FK service_orders |
| labor_amount | numeric | NOT NULL |
| compensation_percentage | numeric | NOT NULL |
| earnings_amount | numeric | NOT NULL |
| status | text | NOT NULL |
| created_at | timestamptz | NOT NULL |
| paid_at | timestamptz | nullable |

---

# 21. `notifications`

Stores user notifications.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| recipient_id | uuid | FK profiles |
| type | notification_type | NOT NULL |
| priority | notification_priority | NOT NULL |
| title | text | NOT NULL |
| message | text | NOT NULL |
| service_order_id | uuid | nullable, FK service_orders |
| is_read | boolean | default false |
| read_at | timestamptz | nullable |
| created_at | timestamptz | NOT NULL |

---

# 22. `service_reminders`

Stores customer service reminders.

| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| customer_id | uuid | FK customers |
| vehicle_id | uuid | FK vehicles |
| reminder_type | reminder_type | NOT NULL |
| title | text | NOT NULL |
| description | text | nullable |
| due_date | date | nullable |
| due_mileage_km | integer | nullable |
| status | reminder_status | NOT NULL |
| completed_at | timestamptz | nullable |
| created_at | timestamptz | NOT NULL |

---

# 23. Relationships

Main relationships:

```text
auth.users
    1 ─── 1 profiles

profiles
    1 ─── 0..1 customers

profiles
    1 ─── 0..1 mechanics

customers
    1 ─── N vehicles

customers
    1 ─── N bookings

vehicles
    1 ─── N bookings

bookings
    1 ─── 0..1 service_orders

customers
    1 ─── N service_orders

vehicles
    1 ─── N service_orders

service_orders
    1 ─── N service_status_history

service_orders
    1 ─── N service_assignments

mechanics
    1 ─── N service_assignments

service_orders
    1 ─── N service_tasks

service_tasks
    1 ─── N task_checklists

service_orders
    1 ─── N part_requests

service_orders
    1 ─── N service_parts

spare_parts
    1 ─── N inventory_transactions

spare_parts
    1 ─── N part_requests

spare_parts
    1 ─── N service_parts

service_orders
    1 ─── N service_costs

service_orders
    1 ─── N mechanic_earnings

mechanics
    1 ─── N mechanic_earnings

profiles
    1 ─── N notifications

customers
    1 ─── N service_reminders

vehicles
    1 ─── N service_reminders
```

---

# 24. Inventory Rules

Inventory must not rely solely on a manually maintained `stock_quantity`.

Stock is derived from transactions.

Conceptually:

```text
Current Stock
=
SUM(inventory_transactions.quantity)
```

Examples:

```text
Initial stock       +20
Purchase            +10
Service usage        -2
Damaged               -1
Return               +1
-----------------------
Current stock        28
```

A service part consumption should correspond to a negative inventory transaction.

---

# 25. Cost Rules

A service's estimated and final cost are separate concepts.

Conceptually:

```text
Labor
+
Parts
+
Additional Charges
-
Discounts
=
Service Total
```

Estimated cost components should use:

```text
is_estimate = true
```

Final cost components should use:

```text
is_estimate = false
```

---

# 26. Mechanic Earnings

Mechanic earnings are based on applicable labor.

Example:

```text
Labor Amount:              Rp 1.000.000
Mechanic Percentage:              30%
Mechanic Earnings:         Rp   300.000
```

The calculated earning should be recorded in `mechanic_earnings`.

---

# 27. Indexes

Indexes should exist for frequently queried relationships and operational filters.

Important indexes include:

```text
profiles(role)
customers(profile_id)
mechanics(profile_id)
vehicles(customer_id)
bookings(customer_id)
bookings(vehicle_id)
bookings(status)
service_orders(customer_id)
service_orders(vehicle_id)
service_orders(status)
service_orders(order_number)
service_status_history(service_order_id)
service_assignments(service_order_id)
service_assignments(mechanic_id)
service_tasks(service_order_id)
service_tasks(assigned_mechanic_id)
task_checklists(service_task_id)
spare_parts(sku)
inventory_transactions(spare_part_id)
inventory_transactions(service_order_id)
part_requests(service_order_id)
part_requests(requested_by)
service_parts(service_order_id)
service_costs(service_order_id)
mechanic_earnings(mechanic_id)
notifications(recipient_id)
notifications(is_read)
service_reminders(customer_id)
service_reminders(vehicle_id)
```

---

# 28. Row Level Security

RLS must be enabled on application tables.

## Admin

Administrators may manage workshop-wide operational data.

Admin access includes:

- Customers
- Mechanics
- Vehicles
- Bookings
- Services
- Tasks
- Inventory
- Costs
- Earnings
- Notifications
- Reminders
- Reports

---

## Customer

Customers may access their own:

- Profile
- Customer record
- Vehicles
- Bookings
- Service orders
- Service history
- Notifications
- Reminders

Customers must not access another customer's records.

---

## Mechanic

Mechanics may access:

- Their own profile
- Their own mechanic record
- Services assigned to them
- Tasks assigned to them
- Relevant service information
- Relevant parts
- Their own earnings
- Relevant notifications

Mechanics must not gain unrestricted access to unrelated customer records.

---

# 29. RLS Helper Functions

The database may provide helper functions such as:

```text
is_admin()
is_mechanic()
is_customer()
current_profile_id()
current_customer_id()
current_mechanic_id()
```

These functions should be designed to avoid repetitive policy logic.

They must not bypass RLS.

---

# 30. Seed Data Requirements

Development seed data should contain realistic workshop data.

Required test accounts:

```text
Admin
Christian Horner
admin@pitmate.co

Mechanic
Max Verstappen
verstappen@pitmate.co

Mechanic
Sergio Perez
perez@pitmate.co

Customer / Company
BMW M Motorsport
motorsport@bmw-m.com

Customer / Company
Aston Martin
motorsport@astonmartin.com

Customer / Individual
Axel Zeed
lexazeed@gmail.com
```

Development password:

```text
000000
```

These credentials are development/test credentials only.

The Axel Zeed email is intentionally retained as a real email address for later password-reset and email-flow testing.

Seed scripts must not automatically send real emails.

---

# 31. Seed Vehicles

BMW M Motorsport:

```text
BMW M Hybrid V8
#15

BMW M Hybrid V8
#20

BMW M4 GT3 Evo
#32

BMW M4 GT3 Evo
#46
```

Aston Martin:

```text
Aston Martin Valkyrie
#007

Aston Martin Valkyrie
#009
```

Axel Zeed:

```text
BMW M3 Touring Competition G81

Toyota Innova Zenix

Ford Raptor
```

---

# 32. Mock Operational Data

Seed data should include realistic examples of:

- Bookings
- Service orders
- Service status history
- Mechanic assignments
- Service tasks
- Task checklists
- Spare parts
- Inventory transactions
- Part requests
- Service parts
- Service costs
- Mechanic earnings
- Notifications
- Service reminders

The data should represent multiple stages of the workshop lifecycle rather than only completed services.

Example statuses should include:

```text
Requested
Approved
Scheduled
Inspection
Diagnosis
Waiting for Approval
Waiting for Parts
In Progress
Completion Review
Completed
Payment
Closed
```

---

# 33. Database Migration Rules

All schema changes must be represented by migration files:

```text
supabase/migrations/
```

Do not modify the remote database schema directly through the Supabase Dashboard once migrations are established.

Migration files must be committed to Git.

---

# 34. Seed Rules

Development seed data belongs in:

```text
supabase/seed.sql
```

Seed files should primarily contain data insertion statements.

Schema creation belongs in migrations.

Seed data must be deterministic enough to reproduce the same development environment.

---

# 35. Authentication Seed Strategy

Authentication users are managed separately from normal database seed data.

Auth users should be created through a trusted Supabase Auth Admin API workflow using a service-role credential that is never committed to Git.

The public `profiles` table must reference the resulting `auth.users.id`.

The seed workflow should therefore ensure:

```text
Auth user
    ↓
Profile
    ↓
Customer / Mechanic
    ↓
Vehicles / Services / Other data
```

The service-role credential must never be included in:

```text
Git
Flutter source code
supabase/seed.sql
README.md
DB-SCHEMA.md
```

---

# 36. Development Environment

The database must support reproducible local development through:

```bash
supabase start
supabase db reset
```

The resulting database should contain:

- All migrations
- Development seed data
- Appropriate RLS
- Test accounts when the auth provisioning step is executed

---

# 37. Production Safety

Seed data is intended for development/testing.

Never use:

```bash
supabase db reset --linked
```

against a production database.

Never run:

```bash
supabase db push --include-seed
```

against production unless the seed strategy has explicitly been designed for that environment.

---

# 38. Source of Truth

The database implementation must remain consistent with:

```text
SPEC.md
ARCHITECTURE.md
DESIGN.md
AGENTS.md
DB-SCHEMA.md
```

Database migrations are the executable representation of this schema.

`DB-SCHEMA.md` describes the intended structure.

The migration files implement it.

`seed.sql` provides reproducible development data.