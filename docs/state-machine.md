# Pitstop Garage
## Service Order State Machine

**Project:** Cars Workshop App  
**Application Name:** Pitstop Garage  
**Document Version:** 1.0  
**Status:** Baseline Specification  
**Last Updated:** 23 September 2026

---

# 1. Purpose

This document defines the lifecycle and state-transition rules for service orders in Pitstop Garage.

A service order represents a vehicle service request being processed by the workshop.

The state machine defines:

- Available service-order states
- Valid state transitions
- Roles responsible for transitions
- Conditions required for transitions
- Terminal states
- Backward transitions
- Status-history requirements

The state machine provides a controlled workflow instead of allowing service-order status to be changed arbitrarily.

---

# 2. Service Order States

Pitstop Garage uses the following service-order states:

```text
REQUESTED
INSPECTION
DIAGNOSIS
WAITING_PARTS
IN_PROGRESS
QUALITY_CHECK
COMPLETED
CANCELLED
```

---

# 3. State Definitions

## 3.1 REQUESTED

The customer or workshop has created a service request.

At this stage:

- The service order has been registered.
- The vehicle is identified.
- The requested service is recorded.
- The order may not yet have an assigned mechanic.
- The Admin reviews the request.

Typical next states:

```text
REQUESTED
    ↓
INSPECTION
```

or:

```text
REQUESTED
    ↓
CANCELLED
```

---

## 3.2 INSPECTION

The vehicle is undergoing an initial inspection.

The mechanic examines the vehicle and determines the condition requiring attention.

Typical activities include:

- Visual inspection
- Initial system checks
- Identifying obvious defects
- Checking vehicle condition
- Recording inspection findings

Typical next state:

```text
INSPECTION
    ↓
DIAGNOSIS
```

---

## 3.3 DIAGNOSIS

The mechanic determines the cause of the reported problem and identifies the required work.

The mechanic may:

- Record diagnosis findings
- Create service tasks
- Identify required parts
- Estimate additional work
- Determine whether parts are required

Possible next states:

```text
DIAGNOSIS
    ├──→ WAITING_PARTS
    └──→ IN_PROGRESS
```

`WAITING_PARTS` is used when required parts are not currently available.

`IN_PROGRESS` is used when the required work can begin immediately.

---

## 3.4 WAITING_PARTS

The service cannot continue because one or more required parts are unavailable or must be obtained before work can continue.

Typical activities include:

- Identifying missing parts
- Monitoring inventory
- Waiting for parts to become available
- Updating the service estimate if necessary

Typical next state:

```text
WAITING_PARTS
    ↓
IN_PROGRESS
```

The order may also be cancelled by an authorized user where applicable.

---

## 3.5 IN_PROGRESS

The mechanic is actively performing the required service work.

Activities may include:

- Completing service tasks
- Installing parts
- Performing repairs
- Recording findings
- Updating task statuses
- Recording parts used

Typical next state:

```text
IN_PROGRESS
    ↓
QUALITY_CHECK
```

If quality inspection later identifies a problem, the order may return to `IN_PROGRESS`.

---

## 3.6 QUALITY_CHECK

The service work has been completed by the mechanic and is undergoing final inspection.

The purpose of this state is to verify that:

- Required tasks were completed
- Parts were installed correctly
- The vehicle is ready for release
- Service requirements were satisfied
- No unresolved issues remain

Possible next states:

```text
QUALITY_CHECK
    ├──→ COMPLETED
    └──→ IN_PROGRESS
```

`COMPLETED` is used when the quality check passes.

`IN_PROGRESS` is used when additional work is required.

---

## 3.7 COMPLETED

The service order has successfully passed the quality check.

At this stage:

- Required service work is complete.
- Required tasks should be completed.
- Final service costs are recorded.
- A service record is created.
- The vehicle may be released.
- The service order becomes part of the customer's service history.

`COMPLETED` is a terminal state.

A completed service order should not normally return to an earlier operational state.

---

## 3.8 CANCELLED

The service order has been cancelled by an authorized user.

`CANCELLED` is a terminal state.

A cancelled order shall remain in the database for historical and audit purposes rather than being deleted.

---

# 4. State Transition Diagram

The normal service workflow is:

