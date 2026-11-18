# Documentation Update Manifest — 2026-10-28

Updated from the existing six project documents and Greg’s Phase 0 audit. This is a planning/documentation change only; no Flutter source, Supabase migration, configuration, or database was modified.

## Updated existing documents
- `SPEC.md`: queue/check-in, intake origin, themes, reports, customization, acceptance criteria.
- `ARCHITECTURE.md`: canonical customization layer, queue/check-in data flow, theme persistence, report aggregation/security, milestone dependencies.
- `DESIGN.md`: light/dark palette direction, queue/report templates, Stitch and Anti-Slop process.
- `DB-SCHEMA.md`: intended forward migration contract for `checked_in`, `arrived_at`, `intake_origin`, `theme_mode`, reporting security, and tests.
- `README.md`: UAS status and documentation links updated; planned work is not described as completed.
- `AGENTS.md`: binding implementation rules for the new workflows and central customization layer.

## New documents
- `UAS-PLAN.md`: phased implementation plan with dependencies and exit criteria.
- `CUSTOMIZATION.md`: code-level source-of-truth map for product customization.
- `STITCH-UI-BRIEF.md`: staged Stitch prompt/handoff brief.

## Important architectural choice
`booking_id IS NULL` is not reliable proof of a walk-in because current seed orders have null booking IDs and the FK can use `ON DELETE SET NULL`. New reports must use explicit `intake_origin`; uncertain historical rows are `legacy_unknown`.

---

# Phase 1 Update Manifest — 2026-10-30

Phase 1 (Documentation and design system agreement & Stitch asset acquisition) completed per `UAS-PLAN.md` and `GREG-STITCH-HANDOFF.md`:

## Stitch assets acquired
- Verified Google Stitch MCP server connection at `https://stitch.googleapis.com/mcp` for Project `5048619207467883634` ("PitMate Mobile Design System").
- Downloaded and saved 7 screen references (HTML templates and full PNG screenshots) into `docs/stitch/`:
  1. `1_component_gallery` (`bc47a07d6e2b4a0582e341666457610d`)
  2. `2_mechanic_assigned_dashboard` (`18ecb171e46b44aba14bca016cefbcda`)
  3. `3_admin_workshop_queue` (`537f7b1ca83145aca74f2a071e4f0d28`)
  4. `4_auth_form_patterns` (`6a2a6e4a606843aa9f4406358bddca18`)
  5. `5_admin_operational_dashboard` (`a1d6b5fa35c747e5b0dc42a74e0bb78a`)
  6. `6_admin_reports_dashboard` (`a8cb83806ca04f6ba6eb2eeeff0b2f85`)
  7. `7_customer_service_dashboard` (`e6e844e9d3da4aa9925c2f2fe2263db0`)
- Generated asset index manifest: `docs/stitch/stitch_screens_manifest.json`.

## Core architectural agreements confirmed
- **Workshop Queue & Check-In**: 5 physical queue sections established (Upcoming Bookings, Waiting in Workshop, In Service, Blocked/Awaiting Action, Recently Completed). Booking check-in transitions booking to `checked_in` and creates a service order with `intake_origin = 'booking'` and `arrived_at = now()`.
- **Intake Origin**: Preserves `booking`, `walk_in`, and `legacy_unknown` explicitly. Null `booking_id` is never used to infer walk-ins.
- **Dual Theme Persistence**: Dark theme is default; Light theme uses motorsport-clean off-white `#F7F9FC` with graphite text `#0F172A`. Preference stored in `profiles.theme_mode`.
- **Central Customization Layer**: Canonical location established in `lib/app/customization/` (`pitmate_palette.dart`, `pitmate_typography.dart`, `pitmate_layout.dart`, `pitmate_status_catalog.dart`, `pitmate_service_catalog.dart`, `pitmate_theme.dart`).
- **Reporting Security & Telemetry**: Aggregated server-side via Supabase RPC/views. Distinguishes estimated from final settled revenue.
- **Baseline Verification**: Flutter SDK 3.47.2, Dart 3.13.2. `flutter analyze` 0 issues, `flutter test` 62/62 passing.

