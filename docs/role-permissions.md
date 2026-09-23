# Role and Permissions Specification

**Project:** Cars Workshop App  
**Application Name:** Pitstop Garage  
**Document:** Role and Permissions Specification  
**Version:** 1.0  
**Status:** Baseline  
**Last Updated:** 23 September 2026

---

## 1. Purpose

This document defines the permissions and access boundaries for the three application roles used by Pitstop Garage:

```text
ADMIN
MECHANIC
CUSTOMER
```

The purpose of this document is to establish:

- what each role can view;
- what each role can create;
- what each role can modify;
- what each role can delete or deactivate;
- which records are restricted by ownership or assignment;
- which workflow actions are available to each role.

Permissions defined here apply regardless of whether the operation is performed through:

- Flutter screens;
- forms;
- buttons;
- API calls;
- database operations;
- future administrative interfaces.

The application shall enforce authorization at the backend/database layer.

---

# 2. Authorization Principles

## RP-01 — Authentication Required

A user must be authenticated before accessing protected application data.

Unauthenticated users shall not access workshop records.

---

## RP-02 — Role-Based Authorization

Every authenticated user shall have one application role:

```text
ADMIN
MECHANIC
CUSTOMER
```

The user's role determines their maximum available permissions.

---

## RP-03 — Backend Enforcement

Flutter route guards and UI restrictions are not sufficient security mechanisms.

Backend authorization and Row Level Security shall enforce access boundaries.

---

## RP-04 — Ownership Restriction

Customer access shall be limited to records belonging to that customer.

A customer shall never gain access to another customer's data by modifying IDs or query parameters.

---

## RP-05 — Assignment Restriction

Mechanic access to operational work shall primarily be based on assignment.

A mechanic shall not automatically receive unrestricted access to every workshop record.

---

## RP-06 — Administrative Authority

Admin has workshop-wide management authority.

Admin may manage operational records subject to historical-integrity and workflow rules.

Admin access does not mean that invalid business operations are automatically permitted.

For example, Admin still cannot create a service order referencing a nonexistent vehicle.

---

# 3. Role Definitions

## 3.1 Admin

The Admin represents the workshop owner, manager, or authorized workshop administrator.

Primary responsibilities:

- workshop management;
- customer management;
- mechanic management;
- vehicle management;
- service-order management;
- task assignment;
- inventory management;
- cost management;
- reporting;
- service-history oversight.

Admin has workshop-wide visibility.

---

## 3.2 Mechanic

The Mechanic represents a workshop technician responsible for performing service work.

Primary responsibilities:

- viewing assigned service orders;
- viewing assigned tasks;
- performing assigned work;
- updating task progress;
- recording diagnosis and work information;
- using relevant parts;
- progressing assigned service work.

Mechanics do not receive administrative authority.

---

## 3.3 Customer

The Customer represents the vehicle owner or organization receiving workshop services.

Primary responsibilities:

- viewing owned vehicles;
- requesting/viewing service;
- monitoring service progress;
- viewing assigned mechanic information;
- viewing estimates;
- viewing final costs;
- viewing service history.

Customers have read-only access to workshop operational data except for explicitly supported customer actions such as creating a service request.

---

# 4. Permission Legend

The following notation is used throughout this document.

| Symbol | Meaning |
|---|---|
| `FULL` | Full authorized management |
| `CREATE` | May create records |
| `READ` | May view records |
| `UPDATE` | May modify records |
| `DELETE` | May delete when business rules allow |
| `ASSIGN` | May assign/reassign responsible mechanic |
| `ACTION` | May perform workflow action |
| `OWN` | Access restricted to user's own records |
| `ASSIGNED` | Access restricted to work assigned to the user |
| `NONE` | No access |

---

# 5. Profiles

The `profiles` table contains application identity information.

| Operation | Admin | Mechanic | Customer |
|---|---|---|---|
| View own profile | FULL | FULL | FULL |
| Update own basic profile | UPDATE | UPDATE | UPDATE |
| View all profiles | FULL | NONE | NONE |
| Create profiles | FULL* | NONE | NONE |
| Change application role | FULL* | NONE | NONE |
| Delete profile | Restricted | NONE | NONE |

\* User creation/authentication lifecycle may be handled through Supabase Auth and administrative tooling rather than directly through normal application screens.

### Rules

Users shall not be allowed to promote themselves to Admin.

Customers and mechanics shall not modify their own role.

