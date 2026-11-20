# PitMate — Product Design & User Experience Specification

> **Product:** PitMate  
> **Version:** 2.0  
> **Status:** Initial Design Specification — Draft  
> **Date:** 2026-11-20  
> **Visual Direction:** Motorsport-inspired professional workshop management  
> **Platforms:** Mobile-first customer/mechanic, responsive desktop/mobile admin

---

# 1. Design Overview

## 1.1 Product Experience

PitMate should feel like a professional automotive workshop operating system.

The interface must reflect the actual responsibilities of each role.

- Admin: Operational control center.
- Mechanic: Focused work execution.
- Customer: Vehicle and service management.

## 1.2 Design Goals

1. Reduce unnecessary navigation.
2. Make important information immediately visible.
3. Keep mechanic interactions simple.
4. Make the workshop floor understandable at a glance.
5. Maintain consistent components across roles.
6. Support mobile and desktop without duplicating application logic.
7. Make status and workflow transitions visually obvious.

## 1.3 Visual Direction

Retain the existing motorsport-inspired visual identity as a starting point.

- Racing red accent.
- Dark and light themes.
- Space Grotesk for prominent headings and technical information.
- Inter for body text and forms.
- Professional, compact information density.
- Clear status colors.
- Consistent spacing and surface hierarchy.

Avoid making every screen resemble a racing telemetry dashboard. Workshop management requires readability more than decoration.

---

# 2. Navigation and Information Architecture

## 2.1 Admin Navigation

### Desktop

```text
PITMATE
│
├── Overview
│
├── WORKSHOP
│   ├── Workshop Floor
│   ├── Schedule
│   ├── Service Orders
│   ├── Bookings
│   ├── Inspections
│   └── Quality Control
│
├── MANAGEMENT
│   ├── Customers
│   ├── Vehicles
│   ├── Mechanics
│   └── Service Catalog
│
├── INVENTORY
│   ├── Parts Catalog
│   ├── Stock Overview
│   ├── Part Requests
│   ├── Stock Movements
│   └── Low Stock
│
├── FINANCE
│   ├── Estimates
│   ├── Invoices
│   ├── Payments
│   ├── Mechanic Earnings
│   └── Reports
│
├── COMMUNICATION
│   ├── Notifications
│   └── Maintenance Reminders
│
└── SETTINGS
    ├── Workshop Profile
    ├── Service Pricing
    ├── Tax Configuration
    ├── Insurance Configuration
    ├── Compensation Rules
    ├── Users & Permissions
    └── Appearance
```

The desktop sidebar should be collapsible.

### Mobile

Use a simplified navigation structure:

- Overview.
- Workshop.
- Orders.
- Inventory.
- More.

The mobile interface must prioritize operational tasks over administrative configuration.

## 2.2 Mechanic Navigation

```text
MECHANIC
│
├── My Work
│   ├── Today's Assignments
│   ├── Active Work
│   └── Upcoming Work
│
├── Requests
│   ├── Part Requests
│   └── Assistance Requests
│
├── Notifications
│
└── Profile
    ├── Work History
    └── Earnings
```

Mechanics should not see administrative pricing, payroll configuration or purchasing controls.

## 2.3 Customer Navigation

```text
CUSTOMER
│
├── Home
│
├── My Garage
│   └── Vehicle Details
│
├── Book Service
│
├── Appointments
│
├── Active Services
│   └── Service Details
│
├── Service History
│
├── Invoices & Payments
│
├── Notifications
│
└── Profile
```

Guest customers do not have an application navigation system. They receive a physical service reference and interact with the admin for their service.

---

# 3. Screen Inventory

## Admin

| ID | Screen | Purpose | Priority |
|---|---|---|---|
| UI-A01 | Admin Dashboard | Operational overview | P0 |
| UI-A02 | Workshop Floor | Five-bay live operation | P0 |
| UI-A03 | Workshop Schedule | Appointment and workload scheduling | P0 |
| UI-A04 | Service Orders | Order management | P0 |
| UI-A05 | Service Order Details | Complete service lifecycle | P0 |
| UI-A06 | Customer Intake | Registered/guest check-in | P0 |
| UI-A07 | Bookings | Appointment management | P0 |
| UI-A08 | Inspection Review | Review diagnostic findings | P0 |
| UI-A09 | Estimate Builder | Pricing and authorization preparation | P0 |
| UI-A10 | Mechanic Management | Availability and assignments | P0 |
| UI-A11 | Inventory Overview | Stock management | P0 |
| UI-A12 | Part Catalog | Part configuration | P0 |
| UI-A13 | Part Requests | Mechanic requests | P0 |
| UI-A14 | Service Catalog | Service templates and pricing | P0 |
| UI-A15 | Quality Control | Final verification | P0 |
| UI-A16 | Invoice & Payments | Billing and settlement | P0 |
| UI-A17 | Mechanic Earnings | Compensation management | P0 |
| UI-A18 | Reports | Operational and financial analytics | P0 |
| UI-A19 | Notifications | Administrative alerts | P0 |
| UI-A20 | Settings | Workshop configuration | P0 |

