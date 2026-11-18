# PitMate — Architecture

## 1. Architecture Overview

PitMate is a Flutter mobile application backed by Supabase.

The architecture is designed around three primary concerns:

1. Presentation
2. Application / state management
3. Data and backend access

The architecture should remain simple enough for an academic project while providing sufficient separation of responsibilities to support the complete final application.

```text
┌───────────────────────────────────────────────┐
│                 Flutter App                   │
│                                               │
│  ┌─────────────┐  ┌─────────────┐             │
│  │ Presentation│  │ State / App │             │
│  │     UI      │←→│   Logic     │             │
│  └─────────────┘  └──────┬──────┘             │
│                          │                    │
│                   ┌──────▼──────┐             │
│                   │ Data Layer  │             │
│                   └──────┬──────┘             │
└──────────────────────────┼────────────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Supabase   │
                    ├─────────────┤
                    │ Auth        │
                    │ PostgreSQL  │
                    │ RLS         │
                    │ Storage     │
                    │ Realtime    │
                    └─────────────┘
```

---

# 2. Architectural Principles

## 2.1 Single Source of Truth

Supabase PostgreSQL is the primary source of persistent application data.

The application must not maintain a separate permanent local database containing duplicated business data.

Temporary local state is allowed for UI state and session-related behavior.

---

## 2.2 Separation of Responsibilities

Each layer has a specific responsibility.

### Presentation

Responsible for:

- Screens
- Widgets
- Layout
- User interaction
- Visual states
- Form input
- Navigation triggers

Presentation code should not directly contain complex database queries.

### State / Application Logic

Responsible for:

- Managing UI state
- Loading states
- Error states
- Form state
- Authentication state
- Feature state
- Coordinating user actions with data operations

### Data Layer

Responsible for:

- Supabase queries
- Authentication operations
- Database operations
- Data mapping
- Repositories
- Backend-related errors

---

# 3. Architecture Style

PitMate uses a **feature-oriented layered architecture**.

The project should be organized primarily by feature rather than by placing every screen, model, and service into global folders.

Conceptually:

```text
features/
├── auth/
├── customer/
├── vehicles/
├── bookings/
├── services/
├── mechanics/
├── inventory/
├── earnings/
├── notifications/
├── reminders/
└── reports/
```

Shared infrastructure belongs outside individual features.

---

# 4. Project Structure

The intended Flutter structure is:

```text
lib/
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router/
│   ├── theme/
│   └── config/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── utils/
│   └── widgets/
│
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
│
├── features/
│   ├── auth/
│   ├── admin/
│   ├── customer/
│   ├── mechanic/
│   ├── vehicles/
│   ├── bookings/
│   ├── services/
│   ├── inventory/
│   ├── earnings/
│   ├── notifications/
│   ├── reminders/
│   └── reports/
│
└── shared/
    ├── models/
    ├── widgets/
    └── providers/
```

The structure may be adjusted during implementation if the change provides a clear architectural benefit.

---

# 5. Application Layer

The `app/` directory contains application-wide configuration.

```text
app/
├── app.dart
├── router/
├── theme/
└── config/
```

## `app.dart`

Responsible for:

- Root application widget
- Global configuration
- Application theme
- Router integration

## `router/`

Responsible for:

- Route definitions
- Route guards
- Authentication redirects
- Role-based navigation

## `theme/`

Responsible for:

- Colors
- Typography
- Component themes
- Design tokens

The detailed visual system is defined in `DESIGN.md`.

## `config/`

Contains application-wide configuration that is safe to keep in the client.

Secrets must not be hardcoded into source code.

---

# 6. Core Layer

The `core/` directory contains functionality shared throughout the application.

```text
core/
├── constants/
├── errors/
├── extensions/
├── utils/
└── widgets/
```

## Constants

Contains shared constants such as:

- Application constants
- Status identifiers
- Shared configuration values

## Errors

Contains standardized application/data errors.

## Extensions

Contains reusable Dart extensions.

## Utils

Contains small, generic utility functions.

