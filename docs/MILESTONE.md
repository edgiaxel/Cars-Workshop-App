# Milestones — PitMate

> **Current milestone:** M3 Workshop Operations — Complete  
> **Overall status:** M0, M1, M2 & M3 Complete (123/123 tests passing, Playwright E2E verified), M4 Next  
> **Version:** 2.3  
> **Last updated:** 2026-11-23  
> **Deadline:** To be confirmed

---

```
[antislop](slashCommand;antislop) [antislop-ui](slashCommand;antislop-ui) [antislop-code](slashCommand;antislop-code) [antislop-human](slashCommand;antislop-human) 

[caveman](slashCommand;caveman)[ultracave](slashCommand;ultracave) be brief, use less token.

Read docs/ with necessary documents then update and sync them. Read the existing project code before continuing. 

We are using multiagent workflow with different worktree
You as the orchestrator your job is to review the work, merge them and make sure the code works to real app, no mockup no hardcode, connect the real workflow to database and backend logic everything and run playwright CLI to test in localhost and do the testing that everything has worked. And make sure no mock/hardcoded data.
```

---

# 1. Project at a Glance

## Goal

Build a complete automotive workshop management application using Flutter and Supabase.

## MVP outcome

A single five-bay workshop can manage customer intake, inspections, estimates, mechanic assignments, inventory, repairs, quality control, invoicing, payment and vehicle handover.

Customers, mechanics and administrators use one integrated application with role-specific experiences.

## Current state

- M0 Project Preparation: Complete.
- M1 Application Foundation: Complete.
- M2 Customer Intake & Diagnosis: Complete (116/116 tests passing, Playwright E2E verified).
- M3 Workshop Operations: Complete (123/123 tests passing, Playwright E2E verified).
- Next: M4 Inventory & Cost Management.

## Next action

Begin Milestone M4 Inventory & Cost Management planning.

## Related documents

- `PRD.md`
- `DESIGN.md`
- `ARCHITECTURE.md`
- `DATABASE_SCHEMA.md`
- `TESTING.md`

---

# 2. Milestone Overview

| ID | Milestone | Outcome | Status |
|---|---|---|---|
| M0 | Project Preparation | Verified development foundation | Complete |
| M1 | Application Foundation | Authentication and role-based application | Complete |
| M2 | Customer Intake & Diagnosis | Complete intake-to-estimate workflow | Complete |
| M3 | Workshop Operations | Dispatch and mechanic execution | Complete |
| M4 | Inventory & Cost Management | Operational stock and service costing | Not started |
| M5 | Completion & Finance | QC, invoice, payment and handover | Not started |
| M6 | Communication & Customer Portal | Real-time notifications and reminders | Not started |
| M7 | Integration & Release | Fully tested workshop application | Not started |

---

# 3. Milestone Details

# M0 — Project Preparation

**Outcome:** A clean, reproducible development foundation.

### Tasks

- [x] Confirm new project directory.
- [x] Initialize Git repository.
- [x] Create Flutter application.
- [x] Verify Flutter and Dart versions.
- [x] Verify Android development environment.
- [x] Configure Flutter Web development.
- [x] Create new Supabase development project.
- [x] Confirm separation from previous Supabase project.
- [x] Configure Supabase CLI.
- [x] Establish local development environment.
- [x] Configure environment variables/build-time configuration.
- [x] Install approved dependencies.
- [x] Commit dependency lockfile.
- [x] Establish initial directory structure.
- [x] Add `README.md`.
- [x] Add `AGENTS.md`.
- [x] Add documentation directory.
- [x] Establish Git branching conventions.
- [x] Establish Antigravity agent workflow.
- [x] Create initial testing structure.
- [x] Create .env to store all env variables like supabase and URLs.

### Technical validation

- [x] Flutter Android application launches.
- [x] Flutter Web application launches.
- [x] Supabase connection works.
- [x] Local Supabase database can be started, if local development is selected.
- [x] Clean database migration process works.
- [x] Git working tree is clean after initial setup.

### Required documentation

- [x] `README.md`
- [x] `AGENTS.md`
- [x] `ARCHITECTURE.md`
- [x] `DATABASE_SCHEMA.md`
- [x] `TESTING.md`

### Exit criteria

