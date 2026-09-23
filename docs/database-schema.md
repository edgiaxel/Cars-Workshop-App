# Database Schema Specification

**Project:** Cars Workshop App  
**Database:** Supabase PostgreSQL  
**Schema Version:** 1.0  
**Status:** Locked for Initial Implementation

---

## 1. Purpose

This document defines the initial database structure for the Cars Workshop App.

The database supports:

- User authentication and role management
- Customer and manufacturer information
- Vehicle registration
- Workshop service orders
- Mechanic assignments
- Service task tracking
- Spare-part inventory
- Service cost estimation and final costs
- Completed service history
- Service-order status history and auditing

The database is designed for a general automotive workshop while allowing both normal road vehicles and motorsport/racing vehicles.

The motorsport-oriented workshop theme is primarily used for application presentation and sample data. The database itself remains generic.

---

# 2. Architecture

The application uses the following architecture:

```text
Flutter Application
        |
        v
Supabase Flutter SDK / API
        |
        v
Supabase Backend
        |
        +---- Supabase Auth
        |
        v
PostgreSQL Database
```

Authentication is handled by Supabase Auth.

Application-specific user information and roles are stored in the `profiles` table.

Database authorization is enforced using PostgreSQL Row Level Security (RLS).

---

# 3. Enumerated Types

## 3.1 `user_role`

Represents the role of an authenticated application user.
    
Allowed values:

- `ADMIN`
- `MECHANIC`
- `CUSTOMER`

---

## 3.2 `customer_type`

Represents the type of workshop customer.

Allowed values:

- `COMPANY`
- `INDIVIDUAL`

A company may represent a manufacturer, racing organization, fleet operator, or other organization.

---

## 3.3 `mechanic_status`

Represents whether a mechanic is currently active.

Allowed values:

- `ACTIVE`
- `INACTIVE`

---

## 3.4 `vehicle_type`

Represents the general type of vehicle.

Allowed values:

- `PASSENGER`
- `SUV`
- `TRUCK`
- `VAN`
- `MOTORSPORT`
- `OTHER`

---

## 3.5 `vehicle_status`

Represents the current operational status of a vehicle.

Allowed values:

- `ACTIVE`
- `IN_SERVICE`
- `INACTIVE`

---

## 3.6 `service_priority`

Represents the urgency of a service order.

Allowed values:

- `LOW`
- `NORMAL`
- `HIGH`
- `URGENT`

---

## 3.7 `service_order_status`

Represents the lifecycle of a service order.

Allowed values:

- `REQUESTED`
- `INSPECTION`
- `DIAGNOSIS`
- `WAITING_PARTS`
- `IN_PROGRESS`
- `QUALITY_CHECK`
- `COMPLETED`
- `CANCELLED`

Normal workflow:

```text
REQUESTED
    |
    v
INSPECTION
    |
    v
DIAGNOSIS
    |
    +----------------------+
    |                      |
    v                      v
WAITING_PARTS          IN_PROGRESS
    |                      |
    +----------->-----------+
                |
                v
          QUALITY_CHECK
                |
                v
           COMPLETED
```

`CANCELLED` is a terminal status.

---

## 3.8 `service_task_status`

Represents the status of an individual service task.

Allowed values:

- `PENDING`
- `IN_PROGRESS`
- `COMPLETED`

---

## 3.9 `part_status`

Represents whether an inventory part is available for normal use.

Allowed values:

- `ACTIVE`
- `INACTIVE`

---

# 4. Tables

## 4.1 `profiles`

### Purpose

Connects Supabase Auth users with application-specific information and roles.

### Columns

| Column | Type | Nullable | Default | Constraints |
|---|---|---:|---|---|
| `id` | `uuid` | NO | — | PRIMARY KEY, FK → `auth.users(id)` |
| `full_name` | `text` | NO | — | Must not be empty |
| `email` | `text` | NO | — | Must not be empty |
| `role` | `user_role` | NO | — | Allowed enum values |
| `phone` | `text` | YES | — | |
| `avatar_url` | `text` | YES | — | |
| `created_at` | `timestamptz` | NO | `now()` | |
| `updated_at` | `timestamptz` | NO | `now()` | |

### Notes

- `id` is the same UUID as the corresponding Supabase Auth user.
- The role is application authorization data.
- The role must not be taken from user-editable authentication metadata.
- A profile must correspond to an existing `auth.users` record.

---

# 4.2 `customers`

### Purpose

Stores workshop customer information.

A customer can represent either an individual person or an organization/company.

### Columns

