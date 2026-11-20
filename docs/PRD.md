# PitMate — Product Requirements Document

> **Product:** PitMate  
> **Version:** 2.0 — Clean-Slate Redesign  
> **Status:** Draft — Pending Approval  
> **Date:** 2026-11-20  
> **Project Mode:** Complete application redesign  
> **Deployment Target:** Android, iOS (future), responsive web/desktop admin  
> **Workshop Model:** Single physical workshop, five service bays

---

# 1. Read This First

## What the product does

PitMate is a workshop management application for automotive service operations. It connects customers, workshop administrators and mechanics through one integrated system.

It manages the complete vehicle service lifecycle, from customer arrival and vehicle inspection to service execution, inventory consumption, invoicing, payment and vehicle handover.

## Who it is for

- Workshop administrators and owners.
- Automotive mechanics and technicians.
- Individual vehicle owners.
- Corporate and motorsport customers managing multiple vehicles.

## Core problem

Traditional workshop operations frequently depend on verbal communication, paper records, manual stock tracking and disconnected administrative processes.

PitMate centralizes these operations while keeping the mechanic's interaction simple and making workshop progress visible to administrators and customers.

## MVP outcome

A workshop can operate a complete vehicle service lifecycle using PitMate:

1. Register or identify a customer.
2. Register or select a vehicle.
3. Accept a booking or walk-in.
4. Inspect and diagnose the vehicle.
5. Create an estimate.
6. Obtain customer authorization.
7. Assign mechanics and service operations.
8. Manage stock allocation and consumption.
9. Complete repair and quality control.
10. Generate an invoice.
11. Record payment.
12. Hand over the vehicle.
13. Preserve service history and generate maintenance reminders.

## Project status

The previous PitMate implementation exists as a reference. The new application is a clean-slate reconstruction.

Existing architecture, database schema and migrations are not binding requirements.

## Next action

Approve the product scope and operating rules, then proceed to architecture and implementation planning.

---

# 2. Product Overview

## 2.1 Description

PitMate is a single-workshop automotive management platform with three primary user roles: Admin, Mechanic and Customer.

The application provides a centralized operational environment where administrators control workshop activities, mechanics execute assigned service operations, and customers access vehicle and service information.

## 2.2 Product principles

1. Workshop-first workflow.
2. Admin-centric operational control.
3. Minimal mechanic interaction.
4. Transparent customer communication.
5. Explicit authorization before additional repair work.
6. Traceable financial and inventory records.
7. Real-time synchronization.
8. Responsive multi-device interfaces.
9. Configurable workshop policies.
10. Auditable historical records.

## 2.3 Physical workshop model

The initial deployment represents one workshop containing:

- Five service bays.
- Customer waiting area.
- Shared tools and equipment area.
- Spare-parts storage/inventory area.
- Administrative reception and service desk.
- Mechanic working area.

The five bays are configurable resources, not five permanently assigned mechanics.

Mechanics can move between bays and work on different vehicles according to assignments.

---

# 3. Users and Actors

| ID | Actor | Goal | Permissions |
|---|---|---|---|
| ACT-001 | Admin | Manage workshop operations | Full operational administration |
| ACT-002 | Mechanic | Execute assigned work | Assigned jobs, task progress, requests |
| ACT-003 | Registered Customer | Manage vehicles and services | Own vehicles, bookings, approvals, payments |
| ACT-004 | Guest Customer | Receive workshop services without an account | No direct application account |
| ACT-005 | Workshop Owner | Review business performance | Admin-level reporting and configuration |
| ACT-006 | System | Coordinate automated processes | Notifications, reminders, status events |

ACT-005 may initially use the Admin role. Separate owner permissions are a future extension.

## 3.1 Authentication

- Admin and mechanics use authenticated accounts.
- Customers can register independently.
- Customer registration uses Supabase Auth with email OTP verification and password setup.
- Admin can create customer records for walk-in visitors.
- Guest customers do not require accounts.
- Existing guest records can later be linked to verified customer accounts through an authorized process.
- Role assignment is controlled by authorized administration, not self-selected during public registration.

---

# 4. Core User Journeys

## 4.1 Registered customer — Booking