The application can run on Android and Web, communicate with the new Supabase environment, and reproduce its initial database state through version-controlled migrations.

No business features need to be implemented yet.

---

# M1 — Application Foundation

**Outcome:** A working multi-role application with a consistent responsive foundation.

### VS-01 — Application Bootstrap

**Related features:** F-001

**Outcome:** The application launches and has a consistent global structure.

Included:

- Flutter bootstrap.
- Supabase initialization.
- Application theme.
- Responsive scaffold.
- Error handling.
- Global loading states.
- Routing.
- Shared components.

Acceptance:

- [x] Application launches on Android.
- [x] Application launches on Web.
- [x] Light and dark themes work.
- [x] Shared layout components work.
- [x] Navigation behaves consistently.
- [x] Loading and error states are handled.

### VS-02 — Authentication and Roles

**Related features:** F-001

**Outcome:** Three roles can authenticate and access their respective workspaces.

Included:

- Admin authentication.
- Mechanic authentication.
- Customer registration.
- OTP verification.
- Password recovery.
- Session management.
- Role-based navigation.
- Initial RLS policies.

Acceptance:

- [x] Admin can authenticate.
- [x] Mechanic can authenticate.
- [x] Customer can register.
- [x] Customer can verify email.
- [x] Users are routed to correct workspaces.
- [x] Unauthorized access is rejected.
- [x] RLS prevents cross-customer access.

### VS-03 — Customer and Vehicle Registry

**Related features:** F-002

**Outcome:** Admin and customers can manage customer and vehicle records.

Included:

- Customer profiles.
- Guest customer records.
- Vehicle registration.
- Vehicle ownership.
- Admin customer management.
- Customer garage.

Acceptance:

- [x] Admin can create a customer.
- [x] Admin can create a guest customer.
- [x] Admin can register vehicles.
- [x] Customer can manage their own vehicles.
- [x] Vehicle ownership is enforced.
- [x] Duplicate registration warnings work.

### M1 Exit Criteria

- [x] All three roles have working authentication.
- [x] Responsive application shells are functional.
- [x] Customer and vehicle records can be managed.
- [x] Basic security tests pass.
- [x] The application is usable on Android and desktop browser.

---

# M2 — Customer Intake & Diagnosis

**Outcome:** A customer can enter the workshop, have their vehicle registered, undergo inspection and receive a repair estimate.

### VS-04 — Booking Management

**Related features:** F-003

Included:

- Appointment requests.
- Appointment scheduling.
- Admin review.
- Approval/rejection.
- Rescheduling.
- Booking history.

Acceptance:

- [x] Customer can request an appointment.
- [x] Admin can approve/reject.
- [x] Admin can reschedule.
- [x] Customer receives booking status.
- [x] Duplicate appointments are handled.
- [x] Booking history is preserved.

### VS-05 — Walk-in Intake

**Related features:** F-004

Included:

- Registered customer intake.
- Guest customer intake.
- Vehicle selection.
- New vehicle registration.
- Customer complaints.
- Odometer.
- Intake records.
- Service order creation.

Acceptance:

- [x] Registered customers can walk in.
- [x] Guest customers can walk in.
- [x] Guest intake does not require an Auth account.
- [x] Booking check-in creates a service order.
- [x] Walk-in intake creates a service order.
- [x] Duplicate service orders are prevented.

### VS-06 — Inspection and Diagnosis

**Related features:** F-005

Included:

- Inspection templates.
- Inspection categories.
- Severity levels.
- Findings.
- Photos.
- Notes.
- Inspection submission.
- Admin review.

Acceptance:

- [x] Mechanic can receive inspection assignment.
- [x] Mechanic can record findings.
- [x] Mechanic can upload evidence.
- [x] Inspection can be submitted.
- [x] Admin can review findings.
- [x] Incomplete inspection cannot be submitted.

### VS-07 — Estimate and Authorization

**Related features:** F-006, F-007, F-013

Included:

- Service templates.
- Custom operations.
- Parts pricing.
- Labor pricing.
- Tax configuration.
- Insurance coverage.
- Estimate revisions.
- Customer authorization.
- Rejection and deferral.

Acceptance:

- [x] Admin can create estimates.
- [x] Estimates contain itemized charges.
- [x] Customer can review estimates.
- [x] Customer can approve/reject.
- [x] Authorization history is preserved.
- [x] Revised estimates require renewed authorization.
- [x] Additional work does not silently modify original authorization.

### M2 Exit Criteria

- [x] Complete demonstration verified: Customer arrives → intake → inspection → diagnosis → estimate → customer approval.
- [x] Database invariant verified: One active service order per vehicle enforced.
- [x] Automated test suite verified: 116/116 unit & widget tests passing.
- [x] E2E Playwright verification completed on localhost web with remote Supabase PostgreSQL.

No repair execution is required yet.

---

# M3 — Workshop Operations

**Outcome:** Administrators can dispatch jobs and mechanics can execute assigned work.

### VS-08 — Workshop Floor and Scheduling

**Related features:** F-009, F-010

Included:

- Five service bays.
- Vehicle location.
- Workshop timeline.
- Mechanic availability.
- Appointment schedule.
- Assignment overview.
- Job priority.
- Blocked-job visibility.

Acceptance:

- [x] Five bays are configurable.
- [x] Vehicles can be assigned to bays.
- [x] Bay conflicts are detected.
- [x] Mechanics and workloads are visible.
- [x] Admin can assign and reassign mechanics.
- [x] Workshop status updates are synchronized.

### VS-09 — Service Operations

**Related features:** F-008

Included:

- Service order operations.
- Operation templates.
- Custom operations.
- Operation dependencies.
- Parallel operations.
- Sequential operations.
- Task checklists.
- Progress history.

Acceptance:

- [x] Service order supports multiple operations.
- [x] Operations can execute in parallel when allowed.
- [x] Sequential dependencies are enforced.
- [x] Completion updates the appropriate workflow.
- [x] Invalid transitions are rejected.

### VS-10 — Mechanic Workspace

**Related features:** F-009, F-017

Included:

- Mechanic dashboard.
- Assigned operations.
- Work instructions.
- Checklists.
- Progress updates.
- Pause/resume.
- Assistance requests.
- Additional findings.

Acceptance:

- [x] Mechanic sees assigned work.
- [x] Mechanic can start and pause work.
- [x] Mechanic can complete tasks.
- [x] Mechanic can report findings.
- [x] Mechanic can request assistance.
- [x] Admin sees updates without manual refresh.

### M3 Exit Criteria

- [x] A vehicle can move from approved estimate to active workshop execution.
- [x] Multiple mechanics can work on one vehicle with independently tracked operations.
- [x] 123/123 tests passing with zero static analysis issues.
- [x] Playwright CLI multi-role E2E verification complete on localhost web with remote Supabase PostgreSQL.

---

# M4 — Inventory & Cost Management

**Outcome:** Administrators can manage physical stock and mechanics can request and consume parts.

### VS-11 — Part Catalog

**Related features:** F-011, F-012

Included:

- Part catalog.
- Categories.
- SKU.
- Unit of measurement.
- Purchase cost.
- Selling price.
- Minimum stock.
- Stock balances.

Acceptance:

- [ ] Admin can create parts.
- [ ] Admin can edit part information.
- [ ] Purchase and selling prices are separate.
- [ ] Stock balances are visible.

### VS-12 — Stock Receiving and Adjustment

**Related features:** F-011, F-012

Included:

- Manual stock receiving.
- Manual stock adjustment.
- Movement history.
- Weighted-average cost.
- Adjustment reasons.

Acceptance:

- [ ] Admin can receive stock.
- [ ] Admin can adjust stock.
- [ ] Every movement creates a ledger entry.
- [ ] Cost calculations are correct.
- [ ] Stock discrepancies are auditable.

### VS-13 — Reservation and Part Requests

**Related features:** F-011

Included:

- Stock reservation.
- Mechanic part request.
- Admin fulfillment.
- Partial fulfillment.
- Unavailable part.
- Reservation release.

Acceptance:

- [ ] Stock can be reserved for an operation.
- [ ] Mechanics can request parts.
- [ ] Admin can fulfill requests.
- [ ] Insufficient stock is handled.
- [ ] Other independent operations remain available.
- [ ] Notifications are generated.

### VS-14 — Consumption and Returns