## Widgets

Contains truly reusable UI components that are not specific to a single feature.

Feature-specific widgets should remain inside their feature.

---

# 7. Data Layer

The data layer is responsible for communicating with Supabase.

```text
data/
├── models/
├── repositories/
└── datasources/
```

---

## 7.1 Models

Models represent application data.

Examples:

- User profile
- Customer
- Mechanic
- Vehicle
- Booking
- Service order
- Service task
- Spare part
- Part request
- Mechanic earning
- Notification
- Reminder

Models should be responsible for representing data, not rendering UI.

---

## 7.2 Data Sources

Data sources communicate directly with backend services.

The primary data source is Supabase.

Examples:

```text
SupabaseAuthDataSource
SupabaseVehicleDataSource
SupabaseBookingDataSource
SupabaseServiceDataSource
SupabaseInventoryDataSource
```

A data source should focus on retrieving or modifying backend data.

It should not contain UI logic.

---

## 7.3 Repositories

Repositories provide a clean interface between application logic and data sources.

Conceptually:

```text
UI
 ↓
State / Application Logic
 ↓
Repository
 ↓
Supabase Data Source
 ↓
Supabase
```

Repositories should hide implementation-specific backend details from the rest of the application.

Example:

```text
VehicleRepository
BookingRepository
ServiceRepository
InventoryRepository
```

---

# 8. Feature Architecture

Each major feature should contain its own UI and feature-specific logic.

Example:

```text
features/
└── vehicles/
    ├── screens/
    ├── widgets/
    ├── providers/
    └── models/
```

A feature should not directly reach into another feature's internal implementation.

Shared functionality belongs in `core/`, `shared/`, or the appropriate data layer.

---

# 9. Authentication Architecture

Authentication is handled through Supabase Auth.

General flow:

```text
Application
    ↓
Auth State
    ↓
Supabase Auth
    ↓
Authenticated Session
    ↓
Profile / Role
    ↓
Role-Based Router
    ↓
Appropriate Application Area
```

Authentication and authorization are separate concepts.

### Authentication

Determines:

> Who is this user?

### Authorization

Determines:

> What is this user allowed to do?

---

# 10. User Profile and Role

Supabase Auth provides the authenticated account.

Application-specific user information should be stored in the database.

The system should maintain a profile representation associated with the authenticated user.

The profile should identify the user's application role.

Supported roles:

```text
admin
mechanic
customer
```

The role must be used for navigation and authorization.

The UI must not be treated as the security boundary.

---

# 11. Authorization

Authorization must be enforced at multiple levels.

## Application Level

The Flutter application uses the user's role to:

- Display the correct navigation
- Display appropriate screens
- Prevent invalid UI actions

## Database Level

Supabase Row Level Security must enforce access to protected records.

This is the actual security boundary.

Example:

```text
Customer
  ↓
Can query own vehicles

Mechanic
  ↓
Can query assigned service data

Admin
  ↓
Can query workshop-wide operational data
```

Hiding a button is not considered sufficient authorization.

---

# 12. Routing

The application uses centralized routing.

The router should support:

- Public routes
- Authentication routes
- Customer routes
- Mechanic routes
- Admin routes

Conceptually:

```text
/
├── Public
│   ├── Landing
│   ├── About
│   ├── Login
│   └── Register
│
├── Customer
│   └── /customer/*
│
├── Mechanic
│   └── /mechanic/*
│
└── Admin
    └── /admin/*
```

---

# 13. Route Guards

Route access should be validated based on:

1. Authentication state
2. User role
3. Route requirements

Example:

```text
Unauthenticated
    ↓
Login

Authenticated Customer
    ↓
Customer Area

Authenticated Mechanic
    ↓
Mechanic Area

Authenticated Admin
    ↓
Admin Area
```

A user attempting to access an unauthorized role area should be redirected appropriately.

---

# 14. State Management

PitMate should use a centralized state-management approach.

The project may use **Riverpod** for application and feature state.

State should represent:

- Authentication
- Loading
- Success
- Error
- Empty
- Form state
- Feature data
- Current user
- Current role

State providers should not contain presentation-specific widget code.

---

# 15. UI State Convention

Screens should explicitly handle common states.

At minimum:

```text
Loading
Success
Empty
Error
```

Example:

```text
Loading
   ↓
Success ──→ Display Data
   │
   └──→ Empty ──→ Empty State

Error ──→ Error State
```

A screen should not silently fail when a database operation produces an error.

---

# 16. Database Architecture

Supabase PostgreSQL is the primary persistent data store.

The database should be relational and normalized enough to avoid unnecessary duplication.

Core conceptual entities include:

```text
profiles
customers
mechanics
vehicles
bookings
service_orders
service_assignments
service_tasks
task_templates
task_checklists
spare_parts
inventory_transactions
part_requests
service_parts
service_costs
mechanic_earnings
notifications
service_reminders
```

The exact SQL schema is defined during database implementation.

The schema must remain consistent with `SPEC.md`.

---

# 17. Database Relationship Principles

Important relationships include:

```text
Profile
 ├── Customer
 │     └── Vehicles
 │           └── Bookings
 │                 └── Service Orders
 │
 └── Mechanic
       └── Service Assignments
             └── Service Orders
```

A service order may have:

```text
Service Order
├── Assignments
├── Tasks
├── Parts
├── Costs
└── Earnings
```

Relationships should use foreign keys wherever appropriate.

---

# 18. Database Security

Row Level Security must be enabled for tables containing user or workshop data that requires access restrictions.

Policies should be based on the authenticated Supabase user and relevant ownership/assignment relationships.

Examples:

### Customer

Can access records associated with their own customer profile.

### Mechanic

Can access records associated with their assignments.

### Admin

Can access workshop-wide operational records.

Security policies must be tested rather than assuming that application-side restrictions are sufficient.

---

# 19. Service Workflow Architecture

The service workflow should be represented through explicit status values.

Conceptual lifecycle:

```text
Requested
    ↓
Approved
    ↓
Scheduled
    ↓
Inspection
    ↓
Diagnosis
    ↓
Waiting for Approval
    ↓
Waiting for Parts
    ↓
In Progress
    ↓
Completion Review
    ↓
Completed
    ↓
Payment
    ↓
Closed
```

Not all services need to pass through every state.

The application should prevent invalid state transitions.

For example:

```text
Completed
   X
   ↓
Inspection
```

A completed service should not be arbitrarily moved backward without an explicitly supported workflow.

---

# 20. Service Task Architecture

Service tasks belong to Service Orders.

A task contains information such as:

- Service order
- Assigned mechanic
- Task name
- Description
- Status
- Checklist
- Required parts
- Completion information

Task state is independent from the overall service-order state.

For example:

```text
Service Order
Status: In Progress

Task A
Status: Completed

Task B
Status: In Progress

Task C
Status: Waiting for Parts
```

The overall service progress can be derived from task completion and service-state information.

---

# 21. Task Templates

Task templates are reusable definitions.

Conceptually:

```text
Task Template
    ↓
Create Service Task
    ↓
Generate Checklist
    ↓
Mechanic Performs Task
```

Templates should not directly represent a specific vehicle service.

They provide reusable starting points.

Custom tasks remain supported.

---

# 22. Inventory Architecture

Inventory is controlled by the Admin.

The system should distinguish between:

### Part Definition

Describes the spare part.

Examples:

- Name
- Brand
- Category
- Supplier
- Unit price

### Inventory State

Describes the current quantity.

### Inventory Transaction

Records stock movement.

Examples:

```text
Stock Added
Stock Reserved
Stock Used
Stock Adjusted
```

Inventory history should not rely solely on overwriting the current quantity.

Where practical, stock-changing operations should generate transaction records.

---

# 23. Part Request Architecture

Mechanics request parts through the Service Order.

Conceptual workflow:

```text
Mechanic
   ↓
Part Request
   ↓
Admin Review
   ↓
Approved / Rejected
   ↓
Inventory Action
```