---

# 6. Customer Records

The `customers` table represents workshop customers.

| Operation | Admin | Mechanic | Customer |
|---|---|---|---|
| View all customers | READ | NONE | OWN |
| View own customer record | FULL | NONE | READ/UPDATE |
| Create customer | CREATE | NONE | NONE |
| Update customer | UPDATE | NONE | OWN |
| Deactivate customer | ACTION | NONE | NONE |
| Delete customer | Restricted | NONE | NONE |

Mechanics may receive customer information only when required for assigned service work.

Customers shall not access unrelated customer records.

---

# 7. Mechanic Records

The `mechanics` table represents workshop mechanics.

| Operation | Admin | Mechanic | Customer |
|---|---|---|---|
| View all mechanics | FULL | ASSIGNED/RELEVANT | RELEVANT |
| View own mechanic record | FULL | FULL | NONE |
| Create mechanic | CREATE | NONE | NONE |
| Update mechanic | UPDATE | Limited | NONE |
| Assign mechanic | ASSIGN | NONE | NONE |
| Change mechanic status | UPDATE | NONE | NONE |
| Deactivate mechanic | ACTION | NONE | NONE |

A mechanic may update their own permitted profile information but shall not modify:

- employee code;
- role;
- status;
- another mechanic's information.

Customers may see the mechanic assigned to their service where appropriate.

---

# 8. Vehicle Records

Vehicles belong to customers.

| Operation | Admin | Mechanic | Customer |
|---|---|---|---|
| View all vehicles | FULL | ASSIGNED/RELEVANT | OWN |
| Create vehicle | CREATE | NONE | CREATE/OWN |
| Update vehicle | UPDATE | Limited | UPDATE/OWN |
| Deactivate vehicle | ACTION | NONE | NONE |
| Delete vehicle | Restricted | NONE | NONE |

### Mechanic access

A mechanic may view vehicle information required to perform assigned work.

### Customer access

A customer may manage their own vehicle information where supported.

A customer cannot transfer a vehicle to another customer.

---

# 9. Service Orders

Service orders are the primary operational records.

| Operation | Admin | Mechanic | Customer |
|---|---|---|---|
| View all service orders | FULL | ASSIGNED | OWN |
| Create service order | CREATE | Limited/None | CREATE request |
| Update service order | UPDATE | Assigned work fields | Limited |
| Assign mechanic | ASSIGN | NONE | NONE |
| Change priority | UPDATE | Limited/None | NONE |
| Change service status | ACTION | Assigned workflow | NONE |
| Cancel service order | ACTION | NONE | Request/limited |
| View estimate | FULL | RELEVANT | OWN |
| View final cost | FULL | RELEVANT | OWN |

Customers may create a service request if that feature is enabled by the application workflow.

A customer-created request shall not automatically bypass Admin review or service-order workflow rules.

---

# 10. Service Order Status Permissions

Status transitions are controlled by the state machine.

| Transition | Admin | Mechanic | Customer |
|---|---|---|---|
| REQUESTED → INSPECTION | ACTION | NONE | NONE |
| REQUESTED → CANCELLED | ACTION | NONE | NONE |
| INSPECTION → DIAGNOSIS | ACTION | ACTION | NONE |
| INSPECTION → CANCELLED | ACTION | NONE | NONE |
| DIAGNOSIS → WAITING_PARTS | ACTION | ACTION | NONE |
| DIAGNOSIS → IN_PROGRESS | ACTION | ACTION | NONE |
| DIAGNOSIS → CANCELLED | ACTION | NONE | NONE |
| WAITING_PARTS → IN_PROGRESS | ACTION | ACTION | NONE |
| WAITING_PARTS → CANCELLED | ACTION | NONE | NONE |
| IN_PROGRESS → QUALITY_CHECK | ACTION | ACTION | NONE |
| IN_PROGRESS → CANCELLED | ACTION | NONE | NONE |
| QUALITY_CHECK → COMPLETED | ACTION | NONE | NONE |
| QUALITY_CHECK → IN_PROGRESS | ACTION | ACTION | NONE |
| QUALITY_CHECK → CANCELLED | ACTION | NONE | NONE |

Actual execution shall additionally require all business-rule prerequisites.

For example, `IN_PROGRESS → QUALITY_CHECK` requires the task completion conditions defined in `docs/task-system.md`.

---

# 11. Service Tasks

