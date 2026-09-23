# AGENTS.md

# Pitstop Garage — Agent Instructions

This file defines the rules and operating procedures for AI coding agents working on the **Cars Workshop App / Pitstop Garage** repository.

Agents must read and follow this document before modifying project files.

---

# 1. Project Identity

**Project:** Cars Workshop App  
**Application:** Pitstop Garage  
**Platform:** Flutter  
**Language:** Dart  
**Backend:** Supabase / PostgreSQL  
**Authentication:** Supabase Auth  
**Authorization:** PostgreSQL Row Level Security (RLS)

Pitstop Garage is a car workshop management application with three primary roles:

```text
ADMIN
MECHANIC
CUSTOMER
```

The application manages:

- customers;
- mechanics;
- vehicles;
- service orders;
- service tasks;
- spare parts;
- inventory;
- service costs;
- service progress;
- service history;
- reporting.

---

# 2. Core Agent Rule

**Do not modify the system based on assumptions when the repository documentation already defines the behavior.**

Before implementing a feature, determine:

1. What requirement does it satisfy?
2. Which business rules apply?
3. Which role(s) can use it?
4. Which route should expose it?
5. Which database records does it affect?
6. Which existing feature owns the behavior?
7. Whether the change affects the state machine, permissions, or schema.

If the answer is unclear, inspect the relevant documentation before writing code.

---

# 3. Documentation Hierarchy

The project has a defined documentation hierarchy.

Read documents in this order when determining intended behavior:

```text
README.md
    │
    ▼
docs/requirements.md
    │
    ▼
docs/state-machine.md
    │
    ▼
docs/task-system.md
    │
    ▼
docs/business-rules.md
    │
    ▼
docs/role-permissions.md
    │
    ▼
docs/route-architecture.md
    │
    ▼
ARCHITECTURE.md
    │
    ▼
DESIGN.md
    │
    ▼
docs/features/*
    │
    ▼
Implementation
```

The core specification documents are:

```text
docs/requirements.md
docs/state-machine.md
docs/task-system.md
docs/business-rules.md
docs/role-permissions.md
docs/route-architecture.md
```

These documents define the intended behavior of the system.

---

# 4. Source-of-Truth Rules

Different types of information have different authoritative sources.

## Requirements

Authoritative source:

```text
docs/requirements.md
```

Defines what the application is required to do.

---

## Workflow

Authoritative sources:

```text
docs/state-machine.md
docs/task-system.md
```

Define:

- service-order states;
- valid transitions;
- task states;
- task progress;
- quality-check prerequisites.

---

## Business Logic

Authoritative source:

```text
docs/business-rules.md
```

Defines operational rules and data constraints.

---

## Authorization

Authoritative source:

```text
docs/role-permissions.md
```

Defines what each role may access or modify.

---

## Navigation

Authoritative source:

```text
docs/route-architecture.md
```

Defines application routes and role-specific navigation.

---

## Database

Authoritative sources:

```text
supabase/migrations/
docs/database-schema.md
```

The actual migration files are authoritative for the deployed database schema.

Do not assume that an old documentation description is more accurate than the current migration.

---

## Visual Design

Authoritative sources:

```text
DESIGN.md
```

and relevant feature documentation.

---

# 5. Before Modifying Code

Before making a non-trivial change:

1. Read the relevant specification.
2. Inspect the existing implementation.
3. Identify affected database tables.
4. Identify affected roles.
5. Identify affected routes.
6. Identify existing reusable components/services.
7. Determine whether a migration is required.
8. Determine whether tests need to be added or updated.

Do not immediately create new files when an existing architecture already provides an appropriate location.

---

# 6. Do Not Invent Requirements

Agents shall not invent major product behavior.

Do not independently introduce:

- new roles;
- new workflow states;
- new database entities;
- new permissions;
- new navigation structures;
- new authentication methods;
- new external services;
- major UI systems;

unless the requirement is explicitly documented or the user specifically requests the change.