If the required part is unavailable, the Service Order may enter `Waiting for Parts`.

---

# 24. Cost Architecture

Service costs should be represented separately from UI display.

Conceptually:

```text
Service Cost
├── Labor
├── Parts
├── Additional Charges
└── Total
```

The application should not calculate financial values independently in multiple screens.

Cost calculation rules should have a single logical source.

---

# 25. Mechanic Earnings Architecture

Mechanic earnings are associated with completed or applicable labor work.

Conceptually:

```text
Service Task
    ↓
Labor Value
    ↓
Mechanic Compensation Rule
    ↓
Mechanic Earning
```

The exact compensation calculation is a business rule and must remain consistent across:

- Service details
- Mechanic earnings
- Admin reports

---

# 26. Notification Architecture

Notifications are stored as application records.

A notification should contain enough information to identify:

- Recipient
- Type
- Related entity
- Message
- Read state
- Creation time

Example:

```text
Notification
 ├── Recipient
 ├── Type
 ├── Related Service
 ├── Message
 ├── Is Read
 └── Created At
```

Push-notification infrastructure is optional during the initial implementation.

The application must at minimum support notification records and an in-app notification interface.

---

# 27. Reminder Architecture

Service reminders are associated with vehicles and customers.

A reminder may be triggered by:

- Date
- Mileage
- Service interval

The reminder system should retain:

- Vehicle
- Reminder type
- Due condition
- Status
- Related service history

Automated reminder processing may be implemented later in the final phase.

---

# 28. File / Storage Architecture

Supabase Storage may be used for files if the application requires them.

Potential future examples:

- Vehicle images
- Service documentation
- Inspection photographs
- Receipts

File storage is not required for the initial UTS implementation unless explicitly needed.

Database records should store references to uploaded files rather than embedding large files directly in PostgreSQL.

---

# 29. Backend Responsibility

Supabase is responsible for:

- Authentication
- Persistent data
- Database relationships
- Access control
- Database-side validation where appropriate
- Storage
- Optional realtime functionality

Flutter is responsible for:

- User interface
- Local UI state
- User interaction
- Navigation
- Form handling
- Calling repositories
- Presenting backend results

Business rules that must be trusted should not exist only in Flutter.

---

# 30. Business Logic Placement

Use the following principle:

```text
UI Logic
    → Flutter

Application State
    → State Management

Data Access
    → Repository / Data Source

Security / Access Rules
    → Supabase RLS

Database Integrity
    → PostgreSQL constraints / functions where appropriate
```

Do not place large business workflows directly inside widgets.

Avoid database queries directly inside presentation widgets.

---

# 31. Error Handling

Backend and application errors should be converted into understandable application-level errors.

The UI should display useful messages.

Examples:

```text
Network failure
Database failure
Authentication failure
Permission denied
Validation failure
Record not found
Invalid state transition
```

Technical exception messages should not always be displayed directly to users.

---

# 32. Form Validation

Forms should perform basic client-side validation before submitting data.

Examples:

- Required fields
- Valid email
- Valid dates
- Valid numbers
- Valid mileage
- Valid quantities
- Valid prices

Backend constraints remain necessary because client-side validation is not a security mechanism.

---

# 33. Loading and Empty States

Every database-backed list should support:

### Loading

Data is being retrieved.

### Success

Data exists.

### Empty

The query succeeded but no records exist.

### Error

The query failed.

Example:

```text
Loading
  ↓
┌──────────────┐
│ Data Exists  │
└──────────────┘

or

┌──────────────┐
│ No Data Yet  │
└──────────────┘

or

┌──────────────┐
│ Error        │
└──────────────┘
```

---

# 34. Environment Configuration

Supabase configuration should not be hardcoded throughout the application.

Environment-specific configuration should be centralized.

Sensitive credentials must not be committed to Git.

Public client configuration that is intended for Flutter may be included through appropriate environment/configuration handling.

Service-role keys must never be included in the Flutter application.

