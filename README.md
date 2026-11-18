# PitMate

**PitMate** is a car workshop management application built with Flutter and Supabase.

The application is designed to help a workshop manage customers, vehicles, bookings, service orders, mechanics, service tasks, spare-parts inventory, costs, service history, notifications, reminders, and reports.

The project uses a motorsport-inspired visual identity focused on technical information, clear operational status, and professional workshop workflows.

---

## 1. Project Overview

PitMate is a college semester project focused on developing a mobile-based workshop management system.

The application supports three primary user roles:

| Role | Purpose |
|---|---|
| **Admin / Workshop Owner** | Manage workshop operations, customers, mechanics, vehicles, services, inventory, costs, and reports |
| **Mechanic** | Handle assigned services, inspections, diagnoses, tasks, checklists, parts requests, and service progress |
| **Customer** | Manage vehicles, request/book services, monitor service progress, view costs and service history |

PitMate is designed for a **single physical workshop**.

Multi-branch workshop management is outside the current project scope.

---

# 2. Main Features

## Authentication

- User registration with direct 6-digit OTP verification across web, desktop, and mobile
- User login
- User logout
- Role-based access
- User profile management

Supported roles:

```text
admin
mechanic
customer
```

---

## Customer Management

Administrators can manage customer information.

Customers can manage their own profile.

---

## Vehicle Management

Customers can manage their registered vehicles.

Vehicle information may include:

- Vehicle name
- Brand
- Model
- Year
- License plate
- VIN
- Mileage
- Other relevant vehicle information

---

## Booking Management

Customers can submit service requests and bookings.

Administrators can review and manage bookings.

Bookings may progress through the workshop service workflow.

---

## Workshop Queue & Intake Management

Administrators can manage physical intake and floor dispatch via the dedicated Workshop Queue:

- **5 Physical Queue Sections**: Upcoming Bookings, Waiting in Workshop, In Service, Blocked / Awaiting Action, and Recently Completed.
- **Deterministic FIFO Ordering**: Arrived vehicles are ordered strictly by arrival time (`arrived_at ASC`) with deterministic tie-breakers (`created_at ASC`, `id ASC`).
- **Booking Check-In**: Atomic arrival check-in converting pending bookings to arrived queue orders via `check_in_booking` RPC.
- **Walk-In Admission**: Direct vehicle admission modal creating service orders with explicit `walk_in` intake origin via `admit_walk_in` RPC.
- **Intake Origin Preservation**: `booking`, `walk_in`, and `legacy_unknown` origins are preserved through mechanic workflows, customer service history, and billing receipts.
- **Hold Blocker Telemetry**: Prominent hold callout banners for blocked orders (waiting for parts, customer approval, completion review).

---

## Dual-Theme Support

Motorsport-clean dual theme system with instant per-user toggle:

- **Dark Theme (Default)**: Motorsport-inspired obsidian surfaces (`#0B0D10`, `#171C22`) with bold racing red accents (`#E10600`) and high-contrast typography.
- **Light Theme**: Technical off-white palette (`#F7F9FC`, `#FFFFFF`) with deep slate typography (`#0F172A`) meeting WCAG AA contrast standards.
- **Persistence**: Saved per-user in Supabase profile (`theme_mode`) and reactive across mobile and desktop app headers.

---

## Service Management

Service orders can contain:

- Customer
- Vehicle
- Service information
- Assigned mechanics
- Tasks
- Checklists
- Spare parts
- Cost information
- Service status
- Service history

---

## Mechanic Management

Administrators can:

- Manage mechanic accounts
- Assign mechanics to services
- Review mechanic activity
- Review mechanic earnings

Mechanics can:

- View assigned services
- Perform assigned tasks
- Complete checklists
- Submit notes
- Request required parts
- Track service progress

---

## Inventory Management

The inventory system manages workshop spare parts.

Information includes:

- Part name
- SKU
- Stock quantity
- Minimum stock
- Unit price
- Inventory transactions
- Part requests
- Parts used by service orders

---

## Cost Management

Service costs can include:

```text
Labor
+
Parts
+
Additional Charges
=
Total Cost
```

The system supports estimated costs and final costs.

Final costs may differ from the original estimate.