| Operation | Admin | Mechanic | Customer |
|---|---|---|---|
| View all tasks | FULL | ASSIGNED | OWN service orders |
| Create task | CREATE | NONE | NONE |
| Update task information | UPDATE | Assigned/limited | NONE |
| Assign task | ASSIGN | NONE | NONE |
| Start assigned task | ACTION | ACTION | NONE |
| Complete assigned task | ACTION | ACTION | NONE |
| Reopen task | ACTION | Assigned/authorized | NONE |
| Delete task | Restricted | NONE | NONE |

### Mechanic restrictions

A mechanic may only perform task actions on tasks assigned to them.

A mechanic cannot:

- assign themselves arbitrary tasks;
- change another mechanic's task;
- modify unrelated service orders;
- mark unrelated tasks as completed.

---

# 12. Task Assignment

| Operation | Admin | Mechanic | Customer |
|---|---|---|---|
| Assign task | YES | NO | NO |
| Reassign task | YES | NO | NO |
| Assign inactive mechanic | NO | NO | NO |
| Remove assignment | YES | NO | NO |
| View assignment | YES | Own | Own service information |

A task entering `IN_PROGRESS` must have an active assigned mechanic.

---

# 13. Spare Parts

| Operation | Admin | Mechanic | Customer |
|---|---|---|---|
| View all parts | FULL | READ | NONE |
| Create part | CREATE | NONE | NONE |
| Update part | UPDATE | NONE | NONE |
| Deactivate part | ACTION | NONE | NONE |
| Adjust stock | ACTION | Authorized usage | NONE |
| View stock level | FULL | RELEVANT | NONE |
| View supplier information | FULL | Relevant | NONE |

Mechanics may access part information necessary to perform assigned work.

Customers shall not access internal inventory-management information.

---

# 14. Service Order Parts

Service-order parts represent parts used by a service order.

| Operation | Admin | Mechanic | Customer |
|---|---|---|---|
| View | FULL | ASSIGNED | OWN service order |
| Add part usage | ACTION | ACTION/Authorized | NONE |
| Update quantity | ACTION | ACTION/Authorized | NONE |
| Remove unused part | ACTION | ACTION/Authorized | NONE |
| Modify historical finalized usage | Restricted | NONE | NONE |

Inventory operations shall comply with stock and cost rules.

---

# 15. Service Records

Service records represent completed historical service.

| Operation | Admin | Mechanic | Customer |
|---|---|---|---|
| View all | FULL | Relevant | OWN |
| Create | ACTION | ACTION/Relevant | NONE |
| Update | UPDATE | Relevant/limited | NONE |
| Delete | Restricted | NONE | NONE |

Service records should normally be created as part of service completion.

Historical service records shall be preserved.

---

# 16. Service Status History

| Operation | Admin | Mechanic | Customer |
|---|---|---|---|
| View all history | FULL | Relevant | OWN |
| Create manually | Restricted | Restricted | NONE |
| Generate transition history | YES | YES | NONE |
| Modify history | NONE/Restricted | NONE | NONE |
| Delete history | NONE | NONE | NONE |

Status-history records should be generated by valid service-order transitions rather than arbitrary user input.

---

# 17. Dashboard Permissions

### Admin

Admin dashboard may contain:

- total customers;
- total vehicles;
- active service orders;
- pending requests;
- active mechanics;
- mechanic workload;
- low-stock parts;
- completed services;
- revenue/cost summaries;
- service statistics.

### Mechanic

Mechanic dashboard may contain:

- assigned service orders;
- assigned tasks;
- pending tasks;
- tasks in progress;
- completed tasks;
- vehicles currently being serviced;
- relevant service information.

### Customer

Customer dashboard may contain:

- owned vehicles;
- active service orders;
- service progress;
- assigned mechanics;
- estimates;
- recent service history.

---

# 18. Reporting Permissions

| Report Type | Admin | Mechanic | Customer |
|---|---|---|---|
| Workshop overview | YES | NO | NO |
| Revenue/cost summary | YES | Limited/No | Own orders |
| Inventory report | YES | Relevant | NO |
| Mechanic workload | YES | Own | Assigned mechanic only where relevant |
| Service history | YES | Relevant | Own vehicles |
| Vehicle service history | YES | Assigned/relevant | Own vehicles |

Reports shall respect the same ownership and assignment restrictions as normal records.

---

# 19. Customer Request Permissions

Customers may initiate service requests through an approved customer workflow.

