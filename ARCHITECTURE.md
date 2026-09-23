# Pitstop Garage — Application Architecture

**Project:** Cars Workshop App  
**Application:** Pitstop Garage  
**Version:** 1.0  
**Status:** Baseline  
**Last Updated:** 23 September 2026

---

# 1. Purpose

This document defines the technical architecture of the Pitstop Garage application.

It describes:

- application layers;
- Flutter project organization;
- feature boundaries;
- state management responsibilities;
- routing;
- authentication;
- data access;
- Supabase integration;
- database responsibilities;
- authorization;
- business-logic placement;
- error handling;
- testing boundaries.

This document explains **how the system is implemented**.

Functional requirements and business behavior are defined separately in the `docs/` specification documents.

---

# 2. Architecture Goals

The architecture is designed around the following goals:

1. Keep UI code separate from business and data logic.
2. Keep database access centralized.
3. Make role-based behavior explicit.
4. Prevent business rules from being scattered across widgets.
5. Keep Supabase-specific implementation isolated from presentation code where practical.
6. Make individual features independently understandable.
7. Make the application easy to extend for UAS functionality.
8. Preserve the ability to test important logic independently.
9. Keep the architecture understandable for an academic project.
10. Avoid unnecessary enterprise-level complexity.

---

# 3. High-Level Architecture

The application follows a layered feature-oriented architecture.

```text
┌───────────────────────────────────────────┐
│              Flutter UI                   │
│        Screens / Widgets / Forms          │
├───────────────────────────────────────────┤
│        Presentation / State Layer         │
│      Controllers / Providers / State      │
├───────────────────────────────────────────┤
│          Domain / Business Layer          │
│     Models / Rules / Workflow Actions     │
├───────────────────────────────────────────┤
│           Repository / Data Layer         │
│      Repository Interfaces / Logic        │
├───────────────────────────────────────────┤
│          Supabase Integration             │
│      Supabase Client / Queries / RPC      │
├───────────────────────────────────────────┤
│          Supabase Backend                 │
│ PostgreSQL / Auth / RLS / Storage         │
└───────────────────────────────────────────┘
```

Not every feature must contain every layer if the feature is simple.

The architecture should avoid unnecessary abstraction.

---

# 4. Architectural Principle

The primary dependency direction is:

```text
UI
 ↓
Presentation / State
 ↓
Domain
 ↓
Repository
 ↓
Supabase
```

Lower layers shall not depend on Flutter UI widgets.

For example:

```text
Repository
    ↓
must NOT import
    ↓
Flutter Widget
```

This keeps the data and business layers independent from the visual presentation.

---

# 5. Project Structure

The project should follow a feature-oriented structure.

```text
lib/
│
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   ├── route_guards.dart
│   │   └── route_paths.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── ...
│   └── config/
│       └── ...
│
├── core/
│   ├── errors/
│   ├── extensions/
│   ├── utils/
│   ├── widgets/
│   └── constants/
│
└── features/
    ├── auth/
    ├── dashboard/
    ├── customers/
    ├── mechanics/
    ├── vehicles/
    ├── service_orders/
    ├── tasks/
    ├── inventory/
    ├── reports/
    └── profile/
```

The exact directory contents may evolve as implementation progresses.

---

# 6. `main.dart`

`main.dart` is the application entry point.

Its responsibilities should remain minimal.

Conceptually:

```text
main.dart
   ↓
Initialize required services
   ↓
Run application
   ↓
App widget
```

`main.dart` should not contain:

- service-order business logic;
- database queries;
- role authorization logic;
- large widget trees;
- feature-specific workflows.

---

# 7. Application Layer

The `app/` directory contains application-wide configuration.

Responsibilities include:

- application initialization;
- routing;
- theme;
- global configuration;
- application-level dependency setup.

Example:

```text
app/
├── app.dart
├── router/
├── theme/
└── config/
```

---

# 8. Routing Architecture

Routing is centralized.

Primary routing responsibilities belong in:

```text
lib/app/router/
```

Recommended files:

```text
app_router.dart
route_guards.dart
route_paths.dart
```

Routing behavior is defined in:

`docs/route-architecture.md`

---

# 9. Route Guards

Route guards determine whether navigation may proceed.

Conceptually:

```text
Incoming Route
      │
      ▼
Authenticated?
   │        │
  NO       YES
   │        │
   ▼        ▼
 Login    Role Check
             │
             ▼
       Permission Check
             │
        ┌────┴────┐
       YES        NO
        │          │
        ▼          ▼
      Route     Forbidden
```

Route guards improve navigation behavior but do not replace backend authorization.

---

# 10. Authentication Architecture

Authentication is handled by Supabase Auth.

The general flow is:

```text
Flutter Login
      │
      ▼
Supabase Auth
      │
      ▼
Authenticated Session
      │
      ▼
profiles
      │
      ▼
Application Role
      │
      ▼
Role-specific Dashboard
```

The application profile determines the user's application role.

Supported roles:

```text
ADMIN
MECHANIC
CUSTOMER
```

---

# 11. Authentication State

The application shall maintain awareness of authentication state.

Conceptual states:

```text
INITIALIZING
AUTHENTICATED
UNAUTHENTICATED
ERROR
```

Authentication state changes may trigger routing updates.

For example:

```text
Authenticated
     ↓
Logout
     ↓
Unauthenticated
     ↓
Login Screen
```

---

# 12. Role Resolution

Role resolution shall use trusted application profile information.

Conceptually:

```text
Supabase Auth User
       │
       ▼
profiles.id
       │
       ▼
profiles.role
       │
       ├── ADMIN
       ├── MECHANIC
       └── CUSTOMER
```

Do not determine authorization from:

- email addresses;
- display names;
- hardcoded user IDs;
- client-controlled metadata.

Demo identities are data, not authorization rules.

---

# 13. Feature Architecture

Each major application capability belongs to a feature.

Example:

```text
features/
├── auth/
├── customers/
├── mechanics/
├── vehicles/
├── service_orders/
├── tasks/
├── inventory/
├── reports/
└── profile/
```

A feature should contain the code primarily related to that capability.

This prevents unrelated functionality from becoming concentrated in global folders.

---

# 14. Feature Internal Structure

A feature may use a structure such as:

```text
service_orders/
├── data/
│   ├── models/
│   ├── datasources/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   └── ...
│
└── presentation/
    ├── pages/
    ├── widgets/
    └── state/
```

Not every feature must contain every directory.

For simple features, unnecessary layers should be avoided.

---

# 15. Presentation Layer

The presentation layer contains:

- screens/pages;
- widgets;
- forms;
- loading states;
- error states;
- user interaction;
- presentation-specific state.

Presentation code should not directly implement complex business rules.

For example, a screen should not contain an entire service-order transition engine inside `build()`.

---

# 16. State Management

The application requires a consistent approach to managing asynchronous and interactive state.

State management is responsible for:

- loading;
- success;
- error;
- form state;
- selected records;
- workflow actions;
- refreshing data.

A conceptual state flow is:

```text
UI
 ↓
State Controller
 ↓
Repository
 ↓
Supabase
 ↓
Repository Result
 ↓
State Controller
 ↓
UI
```

The exact state-management package and implementation shall be defined consistently across the project rather than mixing unrelated patterns without justification.

---

# 17. Domain Layer

The domain layer represents application concepts and business operations independently from the UI.

Examples include:

```text
Customer
Mechanic
Vehicle
ServiceOrder
ServiceTask
Part
ServiceRecord
```

The domain layer may contain:

- entities;
- value representations;
- workflow operations;
- business calculations;
- validation logic that is not database-specific.

---

# 18. Business Logic Placement

Business logic should be placed at the appropriate layer.

### UI

Responsible for:

- displaying information;
- accepting input;
- showing permitted actions.

### Presentation / State

Responsible for:

- coordinating UI actions;
- managing asynchronous state;
- invoking application operations.

### Domain / Business Layer

Responsible for:

- calculations;
- workflow decisions;
- reusable business logic.

### Database

Responsible for:

- constraints;
- authorization;
- referential integrity;
- critical transactional consistency.

No single layer should be expected to perform every responsibility.

---

# 19. Repository Layer

Repositories provide the application's data-access boundary.

Conceptually:

```text
Presentation
     ↓
Repository
     ↓
Supabase
```

Repositories should expose operations meaningful to the application.

Prefer:

```text
serviceOrderRepository.getAssignedOrders()
```

over exposing raw database details throughout the UI.

---

# 20. Repository Responsibilities

Repositories may handle:

- querying records;
- inserting records;
- updating records;
- deleting/deactivating records where permitted;
- mapping database responses;
- invoking database functions/RPCs where appropriate;
- handling data-access errors.

