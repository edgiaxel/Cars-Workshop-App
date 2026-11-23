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

# [1.3.1-nav-audit] — 2026-11-23

### Fixed
- **Role Navigation Consistency:** Created unified single source of truth `RoleNavigation` in `lib/shared/navigation/role_navigation.dart` defining immutable nav items and route bindings for Admin (8 destinations), Mechanic (4 destinations), and Customer (4 destinations).
- **Sidebar & App Bar Standardization:** Enhanced `ResponsiveRoleScaffold` with consistent 250px desktop sidebar, mobile drawer with full navigation routes, and fixed bottom navigation bar preventing overflow and selection crashes.
- **Screen Route & Index Alignment:** Standardized `currentIndex` across all 16 role screens:
  - Admin (8): Overview (`/admin`), Customers & Fleet (`/admin/customers`), Workshop Floor (`/admin/floor`), Bay Schedule & Bookings (`/admin/bookings`), Inspection Review (`/admin/inspection-review`), Inventory & Stock (`/admin/inventory`), Part Requests (`/admin/part-requests`), Compensation (`/admin/compensation`).
  - Mechanic (4): My Work (`/mechanic`), Active Workspace (`/mechanic/operation`), Vehicle Inspection (`/mechanic/inspection`), My Earnings (`/mechanic/earnings`).
  - Customer (4): My Garage (`/customer/garage`), Book Service (`/customer/book-service`), Appointments (`/customer/appointments`), Estimates & Approval (`/customer/estimates`).
- **Mobile Responsive Layout (antislop-layoutmobile):** Eliminated all RenderFlex layout overflows across mobile viewports (390x844) in Admin Overview, Customer Registry, Workshop Floor Console, Mechanic Workspace, Inspection Workspace, and Mechanic Earnings using adaptive `LayoutBuilder`, `Wrap`, and `Expanded` reflow patterns.
- **Automated Verification:** Verified 100% pass rate on test suite (137/137 tests), clean static analysis (0 issues), and verified all 16 screens and 24 navigation transitions via Playwright CLI.

---

# [1.3.0-m4] — 2026-11-23

### Added
- **VS-11 Part Catalog:** Parts catalog console (`AdminInventoryScreen`), part creation and editing modal, SKU, categories, unit of measurement, separate purchase and retail prices, low stock alerts, and live balance counters.
- **VS-12 Stock Receiving and Adjustment:** Manual receiving modal with atomic weighted-average purchase cost recalculation; manual stock adjustment modal with mandatory audit reason; auditable ledger history (`inventory_transactions`).
- **VS-13 Reservation and Part Requests:** Floor coordination console (`AdminPartRequestsScreen`), mechanic request modal inside `OperationWorkspaceScreen`, atomic reservation, pending/fulfilled/rejected status management, and real-time badge updates.
- **VS-14 Consumption and Returns:** Task-level consumption dialog for mechanics, parts issue, actual usage recording, undamaged surplus returns back to inventory, snapshotting unit cost at consumption time, and database-level non-negative available stock protection (`quantity_available >= 0`).
- **VS-15 Mechanic Compensation:** Admin compensation configuration console (`AdminMechanicEarningsScreen`), base salary and incentive percentage profiles, labor incentive accruals on completed work via `generate_task_mechanic_incentives`, multi-mechanic split rules, auditable payroll adjustments via `adjust_mechanic_compensation`, and mechanic personal earnings ledger (`MechanicEarningsScreen`).
- **UI Error Dialogs:** Centralized `showPitErrorDialog` and `PitValidationBanner` in `lib/shared/widgets/pit_error_dialog.dart` preventing raw Flutter crash dumps and presenting clean user validation guidance.
- **Database Schema & RPCs:** Migration `20261123000002_m4_inventory_and_costing.sql` introducing tables `parts`, `inventory_balances`, `inventory_transactions`, `part_requests`, `service_task_part_consumptions`, `mechanic_compensation_profiles`, `mechanic_earnings`, `mechanic_earning_allocations`, `mechanic_payroll_adjustments`, and RPC functions `receive_stock`, `adjust_stock`, `request_part_for_task`, `fulfill_part_request`, `consume_and_return_parts`, `generate_task_mechanic_incentives`, and `adjust_mechanic_compensation`.
- **E2E Playwright Suite:** Full multi-role web localhost E2E verification with 13 screenshot proofs (`e2e_m4_*.png`) validating admin inventory, stock receiving, adjustment reasons, floor requests, fulfillment, consumption, checklist completion, mechanic incentive calculations, payroll adjustments, and responsive mobile layout (390x844).

### Security
- Enforced PostgreSQL row level security across all M4 tables restricting catalog/stock mutations and payroll adjustments to admin role while permitting authenticated mechanics to request parts and view assigned earnings.
- Database CHECK constraint `quantity_on_hand - quantity_reserved >= 0` on `inventory_balances` preventing inventory overselling or negative stock under concurrent usage.

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