If implementation requires a missing decision, identify the ambiguity instead of silently choosing a major architectural direction.

---

# 7. Preserve Existing Architecture

Prefer extending the existing architecture over introducing parallel systems.

Do not create:

```text
another repository layer
another authentication system
another routing system
another state-management pattern
another database access pattern
```

when the project already has an established equivalent.

Consistency is preferred over local convenience.

---

# 8. Flutter Architecture

Flutter code should follow the architecture defined in:

```text
ARCHITECTURE.md
```

Feature-specific code should remain grouped by feature.

Expected conceptual organization:

```text
lib/
├── app/
├── core/
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

The exact structure may evolve if `ARCHITECTURE.md` is updated accordingly.

---

# 9. Routing Rules

Routing behavior is defined in:

```text
docs/route-architecture.md
```

Agents must respect:

- authentication guards;
- role guards;
- ownership restrictions;
- assignment restrictions;
- protected routes;
- route parameters.

Do not treat route visibility as authorization.

For example:

```text
Customer
    ↓
/admin/inventory
```

must not become accessible merely because the route exists.

Backend authorization must independently enforce the same boundary.

---

# 10. Role Rules

The application has three roles:

```text
ADMIN
MECHANIC
CUSTOMER
```

Do not introduce additional roles without an explicit requirement.

### Admin

Admin has workshop-wide management access.

### Mechanic

Mechanic access is primarily limited to assigned or relevant operational work.

### Customer

Customer access is limited to their own customer-owned data and service information.

Detailed permissions are defined in:

```text
docs/role-permissions.md
```

---

# 11. Authentication Rules

Authentication is provided by Supabase Auth.

Application profile information is stored in:

```text
profiles
```

Do not use client-controlled metadata as the authoritative source for authorization.

Do not trust a role supplied by the Flutter client.

The backend/database must determine whether an operation is authorized.

Never embed:

- service-role keys;
- database passwords;
- Supabase secret keys;
- private credentials;

in Flutter application code.

---

# 12. Supabase Rules

Supabase is the project's backend platform.

Use:

```text
supabase/
├── migrations/
└── seed.sql
```

for database-related project files.

Do not make undocumented schema changes directly in the remote dashboard and leave the repository unaware of them.

Schema changes should be represented by migrations.

---

# 13. Database Migration Rules

When modifying the database schema:

1. Create a new migration.
2. Do not rewrite an already-applied migration.
3. Give the migration a descriptive purpose.
4. Update database documentation when necessary.
5. Consider RLS implications.
6. Consider existing data.
7. Consider foreign-key behavior.
8. Consider whether seed data needs updating.

Example:

```bash
supabase migration new add_feature_name
```

Then edit the generated migration file.

Do not modify historical migration files merely to make the current schema look cleaner.

---

# 14. RLS Rules

Row Level Security is part of the application's security model.

Agents must assume that exposed Supabase tables require appropriate authorization.

Do not solve an RLS problem by simply disabling RLS.

Do not replace a secure policy with:

```sql
USING (true)
```

unless unrestricted access is genuinely intended and explicitly justified.

Remember:

```text
Flutter UI restriction
        ≠
Database authorization
```

RLS must protect the data even when a malicious or modified client bypasses the Flutter UI.

---

# 15. Database Access Rules

Use the existing database access patterns established by the architecture.

Do not scatter raw Supabase queries throughout unrelated UI widgets when a repository/data layer exists.

Prefer:

```text
UI
 ↓
Feature logic
 ↓
Repository / data layer
 ↓
Supabase
```

rather than:

```text
UI
 ↓
random database query
```

---

# 16. Service Order State Machine

The service-order state machine is authoritative.

Valid states:

```text
REQUESTED
INSPECTION
DIAGNOSIS
WAITING_PARTS
IN_PROGRESS
QUALITY_CHECK
COMPLETED
CANCELLED
```

Do not add arbitrary states.

Do not expose arbitrary status dropdowns when the workflow requires controlled transitions.

The complete transition rules are defined in:

```text
docs/state-machine.md
```

---

# 17. Task System

Tasks belong to service orders.

Task states are:

```text
PENDING
IN_PROGRESS
COMPLETED
```

Standard lifecycle:

```text
PENDING
    ↓