| Column | Type | Nullable | Default | Constraints |
|---|---|---:|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PRIMARY KEY |
| `profile_id` | `uuid` | NO | — | FK → `profiles(id)`, UNIQUE |
| `customer_type` | `customer_type` | NO | — | Allowed enum values |
| `company_name` | `text` | YES | — | Required when customer type is `COMPANY` |
| `contact_person` | `text` | YES | — | |
| `phone` | `text` | NO | — | |
| `email` | `text` | YES | — | |
| `address` | `text` | YES | — | |
| `notes` | `text` | YES | — | |
| `created_at` | `timestamptz` | NO | `now()` | |
| `updated_at` | `timestamptz` | NO | `now()` | |

### Constraints

If `customer_type = COMPANY`:

```text
company_name IS NOT NULL
```

If `customer_type = INDIVIDUAL`:

```text
company_name MAY BE NULL
```

`profile_id` is unique so one application profile represents at most one customer record.

---

# 4.3 `mechanics`

### Purpose

Stores workshop mechanic information.

### Columns

| Column | Type | Nullable | Default | Constraints |
|---|---|---:|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PRIMARY KEY |
| `profile_id` | `uuid` | NO | — | FK → `profiles(id)`, UNIQUE |
| `employee_code` | `text` | NO | — | UNIQUE |
| `specialization` | `text` | YES | — | |
| `phone` | `text` | YES | — | |
| `hire_date` | `date` | YES | — | |
| `status` | `mechanic_status` | NO | `ACTIVE` | Allowed enum values |
| `created_at` | `timestamptz` | NO | `now()` | |
| `updated_at` | `timestamptz` | NO | `now()` | |

### Constraints

- `employee_code` must be unique.
- A profile can represent at most one mechanic.

---

# 4.4 `vehicles`

### Purpose

Stores vehicles belonging to workshop customers.

The table supports both normal road vehicles and racing/motorsport vehicles.

### Columns

| Column | Type | Nullable | Default | Constraints |
|---|---|---:|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PRIMARY KEY |
| `customer_id` | `uuid` | NO | — | FK → `customers(id)` |
| `brand` | `text` | NO | — | |
| `model` | `text` | NO | — | |
| `year` | `smallint` | YES | — | Must be ≥ 1886 when provided |
| `vehicle_type` | `vehicle_type` | NO | — | Allowed enum values |
| `registration_number` | `text` | YES | — | Optional |
| `unit_number` | `text` | YES | — | Optional |
| `mileage` | `numeric` | NO | `0` | Must be ≥ 0 |
| `status` | `vehicle_status` | NO | `ACTIVE` | Allowed enum values |
| `notes` | `text` | YES | — | |
| `created_at` | `timestamptz` | NO | `now()` | |
| `updated_at` | `timestamptz` | NO | `now()` | |

### Notes

`registration_number` is optional because some motorsport vehicles do not have road registration plates.

`unit_number` is an internal identifier and is **not** a registration number.

Examples:

```text
Racing vehicle:
unit_number = "15"
registration_number = NULL

Workshop fleet:
unit_number = "CAR-01"

Normal road vehicle:
registration_number = "B 1234 XYZ"
unit_number = NULL
```

The database does not store a VIN/chassis-number field because it is not required for the application.

### Constraints

```text
mileage >= 0
```

When `year` is provided:

```text
year >= 1886
```

---

# 4.5 `service_orders`

### Purpose

Core operational table representing a vehicle service request and its complete workshop lifecycle.

### Columns

| Column | Type | Nullable | Default | Constraints |
|---|---|---:|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PRIMARY KEY |
| `customer_id` | `uuid` | NO | — | FK → `customers(id)` |
| `vehicle_id` | `uuid` | NO | — | FK → `vehicles(id)` |
| `assigned_mechanic_id` | `uuid` | YES | — | FK → `mechanics(id)` |
| `service_type` | `text` | NO | — | |
| `description` | `text` | YES | — | |
| `priority` | `service_priority` | NO | `NORMAL` | Allowed enum values |
| `status` | `service_order_status` | NO | `REQUESTED` | Allowed enum values |
| `estimated_labor_cost` | `numeric(12,2)` | NO | `0` | ≥ 0 |
| `estimated_parts_cost` | `numeric(12,2)` | NO | `0` | ≥ 0 |
| `estimated_additional_cost` | `numeric(12,2)` | NO | `0` | ≥ 0 |
| `estimated_total` | `numeric(12,2)` | NO | `0` | Sum of estimate components |
| `final_labor_cost` | `numeric(12,2)` | NO | `0` | ≥ 0 |
| `final_parts_cost` | `numeric(12,2)` | NO | `0` | ≥ 0 |
| `final_additional_cost` | `numeric(12,2)` | NO | `0` | ≥ 0 |
| `final_total` | `numeric(12,2)` | NO | `0` | Sum of final cost components |
| `requested_at` | `timestamptz` | NO | `now()` | |
| `started_at` | `timestamptz` | YES | — | |
| `completed_at` | `timestamptz` | YES | — | |
| `created_at` | `timestamptz` | NO | `now()` | |
| `updated_at` | `timestamptz` | NO | `now()` | |

