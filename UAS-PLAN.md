# PitMate UAS Implementation Plan

**Status:** Planning based on the Phase 0 audit. No implementation is implied by this plan.

## UAS goals

Deliver a reliable workshop intake and queue workflow, complete the highest-priority incomplete mutations, support persistent light/dark themes, provide real Admin reports, and refine the UI using Stitch references and Anti-Slop checks without replacing the current Flutter architecture.

$antislop $antislop-code $antislop-human $antislop-ui 

Read:
- AGENTS.md
- ARCHITECTURE.md
- CHANGELOG-DOCS.md
- CUSTOMIZATION.md
- DB-SCHEMA.md
- DESIGN.md
- GREG-STITCH-HANDOFF.md
- README.md
- SPEC.md
- STITCH-UI-BRIEF.md
- UAS-PLAN.md - also check and update what phases already done after each iteration.
All .md files except README.md and CHANGELOG-DOCS.md are absolute, dont change or modify them unless notified otherwise. If you need to change it, ONLY CHANGE the necessary part dont change/delete the whole files. You can modify Readme for changes in implementation later and change logs to document all changes in this project.
Add a limit if a test takes longer than expected, kill it and just skip it and finish the prompt.
 

## [x] Phase 0 — Audit (complete)

- [x] Current stack and files inspected by Greg.
- [x] Baseline reported: `flutter analyze` 0 issues; `flutter test` 62/62 passing.
- [x] Identified booking-to-order disconnect, queue/check-in gap, missing theme persistence, mock reports, UI-only task actions, and missing workflow integration tests.
- [x] Re-run baseline commands before implementation because the reported result is a snapshot, not a guarantee of current state.

## [x] Phase 1 — Documentation and design system agreement (complete)

**Deliverables:** Updated `SPEC.md`, `ARCHITECTURE.md`, `DESIGN.md`, `DB-SCHEMA.md`, `README.md`, `AGENTS.md`, this plan, `CUSTOMIZATION.md`, and `STITCH-UI-BRIEF.md`.

- [x] Agree on queue sections and booking state semantics.
- [x] Define explicit `intake_origin` and `arrived_at` semantics, including treatment of legacy rows.
- [x] Define `profiles.theme_mode` and theme behavior.
- [x] Define report metrics, date-range behavior, and security model.
- [x] Audit existing token files and establish one canonical `lib/app/customization/` layer.
- [x] Generate Stitch references before implementing major UI changes.

**Exit criteria:** No unresolved contradiction about booking check-in, intake origin, theme persistence, report data, or customization ownership.

## [x] Phase 2 — Database and domain foundations (complete)

- [x] Inspect current live schema, applied migrations, RLS policies, triggers, models, and enum serialization.
- [x] Add a new forward migration for `booking_status.checked_in`, `service_orders.intake_origin`, nullable `service_orders.arrived_at`, and `profiles.theme_mode`.
- [x] Backfill proven booking-origin rows as `booking`; backfill ambiguous historical rows as `legacy_unknown`.
- [x] Create transaction-safe, Admin-authorized check-in and walk-in admission operations.
- [x] Prevent duplicate booking conversion/check-in and validate customer/vehicle consistency.
- [x] Review and correct customer service-order insert policy; customers should submit bookings, not arbitrary service orders.
- [x] Define allowed status transitions and server-side authorization.
- [x] Add necessary indexes and database tests.

**Exit criteria:** Migration applies safely; data is not misclassified; RLS and transaction behaviors are tested.

## [x] Phase 3 — Workshop queue and intake UI (complete)

- [x] Add Admin Workshop Queue with Upcoming, Waiting, In Service, Blocked, and Recently Completed sections.
- [x] Add booking check-in and walk-in admission actions.
- [x] Use FIFO arrival ordering with deterministic tie-breakers.
- [x] Display origin, arrival time, wait duration, status, vehicle, customer, and next permitted action.
- [x] Add assigned-work queue visibility for mechanics; keep customer access scoped to their own records.
- [x] Preserve origin in service history and details.

**Exit criteria:** Booking check-in and walk-in flows work against Supabase; queue distinguishes not-arrived bookings from arrived vehicles; no duplicate order on retries.

## [x] Phase 4 — Complete real service operations (complete)

- [x] Replace high-priority UI-only task mutations with real repository/datasource operations.
- [x] Implement task creation/progress writes according to the existing task schema and business rules.
- [x] Enforce valid service status transitions and role permissions.
- [x] Ensure status history is maintained consistently.
- [x] Correct any misleading success messages where a write failed or was not performed.

