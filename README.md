# PitMate

**Automotive Workshop Management System**  
*Version 2.0 — Motorsport-Inspired Workshop OS*

PitMate is a single-workshop automotive management platform built with **Flutter** and **Supabase**.
It unifies workshop administrators, mechanics, and vehicle owners through a centralized, role-tailored application with real-time operational synchronization.

---

## 1. Project Overview

PitMate manages the complete automotive service lifecycle across a 5-bay workshop:
- **Intake & Diagnostics**: Walk-ins, appointments, check-in, visual inspection, and diagnostic findings.
- **Estimates & Authorization**: Itemized parts and labor estimates with customer digital authorization.
- **Workshop Dispatch**: Bay allocation, mechanic assignments, and dependency-aware operations tracking.
- **Parts & Inventory**: Real-time stock reservation, immutable movement ledger, and part requests.
- **Quality Control**: Multi-point inspection checklists and road test sign-off.
- **Billing & Settlement**: Snapshotted invoices, multiple payment methods, and cash change computation.
- **Vehicle Handover**: Customer sign-off, digital receipts, and preventative maintenance reminders.

---

## 2. User Roles

| Role | Responsibility | Key Interfaces |
|---|---|---|
| **Admin** | Workshop operations, dispatch, inventory, finances, and reporting | Operational Queue, Bay Dispatch, Stock Ledger, Invoicing, Analytics |
| **Mechanic** | Vehicle diagnosis, repair checklists, parts requests, and task progress | Task Execution Dashboard, Diagnostics Form, Checklist Updates, Earning Telemetry |
| **Customer** | Vehicle management, booking appointments, estimate approvals, and tracking | Vehicle Garage, Service Tracker, Estimate Review, Invoices & Payment History |

---

## 3. Technology Stack

- **Frontend**: Flutter 3.47+ (Dart 3.13+)
- **State Management**: Flutter Riverpod
- **Routing**: GoRouter (declarative role-based routing)
- **Backend**: Supabase (PostgreSQL 17)
- **Authentication**: Supabase Auth (Email/Password, Magic Link, OTP)
- **Access Control**: PostgreSQL Row Level Security (RLS)
- **Realtime**: Supabase Realtime (live bay and queue status)
- **Design System**: Motorsport-inspired palette (Racing Red, dark surface density, Space Grotesk & Inter typography)

---

## 4. Repository Structure

```text
cars_workshop/
├── android/                   # Android native platform configuration
├── ios/                       # iOS native platform configuration
├── web/                       # Flutter Web configuration
├── lib/
│   ├── main.dart              # Application entry point
│   ├── app/
│   │   ├── app.dart           # Root MaterialApp.router setup
│   │   ├── bootstrap.dart     # Service initialization (Supabase, logging)
│   │   ├── config/            # AppConfig and environment contracts
│   │   ├── router/            # GoRouter paths, router, and auth guards
│   │   └── theme/             # Motorsport theme, colors, typography, spacing
│   ├── core/                  # Shared utilities, constants, error types
│   ├── shared/                # Cross-feature widgets, models, providers
│   ├── features/              # Feature-first domain modules
│   │   ├── auth/              # Sign-in, sign-up, session management
│   │   ├── customers/         # Customer directory & profile management
│   │   ├── vehicles/          # Vehicle registry & garage
│   │   ├── bookings/          # Appointment booking & scheduling
│   │   ├── workshop/          # Queue, 5-bay layout, intake check-in
│   │   ├── inspections/       # Vehicle diagnostics & inspection findings
│   │   ├── estimates/         # Price quotation & customer approval
│   │   ├── service_orders/    # Authoritative job cards
│   │   ├── operations/        # Specific repair tasks & checklists
│   │   ├── mechanics/         # Roster & task assignment dispatch
│   │   ├── inventory/         # Spare parts catalog, ledger, balances
│   │   ├── quality_control/   # QC inspection & test drive sign-off
│   │   ├── finance/           # Invoices, payments, receipts
│   │   ├── notifications/     # In-app and push notification alerts
│   │   ├── reminders/         # Maintenance & mileage reminders
│   │   └── reports/           # Workshop operational telemetry
│   └── localization/          # Multi-language strings
├── supabase/
│   ├── config.toml            # Local Supabase CLI configuration
│   ├── migrations/            # Ordered, version-controlled SQL migrations
│   └── seed.sql               # Development seed dataset
├── test/
│   ├── unit/                  # Business logic and calculations tests
│   ├── widget/                # UI presentation and form tests
│   ├── integration/           # Supabase contract and smoke tests
│   └── fixtures/              # Reusable mock data fixtures
├── docs/                      # Canonical documentation
│   ├── PRD.md                 # Product Requirements Document (Approved)
│   ├── DESIGN.md              # UI/UX Specifications (Approved)
│   ├── ARCHITECTURE.md        # Technical Architecture (Approved)
│   ├── DATABASE_SCHEMA.md     # Database Schema & RLS Policies (Approved)
│   ├── TESTING.md             # Testing Strategy & Procedures (Approved)
│   ├── MILESTONE.md           # Milestone roadmap (M0 to M7)
│   └── CHANGELOG.md           # Version changelog
├── legacy/                    # Archived Version 1.0 codebase (reference only)
├── AGENTS.md                  # Autonomous agent operating rules
└── pubspec.yaml               # Flutter package configuration
```

---

## 5. Getting Started

### Prerequisites

- Flutter SDK (stable channel, >= 3.47.2)
- Dart SDK (>= 3.13.2)
- Android SDK (build-tools 36.0.0+) or Google Chrome for web
- Supabase CLI (`supabase --version` >= 2.75.0)

### Setup & Run

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Configure environment**:
   Copy the example environment template or run with `--dart-define`:
   ```bash
   flutter run -d chrome \
     --dart-define=SUPABASE_URL=https://<your-project>.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
   ```

3. **Verify tests and analysis**:
   ```bash
   flutter analyze
   flutter test
   ```

---

## 6. Milestone Roadmap

- [x] **M0 — Project Preparation**: Clean reproducible foundation, docs synced, v1.0 archived to `legacy/`.
- [x] **M1 — Application Foundation**: Authentication, session persistence, role-based routing shell, customer & vehicle registry.
- [ ] **M2 — Customer Intake & Diagnosis**: Walk-in admission, booking check-in, inspection findings.
- [ ] **M3 — Workshop Operations**: 5-bay dispatch, mechanic assignment, operation execution.
- [ ] **M4 — Inventory & Cost Management**: Stock reservation, part requests, ledger tracking.
- [ ] **M5 — Completion & Finance**: QC verification, invoicing, payment settlement, handover.
- [ ] **M6 — Communication & Customer Portal**: Maintenance reminders, notifications.
- [ ] **M7 — Integration & Release**: Full workshop end-to-end testing and release build.

---

## 7. Canonical Documentation

- [PRD.md](docs/PRD.md)
- [DESIGN.md](docs/DESIGN.md)
- [ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md)
- [TESTING.md](docs/TESTING.md)
- [MILESTONE.md](docs/MILESTONE.md)
- [AGENTS.md](AGENTS.md)