## Mechanic

| ID | Screen | Purpose | Priority |
|---|---|---|---|
| UI-M01 | Mechanic Home | Daily assignments | P0 |
| UI-M02 | Assignment Details | Work instructions | P0 |
| UI-M03 | Inspection Workspace | Vehicle diagnosis | P0 |
| UI-M04 | Operation Workspace | Execute assigned operation | P0 |
| UI-M05 | Part Request | Request required stock | P0 |
| UI-M06 | Notifications | Receive job updates | P0 |
| UI-M07 | Work History | Completed work | P0 |
| UI-M08 | Earnings | Personal incentive records | P0 |

## Customer

| ID | Screen | Purpose | Priority |
|---|---|---|---|
| UI-C01 | Customer Home | Vehicle and service overview | P0 |
| UI-C02 | My Garage | Vehicle management | P0 |
| UI-C03 | Vehicle Details | Vehicle-specific history | P0 |
| UI-C04 | Book Service | Appointment request | P0 |
| UI-C05 | Appointments | Booking status | P0 |
| UI-C06 | Active Services | Current vehicle services | P0 |
| UI-C07 | Service Tracking | Repair progress | P0 |
| UI-C08 | Estimate Approval | Approve/reject work | P0 |
| UI-C09 | Payment | Simulated payment | P0 |
| UI-C10 | Service History | Historical services | P0 |
| UI-C11 | Invoice & Receipt | Billing documents | P0 |
| UI-C12 | Notifications | Service alerts | P0 |
| UI-C13 | Maintenance Reminders | Future maintenance | P0 |
| UI-C14 | Profile | Customer information | P0 |

---

# 4. Screen Specifications

## UI-A01 — Admin Dashboard

**Purpose:** Provide an immediate overview of workshop operations.

### Layout

Top:
- Date and workshop information.
- Global search.
- Notification center.
- User profile.

Operational summary:
- Vehicles in workshop.
- Waiting for inspection.
- Active service orders.
- Blocked operations.
- Ready for QC.
- Awaiting payment.
- Ready for pickup.

Main area:
- Workshop activity timeline.
- Mechanic availability.
- Upcoming appointments.
- Pending approvals.
- Low-stock alerts.

### Primary actions

- New walk-in.
- Check-in booking.
- Create customer.
- View workshop floor.

### Responsive behavior

Desktop:
- Multi-column overview.
- Detailed tables and charts.

Mobile:
- Vertical operational summary.
- Prioritized action shortcuts.
- Compact activity list.

---

## UI-A02 — Workshop Floor

**Purpose:** Represent the physical workshop and all current vehicle operations.

This is the central admin workspace.

### Layout

Top controls:
- Current date.
- Live synchronization indicator.
- View selector.
- Mechanic filter.
- Status filter.
- Bay filter.

Main workspace:

```text
┌───────────────────────────────────────────────┐
│ WORKSHOP FLOOR                  LIVE ●         │
├───────────────────────────────────────────────┤
│ WAITING / INTAKE                              │
│ [Vehicle A] [Vehicle B]                       │
├───────────────────────────────────────────────┤
│ BAY 01        BAY 02        BAY 03             │
│ [Vehicle]     [Vehicle]     [Available]        │
│ Mechanic A    Mechanic B                       │
├───────────────────────────────────────────────┤
│ BAY 04        BAY 05                          │
│ [Vehicle]     [Vehicle]                        │
│ Mechanic C    Mechanic D                       │
├───────────────────────────────────────────────┤
│ SHARED EQUIPMENT / TOOL AREA                   │
│ INVENTORY / PARTS STORAGE                      │
├───────────────────────────────────────────────┤
│ WAITING FOR QC / COMPLETED / PICKUP            │
└───────────────────────────────────────────────┘
```

The visual arrangement is conceptual, not a construction blueprint.

### Vehicle workspace tile

Each vehicle tile displays:

- Registration plate.
- Vehicle make/model.
- Customer.
- Service reference.
- Current stage.
- Lead mechanic.
- Additional assigned mechanics.
- Elapsed time.
- Estimated completion.
- Blocked indicator.