```text
                         ┌──────────────┐
                         │  REQUESTED   │
                         └──────┬───────┘
                                │
                                ▼
                         ┌──────────────┐
                         │  INSPECTION  │
                         └──────┬───────┘
                                │
                                ▼
                         ┌──────────────┐
                         │  DIAGNOSIS   │
                         └──────┬───────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
                    ▼                       ▼
             ┌──────────────┐        ┌──────────────┐
             │WAITING_PARTS │        │ IN_PROGRESS  │
             └──────┬───────┘        └──────┬───────┘
                    │                       │
                    │                       ▼
                    │                ┌──────────────┐
                    │                │QUALITY_CHECK │
                    │                └──────┬───────┘
                    │                       │
                    │              ┌────────┴────────┐
                    │              │                 │
                    │              ▼                 ▼
                    │       ┌──────────────┐  ┌──────────────┐
                    │       │  COMPLETED   │  │ IN_PROGRESS  │
                    │       └──────────────┘  └──────────────┘
                    │
                    └──────────────────────→
                              IN_PROGRESS
```

Cancellation may occur from applicable active states:

```text
REQUESTED
INSPECTION
DIAGNOSIS
WAITING_PARTS
IN_PROGRESS
QUALITY_CHECK
       │
       ▼
   CANCELLED
```

The exact cancellation permissions are defined in the role-permission specification.

---

# 5. Transition Matrix

| Current State | Next State | Responsible Role | Description |
|---|---|---|---|
| REQUESTED | INSPECTION | Admin | Accept request and begin inspection |
| REQUESTED | CANCELLED | Admin | Cancel service request |
| INSPECTION | DIAGNOSIS | Mechanic | Complete initial inspection |
| INSPECTION | CANCELLED | Admin | Cancel service during inspection |
| DIAGNOSIS | WAITING_PARTS | Mechanic / Admin | Required parts unavailable |
| DIAGNOSIS | IN_PROGRESS | Mechanic | Required work can begin |
| DIAGNOSIS | CANCELLED | Admin | Cancel service after diagnosis |
| WAITING_PARTS | IN_PROGRESS | Mechanic / Admin | Required parts available |
| WAITING_PARTS | CANCELLED | Admin | Cancel service while waiting |
| IN_PROGRESS | QUALITY_CHECK | Mechanic | Service work is ready for inspection |
| IN_PROGRESS | CANCELLED | Admin | Cancel active service |
| QUALITY_CHECK | COMPLETED | Admin | Final quality check passed |
| QUALITY_CHECK | IN_PROGRESS | Admin / Mechanic | Additional work required |
| QUALITY_CHECK | CANCELLED | Admin | Cancel service during quality check |

---

# 6. Transition Rules

## 6.1 REQUESTED → INSPECTION

The Admin accepts the service request for processing.

The service order should have:

- Valid customer
- Valid vehicle
- Service description
- Assigned mechanic where required for inspection

The transition shall create a status-history record.

---

## 6.2 INSPECTION → DIAGNOSIS

The assigned mechanic completes the initial inspection.

Inspection findings should be recorded before or during the transition.

The transition shall create a status-history record.

---

## 6.3 DIAGNOSIS → WAITING_PARTS

This transition occurs when the mechanic determines that required parts are unavailable.

The service order should identify the required parts where applicable.

The transition shall create a status-history record containing an explanation for the waiting state.

---

## 6.4 DIAGNOSIS → IN_PROGRESS

This transition occurs when all required prerequisites are available and service work can begin.

The mechanic may begin completing service tasks.

The transition shall create a status-history record.

---

## 6.5 WAITING_PARTS → IN_PROGRESS

This transition occurs when the required parts become available.

The mechanic or authorized Admin may resume the service.

The transition shall create a status-history record.

---

## 6.6 IN_PROGRESS → QUALITY_CHECK

This transition occurs when the mechanic considers the service work complete.

Before entering quality check:

- Required service tasks should be completed.
- Required parts should be recorded.
- Relevant service information should be recorded.

The transition shall create a status-history record.

---

## 6.7 QUALITY_CHECK → COMPLETED

The Admin performs or approves the final quality check.

The order may be completed only when:

- Required work is complete.
- Required tasks are complete.
- No unresolved service issue remains.
- Final service information is available.
- Final cost information is recorded or ready to be finalized.

Completion shall result in a service record being created or finalized.

---

## 6.8 QUALITY_CHECK → IN_PROGRESS

If the quality check identifies an unresolved problem, the order returns to `IN_PROGRESS`.

The reason for returning the order to active work shall be recorded in the status-history notes.

The mechanic then performs the required corrective work.

After corrective work is completed, the order returns to:

```text
IN_PROGRESS
    ↓
QUALITY_CHECK
```

---

# 7. Cancellation Rules

Cancellation is a terminal state.

An authorized Admin may cancel an active service order when appropriate.

Cancellation should preserve:

- Existing service-order information
- Existing tasks
- Existing status history
- Existing cost information
- Cancellation timestamp
- User responsible for cancellation

A cancelled service order shall not be deleted from the database.

---

# 8. Backward Transitions

The system intentionally permits a limited backward transition:

```text
QUALITY_CHECK
      ↓
IN_PROGRESS
```

This represents failed quality inspection or the discovery of additional work.

Other backward transitions are not part of the normal workflow.

For example:

```text
IN_PROGRESS → DIAGNOSIS
```

is not a standard transition.

If new diagnosis is required after work has started, the information should be recorded through service notes/tasks rather than moving the order through multiple previous states.

---

# 9. Terminal States

The following states are terminal:

```text
COMPLETED
CANCELLED
```

A terminal service order shall not normally return to an active state.

Historical records associated with terminal service orders shall remain available.

---

# 10. Status History

Every successful service-order status transition shall create one record in:

```text
service_order_status_history
```

The record shall contain:

- Service order ID
- New status
- User who performed the transition
- Optional notes
- Timestamp

Example:

```text
REQUESTED
    ↓
INSPECTION
    ↓
DIAGNOSIS
    ↓
WAITING_PARTS
    ↓
IN_PROGRESS
    ↓
QUALITY_CHECK
    ↓
COMPLETED
```

The status-history table therefore provides an auditable timeline of the service order.

---

# 11. State and Task Relationship

Service-order state represents the overall operational phase.

Service tasks represent individual pieces of work.

They are related but not identical.

For example:

```text
Service Order:
IN_PROGRESS

Tasks:
├── Inspect brake system      COMPLETED
├── Replace brake pads        COMPLETED
├── Inspect suspension        IN_PROGRESS
└── Final inspection          PENDING
```

The service order may remain `IN_PROGRESS` while individual tasks have different statuses.

Task behavior is defined separately in:

```text
docs/task-system.md
```

---

# 12. State Machine Implementation Requirements

The Flutter application shall not allow users to arbitrarily select any service-order status.

Available status actions shall depend on:

- Current status
- User role
- Assignment
- Transition rules
- Required conditions

The database shall ultimately enforce authorization so that UI restrictions alone cannot be bypassed.

The implementation should centralize transition logic rather than duplicating transition rules throughout multiple UI components.

---

# 13. Example Complete Service Lifecycle

A typical successful service may follow:

```text
REQUESTED
    │
    │ Admin accepts
    ▼
INSPECTION
    │
    │ Mechanic inspects
    ▼
DIAGNOSIS
    │
    │ Parts unavailable
    ▼
WAITING_PARTS
    │
    │ Parts available
    ▼
IN_PROGRESS
    │
    │ Work completed
    ▼
QUALITY_CHECK
    │
    │ Inspection fails
    ▼
IN_PROGRESS
    │
    │ Corrective work completed
    ▼
QUALITY_CHECK
    │
    │ Inspection passes
    ▼
COMPLETED
```

This workflow demonstrates that service processing is not necessarily strictly linear while remaining intentionally simple.

---

# 14. Relationship to Other Specifications

This document defines the service-order lifecycle.

Related behavior is defined in:

- `docs/requirements.md` — overall system requirements
- `docs/task-system.md` — individual mechanic tasks
- `docs/business-rules.md` — inventory, pricing, and operational rules
- `docs/role-permissions.md` — detailed authorization
- `docs/route-architecture.md` — application screens and routes
- `docs/database-schema.md` — database implementation