**Related features:** F-011, F-012

Included:

- Part issue.
- Actual consumption.
- Unused returns.
- Damaged stock handling.
- Operation cost reconciliation.

Acceptance:

- [ ] Mechanics record actual usage through authorized workflows.
- [ ] Unused parts can return to inventory.
- [ ] Inventory ledger remains consistent.
- [ ] Service operation receives the correct part cost.
- [ ] Negative available stock is prevented.

### VS-15 — Mechanic Compensation

**Related features:** F-016

Included:

- Base salary configuration.
- Incentive rules.
- Contribution splits.
- Earnings history.
- Approved adjustments.

Acceptance:

- [ ] Admin can configure salary.
- [ ] Admin can configure incentives.
- [ ] Multiple mechanics can share incentives.
- [ ] Incentives are tied to completed eligible work.
- [ ] Mechanics can view their earnings.
- [ ] Adjustments are auditable.

### M4 Exit Criteria

A complete service operation can reserve parts, consume stock, calculate costs and generate mechanic incentives.

---

# M5 — Completion and Finance

**Outcome:** Completed work can pass QC, be billed, paid and handed over.

### VS-16 — Quality Control

**Related features:** F-014

Included:

- QC templates.
- QC checklist.
- QC assignment.
- Pass/fail.
- Correction workflow.

Acceptance:

- [ ] Eligible service orders can enter QC.
- [ ] QC can pass or fail.
- [ ] Failed QC records a reason.
- [ ] Failed work can return for correction.
- [ ] Passed QC enables final billing.

### VS-17 — Invoice Generation

**Related features:** F-015

Included:

- Invoice creation.
- Historical pricing.
- Parts and labor totals.
- Tax.
- Insurance coverage.
- Deposits.
- Outstanding balances.

Acceptance:

- [ ] Invoice reflects authorized completed work.
- [ ] Historical prices are preserved.
- [ ] Tax is calculated correctly.
- [ ] Deposits are reconciled.
- [ ] Outstanding balance is accurate.
- [ ] Invoice cannot be silently altered after finalization.

### VS-18 — Simulated Payment

**Related features:** F-015

Included:

- Cash.
- QRIS simulation.
- Card simulation.
- Bank transfer simulation.
- Partial payment.
- Change calculation.
- Payment history.
- Receipt.

Acceptance:

- [ ] Cash payment calculates change.
- [ ] Simulated external payment records a reference.
- [ ] Duplicate payment is prevented.
- [ ] Outstanding balance updates.
- [ ] Receipt is available.
- [ ] Refunds and adjustments are auditable.

### VS-19 — Vehicle Handover

**Related features:** F-015

Included:

- Handover checklist.
- Customer confirmation.
- Responsible admin.
- Handover timestamp.
- Final service closure.

Acceptance:

- [ ] QC must pass before handover.
- [ ] Payment requirements must be satisfied or explicitly overridden by authorized policy.
- [ ] Handover is recorded.
- [ ] Service history is preserved.
- [ ] Customer receives completion notification.

### M5 Exit Criteria

A complete service order can be completed, inspected, invoiced, paid and physically handed over.

---

# M6 — Communication and Customer Experience

**Outcome:** All roles receive timely updates and customers can independently follow their vehicles.

### VS-20 — Notification Infrastructure

**Related features:** F-017

Included:

- Notification event records.
- Persistent notifications.
- Role-specific notification routing.
- Read/unread state.
- Realtime subscriptions.
- Duplicate prevention.

Acceptance:

- [ ] Admin receives operational notifications.
- [ ] Mechanic receives assignment notifications.
- [ ] Customer receives service notifications.
- [ ] Notifications appear without manual refresh.
- [ ] Notification history is preserved.
- [ ] Duplicate notifications are prevented.

### VS-21 — Customer Service Tracking

**Related features:** F-002, F-017

Included:

- Vehicle dashboard.
- Active service tracking.
- Service timeline.
- Customer-visible findings.
- Estimate approval.
- Invoice access.
- Service history.

Acceptance:

- [ ] Customer can see active vehicle service.
- [ ] Customer sees appropriate workflow progress.
- [ ] Customer can approve supplementary work.
- [ ] Customer cannot access internal workshop data.
- [ ] Completed services appear in history.

