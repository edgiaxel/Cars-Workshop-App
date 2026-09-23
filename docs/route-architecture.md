# Route Architecture Specification

**Project:** Cars Workshop App  
**Application Name:** Pitstop Garage  
**Document:** Route Architecture Specification  
**Version:** 1.0  
**Status:** Baseline  
**Last Updated:** 23 September 2026

---

# 1. Purpose

This document defines the navigation and routing architecture of the Pitstop Garage Flutter application.

It establishes:

- application routes;
- route hierarchy;
- authentication routing;
- role-based navigation;
- protected routes;
- route parameters;
- navigation behavior;
- deep-link considerations;
- unauthorized-access behavior.

The route architecture shall reflect the application's roles, business rules, and feature structure.

---

# 2. Routing Principles

## RA-01 — Authentication First

The application shall determine authentication state before displaying protected application content.

The initial routing decision is:

```text
Application Start
       │
       ▼
Authenticated?
   ┌───┴───┐
  NO      YES
   │        │
   ▼        ▼
 Login   Load Profile
              │
              ▼
          Determine Role
              │
       ┌──────┼──────┐
       ▼      ▼      ▼
     ADMIN  MECHANIC CUSTOMER
```

---

## RA-02 — Protected Application

All operational routes shall require authentication.

Unauthenticated users shall be redirected to the login route.

---

## RA-03 — Role-Based Entry

After authentication, the application shall determine the user's application role from the authorized profile.

The user shall then be directed to the appropriate role-specific dashboard.

```text
ADMIN
  → /admin/dashboard

MECHANIC
  → /mechanic/dashboard

CUSTOMER
  → /customer/dashboard
```

---

## RA-04 — Route Authorization

A route shall verify that the authenticated user is authorized to access it.

UI navigation visibility shall not be treated as sufficient authorization.

---

## RA-05 — Unauthorized Access

If an authenticated user attempts to access a route outside their permissions, the application shall display an appropriate unauthorized/forbidden state or redirect them to their permitted dashboard.

Example:

```text
Customer
    ↓
/admin/inventory
    ↓
403 / Unauthorized
    ↓
/customer/dashboard
```

The backend shall independently enforce the corresponding data-access restrictions.

---

# 3. Route Naming Convention

Routes shall use lowercase path segments.

Recommended convention:

```text id="gq7a9m"
/login
/admin/dashboard
/admin/customers
/admin/customers/:customerId
/admin/vehicles
/admin/service-orders
/admin/service-orders/:serviceOrderId
```

Role prefixes shall be used where a route is primarily role-specific.

Shared resources may use neutral paths when appropriate.

---

# 4. Public Routes

Public routes are accessible without authentication.

## 4.1 Login

```text id="j9zv01"
/login
```

Purpose:

- authenticate user;
- establish session;
- retrieve application profile;
- redirect according to role.

---

## 4.2 Authentication Error

Optional route:

```text id="5m7vdp"
/auth/error
```

Purpose:

Display authentication-related errors when the application cannot complete the authentication flow.

---

# 5. Shared Authenticated Routes

Some routes are available to multiple roles.

## 5.1 Profile

```text id="k0m0kr"
/profile
```

Purpose:

- view current user's profile;
- update permitted profile information.

Access:

```text
ADMIN      → Own
MECHANIC   → Own
CUSTOMER   → Own
```

---

## 5.2 Notifications

Optional future route:

```text id="b7u2ez"
/notifications
```

Purpose:

Display system notifications such as:

- service updates;
- task assignments;
- low-stock alerts for Admin;
- service completion notifications.

This route may be implemented after the core application.

---

# 6. Admin Route Tree

The Admin navigation represents workshop-wide management.

```text id="f6f3d7"
/admin
│
├── /dashboard
│
├── /customers
│   ├── /new
│   └── /:customerId
│
├── /mechanics
│   ├── /new
│   └── /:mechanicId
│
├── /vehicles
│   ├── /new
│   └── /:vehicleId
│
├── /service-orders
│   ├── /new
│   └── /:serviceOrderId
│
├── /tasks
│   └── /:taskId
│
├── /inventory
│   ├── /new
│   └── /:partId
│
├── /reports
│
└── /profile
```

---

# 7. Admin Dashboard

```text id="09ewx0"
/admin/dashboard
```