1. Customer logs in.
2. Selects an existing vehicle or adds a new one.
3. Selects a service category or describes a concern.
4. Selects an available appointment date/time.
5. Submits a booking request.
6. Admin reviews the request.
7. Admin approves, rejects or proposes another appointment.
8. Customer receives notification.
9. Customer arrives at the workshop.
10. Admin checks in the vehicle.
11. Service order is created.
12. Workshop inspection begins.

A booking is an appointment request, not an authorization to perform every requested repair.

## 4.2 Registered customer — Walk-in

1. Customer arrives.
2. Admin identifies the customer.
3. Admin selects an existing vehicle or registers a new one.
4. Admin records the customer's complaint.
5. Admin creates a walk-in intake.
6. Vehicle enters the workshop workflow.
7. Customer can track the service through their account.

## 4.3 Guest customer — Walk-in

1. Customer arrives without an account.
2. Admin selects guest intake.
3. Admin records name and available contact information.
4. Admin records vehicle details.
5. Admin records the customer's complaint.
6. Service order is created.
7. Customer receives a physical intake/service reference.
8. All workshop operations continue normally.
9. Final service documentation is retained in the guest customer record.

Guest records must not require artificial email addresses or passwords.

## 4.4 Inspection and authorization

1. Vehicle is checked in.
2. Admin records initial condition and odometer.
3. Mechanic receives inspection assignment.
4. Mechanic performs inspection.
5. Mechanic records findings and evidence.
6. Admin reviews findings.
7. Admin creates an estimate using service templates and custom operations.
8. System calculates parts, labor, applicable tax and coverage.
9. Customer receives the estimate.
10. Customer approves or rejects proposed work.
11. The authorization decision is recorded permanently.
12. Approved work becomes eligible for execution.

If the customer rejects all work, the service order follows the inspection-fee/declined-work closure process.

## 4.5 Repair execution

1. Admin dispatches approved service operations.
2. Mechanics receive assignments.
3. Admin allocates required parts.
4. Mechanics execute their operations.
5. Mechanics update progress and checklists.
6. Additional findings are reported.
7. Additional proposals are handled separately.
8. Completed operations are submitted for QC.
9. Failed QC returns the affected operation for correction.
10. Passed QC allows finalization.

## 4.6 Billing and handover

1. Admin reviews completed work.
2. Final invoice is generated.
3. Previously collected deposits are deducted.
4. Customer pays the outstanding balance.
5. Payment is recorded.
6. Receipt is generated.
7. Vehicle handover is recorded.
8. Service order is closed.
9. Customer receives final notification.
10. Maintenance reminder is scheduled.

---

# 5. Product Scope

## P0 — Must Have

### Identity and customer management
- Admin, mechanic and customer roles.
- OTP customer registration.
- Login, logout and password recovery.
- Guest customer intake.
- Admin customer creation and management.
- Vehicle registration and management.
- Role-based permissions.

### Workshop operations
- Five configurable service bays.
- Booking management.
- Walk-in intake.
- Service orders.
- Initial inspection and diagnosis.
- Estimate generation.
- Customer approval and rejection.
- Service operation templates.
- Custom service operations.
- Mechanic assignment.
- Multiple mechanics per vehicle.
- Sequential and parallel operations.
- Workshop timeline/dispatch board.
- QC and handover.

### Inventory
- Spare-part catalog.
- Stock receiving and manual adjustment.
- Stock availability.
- Reservation and allocation.
- Mechanic part requests.
- Stock consumption.
- Unused part returns.
- Stock movement history.
- Low-stock alerts.

### Finance
- Configurable service prices.
- Configurable labor prices.
- Configurable parts selling prices.
- Configurable tax rules.
- Insurance/coverage recording.
- Estimates and invoices.
- Simulated payment recording.
- Cash change calculation.
- Deposits and outstanding balances.
- Receipts.
- Mechanic base salary.
- Service incentives.
- Incentive allocation among mechanics.

### Communication
- In-app notifications.
- Role-specific notifications.
- Real-time status synchronization.
- Customer maintenance reminders.
- Notification history.

### Customer experience
- Vehicle dashboard.
- Booking and appointment history.
- Active service tracking.
- Inspection and estimate visibility.
- Approval interface.
- Payment interface.
- Invoice and receipt history.
- Maintenance reminders.