**Exit criteria:** The agreed service execution path is real end-to-end, not simulated by SnackBars.

## [x] Phase 5 — Central customization and persistent themes (complete)

- [x] Inspect and reconcile current `AppColors`, `AppTypography`, `AppSpacing`, `AppTheme`, and related tokens.
- [x] Establish the canonical `lib/app/customization/` layer without leaving duplicate competing token files.
- [x] Build light/dark `ThemeData` and token-backed shared component themes.
- [x] Add one theme-mode provider connected to `MaterialApp.router`.
- [x] Persist `dark`, `light`, or `system` to the authenticated profile.
- [x] Add an accessible preference control for all three roles.
- [x] Update shared cards, shells, fields, buttons, dialogs, badges, navigation, charts, and states to consume semantic theme tokens.

**Exit criteria:** Theme survives restart and profile session changes; all roles and core components remain readable in both themes; failure to save is handled honestly.

## [x] Phase 6 — Reporting backend and UI (complete)

- [x] Define the metric contracts and date boundaries.
- [x] Add a secured aggregate view/RPC for intake counts, service volume, status distribution, and mechanic workload.
- [x] Keep `legacy_unknown` separate; do not count it as a walk-in.
- [x] Add financial reporting only if `final_total`, status, and payment semantics support an accurate definition.
- [x] Add a compatible Flutter chart dependency only after checking `pubspec.yaml` and SDK constraints.
- [x] Implement date-range filters, charts, legends, accessible textual summaries, and loading/empty/error states.
- [x] Test authorization and aggregate correctness by role.

**Exit criteria:** Reports use real aggregate queries, respect date filters, and expose only authorized data.

## [x] Phase 7 — Stitch-informed UI refinement and Anti-Slop review (complete)

- [x] Use the screen/component references in `STITCH-UI-BRIEF.md`.
- [x] Implement the approved patterns in existing Flutter components.
- [x] Run Anti-Slop core/UI guidance and check accessibility, responsiveness, hierarchy, contrast, and copy.
- [x] Test representative narrow/mobile layouts and both themes.
- [x] Do not accept purely decorative changes that reduce workflow clarity.

**Exit criteria:** Queue, dashboard, reports, login, forms, cards, and dialogs are consistent with the design system and usable in both themes.

## [x] Phase 8 — Integration testing and final audit (complete)

- [x] Add integration tests for booking → check-in → service → completion.
- [x] Add walk-in → service → completion tests.
- [x] Test duplicate check-in, invalid booking states, origin persistence, status transitions, and RLS.
- [x] Test theme persistence and role independence.
- [x] Test reporting date boundaries and booking/walk-in/legacy-unknown aggregation.
- [x] Run `flutter analyze`, `flutter test`, and the intended build.
- [x] Conduct manual visual checks for both themes and responsive layouts.
- [x] Update README and report remaining limitations accurately.

**Exit criteria:** Critical workflows pass; no known mock success actions remain in the agreed scope; automated and manual results are separately documented.

## [x] Phase 9 — Operational Refinement, OTP Auth, Reminders & Cron (complete)

- [x] Cross-platform 6-digit OTP verification on registration page (`verifyOtp`, `resendOtp`).
- [x] Resilient spare part creation and stock adjustments (`adjust_spare_part_stock`).
- [x] Realigned Admin Vehicle Add/Edit dialog layout: eliminated keyboard viewInsets push/blank box.
- [x] Restructured Customer Booking Card reschedule button: moved below warning text in a responsive column.
- [x] Automated service reminders trigger and backend creation (`trg_auto_generate_service_reminder`, `createReminder`, `syncFromServiceHistory`).
- [x] Expanded check-in booking eligibility to accept `requested`, `approved`, and `scheduled` bookings directly into the queue.
- [x] Verified `flutter analyze` 0 issues, `flutter test` 89/89 passing.

## Cross-cutting risks and guardrails

- Do not edit applied migrations; add forward migrations.
- Do not infer walk-in origin from null `booking_id`.
- Do not mark bookings completed at check-in.
- Do not expose service-role credentials in Flutter.
- Do not use a separate React/Express app for reports without an explicit requirement.
- Do not add arbitrary new statuses; use queue grouping over arrival data and existing statuses where possible.
- Do not claim manual visual review from automated tests.
- Do not implement all phases in one large agent task. Use one milestone prompt at a time.

## Baseline and completion checklist

Baseline reported by Greg at Phase 0: Flutter 3.47.2, Dart 3.13.2, `flutter analyze` clean, 62 tests passing. Re-run and record current results before starting Phase 2. A milestone is complete only when code, tests, docs, and validation report agree.