Repositories should not contain Flutter widgets.

---

# 21. Supabase Data Access

Supabase-specific code should remain within the data layer or clearly designated infrastructure layer.

The UI should not repeatedly contain code such as:

```dart
Supabase.instance.client
    .from('service_orders')
    ...
```

throughout unrelated widgets.

Instead, database operations should be centralized through the appropriate repository/data-access implementation.

---

# 22. Database as Source of Truth

PostgreSQL is the authoritative source for persistent application data.

The database enforces:

- schema;
- foreign keys;
- unique constraints;
- check constraints;
- row-level security;
- important data integrity rules.

Flutter should not attempt to become a second database.

---

# 23. Database Schema

The primary entities are:

```text
profiles
customers
mechanics
vehicles
service_orders
service_tasks
parts
service_order_parts
service_records
service_order_status_history
```

Relationships are defined in:

`docs/database-schema.md`

The actual schema is represented by:

```text
supabase/migrations/
```

---

# 24. Row Level Security

RLS is a core part of the architecture.

The application assumes that database access may be attempted by an untrusted client.

Therefore:

```text
Flutter UI
    ↓
Supabase API
    ↓
RLS
    ↓
PostgreSQL
```

RLS must enforce row access independently from Flutter navigation.

---

# 25. Authorization Architecture

Authorization has multiple layers.

```text
                Authentication
                       │
                       ▼
                  User Profile
                       │
                       ▼
                     Role
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
        ADMIN       MECHANIC     CUSTOMER
          │            │            │
          ▼            ▼            ▼
      UI Routes     UI Routes    UI Routes
          │            │            │
          └────────────┼────────────┘
                       ▼
                     RLS
                       │
                       ▼
                  PostgreSQL
```

The UI determines what should be presented.

RLS determines what data the user is actually allowed to access.

---

# 26. Ownership Model

Customer-owned data follows:

```text
Customer
   │
   └── Vehicles
         │
         └── Service Orders
               │
               ├── Tasks
               ├── Parts
               ├── Status History
               └── Service Record
```

Customer access shall be restricted to their ownership boundary.

---

# 27. Mechanic Assignment Model

Mechanic operational access follows assignment.

```text
Mechanic
   │
   └── Assigned Service Orders
          │
          └── Assigned Tasks
```

A mechanic may access information required to perform assigned work.

This does not grant workshop-wide administrative access.

---

# 28. Service Order Architecture

A service order is the central operational entity.

```text
Service Order
├── Customer
├── Vehicle
├── Mechanic
├── Tasks
├── Parts
├── Cost Estimate
├── Final Cost
├── Status History
└── Service Record
```

The service-order feature should coordinate these relationships without duplicating the underlying records.

---

# 29. Service Order State Machine

Service orders follow:

```text
REQUESTED
    ↓
INSPECTION
    ↓
DIAGNOSIS
    ↓
WAITING_PARTS
    ↓
IN_PROGRESS
    ↓
QUALITY_CHECK
    ↓
COMPLETED
```

`CANCELLED` is a terminal state for applicable transitions.

The authoritative transition definitions are in:

`docs/state-machine.md`

---

# 30. Task Architecture

Tasks are child records of service orders.

```text
Service Order
     │
     ├── Task
     ├── Task
     ├── Task
     └── Task
```

Task state:

```text
PENDING
    ↓
IN_PROGRESS
    ↓
COMPLETED
```

Completed tasks may be reopened when corrective work is required.

Task behavior is defined in:

`docs/task-system.md`

---

# 31. Service Progress

Progress is derived from task completion.

```text
completed_tasks
────────────────── × 100
  total_tasks
```

The application should not maintain multiple independent progress values.

The same underlying task data should drive:

- mechanic progress;
- customer progress;
- service-order progress;
- dashboard summaries.

---

# 32. Inventory Architecture

Inventory consists primarily of:

```text
parts
    │
    └── service_order_parts
             │
             └── service_orders
```

A part record contains current inventory information.

A service-order part record stores historical usage and unit price.

This separation allows current inventory prices to change without altering historical service costs.

---

# 33. Cost Architecture

Service-order costs are stored as component values.

Estimated:

```text
Labor
Parts
Additional
    ↓
Estimated Total
```

Final:

```text
Labor
Parts
Additional
    ↓
Final Total
```