IN_PROGRESS
    ↓
COMPLETED
```

A completed task may be reopened to `IN_PROGRESS` when corrective work is required.

Tasks are used to derive service progress.

Do not add a manually editable service-progress percentage when the value can be derived from task state.

---

# 18. Service Progress

Service progress is calculated from tasks.

```text
progress =
completed_tasks / total_tasks × 100
```

Do not create a second independent source of truth for service progress without a documented reason.

Before an `IN_PROGRESS` service order enters `QUALITY_CHECK`:

- at least one task must exist;
- required tasks must be completed.

---

# 19. Inventory Rules

Inventory is represented primarily by:

```text
parts
service_order_parts
```

Stock shall not become negative.

Part usage must respect available stock.

Current part price and historical service-order part price are separate concepts.

The historical unit price stored in:

```text
service_order_parts.unit_price
```

must not be silently changed when the current part price changes.

Do not implement inventory deduction in a way that can produce negative stock through concurrent operations.

---

# 20. Cost Rules

Service-order estimated costs consist of:

```text
estimated_labor_cost
estimated_parts_cost
estimated_additional_cost
estimated_total
```

with:

```text
estimated_total =
labor + parts + additional
```

Final costs consist of:

```text
final_labor_cost
final_parts_cost
final_additional_cost
final_total
```

with:

```text
final_total =
labor + parts + additional
```

All cost values must remain non-negative.

Do not create independent conflicting total calculations in different parts of the application.

---

# 21. Historical Data

Historical business data must be preserved.

Do not casually hard-delete:

- completed service orders;
- service records;
- service-order history;
- historical part usage;
- historical mechanic relationships.

Entities that support deactivation should generally use their defined inactive status.

Historical integrity takes priority over CRUD convenience.

---

# 22. Business Rules

The complete business rules are defined in:

```text
docs/business-rules.md
```

Before implementing logic involving:

- service status;
- tasks;
- inventory;
- costs;
- customer ownership;
- mechanic assignment;
- completion;
- cancellation;

read the relevant business rules first.

Do not duplicate business rules inconsistently across multiple UI widgets.

---

# 23. Error Handling

Errors should be meaningful to the user.

Prefer:

```text
Cannot start task:
No mechanic is assigned.
```

over:

```text
Exception: PostgrestException...
```

Low-level technical details may be logged for debugging but should not be the only information presented to users.

Never silently ignore important database or workflow failures.

---

# 24. Loading and Empty States

Every data-driven screen should consider:

- loading state;
- successful state;
- empty state;
- error state.

Example:

```text
Loading...
    ↓
Data available → Display content

No records → Display empty state

Database error → Display error state
```

Do not assume that a query always returns at least one record.

---

# 25. UI Rules

Follow:

```text
DESIGN.md
```

for visual consistency.

Prefer reusable components for repeated UI patterns such as:

- buttons;
- cards;
- status badges;
- form fields;
- dialogs;
- tables;
- loading indicators;
- error states.

Do not create five slightly different versions of the same component without a reason.

---

# 26. Forms

Forms should validate input before submission.

However, Flutter-side validation does not replace database constraints.

For example:

```text
Flutter validation
        +
Database constraint
```

Both are useful.

The Flutter layer provides immediate feedback.

The database provides authoritative integrity enforcement.

---

# 27. Service Order Operations

When implementing service-order operations, consider the complete relationship:

```text
Customer
   ↓
Vehicle
   ↓
Service Order
   ├── Mechanic
   ├── Tasks
   ├── Parts
   ├── Costs
   ├── Status History
   └── Service Record
