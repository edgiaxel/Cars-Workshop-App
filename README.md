# PitMate

**Automotive Workshop Management System**

A motorsport-inspired workshop management application built with Flutter and Supabase.

PitMate provides an integrated platform for managing workshop operations, customer vehicles, service bookings, mechanic assignments, inventory, finances and vehicle maintenance.

---

## 1. Overview

PitMate is designed for a single physical automotive workshop.

It connects workshop administrators, mechanics and customers through one application with role-specific interfaces.

The system aims to simplify workshop operations by centralizing:

- Customer and vehicle management.
- Appointment scheduling.
- Walk-in vehicle admission.
- Workshop queue management.
- Vehicle inspection and diagnostics.
- Repair estimates and customer authorization.
- Mechanic assignments and task tracking.
- Spare-parts inventory.
- Service costs and mechanic earnings.
- Quality control.
- Invoicing and payment records.
- Maintenance reminders.
- Workshop reporting.

## 2. User Roles

### Admin

Workshop administrators manage the overall operation.

Capabilities include:

- Workshop dashboard.
- Customer management.
- Vehicle registry.
- Booking management.
- Walk-in admission.
- Workshop queue.
- Bay allocation.
- Mechanic management.
- Service assignments.
- Inventory management.
- Financial records.
- Quality control.
- Reporting and analytics.

### Mechanic

Mechanics handle assigned workshop operations.

Capabilities include:

- Mechanic dashboard.
- Assigned service orders.
- Inspection and diagnostics.
- Task checklists.
- Repair progress updates.
- Parts requests.
- Additional repair findings.
- Work history.
- Earnings information.

### Customer

Customers manage their vehicles and follow workshop services.

Capabilities include:

- Account management.
- Vehicle registration.
- Appointment booking.
- Booking status.
- Active service tracking.
- Service history.
- Repair estimates.
- Customer notifications.
- Invoices.
- Maintenance reminders.

---

## 3. Technology Stack

| Component | Technology |
|---|---|
| Application | Flutter |
| Programming language | Dart |
| Backend | Supabase |
| Database | PostgreSQL |
| Authentication | Supabase Auth |
| Realtime | Supabase Realtime |
| State management | Riverpod |
| Navigation | GoRouter |
| UI framework | Flutter Material 3 |
| Version control | Git |
| Collaboration | GitHub |
| Development IDE | Antigravity IDE |

### Architecture

PitMate follows a layered application architecture.

```text
Flutter Application
│
├── Presentation Layer
│   ├── Admin Interface
│   ├── Mechanic Interface
│   ├── Customer Interface
│   └── Shared Widgets
│
├── State / Application Layer
│   ├── Riverpod Providers
│   ├── State Notifiers
│   └── Application Logic
│
└── Data Layer
    ├── Domain Models
    ├── Repositories
    └── Remote Data Sources
             │
             ▼
       Supabase Backend
             │
             ├── PostgreSQL
             ├── Supabase Auth
             ├── Row Level Security
             ├── Database Functions
             ├── Database Triggers
             └── Realtime
```

The existing application and its architecture are the starting point for further development.

Refer to `ARCHITECTURE.md` for detailed technical documentation.

---

## 4. Repository Structure

The following represents the reported application structure. Inspect the actual repository before assuming every path is unchanged.

```text
pitmate/
│
├── android/
├── web/
│
├── lib/
│   ├── main.dart
│   │
│   ├── app/
│   │   ├── app.dart
│   │   ├── config/
│   │   ├── router/
│   │   ├── theme/
│   │   └── customization/
│   │
│   ├── core/
│   │
│   ├── features/
│   │   ├── admin/
│   │   ├── mechanic/
│   │   ├── customer/
│   │   └── auth/
│   │
│   └── shared/
│       ├── models/
│       ├── providers/
│       ├── repositories/
│       └── widgets/
│
├── supabase/
│   ├── migrations/
│   └── seed.sql
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── docs/
│
├── AGENTS.md
├── ARCHITECTURE.md
├── CHANGELOG.md
├── DESIGN.md
├── MILESTONE.md
├── PRD.md
├── README.md
│
├── pubspec.yaml
└── pubspec.lock
```

---

## 5. Requirements

Before running PitMate, install:

- Flutter SDK (stable channel).
- Dart SDK compatible with the Flutter installation.
- Android SDK for Android development.
- A configured Android emulator or physical device.
- Google Chrome for Flutter Web development.
- Git.
- A Supabase project with appropriate access.

