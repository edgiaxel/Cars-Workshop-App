# Business Rules Specification

**Project:** Cars Workshop App  
**Application Name:** Pitstop Garage  
**Document:** Business Rules Specification  
**Version:** 1.0  
**Status:** Baseline  
**Last Updated:** 23 September 2026

---

## 1. Purpose

This document defines the operational and data rules that govern how Pitstop Garage behaves.

Business rules describe conditions that must be satisfied regardless of which interface performs an operation.

For example:

- Flutter shall not allow a mechanic to start an unassigned task.
- The database shall not accept invalid service relationships.
- A completed service order shall have a corresponding service record.
- A service order shall not enter quality checking while required tasks remain incomplete.
- Inventory usage shall affect available stock.
- Customers shall only access their own vehicles and service information.

These rules form the bridge between the application's requirements and its technical implementation.

---

# 2. General Principles

### BR-01 — Backend Authority

Business rules shall be enforced by the backend/database wherever practical.

Flutter UI restrictions shall improve user experience but shall not be considered sufficient authorization or data-integrity enforcement.

---

### BR-02 — Role-Based Operations

Every protected operation shall be evaluated against the authenticated user's role.

The three application roles are:

```text
ADMIN
MECHANIC
CUSTOMER
```

Users shall not be permitted to perform operations outside their role's defined permissions.

Detailed permissions are specified in:

`docs/role-permissions.md`

---

### BR-03 — Historical Integrity

Historical service information shall be preserved.

Completed service orders, service records, inventory usage, and relevant historical relationships shall not normally be hard-deleted.

Where an entity is no longer operationally active, the preferred mechanism shall be an `INACTIVE` status.

---

### BR-04 — Referential Integrity

Records shall only reference valid related records.

Examples:

- A vehicle shall reference an existing customer.
- A service order shall reference an existing vehicle.
- A task shall reference an existing service order.
- A service order part shall reference an existing part.
- A service record shall reference its service order.

Invalid foreign-key relationships shall be rejected.

---

# 3. User and Authentication Rules

### BR-05 — Authentication Required

All protected application functionality shall require an authenticated user.

Unauthenticated users shall not access protected workshop data.

---

### BR-06 — Profile Requirement

Every application user shall have a corresponding profile record.

The profile shall contain:

- authenticated user ID;
- full name;
- email;
- role.

---

### BR-07 — Role Authority

A user's application role shall be determined by the authorized profile data.

Client-provided role values shall not be trusted as authorization.

---

### BR-08 — Account Deactivation

Deactivating an employee or customer shall not erase their historical records.

Their existing historical relationships shall remain intact.

---

# 4. Customer Rules

### BR-09 — Customer Type

A customer shall have one of the following types:

```text
COMPANY
INDIVIDUAL
```

---

### BR-10 — Company Customer Information

A `COMPANY` customer shall have a company name.

Example:

```text
BMW Motorsport
Porsche Motorsport
```

---

### BR-11 — Individual Customer Information

An `INDIVIDUAL` customer may omit a company name.

A contact person or personal name may represent the customer.

---

### BR-12 — Customer Ownership

A customer shall only access vehicles and service information belonging to that customer.

A customer shall not access another customer's:

- vehicles;
- service orders;
- service tasks;
- service history;
- cost information;
- workshop records.

---

# 5. Mechanic Rules

### BR-13 — Mechanic Profile

Every mechanic shall be associated with an application profile.

A mechanic shall have a unique employee code.

---

### BR-14 — Mechanic Status

Mechanics may be:

```text
ACTIVE
INACTIVE
```

---

### BR-15 — Inactive Mechanic Assignment

Inactive mechanics shall not be assigned to new service orders or new tasks.

Existing historical assignments shall remain preserved.

---

### BR-16 — Mechanic Work Visibility

Mechanics shall primarily access service work assigned to them.

Mechanics shall not automatically receive administrative access to unrelated customer or workshop-management functions.

---

# 6. Vehicle Rules

### BR-17 — Vehicle Ownership

Every vehicle shall belong to exactly one customer.

---

### BR-18 — Vehicle Identity

A vehicle shall contain:

- brand;
- model;
- vehicle type.

Year, registration number, unit number, mileage, and notes may provide additional identification or operational information.

---

### BR-19 — Registration Number

Registration numbers are optional.

This allows the system to support vehicles that do not use conventional road registration, such as:

- race cars;
- competition vehicles;
- track-only vehicles.

---