### Cost model

Estimated cost:

```text
estimated_total =
    estimated_labor_cost
  + estimated_parts_cost
  + estimated_additional_cost
```

Final cost:

```text
final_total =
    final_labor_cost
  + final_parts_cost
  + final_additional_cost
```

All cost components must be greater than or equal to zero.

The totals represent stored values used by the application and should remain consistent with their component values.

### Assignment

`assigned_mechanic_id` is nullable because a newly submitted service request may not yet have a mechanic assigned.

---

# 4.6 `service_tasks`

### Purpose

Stores individual tasks that make up a service order.

A service order can contain multiple tasks.

### Columns

| Column | Type | Nullable | Default | Constraints |
|---|---|---:|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PRIMARY KEY |
| `service_order_id` | `uuid` | NO | — | FK → `service_orders(id)` |
| `assigned_mechanic_id` | `uuid` | YES | — | FK → `mechanics(id)` |
| `title` | `text` | NO | — | |
| `description` | `text` | YES | — | |
| `status` | `service_task_status` | NO | `PENDING` | Allowed enum values |
| `completed_at` | `timestamptz` | YES | — | |
| `created_at` | `timestamptz` | NO | `now()` | |
| `updated_at` | `timestamptz` | NO | `now()` | |

### Example tasks

```text
Inspect brake system
Inspect suspension
Replace brake pads
Check cooling system
Final inspection
```

`assigned_mechanic_id` is nullable because tasks may initially be unassigned.

---

# 4.7 `parts`

### Purpose

Stores workshop spare-part inventory.

### Columns

| Column | Type | Nullable | Default | Constraints |
|---|---|---:|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PRIMARY KEY |
| `part_number` | `text` | NO | — | UNIQUE |
| `name` | `text` | NO | — | |
| `category` | `text` | NO | — | |
| `brand` | `text` | YES | — | |
| `description` | `text` | YES | — | |
| `stock_quantity` | `numeric` | NO | `0` | ≥ 0 |
| `minimum_stock` | `numeric` | NO | `0` | ≥ 0 |
| `unit_price` | `numeric(12,2)` | NO | `0` | ≥ 0 |
| `supplier` | `text` | YES | — | |
| `status` | `part_status` | NO | `ACTIVE` | Allowed enum values |
| `created_at` | `timestamptz` | NO | `now()` | |
| `updated_at` | `timestamptz` | NO | `now()` | |

### Inventory rule

A part is considered low-stock when:

```text
stock_quantity <= minimum_stock
```

---

# 4.8 `service_order_parts`

### Purpose

Junction table connecting service orders with parts used during a service.

### Columns

| Column | Type | Nullable | Default | Constraints |
|---|---|---:|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PRIMARY KEY |
| `service_order_id` | `uuid` | NO | — | FK → `service_orders(id)` |
| `part_id` | `uuid` | NO | — | FK → `parts(id)` |
| `quantity` | `numeric` | NO | `1` | Must be > 0 |
| `unit_price` | `numeric(12,2)` | NO | — | Must be ≥ 0 |
| `created_at` | `timestamptz` | NO | `now()` | |

### Constraints

```text
quantity > 0
unit_price >= 0
UNIQUE(service_order_id, part_id)
```

### Price snapshot

`unit_price` stores the price of the part at the time it is added to the service order.

This is intentionally separate from `parts.unit_price`.

Example:

```text
Current part price:
parts.unit_price = 500000

Historical service:
service_order_parts.unit_price = 450000
```

If the current inventory price changes later, the historical service cost remains unchanged.

---

# 4.9 `service_records`

### Purpose

Stores the permanent service history generated from completed service orders.

### Columns