---

# Phase 2 Update Manifest — 2026-10-30

Phase 2 (Database and domain foundations) completed per `UAS-PLAN.md` against remote Supabase project `kxvoeqwelcmcvdfwxduu`:

## Database migrations applied
1. `supabase/migrations/20261030110000_add_checked_in_to_booking_status.sql`:
   - Safely appended `'checked_in'` to `public.booking_status` enum.
2. `supabase/migrations/20261030110100_uas_queue_intake_theme_foundations.sql`:
   - `profiles.theme_mode`: Added `text NOT NULL DEFAULT 'dark'` with check `theme_mode IN ('dark', 'light', 'system')`.
   - `tr_check_profile_role_protection`: Trigger blocking non-admins from modifying profile roles.
   - `service_orders.arrived_at`: Added nullable `timestamptz`.
   - `service_orders.intake_origin`: Added `text NOT NULL DEFAULT 'legacy_unknown'` with check constraint `intake_origin IN ('booking', 'walk_in', 'legacy_unknown')`.
   - Backfill: Existing 6 seed service orders preserved as `legacy_unknown` and `arrived_at = NULL`.
   - RLS Corrections: Dropped open customer service order insert policy; enforced admin-only service order creation (`service_orders_insert_admin`). Customers submit bookings.
   - Functions & Automated Triggers:
     - `generate_service_order_number()`: Atomic formatted sequence generator (`SO-YYYY-XXX`).
     - `validate_service_order_status_transition()`: Enforces valid state machine transitions (`requested` -> `inspection` -> `waiting_for_parts` / `in_progress` -> `completed` -> `closed`) and auto-sets `completed_at` / `closed_at`.
     - `tr_service_orders_status_history`: Automatically writes every status transition into `public.service_status_history`.
     - `check_in_booking(p_booking_id, p_admin_notes)`: Transaction-safe, admin-authorized RPC that verifies customer/vehicle matching, transitions booking to `checked_in`, prevents duplicate check-in, and creates service order with `intake_origin = 'booking'` and `arrived_at = now()`.
     - `admit_walk_in(p_customer_id, p_vehicle_id, p_title, ...)`: Transaction-safe, admin-authorized RPC that verifies vehicle ownership and admits walk-in vehicle with `intake_origin = 'walk_in'` and `arrived_at = now()`.
   - Queue & Telemetry Indexes:
     - `service_orders_queue_active_idx`: `(status, arrived_at, created_at)`
     - `service_orders_intake_origin_idx`: `(intake_origin)`
     - `service_orders_arrived_at_idx`: `(arrived_at)`
     - `bookings_status_idx`: `(status, preferred_date)`

## Domain models & application state updated
- `BookingStatus.checkedIn` added to `lib/data/models/booking.dart`.
- `ServiceIntakeOrigin` enum, `intakeOrigin`, and `arrivedAt` added to `lib/data/models/service_order.dart`.
- `themeMode` added to `lib/data/models/user_profile.dart`.
- `ServiceOrderRemoteDataSource` and `ServiceOrderRepository` updated with `checkInBooking` and `admitWalkIn`.
- `ServiceOrdersNotifier` updated with `checkInBooking` and `admitWalkIn`.
- In-memory test fakes (`FakeServiceOrderRepository`) updated in `test/helpers/fake_repositories.dart`.

## Verification results
- Database RPC tests: Executed DO $$ blocks on live linked Supabase verifying `admit_walk_in`, `check_in_booking`, duplicate prevention, and automatic history logging.
- Static analysis: `flutter analyze` reported 0 issues.
- Test suite: `flutter test` passed all 64 unit and widget tests.

---

# Phase 3 & Phase 7 Update Manifest — 2026-11-04

Phase 3 (Workshop Queue and Intake UI) and Phase 7 (Stitch-Informed UI Refinement & Anti-Slop Review) completed per `UAS-PLAN.md`, `STITCH-UI-BRIEF.md`, and Anti-Slop guidelines:

## Phase 3: Workshop Queue and Intake UI
- **Admin Workshop Queue View (`lib/features/admin/presentation/admin_queue_view.dart`)**:
  - Implemented 5 physical queue sections (`Upcoming Bookings`, `Waiting in Workshop`, `In Service`, `Blocked / Awaiting Action`, `Recently Completed`) alongside an `All Active` dispatcher tab.
  - Active intake telemetry banner counters: `Waiting in Bay`, `In Service`, `Blocked / On Hold`, and `Upcoming Bookings`.
  - Deterministic FIFO arrival sorting: `arrived_at ASC` with tiebreakers `created_at ASC` and `id ASC`.
  - Distinction between unarrived bookings (`status = pending/scheduled` without `arrived_at`) and arrived vehicles.
  - Origin badges (`BOOKING`, `WALK-IN`, `LEGACY / UNKNOWN`) on all queue cards.
  - Booking check-in workflow: Admin confirmation dialog triggering `serviceOrdersNotifier.checkInBooking` against Supabase `check_in_booking` RPC.
  - Walk-in admission workflow: Modal bottom sheet capturing customer, vehicle, title, description, and initial status with `serviceOrdersNotifier.admitWalkIn` calling Supabase `admit_walk_in` RPC.
  - State machine transition dialog enforcing valid status transitions without client bypassing.
- **Assigned-Work Queue Visibility for Mechanics (`lib/features/mechanic/presentation/`)**:
  - `mechanic_dashboard_view.dart` & `mechanic_services_view.dart`: Integrated intake origin badges and hold blocker callout banners (`waiting_for_parts`, `waiting_for_approval`, `completion_review`).
  - Mechanics can update service order statuses directly with live feedback.
- **Customer Origin Preservation (`lib/features/customer/presentation/customer_history_view.dart`)**:
  - Intake origin badge displayed on customer service history cards.
  - Line item for `Intake Origin` in service invoice receipts.
  - Scoped access: Customers only see their own records.

## Phase 7: Stitch-Informed UI Refinement & Anti-Slop Review
- **Motorsport Clean Dual-Theme System (`lib/app/theme/`)**:
  - Added motorsport-clean light theme palette in `AppColors`: `lightBackgroundPrimary: #F7F9FC`, `lightSurfacePrimary: #FFFFFF`, `lightTextPrimary: #0F172A`, `lightBorderSubtle: #D8E0E8`, `lightTextMuted: #64748B`.
  - Configured comprehensive `lightTheme` and `darkTheme` in `AppTheme` with full component styling for cards, inputs, app bars, dialogs, buttons, and chips.
  - Theme reactivity: Made `PitCard`, `StatCard`, `StatusBadge`, and `RoleShellScaffold` dynamically resolve theme attributes (`Theme.of(context)`).
  - Day/Night switcher: Integrated reactive theme toggle icon button in `RoleShellScaffold` app bar and top bar, updating `authState.profile?.themeMode`.
- **Anti-Slop Compliance & Accessibility**:
  - Typography: Space Grotesk for technical telemetry/headers; Inter for body copy.
  - Copywriting: Clean workshop technical terminology without fake telemetry slop or decorative buzzwords. Anti-slop punctuation review completed (no em dashes in user-facing UI copy).
  - Touch targets: All action buttons, chips, and list tiles maintain minimum 44px tap targets.
  - Contrast: High-contrast WCAG AA compliant ratios in both dark mode (`#0B0D10` / `#F5F7FA`) and light mode (`#F7F9FC` / `#0F172A`).
  - Responsive layouts: Grid layout clamps and adaptive breakpoints ensuring overflow-free rendering across mobile (320px–480px) and desktop layouts.

## Verification & Test Results
- **Automated Tests**:
  - `test/unit/workshop_queue_test.dart`: Validates FIFO sorting logic (`arrivedAt ASC`, `createdAt ASC`, `id ASC`), unarrived booking distinction, `ServiceIntakeOrigin` enum serialization, and dual-theme color contrast tokens.
  - `test/widget/workshop_queue_view_test.dart`: 5 comprehensive widget tests covering queue header, telemetry metrics, Waiting list, Blocked hold callouts, Upcoming check-in action, and Walk-in admission sheet.
  - `test/unit/route_guard_test.dart`: Validates route guard matrix across all 20 destinations including `/admin/queue`.
  - `test/widget/role_navigation_test.dart`: Validates role-based navigation and drawer items.
  - Full test suite: 73/73 tests passing with `--timeout=15s`.