### BR-20 — Unit Number

A unit number may be used as an internal workshop, fleet, or racing identifier.

It shall not be treated as a road registration number.

---

### BR-21 — Vehicle Mileage

Vehicle mileage shall never be negative.

Mileage updates shall preserve valid numeric values.

---

### BR-22 — Vehicle Status

Vehicles may be:

```text
ACTIVE
IN_SERVICE
INACTIVE
```

`IN_SERVICE` indicates that the vehicle is currently undergoing workshop work.

---

# 7. Service Order Rules

### BR-23 — Service Order Ownership

Every service order shall reference:

- one customer;
- one vehicle.

The customer associated with the service order shall correspond to the vehicle's owner.

A service order shall not be created where the selected customer and vehicle belong to different ownership records.

---

### BR-24 — Service Order Identification

Every service order shall have a unique identifier.

The identifier shall remain stable throughout the service lifecycle.

---

### BR-25 — Service Type

Every service order shall specify a service type.

Examples:

```text
Scheduled Maintenance
Brake System Inspection
Cooling System Service
Pre-Race Inspection
Engine Diagnostics
```

---

### BR-26 — Priority

Every service order shall have one priority:

```text
LOW
NORMAL
HIGH
URGENT
```

Priority affects presentation and operational attention but does not bypass authorization or data-integrity rules.

---

### BR-27 — Initial Status

New service orders shall begin in:

```text
REQUESTED
```

---

### BR-28 — Controlled Status Transitions

Service-order statuses shall only change through valid transitions defined by:

`docs/state-machine.md`

Users shall not be allowed to arbitrarily select any status.

---

### BR-29 — Status History

Every successful service-order status transition shall create a corresponding status-history record.

The history record shall contain:

- service order;
- resulting status;
- user who performed the transition;
- optional notes;
- timestamp.

---

### BR-30 — Cancellation

Cancelled service orders shall enter:

```text
CANCELLED
```

and shall be treated as terminal operational records.

A cancelled service order shall not normally resume through the standard workflow.

---

### BR-31 — Completion

Completed service orders shall enter:

```text
COMPLETED
```

and shall be treated as terminal operational records.

---

# 8. Service Task Rules

### BR-32 — Task Ownership

Every task shall belong to exactly one service order.

---

### BR-33 — Task Status

Tasks may have one of three statuses:

```text
PENDING
IN_PROGRESS
COMPLETED
```

---

### BR-34 — Task Transition Rules

The standard task lifecycle shall be:

```text
PENDING → IN_PROGRESS → COMPLETED
```

A completed task may be reopened to `IN_PROGRESS` when corrective work is required.

---

### BR-35 — Task Assignment

A task may remain unassigned while a service order is being prepared.

A task shall have an assigned mechanic before it enters:

```text
IN_PROGRESS
```

---

### BR-36 — Task Assignment Validity

Only active mechanics may be assigned to new tasks.

---

### BR-37 — Task Completion Timestamp

When a task becomes `COMPLETED`, `completed_at` shall be populated.

When a completed task is reopened, `completed_at` shall be cleared.

---

### BR-38 — Task Progress

Service progress shall be derived from task completion.

```text
progress =
completed_tasks / total_tasks × 100
```

Progress shall not be manually entered as an authoritative value.

---

### BR-39 — Quality Check Prerequisite

A service order shall not transition from:

```text
IN_PROGRESS
```

to:

```text
QUALITY_CHECK
```

unless:

1. at least one task exists; and
2. all required tasks are `COMPLETED`.

---

# 9. Mechanic Assignment Rules

### BR-40 — Service Order Assignment

A service order may have one assigned mechanic.

The assignment is optional while the order is being prepared.

---

### BR-41 — Active Mechanic Requirement

Only active mechanics may receive new service-order assignments.

---

### BR-42 — Assignment Changes

Admin may change the assigned mechanic while operational work is ongoing.

The system shall preserve historical service information when assignments change.

---

### BR-43 — Mechanic Access

A mechanic shall be able to access the service order information necessary to perform their assigned work.

This includes relevant:

- vehicle information;
- service description;
- tasks;
- assigned parts;
- service progress;
- work-related notes.

---

# 10. Spare-Part Inventory Rules

### BR-44 — Part Identification

Every part shall have a unique part number.

---

### BR-45 — Part Status

Parts may be:

```text
ACTIVE
INACTIVE
```

Inactive parts shall not be used for new inventory operations.

Historical usage shall remain preserved.