| Column | Type | Nullable | Default | Constraints |
|---|---|---:|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PRIMARY KEY |
| `service_order_id` | `uuid` | NO | — | FK → `service_orders(id)`, UNIQUE |
| `vehicle_id` | `uuid` | NO | — | FK → `vehicles(id)` |
| `mechanic_id` | `uuid` | YES | — | FK → `mechanics(id)` |
| `summary` | `text` | NO | — | |
| `diagnosis` | `text` | YES | — | |
| `work_performed` | `text` | NO | — | |
| `recommendations` | `text` | YES | — | |
| `final_cost` | `numeric(12,2)` | NO | `0` | Must be ≥ 0 |
| `completed_at` | `timestamptz` | NO | `now()` | |
| `created_at` | `timestamptz` | NO | `now()` | |

### Constraint

One completed service order produces at most one service record:

```text
UNIQUE(service_order_id)
```

The service record acts as the permanent historical summary of the completed service.

---

# 4.10 `service_order_status_history`

### Purpose

Stores every status change made to a service order.

This provides an audit trail and allows the application to display a service timeline.

### Columns

| Column | Type | Nullable | Default | Constraints |
|---|---|---:|---|---|
| `id` | `uuid` | NO | `gen_random_uuid()` | PRIMARY KEY |
| `service_order_id` | `uuid` | NO | — | FK → `service_orders(id)` |
| `status` | `service_order_status` | NO | — | Allowed enum values |
| `changed_by` | `uuid` | NO | — | FK → `profiles(id)` |
| `notes` | `text` | YES | — | |
| `created_at` | `timestamptz` | NO | `now()` | |

### Example timeline

```text
09:10  REQUESTED      Customer submitted service request
09:45  INSPECTION     Vehicle inspection started
10:20  DIAGNOSIS      Brake issue identified
11:00  WAITING_PARTS  Waiting for replacement pads
14:30  IN_PROGRESS    Repair started
16:00  QUALITY_CHECK  Final inspection
16:20  COMPLETED      Service completed
```

---

# 5. Relationships

The main database relationships are:

```text
auth.users
    |
    | 1 : 1
    v
profiles
    |
    +--------------------+
    |                    |
    | 1 : 1              | 1 : 1
    v                    v
customers            mechanics
    |
    | 1 : N
    v
vehicles
    |
    | 1 : N
    v
service_orders
    |
    +--------------------------+
    |                          |
    | 1 : N                    | 1 : N
    v                          v
service_tasks          service_order_status_history
    |
    |
    +----------------------+
                           |
                           v
                    service_order_parts
                           ^
                           |
                           |
                         parts

service_orders
    |
    | 1 : 1
    v
service_records
```

Additional relationships:

```text
customers 1 : N service_orders
mechanics 1 : N service_orders
mechanics 1 : N service_tasks
mechanics 1 : N service_records
profiles  1 : N service_order_status_history
vehicles  1 : N service_records
```

---

# 6. Foreign Key Delete Behavior

Historical workshop data must not be accidentally destroyed.

The database therefore follows these principles:

- Important historical relationships should use restrictive delete behavior.
- Customers, mechanics, vehicles, and parts should normally be deactivated rather than deleted.
- Historical service records must remain available.
- Optional operational assignments may use `SET NULL` where appropriate.

Initial intended behavior:

| Relationship | Delete Behavior |
|---|---|
| `profiles → customers` | RESTRICT / NO ACTION |
| `profiles → mechanics` | RESTRICT / NO ACTION |
| `customers → vehicles` | RESTRICT / NO ACTION |
| `customers → service_orders` | RESTRICT / NO ACTION |
| `vehicles → service_orders` | RESTRICT / NO ACTION |
| `mechanics → service_orders` | SET NULL |
| `service_orders → service_tasks` | RESTRICT / NO ACTION |
| `service_orders → service_order_parts` | RESTRICT / NO ACTION |
| `parts → service_order_parts` | RESTRICT / NO ACTION |
| `service_orders → service_records` | RESTRICT / NO ACTION |
| `vehicles → service_records` | RESTRICT / NO ACTION |
| `mechanics → service_records` | SET NULL |
| `service_orders → status_history` | RESTRICT / NO ACTION |
| `profiles → status_history` | RESTRICT / NO ACTION |

The exact SQL `ON DELETE` clauses are defined in the migration.

---

# 7. Business Rules

## 7.1 Customer ownership

A customer can own or operate multiple vehicles.

```text
customers 1 → N vehicles
```

A vehicle belongs to exactly one customer.

---

## 7.2 Service order ownership

Every service order belongs to:

- exactly one customer
- exactly one vehicle

A service order may optionally have one assigned mechanic.

---

## 7.3 Mechanic assignment