A request may contain:

- vehicle;
- requested service type;
- description;
- preferred information where supported.

Creating a request shall not allow the customer to:

- assign a mechanic;
- set an internal workshop status;
- manipulate inventory;
- set final cost;
- mark service work completed.

The request shall enter the controlled service-order workflow.

---

# 20. Permission Boundaries

## Admin

Admin can manage:

```text id="2k9m0t"
Customers
Mechanics
Vehicles
Service Orders
Tasks
Inventory
Parts Usage
Costs
Service Records
Reports
Status History
```

---

## Mechanic

Mechanic can operate primarily on:

```text id="w6zj2e"
Assigned Service Orders
Assigned Tasks
Relevant Vehicles
Relevant Parts
Work Progress
Diagnosis / Work Information
Relevant Service History
```

---

## Customer

Customer can access primarily:

```text id="k20d7w"
Own Profile
Own Customer Record
Own Vehicles
Own Service Requests
Own Service Orders
Own Service Progress
Own Costs
Own Service History
Relevant Assigned Mechanic Information
```

---

# 21. UI Permission vs Backend Permission

The Flutter application shall hide or disable actions that the current role cannot perform.

For example:

```text id="y9lq4u"
Customer:
[ View Service ]
[ View Progress ]

Mechanic:
[ Start Task ]
[ Complete Task ]

Admin:
[ Assign Mechanic ]
[ Edit Service ]
[ Manage Inventory ]
```

However, hiding a button shall not be treated as authorization.

The backend shall independently reject unauthorized operations.

---

# 22. Ownership and Assignment Examples

### Customer Example

Alex owns:

```text id="q5f8wo"
Toyota GR86
BMW M4 Competition
```

Alex may access service orders belonging to those vehicles.

Alex may not access:

```text id="xw3x2p"
Porsche 963
BMW M Hybrid V8
```

if those vehicles belong to another customer.

---

### Mechanic Example

A mechanic is assigned:

```text id="v8f4ue"
BMW M Hybrid V8 Brake System Inspection
```

The mechanic may work on the assigned service and its tasks.

The mechanic shall not automatically gain access to unrelated Porsche service orders.

---

### Admin Example

Admin may access all workshop service orders because Admin has workshop-wide operational authority.

---

# 23. Deactivation and Permissions

Deactivation does not erase historical access relationships.

For example:

```text id="1z7mve"
Mechanic:
Daniel
Status:
INACTIVE
```

Daniel may no longer receive new assignments.

However, historical records may continue to show Daniel as the mechanic who performed previous work.

---

# 24. Permission Matrix Summary

| Resource | Admin | Mechanic | Customer |
|---|---|---|---|
| Profile | Full | Own | Own |
| Customers | Full | Relevant | Own |
| Mechanics | Full | Own/Relevant | Relevant |
| Vehicles | Full | Assigned/Relevant | Own |
| Service Orders | Full | Assigned | Own |
| Service Tasks | Full | Assigned | Own service |
| Parts | Full | Relevant | None |
| Part Usage | Full | Authorized assigned work | None |
| Service Records | Full | Relevant | Own |
| Status History | Full | Relevant | Own |
| Dashboard | Full | Own workload | Own data |
| Reports | Full | Relevant | Own data |

---

# 25. Security Requirements

The authorization model shall follow these principles:

1. Users shall authenticate before accessing protected data.
2. Role information shall be determined by trusted backend data.
3. Row Level Security shall enforce row access.
4. Customers shall be restricted to their own records.
5. Mechanics shall be restricted to relevant assigned work.
6. Admin shall have workshop-wide access.
7. Client-side checks shall not be the sole security mechanism.
8. Service-role or secret backend credentials shall never be embedded in the Flutter application.
9. Authorization shall be enforced consistently across all access paths.

---

# 26. Related Documents

- `docs/requirements.md`
- `docs/state-machine.md`
- `docs/task-system.md`
- `docs/business-rules.md`
- `docs/route-architecture.md`
- `docs/database-schema.md`
- `docs/features/authentication.md`
- `docs/features/service-orders.md`
- `docs/features/service-progress.md`
- `docs/features/inventory.md`
- `docs/features/reporting.md`

---

# 27. Specification Baseline

This document establishes the baseline authorization and role-permission model for Pitstop Garage version 1.0.

Any future feature that introduces a new protected resource or role-sensitive operation shall update this document before implementation is considered complete.