---

# 35. Git Architecture

The repository should contain the complete source project.

Git should track:

- Flutter source
- Configuration templates
- Documentation
- Database migration files
- Tests
- Assets required by the project

Git should not track:

- Secrets
- Private credentials
- Local machine configuration
- Build artifacts
- Temporary files

---

# 36. Database Migrations

Database schema changes should be represented through migration files where practical.

The migration history should provide a reproducible representation of the database structure.

Database changes should not exist only as undocumented manual dashboard modifications.

---

# 37. Testing Architecture

Testing should exist at appropriate levels.

## Unit Tests

For:

- Business calculations
- State logic
- Utility functions
- Cost calculations
- Status transitions where practical

## Widget Tests

For:

- Important UI components
- Forms
- Loading states
- Error states
- Navigation-related UI

## Integration Tests

For critical workflows where practical.

Examples:

```text
Login
Customer creates vehicle
Customer submits booking
Admin approves booking
Admin assigns mechanic
Mechanic updates task
Service completes
```

The testing scope may increase during final-term implementation.

---

# 38. Feature Development Pattern

A feature should generally be implemented in this order:

```text
1. Requirement
      ↓
2. Data Model
      ↓
3. Database / RLS
      ↓
4. Repository
      ↓
5. State Management
      ↓
6. Screen
      ↓
7. Components
      ↓
8. Validation
      ↓
9. Loading / Empty / Error States
      ↓
10. Testing
```

Not every simple UI-only feature requires every step.

---

# 39. Development Milestones

## Milestone 1 — Project Foundation

- Flutter project
- Git repository
- Basic application shell
- Theme foundation
- Router foundation
- Supabase client initialization

## Milestone 2 — Authentication

- Login
- Customer registration
- Logout
- Session handling
- Password management
- Role identification

## Milestone 3 — UTS Interface

- Public pages
- Role dashboards
- Vehicle UI
- Booking UI
- Service UI
- Mechanic UI
- Inventory UI
- History UI
- Reports UI
- Notification UI

## Milestone 4 — Database Integration

- Real Supabase data
- Database relationships
- RLS
- Demo records

## Milestone 5 — Final Workflow

- Booking workflow
- Service workflow
- Mechanic assignments
- Inspection
- Diagnosis
- Tasks
- Checklist
- Parts
- Inventory
- Cost calculation
- Earnings
- Completion
- History

## Milestone 6 — Finalization

- Notifications
- Reminders
- Reports
- Testing
- Error handling
- Performance cleanup
- Security review

---

# 40. UTS Architecture Boundary

During UTS, the architecture should already establish:

```text
Flutter
   ↓
Supabase
   ↓
PostgreSQL
```

The UI may still contain simplified interactions where final business logic has not yet been implemented.

However, the project must not be designed around temporary mock repositories that will later require a complete rewrite.

Demo data should preferably exist in Supabase.

---

# 41. Final Architecture Boundary

The final application should use the same architectural foundation established during UTS.

The final phase adds business logic rather than replacing the architecture.

The goal is:

```text
UTS
UI + Foundation + Database
             ↓
UAS
Complete Business Workflow
```

not:

```text
UTS
Fake Mock Application
             ↓
UAS
Rewrite Everything
```

---

# 42. Design Dependency

`ARCHITECTURE.md` defines technical structure.

`DESIGN.md` defines visual structure.

Neither document should duplicate the other.

The application architecture should consume the design system rather than defining arbitrary visual styles inside individual screens.

---

# 43. Specification Dependency

`SPEC.md` defines what PitMate must do.

If a technical decision conflicts with a functional requirement in `SPEC.md`, the technical decision must be reconsidered.

If the specification itself needs to change, the specification should be updated deliberately before implementation proceeds.

---

# 44. Agent Development Principle

AI coding agents must work incrementally.

The agent should:

1. Read `SPEC.md`
2. Read `ARCHITECTURE.md`
3. Read `DESIGN.md`
4. Read `AGENTS.md`
5. Inspect the existing repository
6. Identify the current milestone
7. Implement only the requested scope
8. Run appropriate validation
9. Report changes
10. Wait for the next milestone

The agent should not redesign the entire project when asked to implement a single feature.

---

# 45. Architecture Decision Rules

When introducing a new dependency, abstraction, or architectural pattern, the implementation should first determine whether it is actually required.

Prefer:

- Simple solutions
- Existing project dependencies
- Flutter-native capabilities
- Supabase capabilities
- Reusable components
- Clear feature boundaries

Avoid unnecessary:

- Custom backend servers
- Duplicate data layers
- Excessive abstractions
- Global state for local UI problems
- Large framework additions
- Premature optimization

---

# 46. Final Architecture Principle

PitMate should remain:

```text
Simple enough to understand
        +
Structured enough to maintain
        +
Secure enough to protect data
        +
Flexible enough to complete the final workflow
```

The architecture exists to support the requirements defined in `SPEC.md`.

It should not become a larger engineering project than PitMate itself.

---

# UAS Architecture Addendum — Operational Queue, Themes, Reports, Customization

## A. Canonical customization layer

The application-wide customization definitions belong under `lib/app/customization/`. This is the only intended code location for frequently adjusted visual/catalog values:

```text
lib/app/customization/
├── pitmate_palette.dart          # semantic light/dark and status colors
├── pitmate_typography.dart       # fonts, type scale, text styles
├── pitmate_layout.dart           # spacing, radii, dimensions
├── pitmate_status_catalog.dart   # status labels, display groups, colors, icons
├── pitmate_service_catalog.dart  # controlled service categories and labels
└── pitmate_theme.dart            # ThemeData and component theme assembly
```

Do not create a second parallel token system in `shared/`, feature folders, or individual screens. Existing files such as `lib/app/theme/app_colors.dart` and `app_theme.dart` must be inspected before implementation; migrate or wrap them deliberately rather than leaving two competing sources. The exact filenames may be adapted to existing naming conventions, but there must be one canonical customization layer and no duplicate definitions.

Database status values are a persistent domain contract and remain defined in `DB-SCHEMA.md`/migrations. `pitmate_status_catalog.dart` is the single Flutter presentation mapping for those values. A status change is incomplete until migration/schema, model validation, status catalog, transition rules, and tests are synchronized.

## B. Queue and check-in data flow

```text
Admin checks in booking ─┐
                         ├─> transaction-safe repository operation
Admin registers walk-in ─┘             │
                                       ├─ create/link service order
                                       ├─ set intake_origin and arrived_at
                                       ├─ update booking to checked_in when applicable
                                       └─ preserve one-to-one booking association
                                                │
                                                ▼
                                    Riverpod queue provider
                                                │
                                                ▼
                                      Admin / Mechanic UI
```

Do not perform check-in as several unrelated client mutations if a partial failure could leave the booking and service order inconsistent. Prefer one PostgreSQL RPC/transaction-backed operation for check-in. The walk-in operation must also set origin and arrival in the same database write/transaction.

Recommended fields:

- `service_orders.intake_origin`: controlled value `booking`, `walk_in`, or `legacy_unknown`.
- `service_orders.arrived_at`: nullable `timestamptz`; set only when the vehicle physically arrives. Do not default this to `now()` for records that might represent pre-arrival work.
- `profiles.theme_mode`: controlled `dark`, `light`, or `system` preference.
- `booking_status.checked_in`: state for the booking after successful admission, before service completion.

`booking_id` alone is not a reliable origin audit field because it is nullable and uses `ON DELETE SET NULL`. Add an origin field and backfill current rows with `legacy_unknown` unless a booking association proves the origin. Never infer historical walk-ins from null `booking_id`.

## C. Queue projection and state derivation

The queue is a view/projection over bookings and service orders, not a new competing lifecycle. Upcoming bookings remain in the booking workflow until check-in. The physical queue includes only service orders with non-null `arrived_at` and an active service status. Sort by `arrived_at ASC`, then `created_at ASC`, then stable ID. Group cards by the existing service status catalog; do not invent extra persisted service statuses just for UI sections.