```

Do not implement service orders as an isolated CRUD table.

---

# 28. Task Operations

Task operations should respect:

- parent service order;
- assigned mechanic;
- task status;
- service-order state;
- completion rules.

For example, starting a task should not simply execute:

```text
UPDATE service_tasks
SET status = 'IN_PROGRESS'
```

without considering whether:

- the current user is authorized;
- the task belongs to them;
- a mechanic is assigned;
- the parent service order permits the operation.

---

# 29. Service Completion

Completion is a multi-condition operation.

Before completing a service order, consider:

- task completion;
- quality check;
- final cost;
- service record;
- status history;
- related historical data.

Do not implement completion as a simple status update if the business rules require additional records or validation.

---

# 30. Testing

When adding significant functionality, add or update appropriate tests.

Consider:

- unit tests;
- widget tests;
- integration tests;
- database tests;
- authorization tests.

Security-sensitive logic should receive particular attention.

Where local Supabase testing is required, the local Supabase environment may be used through Docker.

Docker is not required merely to deploy migrations to the remote Supabase project.

---

# 31. Verification Before Finishing

Before declaring a change complete:

1. Format the Dart code.
2. Run static analysis.
3. Run relevant tests.
4. Verify affected routes.
5. Verify affected role permissions.
6. Verify database operations.
7. Verify loading/error/empty states where applicable.
8. Review the diff.
9. Ensure no secrets were added.
10. Ensure documentation is updated when behavior changed.

Typical Flutter checks:

```bash
flutter format .
flutter analyze
flutter test
```

Run the commands appropriate to the scope of the change.

---

# 32. Git Rules

Keep commits focused.

Do not mix unrelated changes into one implementation.

Avoid commits such as:

```text
fix everything
misc changes
update stuff
```

Prefer descriptive commits such as:

```text
Add service order repository
Implement mechanic task workflow
Add admin inventory screen
Fix customer service-order access
```

Do not rewrite or delete unrelated user changes.

---

# 33. Existing User Changes

**Do not overwrite, revert, or discard existing user work unless explicitly instructed.**

Before modifying a file:

- inspect its current contents;
- understand existing changes;
- preserve unrelated work.

If the working tree contains changes made by the user, treat them as intentional unless clearly instructed otherwise.

---

# 34. Minimal-Change Principle

Prefer the smallest change that correctly implements the requested behavior.

Do not refactor unrelated code merely because it could theoretically be improved.

Avoid:

- unnecessary rewrites;
- speculative abstractions;
- premature optimization;
- unrelated dependency changes;
- broad architectural changes for small features.

If a larger refactor is genuinely necessary, explain why before performing it.

---

# 35. Dependency Rules

Do not add a new package simply because it is convenient.

Before adding a dependency:

1. Check whether Flutter/Dart already provides the required capability.
2. Check whether the project already contains a package that solves the problem.
3. Check whether the package fits the existing architecture.
4. Consider maintenance and compatibility.
5. Add the dependency only when justified.

Do not replace major project dependencies without explicit instruction.

---

# 36. Secrets and Credentials

Never commit:

- passwords;
- API keys;
- service-role keys;
- database passwords;
- private tokens;
- authentication secrets.

Use environment configuration or platform-specific secret storage where appropriate.

Demo passwords used during manual Supabase Auth setup must not be stored in source control.

---

# 37. Documentation Updates

Documentation is part of implementation.

If a change modifies:

- requirements;
- business rules;
- workflow;
- permissions;
- routes;
- database schema;
- architecture;

update the corresponding documentation.

Do not leave the repository in a state where implementation and specification disagree.

---

# 38. When Documentation Conflicts

If two documents appear to conflict:

1. Identify the conflict.
2. Determine which document is intended to be authoritative.
3. Check the actual database migrations/code where relevant.
4. Do not silently choose a behavior that changes the product specification.
5. Update the documentation if the intended behavior has changed.

Do not maintain contradictory specifications.

---

# 39. Agent Workflow

For a normal feature request, follow this process:

```text
1. Understand Request
        ↓
2. Locate Relevant Specification
        ↓
3. Inspect Existing Implementation
        ↓
4. Identify Affected Layers
        ↓