### Interactions

| Action | Response |
|---|---|
| Select vehicle | Open service order |
| Assign mechanic | Open assignment selector |
| Change bay | Validate and update location |
| View blocked job | Show blocking reason |
| Open timeline | Show service history |
| Filter mechanic | Highlight assigned jobs |
| Start service | Validate operation prerequisites |

Drag-and-drop is optional. All important operations must also have accessible explicit controls.

### Mobile behavior

Use a vertical bay list rather than attempting to compress the full workshop map.

Each bay can be expanded to reveal its vehicle and assignments.

---

## UI-A03 — Workshop Schedule

**Purpose:** Coordinate appointments and mechanic workloads.

Views:

- Day.
- Week.
- Mechanic schedule.
- Bay schedule.

Each appointment displays:

- Time.
- Customer.
- Vehicle.
- Expected service.
- Assigned mechanic, if available.
- Appointment status.

The schedule must distinguish planned appointments from actual workshop occupancy.

A booking does not automatically occupy a physical bay.

---

## UI-A06 — Customer Intake

**Purpose:** Create a workshop admission with minimal administrative friction.

### Intake flow

Step 1 — Customer type:

- Registered customer.
- New guest customer.

Step 2 — Customer information:

Registered:
- Search by name, phone or customer reference.

Guest:
- Name.
- Phone, when available.
- Optional email.

Step 3 — Vehicle:

- Select registered vehicle.
- Register a new vehicle.

Step 4 — Service information:

- Walk-in or booking.
- Customer complaint.
- Odometer.
- Visible vehicle condition.
- Intake notes.
- Optional photos.

Step 5 — Confirmation:

- Generate service order.
- Assign intake reference.
- Display intake summary.

The interface should minimize unnecessary page transitions and support a clear progress indicator.

---

## UI-A05 — Service Order Details

**Purpose:** Provide a single administrative workspace for the entire vehicle visit.

### Layout

Header:
- Service reference.
- Customer.
- Vehicle.
- Current status.
- Intake origin.
- Arrival timestamp.

Navigation tabs:

1. Overview.
2. Inspection.
3. Estimates.
4. Operations.
5. Mechanics.
6. Parts.
7. Quality Control.
8. Invoice.
9. History.

### Overview

Show:
- Current stage.
- Progress.
- Blocking issues.
- Active mechanics.
- Bay.
- Estimated completion.
- Outstanding approvals.
- Outstanding payments.

### History

Display a chronological event timeline.

Example:

```text
09:00  Vehicle checked in
09:15  Inspection assigned
09:35  Inspection completed
09:42  Estimate created
10:00  Customer approved
10:10  Mechanics assigned
10:30  Service started
11:45  Additional finding reported
12:00  Customer notified
13:30  Repair completed
14:00  QC passed
14:15  Invoice generated
14:30  Payment received
14:40  Vehicle handed over
```

---

## UI-A08 — Inspection Review

**Purpose:** Let administrators review mechanic findings and create proposed operations.

### Layout

- Vehicle identification.
- Customer complaint.
- Odometer.
- Inspection categories.
- Findings.
- Severity.
- Photos.
- Mechanic notes.
- Recommended operations.

Primary action:
- Create estimate from findings.

The admin must not need to re-enter inspection findings manually.

---

## UI-A09 — Estimate Builder

**Purpose:** Prepare customer-facing repair estimates.

### Layout

Customer and vehicle information.

Line-item editor:

| Field | Description |
|---|---|
| Service | Selected template or custom work |
| Parts | Required spare parts |
| Quantity | Required amount |
| Labor | Service labor fee |
| Discount | Authorized discount |
| Tax | Configured tax |
| Coverage | Applicable insurance contribution |

Summary:
- Parts subtotal.
- Labor subtotal.
- Discounts.
- Tax.
- Insurance coverage.
- Customer payable amount.

Actions:
- Save draft.
- Preview estimate.
- Send to customer.
- Record physical approval.
- Revise estimate.

Customer approval should be clearly distinguished from admin confirmation.

---

## UI-A10 — Mechanic Management

**Purpose:** Help admins dispatch and coordinate mechanics.

Display:

- Mechanic identity.
- Active assignment count.
- Current task.
- Current bay.
- Availability.
- Relevant skills.
- Workload.
- Pending requests.

Assignment interface:

- Select operation.
- Select lead mechanic.
- Select supporting mechanics.
- Allocate incentive shares where applicable.
- Confirm assignment.