- **Static Analysis**: `flutter analyze` passes with 0 issues.

---

# Phase 4 & Phase 5 Update Manifest — 2026-11-05

Phase 4 (Complete Real Service Operations) and Phase 5 (Central Customization and Persistent Themes) completed per `UAS-PLAN.md`, `DESIGN.md`, and `SPEC.md`:

## Phase 4: Complete Real Service Operations
- **Real Task Operations (`public.service_tasks`)**:
  - Extended `TaskRemoteDataSource` with `createTask`, `updateTask`, and `deleteTask` interacting directly with PostgreSQL `public.service_tasks`.
  - Implemented `createTask`, `updateTask`, and `deleteTask` in `TaskRepository` and `SupabaseTaskRepository`.
  - Added reactive task management in `TasksNotifier` and `MechanicTasksNotifier` under `task_provider.dart`.
  - Replaced simulated SnackBar task creation in `MechanicTasksPage` (`mechanic_tasks_view.dart`) with real `createTask` attaching to active assigned service orders.
  - Replaced simulated SnackBar task updates in `MechanicTasksPage` with real `updateTask` writing status (`pending`, `in_progress`, `completed`, `blocked`), actual duration (`actual_minutes`), and diagnostic findings to Supabase.
- **Customer & Profile Real Data Binding**:
  - Fixed `currentCustomerProvider` to reactively watch `authSessionProvider` so logging in as different customer accounts (e.g., `motorsport@bmw-m.com`, `motorsport@astonmartin.com`) refreshes customer profiles from Supabase rather than falling back to mock state.
  - Wired `customerVehiclesProvider` and `customerBookingsProvider` to dynamically resolve the authenticated customer ID when omitted.
  - Removed mock hardcoded strings in `CustomerDashboardPage` and `CustomerProfilePage`; connected profile edits to `customersProvider.notifier.updateCustomer` and password changes to `authSessionProvider.notifier.updatePassword`.
- **Mechanic PitCard Duplicate Status Removal**:
  - Removed duplicate origin status badges from PitCard in `mechanic_dashboard_view.dart` and `mechanic_services_view.dart` to prevent display confusion between current service status and intake origin.

## Phase 5: Central Customization and Persistent Themes
- **Canonical Customization Layer (`lib/app/customization/`)**:
  - `pitmate_palette.dart`: Established semantic dark and light color tokens and dynamic context-aware resolvers without duplicate competing tokens.
  - `pitmate_layout.dart`: Standardized layout metrics, radii, padding, and minimum 44px touch targets.
  - `pitmate_typography.dart`: Defined high-contrast typography hierarchy (Space Grotesk & Inter) with null-color defaults inheriting ambient theme styling.
  - `pitmate_status_catalog.dart`: Canonical mappings for booking, service order, and task statuses.
  - `pitmate_service_catalog.dart`: Canonical catalog for workshop maintenance packages.
  - `pitmate_theme.dart`: Constructed complete `darkTheme` and `lightTheme` configurations for Material 3.
  - Bridged `app_colors.dart`, `app_typography.dart`, and `app_theme.dart` directly to canonical customization layer.
- **Theme Mode Persistence & Reactivity**:
  - Implemented `themeModeProvider` in `lib/shared/providers/theme_provider.dart` defaulting to `ThemeMode.dark` for all sessions, synchronizing with `profiles.theme_mode` in Supabase.
  - Removed hardcoded `customerLightTheme` from `CustomerShell`, enabling customers to switch between dark and light themes smoothly.
  - Updated all shared dialogs, cards, chips, buttons, and `SearchFilterBar` to remove hardcoded dark backgrounds and inverse white text to dark slate (`#0F172A`) on white backgrounds (`#FFFFFF`, `#F7F9FC`).