5. Implement Smallest Correct Change
        ↓
6. Update Tests
        ↓
7. Run Verification
        ↓
8. Update Documentation
        ↓
9. Review Diff
        ↓
10. Report What Changed
```

---

# 40. Feature Workflow Example

For a request such as:

> Add the ability for mechanics to complete tasks.

The agent should inspect:

```text
docs/task-system.md
docs/business-rules.md
docs/role-permissions.md
docs/route-architecture.md
ARCHITECTURE.md
```

Then inspect existing:

```text
service_tasks
service_orders
mechanics
task UI
service-order UI
Supabase access layer
```

Only then implement the feature.

---

# 41. Database-First Awareness

When a feature depends on database behavior, verify the actual schema before writing frontend code.

Do not assume a column exists because a UI requirement mentions it.

Check:

```text
supabase/migrations/
docs/database-schema.md
```

The database schema and frontend models should remain synchronized.

---

# 42. No Fake Data in Production Features

Do not replace real Supabase data with hardcoded arrays merely to make a screen appear functional.

Demo/seed data belongs in:

```text
supabase/seed.sql
```

Application screens should consume the actual data layer.

Temporary mock data may only be used when explicitly requested or when the feature is intentionally being prototyped before backend integration.

---

# 43. UTS / UAS Context

The project has two major academic phases.

## UTS

Focus:

- prototype UI;
- demonstration;
- database-backed demo data;
- basic navigation;
- visual presentation.

The UTS does not require every operation to be fully implemented.

---

## UAS

Focus:

- real data processing;
- forms;
- CRUD operations;
- workflow;
- authentication;
- role-based authorization;
- inventory processing;
- service progress;
- reporting;
- complete application functionality.

Do not throw away the UTS data layer merely because the UAS adds functionality.

Build upon the existing implementation.

---

# 44. Current Demo Data

The Supabase environment contains manually created authentication users and corresponding application data.

The exact identities in the current environment are controlled by Supabase Auth and the seed/application profile data.

Do not assume that an old example identity in documentation is still the active demo identity.

When implementing role-specific behavior, use the user's actual authenticated profile and role rather than hardcoded email addresses.

---

# 45. Hardcoded Identity Restrictions

Do not write logic such as:

```dart
if (email == 'admin@pitstopgarage.test') {
  // Admin
}
```

or:

```dart
if (email.contains('hamilton')) {
  // Customer
}
```

Authorization must use the application's role/profile system.

Demo identities are data, not authorization rules.

---

# 46. Performance

Do not optimize prematurely.

First ensure:

- correct behavior;
- correct authorization;
- correct data relationships;
- maintainable architecture.

When performance becomes an actual issue, measure before changing architecture.

Avoid unnecessary:

- repeated database queries;
- excessive rebuilds;
- duplicated data fetching;
- large unbounded queries.

---

# 47. Accessibility and Usability

UI implementation should consider:

- readable text;
- clear labels;
- sufficient touch targets;
- understandable status indicators;
- meaningful error messages;
- keyboard/form usability where applicable.

Do not communicate important status information using color alone.

---

# 48. Do Not Break the State Machine

Any change that modifies service-order states or transitions requires review of:

```text
docs/state-machine.md
docs/business-rules.md
docs/role-permissions.md
docs/route-architecture.md
```

A new transition is a system-level behavior change, not merely a UI change.

---

# 49. Do Not Break Authorization

Any change involving data access must consider:

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

Ask:

> Who can see this row?

and:

> Who can modify this row?

before implementing the feature.

---

# 50. Final Principle

The goal of an agent working on Pitstop Garage is not merely to make the requested screen or function work.

The goal is to make the change **fit the existing system**.

A correct implementation should:

```text
Respect Requirements
        +
Respect Business Rules
        +
Respect Roles
        +
Respect Routes
        +
Respect Database Integrity
        +
Respect Architecture
        +
Preserve Existing Work
```

When in doubt, inspect the specification and existing implementation before inventing a new solution.