### Administration
- Workshop overview.
- Operational timeline.
- Customer and vehicle management.
- Mechanic management.
- Inventory management.
- Service catalog configuration.
- Financial settings.
- Reports.

## P1 — Should Have

- Advanced technician skill management.
- Mechanic attendance.
- Detailed payroll periods.
- Advanced profitability reports.
- Service warranties.
- Comeback/redo tracking.
- Advanced stocktake.
- Supplier reference management without purchasing workflow.
- Multi-stage insurance claims.
- Customer feedback.
- Advanced scheduling optimization.

## P2 — Could Have

- PDF invoice customization.
- Barcode/QR part identification.
- Advanced vehicle compatibility catalog.
- Offline mechanic task drafts.
- Push notifications.
- Advanced performance analytics.
- Exportable payroll statements.

## Out of Scope

- Multi-branch workshop management.
- Real payment gateway integration.
- Actual QRIS settlement verification.
- Supplier marketplace.
- Supplier purchasing and procurement workflow.
- External accounting system integration.
- Insurer API integration.
- Full HR management.
- Fleet GPS tracking.
- AI-powered mechanical diagnosis.
- Automatic spare-part purchasing.

---

# 6. Feature Requirements

## F-001 — Authentication and Authorization

**Priority:** P0

- Admin and mechanics must authenticate.
- Customers can self-register using email OTP.
- Public registration cannot create admin or mechanic privileges.
- Role permissions are enforced server-side.
- Password recovery is supported.
- Sessions are handled securely.

**Acceptance criteria:**
- [ ] Users can log in and log out.
- [ ] Customers can register and verify their email.
- [ ] Unauthorized users cannot access another role's data.
- [ ] Role changes cannot be performed by customers.
- [ ] Expired sessions are handled correctly.

## F-002 — Customer and Vehicle Management

**Priority:** P0

Admin can create, view and update customer records and vehicles.

Customers can manage their own profile and vehicles.

**Acceptance criteria:**
- [ ] Admin can register guest and account-based customers.
- [ ] Vehicle records contain registration plate, make, model, year and available specifications.
- [ ] Customer ownership is enforced.
- [ ] Vehicle history is preserved.
- [ ] Duplicate plate detection warns administrators.

## F-003 — Booking Management

**Priority:** P0

Customers request appointments and admins manage scheduling.

**Acceptance criteria:**
- [ ] Customers can submit booking requests.
- [ ] Admin can approve, reject or reschedule.
- [ ] Appointment capacity is checked.
- [ ] Approved bookings can be checked in.
- [ ] Cancelled bookings remain in historical records.
- [ ] Duplicate check-in is prevented.

## F-004 — Walk-in Intake

**Priority:** P0

Admin can admit both registered and guest customers.

**Acceptance criteria:**
- [ ] Registered customer can be selected.
- [ ] Guest customer can be created without authentication.
- [ ] Vehicle information is recorded.
- [ ] Customer complaint is documented.
- [ ] Service order receives a unique reference.
- [ ] Intake origin is recorded.

## F-005 — Workshop Inspection

**Priority:** P0

Mechanics perform structured inspection and diagnosis.

**Acceptance criteria:**
- [ ] Inspection must be completed before final repair authorization.
- [ ] Findings support categories and severity.
- [ ] Photos and notes can be recorded.
- [ ] Odometer and inspection timestamp are preserved.
- [ ] Admin can review and convert findings into proposed operations.

## F-006 — Estimate and Authorization

**Priority:** P0

Admin prepares estimates and customers authorize work.

**Acceptance criteria:**
- [ ] Estimates contain itemized parts and labor.
- [ ] Tax and applicable discounts are calculated.
- [ ] Customers can approve or reject proposals.
- [ ] Each authorization decision is timestamped.
- [ ] Approved estimates cannot silently change.
- [ ] Revised estimates require renewed authorization.
- [ ] Rejected and deferred items remain recorded.

## F-007 — Supplementary Work

**Priority:** P0

Additional findings create separate proposals.

**Acceptance criteria:**
- [ ] Mechanics can report additional findings.
- [ ] Admin can create supplementary estimates.
- [ ] Customer can approve, reject or defer.
- [ ] Original authorized work continues when independent.
- [ ] Unsafe affected operations are blocked.
- [ ] Every decision is retained in history.