### VS-22 — Maintenance Reminders

**Related features:** F-018

Included:

- Date-based reminders.
- Odometer-based reminders.
- Reminder generation.
- Notification scheduling.
- Reminder history.

Acceptance:

- [ ] Completed services can generate reminders.
- [ ] Date-based reminders work.
- [ ] Mileage-based reminders work.
- [ ] Duplicate reminder processing is prevented.
- [ ] Customer can view reminders.

### VS-23 — Reporting and Overview

**Related features:** F-019

Included:

- Daily workshop activity.
- Monthly workshop performance.
- Revenue.
- Outstanding invoices.
- Parts consumption.
- Mechanic workload.
- Low-stock overview.

Acceptance:

- [ ] Admin can view daily activity.
- [ ] Admin can view monthly reports.
- [ ] Settled and outstanding revenue are distinct.
- [ ] Inventory costs are represented correctly.
- [ ] Mechanic workload is reportable.

### M6 Exit Criteria

All three roles receive appropriate notifications and the customer can follow a complete vehicle service without depending on the admin for every status update.

---

# M7 — Integration, Quality and Release

**Outcome:** PitMate is stable, demonstrable and ready for university project delivery.

## VS-24 — Full Workflow Integration

Test the complete lifecycle:

- [ ] Registered customer booking.
- [ ] Registered customer walk-in.
- [ ] Guest walk-in.
- [ ] Vehicle registration.
- [ ] Inspection.
- [ ] Estimate.
- [ ] Approval.
- [ ] Mechanic dispatch.
- [ ] Parallel operations.
- [ ] Sequential operations.
- [ ] Inventory reservation.
- [ ] Part consumption.
- [ ] Additional findings.
- [ ] Supplementary approval/rejection.
- [ ] QC.
- [ ] Invoice.
- [ ] Payment.
- [ ] Handover.
- [ ] History.
- [ ] Notifications.
- [ ] Maintenance reminders.

## VS-25 — Responsive and Usability Validation

- [ ] Admin desktop interface reviewed.
- [ ] Admin mobile interface reviewed.
- [ ] Mechanic mobile interface reviewed.
- [ ] Customer mobile interface reviewed.
- [ ] Dialog consistency reviewed.
- [ ] Form validation reviewed.
- [ ] Empty/loading/error states reviewed.
- [ ] Navigation consistency reviewed.
- [ ] Accessibility and touch targets reviewed.

## VS-26 — Security and Regression

- [ ] RLS policies tested.
- [ ] Role isolation tested.
- [ ] Guest data protection tested.
- [ ] Financial access tested.
- [ ] Inventory concurrency tested.
- [ ] Duplicate transaction prevention tested.
- [ ] Realtime authorization tested.
- [ ] Full automated suite passes.
- [ ] Flutter analysis passes.
- [ ] Critical business workflows manually verified.

## VS-27 — Lite Seed

**Timing:** After core workflows are functional.

Purpose: Smoke testing.

Include only a small number of:

- Admin.
- Mechanics.
- Customers.
- Vehicles.
- Service templates.
- Spare parts.
- One or two bookings.
- One walk-in.
- One active service order.

Acceptance:

- [ ] Lite seed can be applied safely.
- [ ] Core screens populate.
- [ ] Core workflows can be tested.
- [ ] Seed is isolated from production.
- [ ] Repeated execution does not create uncontrolled duplicates.

## VS-28 — Full Workshop Seed

**Timing:** After all P0 workflows are implemented and integrated.

Purpose: Simulate a busy operational workshop.

Include:

### Accounts
- Multiple administrators where applicable.
- Multiple mechanics.
- Multiple registered customers.
- Guest customer records.

### Fleet
- Different vehicle types.
- Multiple vehicles per customer.
- Different service histories.

### Workshop
- Five occupied/available bay combinations.
- Waiting vehicles.
- Active vehicles.
- Blocked vehicles.
- QC vehicles.
- Ready-for-pickup vehicles.

### Service operations
- Inspection.
- Oil replacement.
- Tire replacement.
- Brake maintenance.
- Engine maintenance.
- Electrical repairs.
- Custom repair operations.
- Multiple mechanic assignments.
- Parallel and sequential tasks.