The recorded development baseline is:

| Tool | Reported version |
|---|---|
| Flutter | 3.47.2 |
| Dart | 3.13.2 |
| Supabase Flutter | 2.18.0 |
| Riverpod | 3.4.3 |
| GoRouter | 18.0.2 |

Versions should be checked against the current repository's dependency lockfile before making changes.

---

## 6. Installation

### 6.1 Clone the repository

```bash
git clone <REPOSITORY_URL>

cd <REPOSITORY_DIRECTORY>
```

Replace the placeholders with the actual GitHub repository URL and directory.

### 6.2 Verify Flutter

```bash
flutter --version
flutter doctor
```

Resolve required development environment issues before proceeding.

### 6.3 Install dependencies

```bash
flutter pub get
```

Do not delete or regenerate `pubspec.lock` unnecessarily.

### 6.4 Configure Supabase

PitMate connects to Supabase through its existing configuration contract:

`lib/app/config/app_config.dart`

The reported configuration supports:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Provide the appropriate public project URL and publishable client key through the supported build-time configuration mechanism.

Example:

```bash
flutter run \
  --dart-define=SUPABASE_URL=<YOUR_SUPABASE_URL> \
  --dart-define=SUPABASE_ANON_KEY=<YOUR_SUPABASE_PUBLISHABLE_KEY>
```

Use the configuration expected by the actual repository.

**Security:**

- Never use a Supabase service-role key in the Flutter application.
- Never commit private credentials.
- Never place database passwords in client-side configuration.
- Do not publish real credentials in screenshots or documentation.

### 6.5 Run the application

For Android:

```bash
flutter run
```

For Flutter Web:

```bash
flutter run -d chrome
```

Select an available Android device or emulator where necessary.

---

## 7. Development Commands

| Purpose | Command |
|---|---|
| Check Flutter | `flutter --version` |
| Check environment | `flutter doctor` |
| Install dependencies | `flutter pub get` |
| Run Android | `flutter run` |
| Run Web | `flutter run -d chrome` |
| Static analysis | `flutter analyze` |
| Format code | `dart format .` |
| Run tests | `flutter test` |
| Build Android APK | `flutter build apk` |
| Build Web | `flutter build web` |
| Build asset bundle | `flutter build bundle` |

### Validation

Before submitting code changes, execute:

```bash
dart format .
flutter analyze
flutter test
```

Formatting should not introduce unrelated changes. Review the Git diff afterward.

Run integration tests and platform-specific builds when the modified feature requires them.

The commands above are standard Flutter commands; their success in the current working environment must be verified.

---

## 8. Database

PitMate uses Supabase PostgreSQL as its primary persistent database.

The reported baseline contains:

- 19 core PostgreSQL tables.
- 10 database migrations.
- Row Level Security policies.
- Database functions and RPC operations.
- Automated database triggers.
- Inventory movement records.
- Service status history.

Important existing database operations include:

| Function | Purpose |
|---|---|
| `check_in_booking` | Convert an eligible booking into a service order |
| `admit_walk_in` | Register an unscheduled workshop arrival |
| `get_admin_reports_telemetry` | Generate aggregated workshop reports |
| `adjust_spare_part_stock` | Adjust inventory and record stock movement |

### Database Rules

- Use version-controlled migrations.
- Preserve existing migration history.
- Maintain Row Level Security.
- Preserve transactional integrity.
- Do not manually modify production schema without authorization.
- Never reset the database without explicit approval.

Refer to the existing database schema documentation for the authoritative table and function definitions.

---

## 9. Testing

PitMate uses Flutter's testing framework.

### Unit Testing

Tests individual business logic and application components.

Examples:

- Authentication.
- User roles.
- Model serialization.
- Business calculations.
- Route guards.
- Workshop queue ordering.

### Widget Testing

Tests UI behavior.

Examples:

- Role navigation.
- Login and registration.
- Workshop queue.
- Admin reports.
- Shared widgets.
- Responsive components.

### Integration Testing

Tests interactions across application and backend boundaries.

Examples:

- Booking lifecycle.
- Walk-in admission.
- Service order creation.
- Role isolation.
- Supabase RPC contracts.

### Reported Baseline

The system discovery report dated 2026-11-20 recorded:

| Check | Result |
|---|---|
| `flutter analyze` | 0 issues |
| `flutter test` | 89/89 passed |
| `flutter build bundle` | Passed |

These are historical results. Run the checks again after making changes.

---

## 10. Project Documentation

PitMate maintains separate documents for product, design, engineering and development progress.

| Document | Description |
|---|---|
| `PRD.md` | Product requirements and approved scope |
| `DESIGN.md` | UI/UX specifications and screen behavior |
| `ARCHITECTURE.md` | Technical architecture |
| `MILESTONE.md` | Development milestones and vertical slices |
| `AGENTS.md` | Coding-agent instructions |
| `CHANGELOG.md` | Historical project changes |
| `CUSTOMIZATION.md` | Design token and UI customization rules |
| `DB-SCHEMA.md` / `DATABASE_SCHEMA.md` | Database documentation, depending on the retained repository convention |
| `TESTING.md` | Testing procedures, if maintained |

Read relevant documents before implementing features.

Do not create duplicate documentation without a reason.

---

## 11. Development Workflow

PitMate follows incremental development.

### Workflow

```text
Approved Requirement
        │
        ▼
GitHub Issue
        │
        ▼
Repository Inspection
        │
        ▼
Implementation Plan
        │
        ▼
Development Branch
        │
        ▼
Implementation
        │
        ▼
Testing & Verification
        │
        ▼
Git Diff Review
        │
        ▼
Pull Request
        │
        ▼
Review & Integration
        │
        ▼
Documentation Update
```

### Branch Naming

```text
main
develop

feature/<short-name>
fix/<short-name>
refactor/<short-name>
chore/<short-name>
docs/<short-name>
test/<short-name>
```

### Commit Convention

```text
feat: add customer vehicle registration

fix: prevent duplicate booking check-in

refactor: improve inventory repository

test: add workshop lifecycle tests

docs: update application architecture

chore: update dependencies
```

### Pull Request Requirements

Every substantial pull request should include:

- Description of changes.
- Related GitHub issue.
- Acceptance criteria.
- Files affected.
- Test results.
- Known limitations.
- Screenshots for significant UI changes.

---

## 12. Coding Agents

The primary development environment is Antigravity IDE.

Greg refers to the Gemini coding agent used in the development workflow.

### Agent Rules

All coding agents must follow `AGENTS.md`.

Agents must:

- Inspect before modifying.
- Respect approved project scope.
- Preserve working functionality.
- Avoid unnecessary refactoring.
- Follow existing architecture.
- Write relevant tests.
- Verify their changes.
- Report exact results.
- Avoid exposing credentials.
- Keep documentation synchronized.

Parallel agents may work on independent tasks using separate branches or worktrees.

All changes must be reviewed before integration.

---

## 13. Current Development Status

**Baseline:** v1.0.0-alpha

The existing application has an operational foundation covering authentication, customer and vehicle management, booking, workshop queue, mechanic task management, inventory, reporting and customer-facing functionality.

Further development follows the approved product requirements and milestone plan.

The current implementation status must be reconciled against the repository before marking individual milestones complete.

Refer to `MILESTONE.md` for current priorities and verified progress.

---

## 14. Scope and Limitations

PitMate currently targets a single physical workshop.

The project does not require:

- Multi-branch workshop management.
- Microservices.
- A separate Node.js backend.
- Kubernetes.
- A dedicated message broker.
- A production payment gateway as part of the simulated payment workflow.

Additional capabilities must be justified by actual product requirements and approved before implementation.

---

## 15. Contributing

Contributions should follow the established engineering workflow.

1. Read `AGENTS.md`.
2. Understand the relevant requirements.
3. Inspect the existing implementation.
4. Create a focused branch.
5. Implement the assigned change.
6. Run relevant tests.
7. Review the Git diff.
8. Open a pull request.
9. Update documentation where necessary.

Do not submit unrelated changes together.

---

## 16. License

License information is pending confirmation.

Do not assume that the project is open source or redistribute it under an unapproved license.

---

## 17. References

- Flutter: https://flutter.dev/
- Dart: https://dart.dev/
- Supabase: https://supabase.com/
- Supabase Flutter: https://supabase.com/docs/reference/dart/introduction
- Riverpod: https://riverpod.dev/
- GoRouter: https://pub.dev/packages/go_router

---

**PitMate — Built for the workshop, designed for the people who keep it running.**