A service order may initially be unassigned.

Once assigned, the assigned mechanic is responsible for the operational work associated with the service order.

Individual service tasks may also have their own mechanic assignment.

---

## 7.4 Service tasks

A service order can contain multiple tasks.

Each task has its own status:

```text
PENDING → IN_PROGRESS → COMPLETED
```

Task completion can be used to represent detailed service progress.

---

## 7.5 Inventory usage

When parts are used for a service:

1. A record is created in `service_order_parts`.
2. The quantity used is recorded.
3. The current part price is copied into `service_order_parts.unit_price`.
4. Inventory stock is decreased.
5. The service order's parts cost is updated.

The historical unit price must not depend on future changes to `parts.unit_price`.

---

## 7.6 Cost calculation

Estimated cost:

```text
estimated_total =
estimated_labor_cost
+ estimated_parts_cost
+ estimated_additional_cost
```

Final cost:

```text
final_total =
final_labor_cost
+ final_parts_cost
+ final_additional_cost
```

---

## 7.7 Service history

When a service order is completed, a corresponding `service_records` entry stores the permanent service summary.

The service record contains:

- service order
- vehicle
- mechanic
- summary
- diagnosis
- work performed
- recommendations
- final cost
- completion time

---

## 7.8 Status history

Every service-order status transition should create an entry in `service_order_status_history`.

The history stores:

- service order
- new status
- user who changed the status
- optional notes
- timestamp

This allows the application to display the service timeline and calculate/report service durations.

---

# 8. Data Integrity Constraints

The database must enforce the following basic constraints.

### Required text fields

Required text fields must not contain an empty string.

Examples:

```text
full_name <> ''
email <> ''
service_type <> ''
employee_code <> ''
part_number <> ''
name <> ''
category <> ''
title <> ''
summary <> ''
work_performed <> ''
```

### Numeric constraints

```text
vehicles.mileage >= 0

parts.stock_quantity >= 0
parts.minimum_stock >= 0
parts.unit_price >= 0

service_order_parts.quantity > 0
service_order_parts.unit_price >= 0

service_records.final_cost >= 0
```

All service-order cost components must be:

```text
>= 0
```

---

# 9. Database Authorization

Row Level Security (RLS) is required for application tables exposed through the Supabase API.

The application uses three roles:

```text
ADMIN
MECHANIC
CUSTOMER
```

General authorization model:

### ADMIN

Can manage workshop operations, including:

- customers
- vehicles
- mechanics
- service orders
- service tasks
- inventory
- service records
- reports
- service status workflow

### MECHANIC

Can access operational information required for assigned work, including:

- assigned service orders
- assigned service tasks
- relevant vehicle information
- relevant parts/inventory information
- service progress
- inspection and work notes

### CUSTOMER

Can access their own:

- profile
- vehicles
- service requests
- service orders
- service progress
- estimates
- final costs
- service history

Customers must not be able to access another customer's vehicles or service data.

The exact RLS policies are implemented separately from this structural schema specification.

---

# 10. Tables Summary

| Table | Main Purpose |
|---|---|
| `profiles` | Authenticated application users and roles |
| `customers` | Workshop customers / organizations |
| `mechanics` | Workshop mechanic information |
| `vehicles` | Customer vehicles |
| `service_orders` | Main service workflow and costs |
| `service_tasks` | Detailed work tasks |
| `parts` | Spare-part inventory |
| `service_order_parts` | Parts used by service orders |
| `service_records` | Permanent completed-service history |
| `service_order_status_history` | Service status audit timeline |

---

# 11. Schema Versioning

Current version:

```text
v1.0
```

This schema is the initial database contract for the project.

Changes to the database structure after implementation should be performed through migrations and reflected in this document.

The documentation and database migration should remain synchronized.

---

# 12. Implementation Order

Initial database implementation should follow this order:

```text
1. Create ENUM types
        ↓
2. Create profiles
        ↓
3. Create customers
        ↓
3. Create mechanics
        ↓
4. Create vehicles
        ↓
5. Create service_orders
        ↓
6. Create service_tasks
        ↓
7. Create parts
        ↓
8. Create service_order_parts
        ↓
9. Create service_records
        ↓
10. Create service_order_status_history
        ↓
11. Add indexes
        ↓
12. Enable / verify RLS
        ↓
13. Create RLS policies
        ↓
14. Seed development data
```

The initial structural migration should establish the tables, relationships, constraints, indexes, and database functions/triggers required by the schema.

Authorization policies may be implemented as part of the initial database setup after the structural tables have been verified.