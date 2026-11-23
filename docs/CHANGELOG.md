# PitMate — Changelog

All notable changes to PitMate are documented here.

This changelog follows a simplified Keep a Changelog structure.

Version numbers follow semantic versioning where practical.

## Status Definitions

- **Added:** New functionality.
- **Changed:** Modification to existing functionality.
- **Fixed:** Bug fixes.
- **Removed:** Removed functionality.
- **Security:** Security-related improvements.
- **Infrastructure:** Build, environment, database or tooling changes.
- **Documentation:** Documentation changes.

Only record meaningful changes.

Do not record planned functionality as completed.

---

# [1.2.0-m3] — 2026-11-23

### Added
- **VS-08 Workshop Floor & Scheduling:** Live 5-bay console (`AdminWorkshopFloorScreen`), bay conflict prevention, real-time bay telemetry, and vehicle allocation.
- **VS-09 Service Operations:** Operation tasks, sequential dependency enforcement, checklist management, and atomic dispatch via `dispatch_order_operations` RPC.
- **VS-10 Mechanic Workspace:** Live mechanic execution console (`OperationWorkspaceScreen`), start, pause/resume with reasons, assistance requests, and additional finding reporting.
- **Database Schema & RPCs:** Migration `20261123000001_m3_workshop_operations.sql` with tables `workshop_bays`, `service_order_tasks`, `task_checklists`, `mechanic_assignments`, `task_assistance_requests`, `service_order_additional_findings`, and RPCs `assign_vehicle_bay`, `dispatch_order_operations`, `start_task_operation`, `pause_task_operation`, `resume_task_operation`, `complete_task_operation`, `request_task_assistance`, and `report_additional_finding`.
- **E2E Playwright Suite:** Full multi-role web localhost E2E verification with 11 screenshot proofs.

---

# [1.1.0-m2] — 2026-11-23

### Added

- **VS-04 Booking Management:** Complete customer appointment request, admin review, approval, reschedule, and cancellation flows.
- **VS-05 Walk-in Intake:** Physical intake modal with odometer recording, guest/registered customer support, and atomic service order creation.
- **VS-06 Inspection & Diagnosis:** Category-based digital inspection workspace, severity evaluation, urgent finding flags, and submission validation.
- **VS-07 Estimate & Authorization:** Admin estimate builder with parts and labor items, 11% PPN integer tax calculation, revision management, and customer digital authorization.
- **Database Schema & RPCs:** Migration `20261123000000_m2_customer_intake_diagnosis.sql` with tables `bookings`, `service_orders`, `inspections`, `inspection_findings`, `estimates`, `estimate_items`, `estimate_authorizations`, and RPC functions `create_service_order_intake`, `submit_inspection`, and `authorize_estimate`.
- **E2E Playwright Suite:** Full automated multi-role localhost verification using Playwright CLI against live remote Supabase PostgreSQL.

### Security

- Enforced Row Level Security (RLS) on all M2 tables isolating customer data, mechanic assignments, and admin permissions.
- Unique partial PostgreSQL index `idx_service_orders_single_active_vehicle` preventing concurrent active service orders for a single vehicle.

### Documentation

- Created detailed E2E Walkthrough artifact with 13 visual proof screenshots.
- Updated `DATABASE_SCHEMA.md`, `MILESTONE.md`, and `TESTING.md`.

---

# [1.0.0-alpha] — 2026-11-20

**Baseline release recorded by the system discovery report.**

### Added

- Three-role application architecture:
  - Admin.
  - Mechanic.
  - Customer.
- Supabase authentication with password and OTP-based flows.
- Customer and vehicle management.
- Customer vehicle registration.
- Appointment booking and administrative booking management.
- Workshop queue with five physical bay sections.
- Booking check-in.
- Walk-in vehicle admission.
- Mechanic assignment and service task management.
- Task checklists and diagnostic findings.
- Spare-parts inventory management.
- Inventory stock adjustment with transaction logging.
- Mechanic earnings and commission tracking.
- Customer maintenance reminders.
- Persistent customer notifications.
- Admin reporting and aggregated workshop telemetry.
- Responsive role-specific application interfaces.
- Dynamic light and dark themes.
- Centralized UI customization and design tokens.
- Route protection and role-based navigation.
- Database-backed workshop lifecycle operations.

### Changed

- Consolidated application presentation, state and data responsibilities into a three-layer architecture.
- Centralized UI design tokens under `lib/app/customization/`.
- Implemented shared responsive role shells.
- Integrated server-side reporting through PostgreSQL RPC.
- Established atomic booking check-in and walk-in admission operations.

### Fixed

- Improved booking check-in validation.
- Added duplicate check-in prevention.
- Improved vehicle-customer relationship validation.
- Improved workshop queue ordering.
- Added service-order status history tracking.
- Improved role-based route protection.
- Improved theme consistency across shared components.
- Added error handling for backend-dependent operations.

### Security

- Implemented PostgreSQL Row Level Security policies.
- Added role protection for profile updates.
- Protected administrative operations through server-side authorization.
- Kept service-role credentials out of Flutter client code.

### Infrastructure

- Established Supabase PostgreSQL as the persistent data backend.
- Established version-controlled database migrations.
- Established application configuration through `lib/app/config/app_config.dart`.
- Established Flutter, Riverpod and GoRouter integration.

### Documentation

- Added and maintained project specifications.
- Documented database structure and RPC contracts.
- Documented UI customization conventions.
- Documented application architecture.
- Established coding-agent instructions.

---

# Historical Baseline

The uploaded system discovery report dated 2026-11-20 records the following baseline:

| Item | Recorded result |
|---|---|
| Flutter | 3.47.2 stable |
| Dart | 3.13.2 |
| Supabase Flutter | 2.18.0 |
| Riverpod | 3.4.3 |
| GoRouter | 18.0.2 |
| PostgreSQL tables | 19 |
| Database migrations | 10 |
| Static analysis | 0 issues |
| Automated tests | 89/89 passed |
| Asset bundle build | Passed |
| Git branch | main |
| Git tag | v1.0.0-alpha |

These results describe the recorded release baseline. They must not be interpreted as the current state after subsequent modifications.

---

# Changelog Maintenance Rules

1. Record meaningful completed changes.
2. Do not record unfinished features as completed.
3. Do not invent release dates.
4. Keep entries concise and understandable.
5. Group related changes.
6. Update the Unreleased section during development.
7. Move completed changes into a release section when a release is actually created.
8. Preserve previous entries.
9. Do not rewrite historical releases without a documented correction.
10. Link significant changes to GitHub issues or pull requests where available.

## Release Naming

Examples:

- `0.1.0` — Initial development release.
- `1.0.0-alpha` — Existing alpha baseline.
- `1.0.0-beta` — Feature-complete testing release.
- `1.0.0` — First stable release.

Version names are examples of future release conventions, not commitments to specific release dates.