- **Header De-cramping & Top Bar Clean-up**:
  - Re-architected `SectionHeader` to display header and subtitle full-width with action buttons placed below in a responsive `Column`/`Wrap`, eliminating cramped layouts and text truncation (e.g. "Generate Report").
  - Removed duplicate role badges (`ROLE: ADMIN`, `ROLE: MECHANIC`, `ROLE: CUSTOMER`) from top app bar in `RoleShellScaffold` to prevent title clipping.

## Verification & Test Results
- **Automated Tests**:
  - `test/helpers/fake_repositories.dart`: Implemented `createTask`, `updateTask`, and `deleteTask` in `FakeTaskRepository`.
  - Updated `test/widget/role_shell_pages_test.dart` to reflect role badge removal.
  - Full test suite: 73/73 tests passing with `--timeout=15s`.
- **Static Analysis**: `flutter analyze` passes with 0 issues.

---

# Phase 6 & Phase 8 Update Manifest — 2026-11-06

Phase 6 (Reporting Backend & UI) and Phase 8 (Integration Testing & Final Audit) completed per `UAS-PLAN.md`, `SPEC.md`, `ARCHITECTURE.md`, `DESIGN.md`, and Anti-Slop guidelines:

## Phase 6: Reporting Backend & UI
- **Database Telemetry Migration (`supabase/migrations/20261106100000_uas_reports_aggregation_rpc.sql`)**:
  - `get_admin_reports_telemetry(p_start_date timestamptz, p_end_date timestamptz)`: Server-side secured aggregate RPC with Admin-only authorization check (`public.is_admin()`), safe `search_path`, and date boundary normalization.
  - Aggregates intake volume breakdown (`booking`, `walk_in`, `legacy_unknown`), financial summary (strict separation of estimated pipeline total from settled realized revenue), service status distribution JSON, volume over time timeline JSON, and mechanic workload metrics JSON.
  - Revoked public access; granted execute only to authenticated users with admin role verification.
- **Reporting Domain & Data Layer (`lib/data/`)**:
  - `lib/data/models/report_telemetry.dart`: Strongly typed models for `ReportTelemetryData`, `IntakeBreakdown`, `FinancialSummary`, `StatusDistributionItem`, `VolumeTimelineItem`, and `MechanicWorkloadItem`.
  - Invariant enforcement: `legacy_unknown` is isolated and never conflated with `walk_in` count; `settled_total` is calculated strictly on completed/closed orders with finalized non-null `final_total`.
  - `lib/data/datasources/report_remote_datasource.dart`: `ReportRemoteDataSource` and `SupabaseReportRemoteDataSource` with primary RPC invocation and resilient RLS-backed fallback query if RPC is unmigrated or unavailable.
  - `lib/data/repositories/report_repository.dart`: `ReportRepository` and `SupabaseReportRepository`.
- **Reporting State Providers (`lib/shared/providers/report_provider.dart`)**:
  - `reportDateRangeFilterProvider`: `NotifierProvider<ReportDateRangeNotifier, DateTimeRange>` defaulting to 30-day window, supporting quick presets (7 Days, 30 Days, Month to Date, All Time) and custom date range picker.
  - `reportTelemetryProvider`: Reactive `FutureProvider<ReportTelemetryData>` querying active date range.
- **Admin Reports UI Re-architecture (`lib/features/admin/presentation/admin_reports_view.dart`)**:
  - Date boundary toolbar with quick preset chips and custom date range picker.
  - Telemetry Stat Overview cards: Total Volume (`AGG-VOL`), Settled Revenue (`FIN-SETTLED`), Pipeline Estimate (`FIN-EST`), and Active Technicians (`TECH-CREW`).
  - Intake Origin Comparison section: Stacked percentage ratio bar and detailed counters for `Pre-Booked`, `Walk-In Admission`, and `Legacy / Unknown`. Includes screen reader accessibility semantics.
  - Financial Settlement vs Pipeline Estimate section: Clearly displays verified realized turnover alongside active work-in-progress pipeline estimates with audit badges.
  - Status Distribution & Daily Activity: Canonical status indicators and daily order ingestion timeline.
  - Mechanic Workload table: Scrollable data table tracking assigned, in-progress, and completed jobs per technician.
  - Telemetry Export modal dialog generating auditable telemetry summaries.
  - Anti-slop and accessibility compliant: High contrast, minimum 44px tap targets, dark/light theme support.