---

### BR-46 — Stock Quantity

Part stock quantity shall never be negative.

---

### BR-47 — Minimum Stock

Every part shall have a non-negative minimum-stock value.

---

### BR-48 — Low Stock

A part shall be considered low stock when:

```text
stock_quantity <= minimum_stock
```

Example:

```text
Stock:          3
Minimum Stock:  5

Result: LOW STOCK
```

---

### BR-49 — Part Price

Part unit prices shall never be negative.

---

### BR-50 — Historical Part Price

When a part is added to a service order, the current unit price shall be copied into:

```text
service_order_parts.unit_price
```

This creates a historical price snapshot.

Future changes to the part's current price shall not alter the historical price of already-recorded service work.

---

# 11. Service Order Part Usage

### BR-51 — Part Usage Quantity

Part usage quantity shall be greater than zero.

---

### BR-52 — Part Usage Relationship

A part used in a service order shall create a `service_order_parts` record.

---

### BR-53 — Duplicate Part Usage

The same part shall not appear more than once within the same service order.

If additional quantity is required, the existing quantity should be updated rather than creating duplicate records.

---

### BR-54 — Inventory Deduction

When part usage is finalized, the corresponding stock quantity shall decrease by the used quantity.

```text
new_stock =
current_stock - used_quantity
```

The resulting stock shall never be negative.

---

### BR-55 — Insufficient Stock

The system shall not finalize a part usage operation when available stock is insufficient.

Example:

```text
Available: 2
Required:  5

Result:
Operation rejected
```

---

### BR-56 — Inventory and Task Separation

Completing a task shall not automatically deduct inventory unless the application's inventory-processing operation explicitly records the part usage.

Tasks represent work.

`service_order_parts` represents material usage.

---

# 12. Cost Rules

### BR-57 — Estimated Cost Components

Service-order estimated cost consists of:

```text
estimated_labor_cost
estimated_parts_cost
estimated_additional_cost
```

---

### BR-58 — Estimated Total

The estimated total shall equal:

```text
estimated_total =
estimated_labor_cost
+ estimated_parts_cost
+ estimated_additional_cost
```

---

### BR-59 — Final Cost Components

Final service cost consists of:

```text
final_labor_cost
final_parts_cost
final_additional_cost
```

---

### BR-60 — Final Total

The final total shall equal:

```text
final_total =
final_labor_cost
+ final_parts_cost
+ final_additional_cost
```

---

### BR-61 — Non-Negative Costs

All cost components and totals shall be greater than or equal to zero.

---

### BR-62 — Estimated vs Final Cost

Estimated cost represents the expected service cost before completion.

Final cost represents the actual recorded service cost after work is completed.

The final cost may differ from the estimate.

---

### BR-63 — Customer Cost Visibility

Customers may view the estimated and final costs associated with their own service orders.

They shall not modify those values.

---

# 13. Service History Rules

### BR-64 — Completed Service Record

A completed service order shall have one corresponding service record.

---

### BR-65 — Service Record Uniqueness

Each service order may have at most one service record.

The relationship is:

```text
service_order
     │
     └── 0..1 service_record
```

---

### BR-66 — Service Record Contents

A service record shall contain:

- service order;
- vehicle;
- mechanic where applicable;
- summary;
- diagnosis where applicable;
- work performed;
- recommendations where applicable;
- final cost;
- completion timestamp.

---

### BR-67 — Historical Vehicle Record

Service history shall remain associated with the vehicle even if the vehicle is later marked inactive.

---

### BR-68 — Historical Mechanic Record

If a mechanic becomes inactive, historical service records shall continue to reference the mechanic where applicable.

---

# 14. Service Status History Rules

### BR-69 — Immutable Transition History

Status-history entries represent historical events and shall not normally be edited or deleted through ordinary application operations.

---

### BR-70 — Transition Actor

Every status-history entry shall identify the authenticated profile responsible for the transition.

---

### BR-71 — Chronological History

Status-history records shall contain timestamps that allow the application to reconstruct the service-order timeline.

---

### BR-72 — Customer Timeline Visibility

Customers may view the relevant status history of their own service orders.

Internal administrative information shall not be exposed merely because it exists in the underlying history record.

---

# 15. Service Workflow Rules

The standard service workflow is:

```text
REQUESTED
    ↓
INSPECTION
    ↓
DIAGNOSIS
    ↓
WAITING_PARTS ─────┐
    ↓              │
IN_PROGRESS ←──────┘
    ↓
QUALITY_CHECK
    ↓
COMPLETED
```