The Admin dashboard provides workshop-wide operational information.

Possible sections:

- active service orders;
- pending requests;
- vehicles currently in service;
- mechanic workload;
- low-stock parts;
- recent service activity;
- completed services;
- financial/service summaries.

---

# 8. Admin Customer Routes

### Customer List

```text id="4yq0pq"
/admin/customers
```

Purpose:

- view customers;
- search;
- filter;
- create new customers.

### Create Customer

```text id="6gh9o6"
/admin/customers/new
```

### Customer Detail

```text id="x4g2fu"
/admin/customers/:customerId
```

Possible information:

- customer profile;
- contact information;
- vehicles;
- active service orders;
- service history.

---

# 9. Admin Mechanic Routes

### Mechanic List

```text id="6c5h5m"
/admin/mechanics
```

### Create Mechanic

```text id="1p1r5y"
/admin/mechanics/new
```

### Mechanic Detail

```text id="7q0x7g"
/admin/mechanics/:mechanicId
```

Possible information:

- mechanic profile;
- specialization;
- status;
- current assignments;
- workload;
- service history.

---

# 10. Admin Vehicle Routes

### Vehicle List

```text id="k8v4x4"
/admin/vehicles
```

### Create Vehicle

```text id="b3s1cl"
/admin/vehicles/new
```

### Vehicle Detail

```text id="9gqk2r"
/admin/vehicles/:vehicleId
```

Possible information:

- customer owner;
- vehicle specifications;
- mileage;
- status;
- active service order;
- service history.

---

# 11. Admin Service Order Routes

### Service Order List

```text id="t4n8x2"
/admin/service-orders
```

Purpose:

- view all service orders;
- filter by status;
- filter by priority;
- filter by mechanic;
- search vehicles/customers;
- create service orders.

### Create Service Order

```text id="m7h2e8"
/admin/service-orders/new
```

### Service Order Detail

```text id="s7a4v9"
/admin/service-orders/:serviceOrderId
```

The detail route is the primary operational view for a service order.

It may contain:

- customer information;
- vehicle information;
- service description;
- priority;
- current status;
- status timeline;
- assigned mechanic;
- task list;
- task progress;
- parts used;
- estimated cost;
- final cost;
- service record.

---

# 12. Admin Task Routes

Tasks may primarily be managed from the service-order detail screen.

A dedicated task route may also exist:

```text id="j0q0cw"
/admin/tasks/:taskId
```

Purpose:

- inspect task details;
- modify assignment;
- modify permitted task information;
- review status.

The application should avoid unnecessary navigation depth where task operations can be completed directly inside a service-order screen.

---

# 13. Admin Inventory Routes

### Inventory List

```text id="b0t5l8"
/admin/inventory
```

Purpose:

- view parts;
- search parts;
- filter categories;
- identify low-stock parts;
- view stock levels.

### Create Part

```text id="p3x4c2"
/admin/inventory/new
```

### Part Detail

```text id="r6n2k5"
/admin/inventory/:partId
```

Possible information:

- part number;
- name;
- category;
- brand;
- supplier;
- stock;
- minimum stock;
- unit price;
- active/inactive status.

---

# 14. Admin Reporting Route

```text id="d8r4x1"
/admin/reports
```

Purpose:

- workshop performance;
- service statistics;
- inventory reports;
- service history analysis;
- financial/cost summaries.

Reports shall respect the permission rules defined in `role-permissions.md`.

---

# 15. Mechanic Route Tree

The Mechanic interface focuses on assigned work.

```text id="c4q6w1"
/mechanic
│
├── /dashboard
├── /service-orders
│   └── /:serviceOrderId
├── /tasks
│   └── /:taskId
├── /vehicles
│   └── /:vehicleId
└── /profile
```

---

# 16. Mechanic Dashboard

```text id="4p4h4x"
/mechanic/dashboard
```

Possible sections:

- assigned service orders;
- tasks in progress;
- pending tasks;
- completed tasks;
- high-priority work;
- vehicles currently being serviced.

The dashboard shall prioritize the mechanic's current workload.

---

# 17. Mechanic Service Order Routes

### Assigned Service Orders

```text id="r7n8a5"
/mechanic/service-orders
```

Displays service orders relevant to the mechanic.

### Service Order Detail