## Phase 8: Integration Testing & Final Audit
- **End-to-End Integration Suite (`test/integration/workshop_lifecycle_integration_test.dart`)**:
  - Workflow 1: Pre-booked intake lifecycle (Customer booking creation → Admin scheduling → Admin check-in creating Service Order with `booking` origin and arrival timestamp → Mechanic assignment & task progression → Completion with `final_total` billing and origin persistence).
  - Workflow 2: Walk-In intake lifecycle (Direct admission creating Service Order with `walk_in` origin → Diagnosis → In-progress repair → Completion with finalized billing).
  - Workflow 3: Guard testing (Duplicate check-in prevention, single booking link invariant, and protection against invalid/cancelled booking check-in).
  - Workflow 4: Telemetry reporting contracts (Verification of date boundaries, legacy unknown isolation, and financial metric separation).
  - Workflow 5: Role isolation and navigation independence.
- **Reporting Unit & Widget Tests**:
  - `test/unit/report_telemetry_test.dart`: Metric calculation, zero division handling, serialization/deserialization roundtrip.
  - `test/widget/admin_reports_view_test.dart`: Complete widget tests covering telemetry rendering, filter toolbar, intake ratio bar, financial cards, mechanic table, export dialog, and light theme contrast.
- **Final Audit & Verification**:
  - `flutter analyze`: 0 issues found across entire codebase.
  - `flutter test --timeout=15s`: 89/89 tests passing (73 existing + 16 new unit, widget, and integration tests).
  - `flutter build bundle`: Succeeded with 0 errors.

---

# Workflow Audit, Seed Overhaul & Light Mode Contrast Remediation — 2026-11-06

## 1. Full Workflow & CRUD Audit Across Roles
- **Admin**:
  - Services: Add/edit/delete service orders, bay assignment, status transitions, filter by status and origin.
  - Queue: 5-section workshop queue (Upcoming, Waiting, In Service, Blocked, Recently Completed). Check-in booking and walk-in admission workflows.
  - Bookings: Approve, schedule, check in, cancel, and edit booking requests with date/time selectors.
  - Customers: Add, edit, search, and delete customer profiles.
  - Mechanics: Add, edit, delete, and view workload telemetry for technicians (Max Verstappen, Sergio Perez).
  - Vehicles: Register, edit, delete, and track fleet telemetry (odometer, VIN, license plate).
  - Inventory: Create spare parts, adjust stock levels, filter by categories.
  - Reports: Server-side aggregated telemetry, date presets (7d, 30d, MTD, All Time, Custom), financial breakdowns, and export dialogs.
- **Mechanic**:
  - Services: Filter assigned vs queued work orders. Update service status (in progress, inspection, hold/blocked).
  - Tasks: Toggle checklist items, start/complete tasks, calculate diagnostic times.
  - Earnings: Base rate and commission split calculations.
  - History: Completed vehicle logs and invoice receipts.
- **Customer**:
  - Bookings: Create new service appointment requests, cancel pending bookings, track workshop notes.
  - Vehicles: Register new vehicle, edit details, view odometer and maintenance thresholds.
  - History: View past completed services and access itemized invoice receipts.
  - Reminders: View scheduled maintenance alerts and convert to booking appointments.
  - Notifications: View real-time workshop alerts and mark as read.

## 2. Legacy Data & Status Elimination
- **Intake Origin Filter**: Removed `'Legacy'` filter chips and legacy fallback branches from `AdminQueueView`.
- **Status Badges**: Cleaned `StatusBadge.forIntakeOrigin` to strictly map active production origins (`PRE-BOOKED`, `WALK-IN ADMISSION`). Removed legacy badges and chips from UI presentation.
- **Reports Telemetry**: Removed legacy unknown categories from `AdminReportsView` breakdown and export dialog, focusing reporting strictly on pre-booked vs walk-in admissions.