### Inventory
- Normal stock.
- Low stock.
- Out of stock.
- Reserved stock.
- Issued stock.
- Consumed stock.
- Returned stock.
- Stock adjustments.

### Finance
- Different estimates.
- Approved and rejected proposals.
- Supplementary proposals.
- Cash payments.
- Simulated QRIS payments.
- Simulated card payments.
- Deposits.
- Outstanding balances.
- Completed invoices.
- Mechanic earnings.

### Notifications
- Booking updates.
- Assignment alerts.
- Part request alerts.
- Customer approval requests.
- Service progress.
- Completion alerts.
- Maintenance reminders.

Acceptance:

- [ ] All three roles can log in.
- [ ] Full seed is deterministic.
- [ ] Seed represents realistic workflow combinations.
- [ ] Every financial record is internally consistent.
- [ ] Every inventory movement reconciles.
- [ ] Seed data supports complete demonstrations.
- [ ] Production database cannot be seeded accidentally.

## VS-29 — Documentation and Release

- [ ] README finalized.
- [ ] PRD synchronized.
- [ ] DESIGN synchronized.
- [ ] ARCHITECTURE synchronized.
- [ ] DATABASE_SCHEMA finalized.
- [ ] TESTING finalized.
- [ ] SEED_STRATEGY finalized.
- [ ] CHANGELOG updated.
- [ ] AGENTS.md updated.
- [ ] Final demo scenarios prepared.
- [ ] Android build verified.
- [ ] Web build verified.
- [ ] Known limitations documented.

### M7 Exit Criteria

The application passes its defined acceptance and regression tests, supports complete demonstration workflows and has synchronized technical documentation.

---

# 4. Current Focus

## Current milestone

M0 — Project Preparation.

## Why this is next

The product and architecture have been defined, but there is no verified new repository or backend foundation.

We must establish the environment before implementing features.

## Dependencies

- Approved PRD.
- Approved DESIGN.
- Approved architecture.
- Flutter toolchain.
- Supabase account/project.
- Git repository.
- Antigravity IDE.

## Expected result

A clean Flutter project that can communicate with the new Supabase environment and reproduce its initial schema.

## Verification

- Android launch.
- Web launch.
- Supabase connectivity.
- Database migration test.
- Git repository verification.

## Blockers

- New repository location not established.
- New Supabase project not established.
- Exact dependency versions not selected.
- Design prototype not yet approved.

---

# 5. Next Actions

1. Review and approve `ARCHITECTURE.md`.
2. Save the three Part 3 documents into the project.
3. Create the new project repository.
4. Create or confirm the new Supabase development environment.
5. Establish `AGENTS.md` and Antigravity agent rules.
6. Execute technical spikes for RLS, Realtime and inventory transactions.
7. Complete the detailed database schema.
8. Begin M0 implementation.

---

# 6. Risks and Blockers

| Item | Impact | Next action | Status |
|---|---|---|---|
| RLS complexity | High | Test role isolation | Pending |
| Guest customer linking | High | Define identity linking flow | Pending |
| Inventory concurrency | High | Test atomic reservations | Pending |
| Financial calculations | High | Establish calculation tests | Pending |
| Realtime synchronization | High | Multi-client PoC | Pending |
| Scheduled notifications | Medium | Test scheduled processing | Pending |
| Responsive workshop board | Medium | Prototype review | Pending |
| Database reset | High | Establish separate environment | Pending |

---

# 7. Change History

| Date | Change |
|---|---|
| 2026-11-20 | Initial milestone structure established |
| 2026-11-20 | Clean-slate development strategy approved |
| 2026-11-20 | Vertical slices defined |
| 2026-11-20 | Three-stage seed strategy established |

---

# Project Management Rules

1. MILESTONE.md is the overview, not a replacement for GitHub Issues.
2. Each vertical slice must have bounded scope.
3. Each issue must have acceptance criteria.
4. Do not implement dependent features before required foundations are validated.
5. Update milestone status only with evidence.
6. Do not mark a milestone complete just because the code compiles.
7. Record blockers rather than silently skipping them.
8. Update documentation when approved requirements change.
9. Keep all work traceable to PRD feature IDs.
10. Every completed vertical slice must have a demonstrable outcome.