## F-008 — Service Operations

**Priority:** P0

Service orders contain multiple individually managed operations.

**Acceptance criteria:**
- [ ] Operations support templates and custom definitions.
- [ ] Each operation has instructions and estimated duration.
- [ ] Dependencies between operations can be configured.
- [ ] Parallel operations can execute concurrently.
- [ ] Sequential operations respect dependencies.
- [ ] Completion is tracked individually.
- [ ] Service order status reflects operation and workflow states.

## F-009 — Mechanic Assignment

**Priority:** P0

Admin dispatches work to mechanics.

**Acceptance criteria:**
- [ ] Multiple mechanics can be assigned to one service order.
- [ ] Different mechanics can own different operations.
- [ ] One lead mechanic can be designated.
- [ ] Workload and availability are visible.
- [ ] Conflicting assignments are flagged.
- [ ] Incentive contributions can be allocated separately.

## F-010 — Workshop Floor Management

**Priority:** P0

Admin controls the five-bay workshop.

**Acceptance criteria:**
- [ ] Five bays can be represented.
- [ ] Vehicle locations are visible.
- [ ] Waiting, active, blocked and completed stages are distinguishable.
- [ ] Mechanics and assignments are visible.
- [ ] Admin can move vehicles and reassign bays.
- [ ] Conflicts require resolution.
- [ ] Unauthorized workflow transitions are prevented.

## F-011 — Inventory Management

**Priority:** P0

Admin manages physical stock.

**Acceptance criteria:**
- [ ] Parts can be created and categorized.
- [ ] Admin can receive and adjust stock.
- [ ] Available and reserved quantities are distinct.
- [ ] Mechanics can request parts.
- [ ] Admin can fulfill requests.
- [ ] Consumption is linked to service operations.
- [ ] Unused parts can be returned.
- [ ] Every stock movement is auditable.
- [ ] Negative available stock is prohibited.

## F-012 — Inventory Costing

**Priority:** P0

Use weighted-average costing for the initial implementation.

**Acceptance criteria:**
- [ ] Purchase cost is distinct from selling price.
- [ ] Receiving stock recalculates average cost.
- [ ] Consumption records inventory cost at the applicable valuation.
- [ ] Historical service costs do not change when catalog prices change.
- [ ] Stock adjustments require a reason.

## F-013 — Service Catalog and Pricing

**Priority:** P0

Admin configures service templates.

**Acceptance criteria:**
- [ ] Service templates can be created and edited.
- [ ] Templates support labor, parts and duration.
- [ ] Incentive rules are configurable.
- [ ] Tax rules are configurable.
- [ ] Historical estimates preserve original pricing snapshots.

## F-014 — Quality Control

**Priority:** P0

Completed operations undergo final verification.

**Acceptance criteria:**
- [ ] QC checklist is configurable.
- [ ] Failed QC requires a recorded reason.
- [ ] Failed items can return to repair.
- [ ] Passed QC permits billing finalization.
- [ ] QC identity and timestamps are recorded.

## F-015 — Invoice and Payment

**Priority:** P0

**Acceptance criteria:**
- [ ] Final invoice reflects completed authorized work.
- [ ] Deposits are deducted.
- [ ] Outstanding balances are calculated.
- [ ] Cash payment calculates change.
- [ ] QRIS, card and bank transfer can be recorded as simulated external settlements.
- [ ] Customer can complete simulated payment through the portal.
- [ ] Payment references are unique.
- [ ] Receipts can be viewed and printed.
- [ ] Refunds and corrections require authorization and audit records.

## F-016 — Mechanic Compensation

**Priority:** P0

**Acceptance criteria:**
- [ ] Monthly base salary is configurable.
- [ ] Incentives are defined per service operation.
- [ ] Multiple contributors can split incentive pools.
- [ ] Only approved completed work qualifies for incentives.
- [ ] Adjustments are auditable.
- [ ] Mechanics can view their own earnings.
- [ ] Payroll calculations do not alter invoice totals.

## F-017 — Notifications

**Priority:** P0