The system should warn when assignment capacity is exceeded.

---

## UI-A11 — Inventory Overview

**Purpose:** Provide a complete stock overview.

### Summary

- Total part types.
- Low-stock items.
- Out-of-stock items.
- Reserved quantity.
- Current inventory valuation.

### Stock table

| Part | On hand | Reserved | Available | Minimum |
|---|---:|---:|---:|---:|
| Oil 1L | 50 | 10 | 40 | 15 |
| Oil filter | 15 | 4 | 11 | 10 |
| Brake pad | 8 | 8 | 0 | 5 |

### Actions

- Receive stock.
- Adjust stock.
- View movements.
- Review requests.
- Review low stock.

Stock receiving should support:
- Part.
- Quantity.
- Unit purchase cost.
- Supplier reference (optional text).
- Date.
- Responsible admin.
- Notes.

No in-app purchasing workflow.

---

## UI-A13 — Part Requests

Admin receives requests from mechanics.

Request details:
- Mechanic.
- Service order.
- Operation.
- Part.
- Quantity.
- Request reason.
- Availability.

Actions:
- Fulfill.
- Partially fulfill.
- Reject.
- Mark unavailable.

The mechanic receives a notification when the request is resolved.

---

## UI-M01 — Mechanic Home

**Purpose:** Show mechanics exactly what they need to work on.

### Layout

Top:
- Greeting.
- Current date.
- Notification indicator.

Main:
- Current active operation.
- Next assignment.
- Pending inspection.
- Part requests.
- Completed operations today.

Each assignment shows:

- Vehicle.
- Service reference.
- Operation name.
- Priority.
- Instructions.
- Required parts.
- Due/estimated time.

Primary action:
- Open work.

Avoid excessive analytics and administrative statistics.

---

## UI-M02 — Assignment Details

**Purpose:** Give the mechanic everything necessary to execute assigned work.

Display:

1. Vehicle identification.
2. Customer complaint.
3. Relevant inspection findings.
4. Approved operation scope.
5. Instructions.
6. Required parts.
7. Checklist.
8. Assigned team.
9. Notes and attachments.

Primary actions:

- Start operation.
- Update checklist.
- Add finding.
- Request part.
- Request assistance.
- Complete operation.

A mechanic must not be able to silently expand the approved work scope.

---

## UI-M03 — Inspection Workspace

Use structured inspection templates.

Each category provides:

- Pass.
- Needs attention.
- Critical.
- Not applicable.

Mechanics can add:

- Notes.
- Photos.
- Recommended work.
- Severity.

The mechanic submits the inspection to admin for review.

---

## UI-M04 — Operation Workspace

**Purpose:** Minimize distractions while work is underway.

Main content:

- Vehicle identification.
- Operation title.
- Work instructions.
- Checklist.
- Required parts.
- Timer/elapsed duration.
- Team assignments.

Primary controls:

- Start.
- Pause with reason.
- Resume.
- Request part.
- Report additional finding.
- Complete.

Use large touch targets and minimal text entry.

---

## UI-M05 — Part Request

A short request form:

- Select required part.
- Quantity.
- Optional note.
- Submit.

The system automatically associates the request with the active service order and operation.

---

## UI-C01 — Customer Home

**Purpose:** Show the customer their vehicle ownership and current services.

Display:

- My vehicles.
- Active service.
- Upcoming appointment.
- Outstanding approval.
- Outstanding invoice.
- Maintenance reminders.

Primary actions:

- Book service.
- Add vehicle.
- View active service.

---

## UI-C06 — Active Services

Each vehicle service appears as a timeline.

Example:

```text
Vehicle checked in       ✓
Inspection completed     ✓
Estimate approved        ✓
Repair in progress       ●
Quality control          ○
Payment                  ○
Ready for pickup         ○
```

Customers should only see customer-approved information.

Internal mechanic notes, purchasing costs and private administrative records must never be exposed.

---

## UI-C08 — Estimate Approval

Display:

- Proposed operations.
- Parts and labor.
- Tax.
- Insurance coverage.
- Total payable.
- Approval deadline, if configured.

Actions:

- Approve.
- Reject.
- Request clarification.

Rejected work must have a recorded outcome.

---

## UI-C09 — Payment

Show:

- Invoice reference.
- Amount due.
- Deposit already paid.
- Remaining balance.
- Available simulated payment methods.

Cash is recorded at the workshop by admin.

For QRIS, card and bank transfer, provide a clearly labeled simulated settlement flow.

Never imply that an actual payment gateway has been connected.

---

# 5. Shared Components and Patterns