---

## Service History

Completed services are retained as service history.

History may include:

- Vehicle
- Service performed
- Service date
- Mechanics
- Tasks
- Parts used
- Costs
- Final status

---

## Notifications

The application provides automated notifications for relevant operational events:

- Booking updates and multi-interval countdowns (1h, 30m, exact time)
- 24-hour missed booking grace window notifications with one-click reschedule
- Low stock and critical inventory alerts for administrators
- Service status changes and assignment notifications for mechanics
- Real-time notification drawer with unread counter across all roles

---

## Reminders

Customers receive service-related reminders with automated sync:

- Automated follow-up maintenance reminders generated from completed service orders (+6 months / +10,000 KM)
- Custom user-created interval and mileage alerts
- Target mileage and milestone specification tracking
- One-click "Sync History" to backfill vehicle maintenance schedules

---

## Reports & Workshop Telemetry

The reporting engine provides real-time, secured operational telemetry powered by Supabase aggregation RPCs (`get_admin_reports_telemetry`) and resilient RLS fallback:

- **Date Boundary Filtering**: Normalized inclusive date windows with quick presets (`7 Days`, `30 Days`, `Month to Date`, `All Time`) and custom date range picker.
- **Intake Origin Comparison**: Compares scheduled bookings vs direct walk-in admissions, keeping `legacy_unknown` strictly isolated (never conflated with walk-ins) with screen reader accessibility summaries and stacked visual ratio bars.
- **Financial Telemetry**: Strictly distinguishes between **Settled Realized Revenue** (finalized invoices on completed/closed orders) and **Estimated Pipeline Total** (work in progress).
- **Service Status Distribution & Daily Activity**: Visual breakdown of orders across lifecycle states and daily volume ingestion timeline.
- **Mechanic Workload Allocation**: Detailed table tracking assigned, active, and completed jobs per technician.
- **Telemetry Export**: Auditable export modal generating operational telemetry summaries.

---

# 3. Service Workflow

A service order may progress through the following states:

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

Not every service must necessarily pass through every state.

The exact workflow is defined by the project specification and implementation.

---

# 4. Technology Stack

## Frontend

- Flutter
- Dart

## Backend

- Supabase
- PostgreSQL
- Supabase Auth
- Row Level Security (RLS)

## State Management

- Riverpod

## Navigation

- GoRouter

## Typography

- Inter
- Space Grotesk

---

# 5. Architecture

The application follows a feature-oriented Flutter architecture.

High-level structure:

```text
Flutter Application
        │
        ├── Presentation
        │
        ├── State / Application Logic
        │
        └── Data Layer
                │
                └── Supabase
                      │
                      ├── Authentication
                      ├── PostgreSQL
                      ├── RLS
                      └── Optional Storage / Realtime
```

The main project structure is:

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router/
│   ├── customization/
│   ├── theme/
│   └── config/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── utils/
│   └── widgets/
├── data/
│   ├── models/
│   ├── repositories/
│   └── datasources/
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
└── shared/
    ├── models/
    ├── widgets/
    └── providers/
```

For a detailed explanation, see:

- `ARCHITECTURE.md`
- `DESIGN.md`
- `SPEC.md`
- `AGENTS.md`
- `CUSTOMIZATION.md`

---

# 6. Design

PitMate features a motorsport-inspired interface designed for high legibility, performance, and accessibility.

The design emphasizes:

- Technical telemetry & clean workshop hierarchy
- Dual-theme system (Motorsport Dark by default, with accessible Motorsport Light switch)
- Central customization layer in `lib/app/customization/` (`PitmatePalette`, `PitmateTypography`, `PitmateLayout`, `PitmateTheme`)
- Per-profile theme persistence across sessions stored in `profiles.theme_mode`
- Clear, distinct status communication (`StatusBadge`, `PitCard`, `StatCard`)
- High contrast WCAG AA ratios across both light (`#F7F9FC` background / `#0F172A` text) and dark (`#0B0D10` background / `#F5F7FA` text)
- Minimum 44px tap targets for mobile technicians and workshop service desks

Detailed design rules are defined in:

```text
DESIGN.md
CUSTOMIZATION.md
```

---

# 7. Security