```text id="b5c3p1"
/mechanic/service-orders/:serviceOrderId
```

Possible information:

- vehicle;
- customer information necessary for work;
- service description;
- priority;
- current status;
- assigned tasks;
- task progress;
- relevant parts;
- diagnosis;
- work notes;
- service history where relevant.

The mechanic shall not receive unrestricted administrative controls from this route.

---

# 18. Mechanic Task Routes

### Task List

```text id="m1k8f4"
/mechanic/tasks
```

Possible filters:

- pending;
- in progress;
- completed.

### Task Detail

```text id="v8q2d6"
/mechanic/tasks/:taskId
```

Possible actions:

```text
PENDING
→ Start Task

IN_PROGRESS
→ Complete Task
```

A mechanic may only perform actions on tasks assigned to them.

---

# 19. Mechanic Vehicle Routes

```text id="q9w2r6"
/mechanic/vehicles/:vehicleId
```

This route provides vehicle information relevant to assigned service work.

It may display:

- vehicle identity;
- mileage;
- current service;
- relevant service history;
- technical notes necessary for work.

---

# 20. Customer Route Tree

The Customer interface focuses on owned vehicles and service visibility.

```text id="k6s3f8"
/customer
│
├── /dashboard
├── /vehicles
│   ├── /new
│   └── /:vehicleId
├── /service-orders
│   ├── /new
│   └── /:serviceOrderId
├── /service-history
└── /profile
```

---

# 21. Customer Dashboard

```text id="r2h7c4"
/customer/dashboard
```

Possible sections:

- owned vehicles;
- active service orders;
- service progress;
- pending requests;
- recent service history;
- estimated costs.

---

# 22. Customer Vehicle Routes

### Vehicle List

```text id="m5n3w2"
/customer/vehicles
```

### Add Vehicle

```text id="h4r8q2"
/customer/vehicles/new
```

### Vehicle Detail

```text id="s2c7p9"
/customer/vehicles/:vehicleId
```

Possible information:

- vehicle details;
- current status;
- active service;
- service history.

---

# 23. Customer Service Order Routes

### Service Order List

```text id="q4t7y2"
/customer/service-orders
```

### Service Request

```text id="u5p1n8"
/customer/service-orders/new
```

### Service Order Detail

```text id="w3j6m4"
/customer/service-orders/:serviceOrderId
```

The customer detail view may display:

- service type;
- vehicle;
- service description;
- current status;
- progress;
- task summary;
- assigned mechanic;
- estimated cost;
- final cost;
- service timeline.

Customer task information shall remain read-only.

---

# 24. Customer Service History

```text id="z6x2n1"
/customer/service-history
```

Purpose:

Display completed service records for the customer's vehicles.

Possible filters:

- vehicle;
- date;
- service type.

---

# 25. Shared Service Order Detail Concept

Although different roles may have separate routes, they may use a common conceptual service-order detail component.

```text id="j4p8s7"
                    Service Order
                         │
             ┌───────────┼───────────┐
             │           │           │
           Admin      Mechanic    Customer
             │           │           │
       Full controls   Work UI    Read-only UI
```

The application should avoid duplicating the entire service-order implementation unnecessarily.

Instead, shared components may expose role-appropriate actions.

---

# 26. Route Parameters

Dynamic resources shall use stable UUID-based identifiers.

Examples:

```text id="f1v7c9"
/admin/customers/:customerId
/admin/vehicles/:vehicleId
/admin/service-orders/:serviceOrderId
/admin/tasks/:taskId
/admin/inventory/:partId
```

The route parameter shall identify the record but shall not grant access to it.

Authorization must still verify that the current user has permission to access the referenced record.

---

# 27. Query Parameters

Query parameters may be used for filtering and UI state.

Examples:

```text id="x5j1m2"
/admin/service-orders?status=IN_PROGRESS
/admin/service-orders?priority=HIGH
/admin/inventory?low_stock=true
```

Query parameters shall not be treated as authorization mechanisms.

---

# 28. Navigation Hierarchy

The primary navigation structure should remain shallow.

Recommended Admin navigation:

```text id="h5d2w9"
Dashboard
Customers
Mechanics
Vehicles
Service Orders
Inventory
Reports
Profile
```

Recommended Mechanic navigation:

```text id="e4q8p1"
Dashboard
My Service Orders
My Tasks
Vehicles
Profile
```

Recommended Customer navigation:

```text id="n8v3k5"
Dashboard
My Vehicles
My Services
Service History
Profile
```

---

# 29. Route Guards

The application should use route guards or equivalent navigation middleware.

Conceptually:

```text id="x7s5v2"
Route Request
     │
     ▼
Authenticated?
   │       │
  NO      YES
   │       │
 Login     ▼
       Role Check
           │
     ┌─────┼─────┐
     ▼     ▼     ▼
   ADMIN MECH CUSTOMER
     │     │     │
     ▼     ▼     ▼
  Allowed Route?
       │
   ┌───┴───┐
  YES      NO
   │        │
   ▼        ▼
 Enter    Forbidden/
 Route    Redirect
```

---

# 30. Deep Linking

The application should support opening a specific resource route directly when possible.

Example:

```text id="e1r7w4"
/admin/service-orders/123
```

The application shall still:

1. authenticate the user;
2. determine the user's role;
3. verify authorization;
4. load the resource;
5. display the appropriate screen.

A valid UUID alone shall never bypass authorization.

---

# 31. Session Expiration

When an authenticated session expires:

```text id="s5n2k7"
Protected Route
      ↓
Session Invalid
      ↓
/login
```

The application may preserve the intended destination temporarily so the user can return to it after successful authentication, provided doing so does not bypass authorization.

---

# 32. Logout

Logout shall terminate the authenticated application session.

After logout:

- protected routes shall no longer be accessible;
- the user shall be redirected to `/login`;
- cached role-sensitive information should be cleared or invalidated.

---

# 33. Unknown Routes

Unknown paths shall display an application-level not-found page.

Example:

```text id="v2k8m4"
/this-route-does-not-exist
        ↓
      404
```

The not-found screen may provide navigation back to the user's dashboard.

---

# 34. Unauthorized vs Not Found

The application should distinguish between:

### Unauthorized

The route exists, but the user does not have permission.

Example:

```text
Customer → /admin/inventory
```

### Not Found

The requested route or resource does not exist.

Example:

```text
/admin/service-orders/nonexistent-id
```

Where appropriate, the application may avoid revealing whether a restricted resource exists.

---

# 35. Route-to-Feature Mapping

| Route Area | Feature |
|---|---|
| `/login` | Authentication |
| `/admin/dashboard` | Admin Dashboard |
| `/admin/customers` | Customer Management |
| `/admin/mechanics` | Mechanic Management |
| `/admin/vehicles` | Vehicle Management |
| `/admin/service-orders` | Service Orders |
| `/admin/tasks` | Task Management |
| `/admin/inventory` | Inventory |
| `/admin/reports` | Reporting |
| `/mechanic/dashboard` | Mechanic Dashboard |
| `/mechanic/service-orders` | Mechanic Service Work |
| `/mechanic/tasks` | Mechanic Task Management |
| `/mechanic/vehicles` | Mechanic Vehicle Information |
| `/customer/dashboard` | Customer Dashboard |
| `/customer/vehicles` | Customer Vehicles |
| `/customer/service-orders` | Customer Services |
| `/customer/service-history` | Service History |
| `/profile` | User Profile |

---

# 36. Route Access Matrix

| Route Area | Admin | Mechanic | Customer |
|---|---|---|---|
| `/login` | YES | YES | YES |
| `/admin/*` | YES | NO | NO |
| `/mechanic/*` | NO* | YES | NO |
| `/customer/*` | NO* | NO | YES |
| `/profile` | Own | Own | Own |

\* Administrative or support access to another role's UI should not be assumed unless explicitly implemented. Backend data access and role permissions remain authoritative.

---

# 37. Navigation and Backend Separation

Routing determines which screen the user may attempt to access.

Backend authorization determines which data and operations the user may actually perform.

Therefore:

```text id="n6w5p2"
ROUTING
   ≠
AUTHORIZATION
```

Both layers are required.

---

# 38. Implementation Structure

The routing implementation should be centralized rather than scattering route decisions across individual widgets.

A conceptual Flutter structure may be:

```text id="w9m4x7"
lib/
├── app/
│   ├── router/
│   │   ├── app_router.dart
│   │   ├── route_guards.dart
│   │   └── route_paths.dart
│   │
│   └── ...
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── customers/
│   ├── mechanics/
│   ├── vehicles/
│   ├── service_orders/
│   ├── tasks/
│   ├── inventory/
│   ├── reports/
│   └── profile/
│
└── ...
```

The exact state-management and repository structure shall be defined in `ARCHITECTURE.md`.

---

# 39. Route Naming and Code Consistency

Route path strings shall not be duplicated throughout the application.

Prefer centralized route definitions such as:

```text id="z3h8c1"
RoutePaths.login
RoutePaths.adminDashboard
RoutePaths.adminServiceOrders
RoutePaths.adminServiceOrderDetail
```

rather than manually repeating literal strings throughout widgets.

---

# 40. Navigation Actions

Navigation actions should correspond to meaningful user operations.

Examples:

```text id="q8k4y2"
Admin Dashboard
    ↓
View Service Orders
    ↓
Service Order List
    ↓
Select Service Order
    ↓
Service Order Detail
```

```text id="c6v2p8"
Mechanic Dashboard
    ↓
My Tasks
    ↓
Task Detail
    ↓
Start / Complete Task
```

```text id="d4s7m1"
Customer Dashboard
    ↓
My Vehicles
    ↓
Vehicle Detail
    ↓
Service History
```

---

# 41. Route Architecture and Role Permissions

Routes shall reflect the permission specification defined in:

`docs/role-permissions.md`

The route architecture shall not introduce permissions that do not exist in the authorization model.

If a new route requires a new permission, both:

- `role-permissions.md`; and
- this document

shall be updated.

---

# 42. Route Architecture and Business Rules

Navigation shall expose only operations that satisfy the business rules defined in:

`docs/business-rules.md`

For example:

```text
Task:
PENDING
   ↓
[Start Task]
```

The Start action shall only be displayed/enabled when:

- the mechanic is authorized;
- the task belongs to the mechanic;
- the task has an assigned active mechanic;
- the service-order state permits the operation.

---

# 43. Route Architecture and State Machine

Service-order detail screens shall display actions based on the current service-order state.

Example:

```text id="e7k3q2"
REQUESTED
→ [Begin Inspection]

INSPECTION
→ [Enter Diagnosis]

DIAGNOSIS
→ [Wait for Parts]
→ [Begin Work]

IN_PROGRESS
→ [Quality Check]

QUALITY_CHECK
→ [Complete Service]
→ [Return to Work]
```

The interface shall not display actions that are invalid for the current state.

---

# 44. Future Routes

The following routes may be introduced later without changing the fundamental routing architecture:

```text id="m7q2x9"
/admin/settings
/admin/audit-log
/admin/suppliers
/admin/inventory/transactions
/mechanic/notifications
/customer/notifications
/customer/invoices
```

Future routes shall only be added after their corresponding requirements and permissions are defined.

---

# 45. Initial Route Scope

For the initial implementation, the application shall prioritize:

### Authentication

```text
/login
```

### Admin

```text
/admin/dashboard
/admin/customers
/admin/mechanics
/admin/vehicles
/admin/service-orders
/admin/inventory
/admin/reports
```

### Mechanic

```text
/mechanic/dashboard
/mechanic/service-orders
/mechanic/tasks
```

### Customer

```text
/customer/dashboard
/customer/vehicles
/customer/service-orders
/customer/service-history
```

### Shared

```text
/profile
```

Detail and creation routes shall be implemented as required by the corresponding feature.

---

# 46. Related Documents

- `docs/requirements.md`
- `docs/state-machine.md`
- `docs/task-system.md`
- `docs/business-rules.md`
- `docs/role-permissions.md`
- `docs/database-schema.md`
- `docs/features/authentication.md`
- `docs/features/service-orders.md`
- `docs/features/inventory.md`
- `docs/features/service-progress.md`
- `docs/features/reporting.md`
- `ARCHITECTURE.md`
- `DESIGN.md`

---

# 47. Specification Baseline

This document establishes the baseline route architecture for Pitstop Garage version 1.0.

Any new protected route shall define:

1. its purpose;
2. its required role;
3. its required permission;
4. its resource ownership/assignment rules;
5. its route parameters;
6. its relationship to existing feature routes.

Route changes that alter authorization or business behavior shall update the corresponding specification documents.