**Acceptance criteria:**
- [ ] Notifications are generated by relevant business events.
- [ ] Customer, admin and mechanic receive role-specific notifications.
- [ ] Notifications appear without manual page refresh.
- [ ] Notifications are persisted.
- [ ] Read/unread state is tracked.
- [ ] Duplicate event delivery does not create duplicate notifications.
- [ ] Failed delivery can be retried safely.

## F-018 — Maintenance Reminders

**Priority:** P0

**Acceptance criteria:**
- [ ] Reminders support dates and odometer readings.
- [ ] Reminders can be scheduled after completed services.
- [ ] Customers receive in-app notifications.
- [ ] Duplicate reminders are prevented.
- [ ] Admin can review upcoming reminders.

## F-019 — Reporting

**Priority:** P0

**Acceptance criteria:**
- [ ] Admin can view daily and monthly service totals.
- [ ] Revenue distinguishes invoiced, paid and outstanding amounts.
- [ ] Parts costs and labor revenue are distinguishable.
- [ ] Mechanic workload is reportable.
- [ ] Inventory levels and low-stock parts are visible.
- [ ] Cancelled and rejected work is not counted as settled revenue.

## F-020 — Seed and Demonstration Data

**Priority:** P0 for release preparation; execution deferred.

**Acceptance criteria:**
- [ ] Lite seed contains a small valid smoke-test dataset.
- [ ] Full seed represents a busy five-bay workshop.
- [ ] Seed includes all three roles.
- [ ] Seed includes guest and registered customers.
- [ ] Seed includes multiple workflow states.
- [ ] Seed includes realistic stock movements and financial records.
- [ ] Seed is deterministic and repeatable.
- [ ] Seed never runs automatically against production.

---

# 7. Functional Requirements

| ID | Requirement |
|---|---|
| FR-001 | The system shall enforce role-based authorization. |
| FR-002 | The system shall support guest customer intake without authentication. |
| FR-003 | The system shall maintain vehicle ownership records. |
| FR-004 | The system shall distinguish booking from physical check-in. |
| FR-005 | The system shall require inspection completion before final repair authorization. |
| FR-006 | The system shall preserve estimates and authorization decisions. |
| FR-007 | The system shall distinguish original work from supplementary work. |
| FR-008 | The system shall support parallel and dependent service operations. |
| FR-009 | The system shall support multiple mechanics per vehicle. |
| FR-010 | The system shall prevent unavailable stock from being consumed. |
| FR-011 | The system shall record all inventory movements. |
| FR-012 | The system shall preserve historical financial snapshots. |
| FR-013 | The system shall distinguish payment recording from actual gateway settlement. |
| FR-014 | The system shall calculate cash change. |
| FR-015 | The system shall distinguish vehicle completion, payment and handover. |
| FR-016 | The system shall create persistent role-specific notifications. |
| FR-017 | The system shall synchronize operational updates across connected clients. |
| FR-018 | The system shall maintain audit histories for critical actions. |
| FR-019 | The system shall preserve closed and cancelled service records. |
| FR-020 | The system shall prevent invalid workflow transitions server-side. |

---

# 8. Quality Requirements

## Performance
- Common navigation should feel responsive.
- Routine data views should avoid unnecessary full-page reloads.
- Long-running operations should expose loading/progress feedback.
- Real-time updates should update affected screens without manual refresh.
- Lists should support pagination or appropriate limits.

No unverified hard latency guarantees are imposed at this stage.

## Security
- Row Level Security on sensitive data.
- Server-side role enforcement.
- No service-role secrets in client applications.
- Validated database transitions.
- Secure account linking.
- Restricted access to salaries, costs and financial information.

## Reliability
- Financial and stock operations must be transactional.
- Important actions must be idempotent where retry is possible.
- Failed notification delivery must not corrupt service state.
- Historical records must not be silently deleted.

## Usability
- Mechanic actions must require minimal input.
- Admin must have a clear operational overview.
- Customer must understand service progress.
- Every blocked action must explain the reason.
- Every successful operation must provide feedback.

## Compatibility
- Android-first mobile support.
- Responsive desktop and mobile admin interface.
- Customer and mechanic interfaces optimized for phones.
- Desktop web administration through a local development server and future hosted deployment.

---

# 9. Integrations and AI

## Supabase
- Authentication.
- PostgreSQL database.
- Row Level Security.
- Realtime subscriptions.
- Database functions and triggers.
- Scheduled jobs where necessary.