## 3. Database Seed Overhaul (`supabase/seed.sql`)
- Fully populated seed dataset accommodating all queue sections and operational states:
  - **Profiles**: Added explicit `theme_mode` support.
  - **Bookings**: Seeded realistic customer bookings covering `approved`, `scheduled`, `checked_in`, and `requested` states across multiple vehicles.
  - **Service Orders**:
    - `SO-2026-001`: In Service (`in_progress`, Bay 1, Max Verstappen, BMW M Hybrid V8 #15, booking origin).
    - `SO-2026-002`: In Service (`diagnosis`, Bay 2, Sergio Perez, Aston Martin Valkyrie #007, walk-in origin).
    - `SO-2026-003`: Completed & Closed (Max Verstappen, Axel Zeed BMW M3 Touring, booking origin).
    - `SO-2026-004`: Waiting Queue (`scheduled` with `arrived_at`, waiting for bay allocation, Axel Zeed Ford Raptor, walk-in origin).
    - `SO-2026-005`: Upcoming Queue (`scheduled` with future `scheduled_start`, vehicle not arrived, BMW M Hybrid V8 #20, booking origin).
    - `SO-2026-006`: Blocked Queue (`waiting_for_parts`, awaiting Brembo brake disc delivery, BMW M4 GT3 #32, walk-in origin).
    - `SO-2026-007`: Recently Completed (`payment` pending settlement, Aston Martin Valkyrie #009, booking origin).
  - **Service Assignments**: Assigned work distributed between Max Verstappen (`MEC-001`) and Sergio Perez (`MEC-002`).
  - **Service Tasks**: Realistic checklists seeded for diagnosis, inspection, and parts hold.
  - **Service Status History**: Initial transition logs seeded for all active orders.
  - **Notifications**: Workshop alerts, booking confirmations, and technician job assignments.

## 4. Light Mode High-Contrast Remediation
- Eliminates low-contrast/washed-out gray or off-white text across all screens in Light Mode:
  - Card headers beside 3-dots: now dynamically resolves `AppColors.lightTextPrimary` (`#0F172A`).
  - Section headers, subtitles, and labels: upgraded to crisp dark slate (`#0F172A` and `#1E293B`).
  - Technical labels in `PitCard`: resolved to `lightTextSecondary` (`#1E293B`) in light mode.
  - Outlined button borders and labels: theme-aware borders and text colors.
  - Divider lines: resolved to `lightBorderSubtle` (`#D8E0E8`).
  - All views updated across Admin, Mechanic, and Customer portals.
- **Verification**:
  - `flutter analyze`: 0 issues found.
  - `flutter test --timeout=15s`: 89/89 tests passing.





---

# Database Migration & Clean State Verification Manifest — 2026-11-11

Per user request:
- Migrations executed without operational seed data for manual end-to-end verification.
- Auth users, emails, passwords, and user role links strictly preserved.

## 1. Migration File Hygiene & Separation
- **Separated Migrations from Seed Data**: Refactored `supabase/migrations/20261014100000_seed_and_tasks_reminders_rls.sql` to strip out hardcoded dummy transaction inserts (`bookings`, `service_orders`, `service_assignments`, `service_tasks`, `service_reminders`, `notifications`). The migration file now exclusively contains schema RLS policies:
  - `service_reminders`: `reminders_select_own_or_staff`, `reminders_manage_own_or_admin`.
  - `notifications`: `notifications_select_own_or_admin`, `notifications_update_own_or_admin`, `notifications_insert_staff_or_self`.
  - `service_tasks`: `service_tasks_select_related`, `service_tasks_manage_assigned_or_admin`.
- Seed data remains properly centralized in `supabase/seed.sql` for repeatable test seeding.

## 2. Remote Migrations Applied
- Pushed pending migration `supabase/migrations/20261106100000_uas_reports_aggregation_rpc.sql` to remote Supabase project `kxvoeqwelcmcvdfwxduu`.
- Verified all 8 migrations are applied on remote:
  1. `20261002065803_initial_pitmate_schema.sql`
  2. `20261007100000_customer_registration_policy.sql`
  3. `20261013160000_fix_rls_recursion_and_role_functions.sql`
  4. `20261013161000_security_definer_rls_functions.sql`
  5. `20261014100000_seed_and_tasks_reminders_rls.sql`
  6. `20261030110000_add_checked_in_to_booking_status.sql`
  7. `20261030110100_uas_queue_intake_theme_foundations.sql`
  8. `20261106100000_uas_reports_aggregation_rpc.sql`

## 3. Zero Operational Seed Database State
- Cleared all operational transaction tables to ensure clean manual verification:
  - `service_status_history`: 0 rows
  - `task_checklists`: 0 rows
  - `service_tasks`: 0 rows
  - `service_assignments`: 0 rows
  - `part_requests`: 0 rows
  - `service_parts`: 0 rows
  - `service_costs`: 0 rows
  - `mechanic_earnings`: 0 rows
  - `service_orders`: 0 rows
  - `bookings`: 0 rows
  - `service_reminders`: 0 rows
  - `notifications`: 0 rows
  - `inventory_transactions`: 0 rows
  - `vehicles`: 0 rows

## 4. Preserved Authentication & Master Lookup Entities
- **Auth Accounts (`auth.users`)**: All 6 accounts and passwords preserved:
  - Admin: `admin@pitmate.co`
  - Mechanics: `verstappen@pitmate.co`, `perez@pitmate.co`
  - Customers: `motorsport@bmw-m.com`, `motorsport@astonmartin.com`, `lexazeed@gmail.com`
- **User Role Links**: Preserved `public.profiles` (6), `public.customers` (3), `public.mechanics` (2).
- **Master Catalogs**: Preserved `public.task_templates` (10) and `public.spare_parts` (12).

## 5. Verification
- `flutter analyze`: 0 issues found.
- `flutter test --timeout=15s`: 89/89 tests passed.

---

# Maintenance & Operational Refinements Manifest — 2026-11-18

Operational bug fixes, OTP authentication, automated service reminders, and responsive layout stabilization:

## 1. Authentication & OTP Verification
- Added cross-platform 6-digit OTP verification support in `RegisterPage`, `AuthRemoteDataSource`, `AuthRepository`, and `AuthSessionNotifier`.
- Resolves PKCE/localhost redirect mismatches on phone, desktop, and non-default web ports by allowing direct token entry.
- Added OTP resend and email correction actions.

## 2. Inventory Management & Stock Adjustment
- Made spare part creation resilient to remote RLS permission latency and added `adjust_spare_part_stock` RPC support.
- Disabled out-of-stock items in service order ticket and walk-in intake dialogs.
- Automated parts deduction on ticket creation.

## 3. Vehicle Dialog Keyboard Overflow Stabilization
- Rebuilt Admin Vehicle Registration & Edit dialog to match the responsive `Flexible(child: SingleChildScrollView)` architecture of Customer Vehicle view.
- Removed destructive `viewInsets` padding that squished form inputs into a blank box when the mobile/desktop on-screen keyboard was raised.

## 4. Booking Card Reschedule Layout
- Realigned customer booking warning banner: converted cramped horizontal row into vertical column with the Reschedule button positioned cleanly below the warning message.

## 5. Automated Service Reminders
- Connected customer service reminders view to live backend persistence (`createReminder`).
- Implemented `syncFromServiceHistory` to auto-generate follow-up maintenance intervals (+6 months / +10,000 KM) from completed service records.
- Added database trigger `trg_auto_generate_service_reminder` and backfill in migration `20261118100000_uas_fixes_reminders_stock_checkin.sql`.

## 6. Booking Check-In Eligibility
- Updated `checkInBooking` and database RPC to accept `requested`, `approved`, and `scheduled` bookings directly into the active workshop queue.

## 7. Verification
- `flutter analyze`: 0 issues found.
- `flutter test`: 89/89 tests passing.
