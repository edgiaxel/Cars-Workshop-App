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

- User registration
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

The application can provide notifications for relevant operational events.

Examples include:

- Booking updates
- Service status changes
- Approval updates
- Inventory warnings
- Other relevant workshop events

---

## Reminders

Customers can receive service-related reminders.

Examples include:

- Upcoming maintenance
- Recommended service
- Vehicle-related reminders

---

## Reports

Administrators can access operational summaries and reports.

Possible report information includes:

- Service activity
- Revenue
- Inventory status
- Mechanic workload
- Service history
- Other relevant workshop metrics

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

---

# 6. Design

PitMate uses a dark, motorsport-inspired interface.

The design emphasizes:

- Technical information
- Strong information hierarchy
- Clear service status
- Operational dashboards
- Compact data presentation
- Professional workshop aesthetics
- Mobile usability

The primary visual foundation uses dark surfaces with controlled accent and semantic colors.

Detailed design rules are defined in:

```text
DESIGN.md
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

The UAS milestone extends the existing foundation with complete operational workflows.

Primary objectives include:

- Complete service lifecycle
- Mechanic assignments
- Service tasks
- Checklists
- Parts requests
- Inventory transactions
- Service parts
- Cost calculations
- Final costs
- Mechanic earnings
- Service history
- Notifications
- Reminders
- Reports
- RLS policies
- Testing
- Final integration

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

The project uses the following primary documentation:

| Document | Purpose |
|---|---|
| `SPEC.md` | Functional requirements and project scope |
| `ARCHITECTURE.md` | Application architecture and technical structure |
| `DESIGN.md` | Visual identity and UI/UX system |
| `AGENTS.md` | AI-assisted development rules |
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