The total is derived from its components and must remain consistent.

---

# 34. Service History Architecture

Completed services produce service records.

```text
Service Order
      │
      ▼
Completion
      │
      ▼
Service Record
      │
      ▼
Vehicle Service History
```

Service history is historical data and should not be treated as disposable UI state.

---

# 35. Status History Architecture

Every successful service-order status transition should produce a status-history record.

```text
Status Transition
       │
       ├── Update Service Order
       │
       └── Create History Entry
```

These operations should be treated as one logical workflow.

Where necessary, transactional database functions should be used to guarantee consistency.

---

# 36. Transactional Operations

Some operations affect multiple records and should be atomic.

Examples:

### Status transition

```text
Update service_order
        +
Insert status_history
```

### Service completion

```text
Validate completion
        +
Create service_record
        +
Update service_order
        +
Record status transition
```

### Inventory usage

```text
Validate stock
        +
Record part usage
        +
Deduct stock
```

The exact implementation may use database transactions/functions where appropriate.

---

# 37. Error Architecture

Errors should be handled at appropriate boundaries.

Conceptually:

```text
Supabase Error
      ↓
Repository
      ↓
Application Error
      ↓
Presentation State
      ↓
User-Friendly Message
```

Low-level database exceptions should not be exposed directly to normal users.

---

# 38. Loading State Architecture

Data-driven screens should support:

```text
Loading
   ↓
Success
   │
   ├── Data
   └── Empty
```

and:

```text
Loading
   ↓
Error
```

Screens should not assume that data is immediately available.

---

# 39. Form Architecture

Forms should use a consistent pattern:

```text
User Input
    ↓
Client Validation
    ↓
State / Controller
    ↓
Repository
    ↓
Database Validation
    ↓
Success / Error
```

Client validation improves UX.

Database constraints remain authoritative.

---

# 40. Dashboard Architecture

Dashboards are role-specific presentations of existing data.

They should not become independent data silos.

### Admin

Aggregates workshop-wide data.

### Mechanic

Aggregates assigned work.

### Customer

Aggregates owned vehicles and services.

Dashboard values should be derived from authoritative records.

---

# 41. Reporting Architecture

Reporting should read from existing application data.

Reports should not introduce a second storage system for ordinary operational data.

Where complex aggregation becomes necessary, database views or functions may be considered.

---

# 42. Feature Dependencies

Major dependencies are:

```text
Authentication
      │
      ▼
Profiles / Roles
      │
      ├──────────────┐
      ▼              ▼
 Customers       Mechanics
      │              │
      ▼              │
 Vehicles             │
      │              │
      └──────┬───────┘
             ▼
       Service Orders
             │
       ┌─────┼─────┐
       ▼     ▼     ▼
     Tasks  Parts  Costs
       │     │
       │     ▼
       │ Inventory
       │
       ▼
     Progress
       │
       ▼
 Quality Check
       │
       ▼
 Service Record
       │
       ▼
 Service History
```

---

# 43. Feature Boundaries

Features should communicate through defined interfaces rather than directly manipulating unrelated feature internals.

For example:

```text
service_orders
      ↓
tasks
```

is preferable to having unrelated UI widgets directly manipulate each other's internal state.

Shared domain models or repositories may be used where appropriate.

---

# 44. Shared Core

The `core/` directory should contain genuinely reusable application infrastructure.

Examples:

```text
core/
├── errors/
├── extensions/
├── utils/
├── constants/
└── widgets/
```

Do not place feature-specific code into `core/` merely because it is used by multiple files.

A utility belongs in `core/` when it is genuinely application-wide.

---

# 45. Design System

Visual consistency is defined in:

`DESIGN.md`

Shared UI components should be used where practical.

The architecture should prevent every feature from inventing its own:

- button;
- card;
- status badge;
- form field;
- dialog;
- loading state.

---

# 46. Dependency Management

Dependencies should be kept intentional and minimal.

Before adding a package:

1. check existing dependencies;
2. check whether Flutter/Dart provides the capability;
3. evaluate whether the package fits the architecture;
4. avoid introducing duplicate libraries for the same purpose.

---

# 47. Testing Architecture

Testing should occur at multiple levels.

## Unit Tests

For:

- calculations;
- validation;
- state transformations;
- reusable business logic.

## Widget Tests

For:

- screens;
- forms;
- widgets;
- UI states.

## Integration Tests

For:

- authentication flows;
- navigation;
- major service workflows;
- database-backed functionality where practical.

## Database Tests

For:

- constraints;
- RLS;
- database functions;
- important transactional behavior.

---

# 48. Security Architecture

Security responsibilities are distributed:

```text
Supabase Auth
    ↓
Authentication

Flutter Router
    ↓
Navigation Protection

Application Role
    ↓
Role-Aware UI

PostgreSQL RLS
    ↓
Data Authorization

Database Constraints
    ↓
Data Integrity
```

No single layer should be considered sufficient by itself.

---

# 49. Security Boundaries

Never place secrets inside the Flutter application.

The client is considered untrusted.

Assume that a user can:

- inspect network requests;
- modify client code;
- bypass UI controls;
- send requests manually.

Therefore, critical authorization must exist at the backend/database layer.

---

# 50. Data Lifecycle

The general lifecycle is:

```text
Authentication
      ↓
Profile / Role
      ↓
Customer / Mechanic
      ↓
Vehicle
      ↓
Service Order
      ↓
Tasks / Parts / Costs
      ↓
Quality Check
      ↓
Completion
      ↓
Service Record
      ↓
Historical Data
```

---

# 51. Architecture Decision Principles

When making future architectural decisions, prefer:

1. Simplicity.
2. Explicit behavior.
3. Consistency.
4. Testability.
5. Security.
6. Maintainability.
7. Minimal unnecessary abstraction.

The project is an academic application, not a distributed enterprise platform.

Do not introduce infrastructure complexity without a clear benefit.

---

# 52. What Not to Do

Avoid:

- business logic directly inside large widget `build()` methods;
- database queries scattered across UI;
- hardcoded role detection;
- hardcoded user identity checks;
- arbitrary service-status updates;
- duplicated progress calculations;
- duplicated cost calculations;
- bypassing RLS;
- storing secrets in Flutter;
- unrelated feature-to-feature coupling;
- unnecessary global state;
- unnecessary dependencies;
- speculative microservices;
- unnecessary backend infrastructure.

---

# 53. Implementation Workflow

A typical feature implementation should follow:

```text
Specification
     ↓
Architecture Review
     ↓
Database / Data Model
     ↓
Repository
     ↓
State / Controller
     ↓
UI
     ↓
Routing
     ↓
Authorization
     ↓
Testing
     ↓
Documentation
```

Not every feature requires every step, but the dependencies should remain conceptually consistent.

---

# 54. UTS Architecture

During UTS, the architecture may intentionally prioritize:

- working navigation;
- database-backed demo data;
- visible UI;
- basic authentication;
- representative workflows.

The application does not need to expose every UAS operation yet.

However, UTS implementation should avoid decisions that make later UAS expansion unnecessarily difficult.

---

# 55. UAS Architecture

During UAS, the existing architecture should be extended to support:

- full CRUD;
- real forms;
- complete workflow transitions;
- role enforcement;
- task operations;
- inventory processing;
- cost calculations;
- service records;
- reporting;
- validation;
- error handling.

The UAS implementation should build upon the UTS foundation rather than replacing the entire application.

---

# 56. Documentation Relationship

This architecture document works together with:

```text
README.md
docs/requirements.md
docs/state-machine.md
docs/task-system.md
docs/business-rules.md
docs/role-permissions.md
docs/route-architecture.md
docs/database-schema.md
DESIGN.md
docs/features/*
```

Each document has a different responsibility.

Architecture explains **how** the system is structured.

Requirements explain **what** the system must provide.

Business rules explain **what must be true**.

Role permissions explain **who may do what**.

Route architecture explains **where users navigate**.

Database documentation explains **how persistent data is structured**.

Design documentation explains **how the interface should look and behave visually**.

---

# 57. Change Management

A change that affects architecture should be reflected in this document.

Examples include:

- changing state-management strategy;
- changing repository architecture;
- changing routing architecture;
- introducing a new major application layer;
- changing Supabase integration strategy;
- introducing a new major feature boundary.

Small implementation details do not require rewriting this document.

---

# 58. Architecture Baseline

This document establishes the baseline technical architecture for Pitstop Garage version 1.0.

The architecture should remain intentionally simple and understandable while providing clear separation between:

```text
Presentation
Business Logic
Data Access
Backend
Database
Authorization
```

Future changes should preserve these boundaries unless a documented architectural decision justifies changing them.