## Payment
No real payment gateway in the initial product.

All payment methods are recorded as simulations or manually confirmed external settlements.

## Notifications
- Persistent in-app notifications.
- Supabase Realtime for connected clients.
- Scheduled backend jobs for reminders.
- Push notifications are optional future work.

## AI
AI is not a required product capability.

---

# 10. Constraints and Dependencies

- Single workshop.
- Five physical service bays.
- Flutter-based client application.
- Supabase backend.
- No supplier purchasing workflow.
- No actual payment gateway.
- No insurer integration.
- Clean-slate database and migration history.
- Destructive database reset requires explicit environment verification and backup.
- No legacy schema compatibility requirement.
- Comprehensive seed data is deferred until the application workflows are operational.

---

# 11. Success and Definition of Done

PitMate is considered functionally complete when a complete end-to-end workshop lifecycle can be demonstrated.

Required demonstration scenarios:

1. Registered customer books and checks in.
2. Guest customer receives a walk-in service without creating an account.
3. Mechanic completes an inspection.
4. Admin prepares an estimate.
5. Customer approves the estimate.
6. Admin assigns multiple mechanics.
7. Mechanics complete parallel and sequential operations.
8. Mechanic requests unavailable stock.
9. Admin records stock arrival and fulfills the request.
10. Mechanic reports additional findings.
11. Customer rejects supplementary work without blocking the original work.
12. Repair passes QC.
13. Admin creates invoice.
14. Customer pays through simulated QRIS/card.
15. Admin records cash payment and change in a separate scenario.
16. Vehicle is handed over.
17. History and reminders are generated.
18. All three roles receive appropriate notifications.

The full seed must make these scenarios demonstrable without manually constructing every record.

---

# 12. Assumptions, Risks and Open Questions

## Approved by user
- Single workshop.
- Five service bays.
- Guest walk-in support.
- Registered customer portal.
- Admin-centric operations.
- Minimal mechanic UI.
- Inspection and diagnosis before repair authorization.
- Separate supplementary work.
- No in-app purchasing.
- Simulated payment.
- Hybrid mechanic compensation.
- In-app notifications.
- Clean-slate reconstruction.

## Recommended defaults
- Weighted-average inventory costing.
- No negative stock.
- One primary bay per vehicle at a time.
- Admin-controlled dispatch.
- Customer approval for all additional chargeable work.
- Inspection fee configurable.
- Payment timing configurable per order.
- Mechanic incentives calculated per completed operation.
- Failed QC returns only affected operations.
- Historical financial records remain immutable.

## Open decisions
- Exact inspection fee.
- Actual tax configuration.
- Insurance coverage rules.
- Deposit percentage or amount.
- Default appointment durations.
- Workshop opening hours.
- Exact mechanic base salary and incentive rates.
- Whether attendance is included in the initial release.
- Exact cancellation and refund policies.
- Whether customers can approve supplementary work remotely or only through the admin.

---

# 13. Decision Log

| ID | Decision | Status |
|---|---|---|
| DEC-001 | Clean-slate application reconstruction | Approved |
| DEC-002 | New database and migrations | Approved |
| DEC-003 | Old data migration unnecessary | Approved |
| DEC-004 | Five service bays | Approved |
| DEC-005 | Guest customer walk-in | Approved |
| DEC-006 | Separate original and supplementary work | Approved |
| DEC-007 | External procurement | Approved |
| DEC-008 | Hybrid mechanic compensation | Recommended |
| DEC-009 | Weighted-average costing | Recommended |
| DEC-010 | Simulated payment methods | Approved |
| DEC-011 | Real-time in-app notifications | Approved |
| DEC-012 | Deferred lite/full seed execution | Approved |
| DEC-013 | Configurable payment timing | Recommended |
| DEC-014 | Configurable tax and insurance | Approved |

---

# 14. Related Documents

- DESIGN.md
- Part 3 — Architecture & Milestone Planning
- Part 4 — Implementation Planning
- Part 5 — SYSTEM_DISCOVERY.md (historical reference only)
- TESTING.md (to be established)
- SEED_STRATEGY.md (to be established)
- DATABASE_SCHEMA.md (Part 3 output)