Admin may see all workshop queue entries permitted by RLS. Mechanics see their assigned work only. Customer views remain restricted to their own vehicles/orders. “Waiting for parts” and “waiting for approval” must remain visibly blocked, not visually conflated with “in progress.”

## D. Theme state and persistence

`MaterialApp.router` reads the current `ThemeMode` from one Riverpod provider. The provider initializes from the authenticated profile, updates local state immediately after a successful preference mutation, and persists `theme_mode` to Supabase. Define explicit behavior for loading/auth transitions and failed writes; a failed persistence operation must not silently imply that a preference was saved. `system` mode follows the platform theme, while `dark` remains the default for existing profiles until changed.

The provider manages preference state, not palette values. `pitmate_theme.dart` composes both themes from the customization layer. Shared widgets must use `Theme.of(context)` / `ColorScheme` and token-backed component themes rather than hardcoding the old dark colors.

## E. Reporting flow

```text
Admin Reports UI
  -> reportsProvider(date range / grouping)
  -> reportsRepository
  -> Supabase RPC or aggregate views
  -> PostgreSQL with explicit authorization and aggregation
  -> typed report DTOs
  -> charts + accessible textual/table summaries
```

Use a date-scoped aggregate contract and return only fields required for the report. Use a PostgreSQL view when the query is reusable and naturally compatible with RLS. Use an RPC for parameterized date ranges or coordinated aggregates. Prefer invoker security; any definer function needs explicit Admin authorization, safe `search_path`, restricted grants, and security tests. Avoid loading all service orders into Flutter and computing aggregate business reports in memory.

Mandatory intake metric uses `intake_origin`; `legacy_unknown` is its own bucket and is excluded from booking/walk-in comparison. Define each financial metric and its qualifying statuses before coding. Do not combine estimated and final totals into one figure.

## F. UAS dependency order

1. Audit existing schema, migrations, models, providers, routes, and current theme/token files.
2. Finalize docs and UI references; agree on the customization layer.
3. Add migration and transaction-safe check-in/origin/theme/report foundations with RLS tests.
4. Implement queue and check-in.
5. Complete real service-task mutations and status-transition validation.
6. Implement persistent dual themes.
7. Implement report RPC/views and chart presentation.
8. Apply Stitch-informed UI refinement and Anti-Slop checks.
9. Run workflow integration tests, `flutter analyze`, `flutter test`, and the target build; report any manual checks separately.

## G. Authentication OTP, Automated Reminders & Cron Architecture

### 1. Cross-Platform OTP Verification
Supabase Auth email confirmation links rely on PKCE redirect tokens targeting localhost or specific app schemes, which fail when links are opened on a different device or email scanners consume the single-use token.
PitMate provides a direct 6-digit OTP verification flow (`verifyOtp`, `resendOtp` in `AuthRemoteDataSource` and `AuthSessionNotifier`). Users on web, desktop, and mobile can enter the verification token received in their email directly inside the client to activate their account and establish an authenticated session.

### 2. Automated Service Reminders Lifecycle
```text
Service Order completed / closed
       │
       ▼ (DB Trigger: trg_auto_generate_service_reminder)
Create pending service reminder (+6 months / +10,000 KM)
       │
       ▼ (Client sync: customerServiceRemindersProvider.syncFromServiceHistory)
Customer Reminders View & Dashboard alert
```
Customers can also author custom specification reminders through `createReminder`, which persist to `public.service_reminders` with vehicle-level associations.

### 3. Background Cron & On-Demand Refresh
- Function `public.check_workshop_cron_tasks()` handles 24-hour expired booking cancellations, multi-interval notification dispatches, and inventory threshold monitoring.
- Scheduled automatically in PostgreSQL via `pg_cron` (`*/5 * * * *`).
- Exposed via safe RPC and triggered interactively by the Global Refresh button in `RoleShellScaffold`.