Cancellation may occur from applicable active stages.

The complete transition matrix is defined in:

`docs/state-machine.md`

---

# 16. Inspection Rules

### BR-73 — Inspection

During `INSPECTION`, the workshop evaluates the vehicle and identifies relevant conditions or required work.

Inspection may result in:

- diagnosis;
- identified tasks;
- required parts;
- additional work requirements.

---

# 17. Diagnosis Rules

### BR-74 — Diagnosis

During `DIAGNOSIS`, the mechanic or authorized Admin may determine the work required to address the vehicle's condition.

Diagnosis may lead to:

```text
WAITING_PARTS
```

when required parts are unavailable, or:

```text
IN_PROGRESS
```

when work can begin.

---

# 18. Waiting-for-Parts Rules

### BR-75 — Waiting for Parts

A service order may enter `WAITING_PARTS` when required parts are unavailable or procurement is necessary.

---

### BR-76 — Leaving Waiting-for-Parts

A service order may leave `WAITING_PARTS` and enter `IN_PROGRESS` when required parts are available and work can continue.

---

# 19. Quality Check Rules

### BR-77 — Quality Check

`QUALITY_CHECK` represents verification that the recorded service work has been completed correctly.

---

### BR-78 — Quality Check Failure

If quality checking identifies incomplete or incorrect work, the service order may return to:

```text
IN_PROGRESS
```

Corrective tasks may then be reopened or created.

---

### BR-79 — Quality Check Completion

A service order may enter `COMPLETED` only after the quality check has passed and all required completion information is available.

---

# 20. Completion Rules

### BR-80 — Completion Requirements

Before a service order becomes `COMPLETED`, the system shall verify:

1. required service tasks are completed;
2. quality check has passed;
3. final service information is recorded;
4. final cost is available;
5. service record can be created or finalized.

---

### BR-81 — Completed Service Order Immutability

A completed service order shall not return to normal active service states.

If additional work is required after completion, a new service order or an explicitly authorized corrective process shall be used.

---

# 21. Cancellation Rules

### BR-82 — Cancellation Authority

Cancellation shall be restricted to authorized roles according to the service-order state machine and role-permission specification.

---

### BR-83 — Cancellation Preservation

Cancelling a service order shall preserve its existing historical data.

The record shall remain available for authorized review.

---

### BR-84 — Cancellation and Inventory

Cancelling a service order shall not automatically erase historical inventory transactions that have already been finalized.

If reserved or unused parts require reversal, that shall be handled through an explicit inventory operation.

---

# 22. Dashboard Rules

### BR-85 — Dashboard Data

Dashboard statistics shall be derived from actual database records.

Examples include:

- active service orders;
- completed services;
- pending requests;
- vehicles currently in service;
- low-stock parts;
- active mechanics;
- current workload.

---

### BR-86 — Role-Specific Dashboard

Dashboard information shall reflect the authenticated user's role.

For example:

```text
ADMIN
→ workshop-wide statistics

MECHANIC
→ assigned workload and tasks

CUSTOMER
→ personal vehicles and service progress
```

---

# 23. Reporting Rules

### BR-87 — Report Accuracy

Reports shall be generated from authoritative database records.

---

### BR-88 — Historical Reporting

Reports may include historical service data without modifying the underlying records.

---

### BR-89 — Role-Based Reporting

Users shall only access reports appropriate to their role.

Admin may access workshop-wide reporting.

Mechanics may access work-related information.

Customers may access information concerning their own vehicles and services.

---

# 24. Data Modification Rules

### BR-90 — No Client-Side Authority

The application shall not trust client-side role checks as the sole security mechanism.

---

### BR-91 — Protected Relationships

Users shall not be allowed to manually change foreign-key relationships in ways that bypass ownership or authorization rules.

For example, a customer shall not be able to modify a service order's `customer_id` to access another customer's records.

---

### BR-92 — Atomic Operations

Operations that modify multiple related records should be executed atomically where required.

Examples include:

- finalizing part usage and deducting stock;
- completing a service order and creating its service record;
- changing service status and creating status history.

Partial completion of such operations shall be prevented where data consistency would otherwise be compromised.

---

# 25. Soft Deactivation Rules

### BR-93 — Operational Deactivation

The following entities use active/inactive states rather than routine deletion:

- customers;
- mechanics;
- vehicles;
- parts.

---

### BR-94 — Historical References