PitMate uses Supabase Authentication and PostgreSQL Row Level Security.

The application uses role-based authorization for:

```text
Admin
Mechanic
Customer
```

UI restrictions are not considered a sufficient security mechanism.

Database permissions must be protected through appropriate RLS policies.

The Flutter application must never contain:

- Supabase service-role keys
- Private backend credentials
- Other server-side secrets

---

# 8. Project Scope

## Included

The project includes:

- Authentication
- Role-based interfaces
- Customer management
- Mechanic management
- Vehicle management
- Booking management
- Service orders
- Mechanic assignments
- Service tasks
- Task checklists
- Service progress
- Spare-parts inventory
- Part requests
- Cost estimation
- Final cost recording
- Service history
- Mechanic earnings
- Notifications
- Reminders
- Reports

---

## Out of Scope

The following are outside the current project scope:

- Multi-branch workshop management
- Real payment gateway integration
- External accounting systems
- Automatic parts purchasing
- ECU/OBD diagnostics
- Vehicle telemetry
- Insurance integration
- Manufacturer APIs
- GPS tracking
- Marketplace functionality
- Full payroll/tax management
- External appointment synchronization

These features should not be added unless the project scope is explicitly changed.

---

# 9. Development Phases

## UTS

The UTS milestone focuses on establishing the project foundation and major interface structure.

Primary objectives include:

- Flutter project setup
- Application shell
- Navigation
- Authentication interface
- Role-aware interface foundation
- Dashboard interfaces
- Vehicle management
- Booking interface
- Service interface
- Inventory interface
- Reports/history interface
- Notifications/reminders interface
- Supabase connection
- Database foundation
- Authentication foundation
- Demo data

---

## UAS

**Status: Phase 1 (Docs & Stitch Assets), Phase 2 (Database & Domain Foundations), Phase 3 (Workshop Queue & Intake UI), and Phase 7 (Stitch-Informed UI Refinement & Anti-Slop Review) Complete.** Workshop Queue with 5 physical sections, deterministic FIFO arrival sorting, booking check-in, walk-in admission, mechanic blocker telemetry, customer origin retention, dual-theme persistence, and WCAG AA contrast compliance verified with 73/73 tests passing. Follow `UAS-PLAN.md` for dependency order and acceptance criteria.


Primary objectives include:

- Explicit workshop queue and vehicle check-in
- Booking-to-service-order conversion with a persistent intake origin
- Walk-in service-order creation and FIFO queue ordering
- Complete service lifecycle, assignments, tasks, and checklists
- Real Supabase writes for actions currently represented by SnackBars
- Persistent per-user light/dark theme selection for all roles
- PostgreSQL-backed report aggregation and real Flutter charts
- Booking-versus-walk-in history and reporting
- RLS, valid status transitions, and workflow integration tests
- Anti-Slop review and Stitch-informed UI refinement
- Final analysis, tests, and build validation

---

# 10. Development Guidelines

PitMate is developed using AI-assisted programming.

AI agents must follow the project's documentation and existing architecture.

The primary development rule is:

> **Inspect before editing. Implement incrementally. Validate before claiming success.**

Agents should avoid:

- Unnecessary rewrites
- Unrelated refactoring
- Arbitrary dependencies
- Inventing requirements
- Bypassing security
- Replacing the established architecture without approval

Detailed agent rules are defined in:

```text
AGENTS.md
```

---

# 11. Documentation

UAS planning references: `UAS-PLAN.md`, `CUSTOMIZATION.md`, and `STITCH-UI-BRIEF.md`.

The project uses the following primary documentation:

| Document | Purpose |
|---|---|
| `SPEC.md` | Functional requirements and project scope |
| `ARCHITECTURE.md` | Application architecture and technical structure |
| `DESIGN.md` | Visual identity and UI/UX system |
| `DB-SCHEMA.md` | Database schema, constraints, and RLS contract |
| `AGENTS.md` | AI-assisted development rules |
| `CUSTOMIZATION.md` | Canonical app customization source-of-truth rules |
| `UAS-PLAN.md` | UAS milestones, dependencies, and acceptance criteria |
| `STITCH-UI-BRIEF.md` | Google Stitch reference-generation and handoff brief |
| `README.md` | Project overview and setup reference |