All roles should use a shared component library.

## Application shell
- ResponsiveScaffold.
- ResponsiveSidebar.
- MobileNavigation.
- AppBar.
- Breadcrumbs.
- NotificationCenter.

## Data components
- DataTable.
- ResponsiveList.
- SearchField.
- FilterBar.
- Pagination.
- EmptyState.
- LoadingState.
- ErrorState.

## Workshop components
- VehicleTile.
- BayPanel.
- WorkshopTimeline.
- ServiceProgress.
- MechanicAvatar.
- AssignmentPanel.
- StatusIndicator.
- OperationChecklist.
- BlockingAlert.

## Financial components
- MoneyDisplay.
- PriceBreakdown.
- EstimateSummary.
- InvoiceSummary.
- PaymentMethodSelector.
- CashChangeCalculator.

## Dialog and form components
- ConfirmationDialog.
- FormDialog.
- BottomSheet.
- MultiStepForm.
- FormSection.
- ValidationMessage.

All dialogs should have consistent:
- Width.
- Padding.
- Heading.
- Primary/secondary action placement.
- Loading behavior.
- Validation feedback.

Destructive actions must require explicit confirmation.

---

# 6. Visual Direction

## Layout
- Consistent page margins.
- Clear separation of content sections.
- Responsive grids.
- Compact but readable operational tables.
- Sticky action bars where appropriate.

## Typography
- Space Grotesk for headings.
- Inter for body text.
- Consistent hierarchy and numerical alignment.

## Color
- Racing red as primary accent.
- Dark and light neutral surfaces.
- Semantic colors for statuses.

Status colors must not rely on color alone. Include labels and icons.

## Shape and surfaces
- Consistent card radius.
- Subtle borders.
- Restrained elevation.
- Consistent modal dimensions.

## Motion
- Short navigation transitions.
- Clear state-change feedback.
- Subtle notifications.
- No unnecessary decorative animation.

---

# 7. Prototype Record

No approved prototype exists yet.

Recommended prototype targets:

| Prototype | Screens | What it tests |
|---|---|---|
| P-01 | Admin Dashboard + Workshop Floor | Operational visibility |
| P-02 | Customer Intake + Service Order | Administrative workflow |
| P-03 | Mechanic Home + Operation Workspace | Mechanic usability |
| P-04 | Estimate + Approval | Customer authorization |
| P-05 | Inventory + Part Requests | Stock coordination |
| P-06 | Customer Service Tracking | Customer transparency |

Prototype status: Not started.

---

# 8. Approved Design Decisions

- One shared visual system.
- Role-specific navigation.
- Admin-first desktop workspace.
- Mechanic-first mobile workspace.
- Customer-first mobile experience.
- Five-bay workshop representation.
- Timeline-based service visibility.
- Consistent dialogs and forms.
- Shared responsive scaffold.
- Minimal mechanic interaction.
- Explicit workflow feedback.
- No requirement to preserve old screen layouts.

---

# 9. Open Design Questions

- Exact workshop floor visualization.
- Whether the desktop workshop board uses Kanban, timeline or a combined view.
- Whether the customer portal includes a dedicated desktop navigation layout.
- Exact mobile navigation pattern for mechanics.
- Whether workshop bay movement should support drag-and-drop.
- Exact notification presentation and grouping.
- Invoice printing layout.
- Final iconography and typography adjustments.

---

# 10. Design-to-PRD Mapping

| Screen | Related features |
|---|---|
| UI-A01 | F-010, F-017, F-019 |
| UI-A02 | F-008, F-009, F-010 |
| UI-A03 | F-003, F-010 |
| UI-A05 | F-005, F-006, F-007, F-008 |
| UI-A06 | F-002, F-004 |
| UI-A09 | F-006, F-013 |
| UI-A10 | F-009, F-016 |
| UI-A11 | F-011, F-012 |
| UI-A13 | F-011 |
| UI-M01 | F-009, F-017 |
| UI-M02 | F-008, F-009 |
| UI-M03 | F-005 |
| UI-M04 | F-008, F-007 |
| UI-M05 | F-011 |
| UI-C01 | F-002, F-017, F-018 |
| UI-C04 | F-003 |
| UI-C06 | F-008, F-017 |
| UI-C08 | F-006, F-007 |
| UI-C09 | F-015 |
| UI-C10 | F-002, F-015, F-018 |

---

# Design Handoff

This document defines the intended user experience, navigation, screen responsibilities and interactions.

It does not authorize implementation.

All screens and shared components must be reconciled with the approved PRD before architecture and implementation planning begin.