Deactivated entities may continue to appear in historical records.

For example:

```text
Mechanic:
Marcus Weber
Status:
INACTIVE

Historical Service:
BMW M4 Scheduled Maintenance
Mechanic:
Marcus Weber
```

The historical relationship remains valid.

---

# 26. Data Integrity Rules

### BR-95 — Required Relationships

Required foreign-key relationships shall never be null.

Examples:

```text
vehicle.customer_id
service_order.customer_id
service_order.vehicle_id
service_task.service_order_id
service_order_part.service_order_id
service_order_part.part_id
service_record.service_order_id
```

---

### BR-96 — Numeric Validation

The following values shall never be negative:

- mileage;
- stock quantity;
- minimum stock;
- unit prices;
- estimated costs;
- final costs;
- final totals.

---

### BR-97 — Positive Quantities

Service-order part quantities shall always be greater than zero.

---

### BR-98 — Unique Identifiers

The following values shall remain unique where defined by the database:

- profile ID;
- customer profile ID;
- mechanic profile ID;
- mechanic employee code;
- part number;
- service order/task/vehicle/etc. UUIDs.

---

# 27. Concurrency and Consistency

### BR-99 — Inventory Concurrency

Inventory deduction shall be protected against simultaneous operations that could cause stock to become negative.

The backend shall validate current stock at the time the inventory operation is committed.

---

### BR-100 — Status Consistency

A service-order status change and its status-history record should be treated as one logical operation.

If the history record cannot be created, the status transition should not be considered successfully completed.

---

### BR-101 — Completion Consistency

A service order shall not be considered successfully completed if the required service record cannot be created or finalized.

---

# 28. Customer-Facing Information Rules

### BR-102 — Relevant Visibility

Customers shall see information necessary to understand their service.

This may include:

- service type;
- description;
- vehicle;
- status;
- progress;
- assigned mechanic;
- estimated cost;
- final cost;
- service history;
- relevant status timeline.

---

### BR-103 — Internal Information

Internal administrative information shall not automatically be exposed to customers.

Examples may include:

- internal operational notes;
- internal audit information;
- unrelated customers;
- workshop-wide financial reports;
- unrelated mechanic workload.

---

# 29. Error Handling Rules

### BR-104 — Invalid Operations

When an operation violates a business rule, the system shall reject the operation and provide an understandable error.

Examples:

```text
Cannot start task:
No mechanic is assigned.

Cannot complete service:
2 tasks are still incomplete.

Cannot use part:
Insufficient stock.

Cannot assign mechanic:
Selected mechanic is inactive.
```

---

### BR-105 — No Silent Failure

Important business operations shall not fail silently.

The application should clearly communicate whether the requested operation:

- succeeded;
- failed;
- requires additional information;
- requires another workflow step.

---

# 30. Business Rule Priority

When multiple rules apply, the following principles take precedence:

1. Data integrity
2. Authorization and ownership
3. Historical preservation
4. Workflow validity
5. Operational convenience
6. User-interface convenience

A UI convenience shall never override a higher-priority business rule.

---

# 31. Implementation Guidance

Business rules shall be implemented across appropriate layers.

### Flutter Application

Responsible for:

- user interaction;
- validation feedback;
- displaying permitted actions;
- preventing obviously invalid user actions;
- presenting workflow state.

### Backend / Database

Responsible for:

- authorization;
- row-level security;
- referential integrity;
- critical state validation;
- inventory consistency;
- transactional operations;
- historical integrity.

### Documentation

The following documents define the detailed behavior:

```text
requirements.md
    ↓
state-machine.md
    ↓
task-system.md
    ↓
business-rules.md
    ↓
role-permissions.md
    ↓
route-architecture.md
```

---

# 32. Related Documents

- `docs/requirements.md`
- `docs/state-machine.md`
- `docs/task-system.md`
- `docs/role-permissions.md`
- `docs/route-architecture.md`
- `docs/database-schema.md`
- `docs/features/authentication.md`
- `docs/features/service-orders.md`
- `docs/features/inventory.md`
- `docs/features/service-progress.md`
- `docs/features/reporting.md`

---

# 33. Specification Baseline

This document establishes the baseline business rules for Pitstop Garage version 1.0.

Any implementation that changes the behavior of authentication, ownership, service workflow, tasks, inventory, costs, history, completion, or data integrity shall be evaluated against these rules.

If a future implementation intentionally changes a business rule, the relevant specification shall be updated before the implementation is considered complete.