These documents should remain consistent with the implementation.

---

# 12. Project Structure

At the repository level, the project is expected to contain structures similar to:

```text
pitmate/
├── android/
├── ios/
├── lib/
├── test/
├── assets/
├── supabase/
│   └── migrations/
├── docs/
├── .gitignore
├── AGENTS.md
├── ARCHITECTURE.md
├── DESIGN.md
├── README.md
├── SPEC.md
├── analysis_options.yaml
├── pubspec.yaml
└── ...
```

The exact structure may evolve as implementation progresses.

---

# 13. Getting Started

## Prerequisites

Install the required development tools:

- Flutter SDK
- Dart SDK through Flutter
- Git
- Android Studio or another supported Android development environment
- A configured Android emulator or physical Android device
- Supabase project

Verify Flutter installation:

```bash
flutter --version
```

Verify the development environment:

```bash
flutter doctor
```

---

# 14. Installing Dependencies

After cloning the project:

```bash
flutter pub get
```

---

# 15. Environment Configuration

Supabase configuration must be provided through the project's approved configuration mechanism.

Do not commit private credentials.

The project should contain only client-safe configuration values in the Flutter application.

If environment configuration is required, follow the project's current configuration implementation rather than creating an additional configuration system.

---

# 16. Running the Application

Check available devices:

```bash
flutter devices
```

Run the application:

```bash
flutter run
```

For a specific device:

```bash
flutter run -d <device-id>
```

---

# 17. Static Analysis

Run:

```bash
flutter analyze
```

The project should not introduce new analyzer errors.

Warnings should be reviewed rather than blindly ignored.

---

# 18. Testing

Run the test suite with:

```bash
flutter test
```

For a specific test:

```bash
flutter test test/<test_file>.dart
```

Tests should be added when important business logic or application behavior is introduced.

---

# 19. Building

For Android APK development builds:

```bash
flutter build apk
```

For a release build:

```bash
flutter build apk --release
```

Build commands may change depending on the deployment requirements.

---

# 20. Git Workflow

Before committing changes:

```bash
git status
```

Review modified files carefully.

The repository should not contain:

- Secrets
- Service-role keys
- Temporary files
- Build artifacts
- Local machine credentials

Commit messages should describe the actual change.

Example:

```text
feat: add vehicle management screen
```

or:

```text
fix: prevent duplicate service assignment
```

---

# 21. Current Project Philosophy

PitMate is intentionally designed as a focused college project rather than a production-scale enterprise platform.

The project should remain:

- Understandable
- Maintainable
- Secure
- Testable
- Visually distinctive
- Practical to develop within the available project timeline

Complexity should only be introduced when it solves an actual requirement.

---

# 22. Quick Reference

```text
Project
└── PitMate
    └── Car Workshop Management Application

Frontend
└── Flutter / Dart

Backend
└── Supabase / PostgreSQL

Authentication
└── Supabase Auth

Authorization
└── PostgreSQL RLS

State Management
└── Riverpod

Navigation
└── GoRouter

Design
└── Motorsport-inspired dark UI

Roles
├── Admin
├── Mechanic
└── Customer
```

---

# 23. Source of Truth

When working on PitMate, consult the project documentation before making significant changes.

```text
SPEC.md
    ↓
What the application must do

ARCHITECTURE.md
    ↓
How the application is structured

DESIGN.md
    ↓
How the application should look and behave

AGENTS.md
    ↓
How AI agents should modify the project

README.md
    ↓
How the project is understood, configured, and run
```

Together, these documents define the initial foundation of PitMate.

---

# UAS Scope Clarification — Phase 0 Audit

The Phase 0 audit found `admin_reports_view.dart` is currently a placeholder with simulated export feedback, and mechanic task actions include UI-only stubs. The booking approval flow does not yet create a linked service order. These are known gaps, not completed capabilities.

The UAS work is tracked in `UAS-PLAN.md`. Read `CUSTOMIZATION.md` for the central app customization layer and `STITCH-UI-BRIEF.md` for the UI-reference workflow. Keep the technology stack Flutter + Riverpod + GoRouter + Supabase unless an explicit course requirement changes it.
