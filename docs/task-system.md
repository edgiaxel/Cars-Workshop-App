# Task System Specification

**Project:** Cars Workshop App  
**Application Name:** Pitstop Garage  
**Document:** Task System Specification  
**Version:** 1.0  
**Status:** Baseline  
**Last Updated:** 23 September 2026

---

## 1. Purpose

The task system defines the individual work items performed as part of a service order.

A service order represents the overall service job for a vehicle, while service tasks represent the specific pieces of work required to complete that job.

For example:

> **Service Order:** BMW M Hybrid V8 Brake System Inspection

May contain:

1. Inspect brake system
2. Inspect brake discs
3. Inspect brake pads
4. Replace worn brake pads
5. Perform brake system test

The task system provides the application with a structured way to:

- break service work into smaller activities;
- assign individual tasks to mechanics;
- track task-level progress;
- determine overall service progress;
- identify unfinished work;
- support quality checking before service completion.

---

## 2. Relationship to Service Orders

Every service task belongs to exactly one service order.

### Relationship

```text
Customer
   │
   └── Vehicle
         │
         └── Service Order
                │
                ├── Task 1
                ├── Task 2
                ├── Task 3
                └── Task N
```

A service order may contain multiple tasks.

A task cannot exist independently of a service order.

### Rules

- Every task shall reference a valid `service_order_id`.
- A service order may have zero or more tasks during initial creation.
- A service order should have at least one task before operational work begins.
- Tasks shall not be transferred between service orders.
- Deleting historical service orders or their tasks shall not be part of normal application operation.

---

## 3. Task Data Model

The task system uses the `service_tasks` table.

| Field | Type | Description |
|---|---|---|
| `id` | uuid | Unique task identifier |
| `service_order_id` | uuid | Parent service order |
| `assigned_mechanic_id` | uuid, nullable | Mechanic responsible for the task |
| `title` | text | Short task name |
| `description` | text, nullable | Detailed instructions or notes |
| `status` | service_task_status | Current task state |
| `completed_at` | timestamptz, nullable | Time the task was completed |
| `created_at` | timestamptz | Task creation timestamp |
| `updated_at` | timestamptz | Last modification timestamp |

---

## 4. Task Status

The task system uses three statuses:

```text
PENDING
   │
   ▼
IN_PROGRESS
   │
   ▼
COMPLETED
```

### 4.1 PENDING

The task has been created but work has not started.

Typical conditions:

- task has not been started;
- mechanic may or may not have been assigned;
- task is waiting to be worked on.

Example:

> `Inspect brake discs — PENDING`

---

### 4.2 IN_PROGRESS

The mechanic has started working on the task.

Typical conditions:

- task is actively being worked on;
- an assigned mechanic should exist;
- the task contributes to the service order's active work.

Example:

> `Inspect brake discs — IN_PROGRESS`

---

### 4.3 COMPLETED

The mechanic has finished the task.

Typical conditions:

- required work has been performed;
- the task is considered complete;
- `completed_at` contains the completion timestamp.

Example:

> `Inspect brake discs — COMPLETED`

---

## 5. Task Lifecycle

The standard lifecycle is:

```text
PENDING
   │
   │ Start Task
   ▼
IN_PROGRESS
   │
   │ Complete Task
   ▼
COMPLETED
```

### Standard transitions

| Current Status | Next Status | Allowed Action |
|---|---|---|
| PENDING | IN_PROGRESS | Start task |
| IN_PROGRESS | COMPLETED | Complete task |

The application shall not provide arbitrary status selection.

For example, a user should not be able to directly select:

```text
PENDING → COMPLETED
```

without the task passing through `IN_PROGRESS`.

---

## 6. Task Reopening

A completed task may need to be reopened when a problem is discovered during quality checking.

Therefore, the following corrective transition is permitted:

```text
COMPLETED
   │
   │ Corrective Work Required
   ▼
IN_PROGRESS
```

This transition shall only be performed by an authorized Admin or the mechanic responsible for the task.

When a completed task is reopened:

- its status shall change to `IN_PROGRESS`;
- `completed_at` shall be cleared;
- the task shall once again count as incomplete;
- the parent service order may need to return from `QUALITY_CHECK` to `IN_PROGRESS`.

The system shall not allow arbitrary reopening of completed tasks outside legitimate corrective work.

---

## 7. Task Assignment

Tasks may optionally be assigned to a mechanic.

### Assignment rules

- Admin may assign a task to an active mechanic.
- Admin may change the assigned mechanic.
- A mechanic may view tasks assigned to them.
- A mechanic may update the status of their assigned tasks.
- Customers may view task progress but cannot assign or modify tasks.
- Inactive mechanics shall not be assigned to new work.
- A task may temporarily have no assigned mechanic while the service order is being prepared.

### Starting a task

A task should have an assigned mechanic before entering `IN_PROGRESS`.

Therefore:

```text
PENDING + No Mechanic
        ↓
Cannot Start

PENDING + Assigned Mechanic
        ↓
Can Start
```

This prevents work from being marked as started without an identifiable responsible mechanic.

---

## 8. Task Creation

Tasks are normally created as part of service-order preparation.

### Admin responsibilities

Admin may:

- create tasks;
- edit task titles;
- edit descriptions;
- assign mechanics;
- change assignments;
- reorder tasks for presentation;
- remove tasks that have not become part of completed historical work.

### Mechanic responsibilities

Mechanics may:

- view tasks assigned to them;
- start assigned tasks;
- complete assigned tasks;
- provide task-related work information where supported by the interface.

Mechanics shall not create arbitrary service orders through the task system.

### Customer responsibilities

Customers may:

- view their service order's tasks;
- view task status;
- view overall progress.

Customers may not:

- create tasks;
- assign mechanics;
- change task status;
- mark work as completed.

---

## 9. Task Progress Calculation

Service progress shall be derived from task completion.

The system shall not store a separate manually editable progress percentage on the service order.

### Formula

```text
Progress =
(completed_tasks / total_tasks) × 100
```

Example:

```text
Total Tasks:     5
Completed Tasks: 3

Progress = (3 / 5) × 100
         = 60%
```

### Progress states

| Condition | Progress |
|---|---:|
| No tasks | 0% |
| 1 of 4 completed | 25% |
| 2 of 4 completed | 50% |
| 3 of 4 completed | 75% |
| All completed | 100% |

Progress shall be calculated dynamically from the current task statuses.

---

## 10. Zero-Task Service Orders

A service order may temporarily exist without tasks while it is being prepared.

A service order with zero tasks shall display:

```text
Progress: 0%
Tasks: 0
```

However, a service order shall not be allowed to enter the final operational stages without appropriate tasks.

In particular, the system should require at least one task before moving active work toward quality checking.

This prevents a service order from being completed without any recorded work.

---

## 11. Quality Check Requirement

Tasks provide the basis for determining whether the service order is ready for quality checking.

Before an active service order can transition to:

```text
IN_PROGRESS → QUALITY_CHECK
```

the system shall verify that:

1. the service order contains at least one task; and
2. all required tasks have status `COMPLETED`.

Therefore:

```text
5 Tasks
├── Completed
├── Completed
├── Completed
├── Completed
└── Completed
        ↓
   100% Complete
        ↓
   QUALITY_CHECK
```

If any task remains:

```text
PENDING
```

or:

```text
IN_PROGRESS
```

the service order shall remain in active work.

Example:

```text
5 Tasks
├── Completed
├── Completed
├── Completed
├── Completed
└── IN_PROGRESS
        ↓
      80%
        ↓
Cannot enter QUALITY_CHECK
```

---

## 12. Task Timestamps

Task timestamps shall reflect meaningful lifecycle events.

### Creation

When a task is created:

```text
created_at = current timestamp
updated_at = current timestamp
```

### Modification

When task information changes:

```text
updated_at = current timestamp
```

### Completion

When a task changes to `COMPLETED`:

```text
completed_at = current timestamp
```

### Reopening

When a completed task returns to `IN_PROGRESS`:

```text
completed_at = NULL
```

This ensures that `completed_at` always represents the most recent completion of the current task lifecycle.

---

## 13. Task Titles and Descriptions

Task titles shall be concise and describe a specific unit of work.

### Recommended examples

```text
Inspect brake system
Inspect brake discs
Replace brake pads
Check engine oil level
Replace engine oil
Inspect cooling system
Check coolant level
Inspect suspension
Perform electrical diagnostics
Perform final inspection
```

Descriptions may provide additional detail:

```text
Inspect front and rear brake components for excessive wear,
cracks, leaks, or abnormal operating conditions.
```

Tasks should represent actionable work rather than vague categories.

### Avoid

```text
Brake
Engine
Maintenance
Car Check
```

### Prefer

```text
Inspect brake discs
Replace engine oil
Perform brake system pressure test
```

---

## 14. Task Granularity

Tasks should be sufficiently specific to represent meaningful progress without becoming excessively fragmented.

### Too broad

```text
Service entire vehicle
```

### Too fragmented

```text
Open toolbox
Pick up wrench
Remove bolt
Put bolt aside
```

### Appropriate

```text
Inspect brake system
Replace front brake pads
Inspect brake discs
Perform brake system test
```

The purpose of the task system is to represent meaningful workshop activities, not every physical action performed by a mechanic.

---

## 15. Task System and Inventory

Tasks and spare-part usage are related but are separate concepts.

A task may require spare parts, but a task does not directly represent inventory movement.

For example:

```text
Task:
Replace front brake pads
        │
        └── Uses:
             High Performance Brake Pad Set
```

The actual inventory transaction is recorded through:

```text
service_order_parts
```

This separation allows:

- tasks to track work;
- parts to track inventory usage;
- service orders to calculate costs.

Task completion alone shall not automatically imply that a part was consumed unless the inventory-processing logic explicitly records the part usage.

---

## 16. Task System and Service Order Status

Task status and service-order status serve different purposes.

### Service Order Status

Represents the overall lifecycle of the service job:

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

### Task Status

Represents the state of an individual work item:

```text
PENDING
IN_PROGRESS
COMPLETED
```

Therefore, multiple task statuses may exist inside one service-order status.

Example:

```text
Service Order:
IN_PROGRESS

Tasks:
├── Inspect brakes       → COMPLETED
├── Replace brake pads   → COMPLETED
├── Inspect suspension   → IN_PROGRESS
└── Road test            → PENDING
```

The service order remains `IN_PROGRESS` because not all work is complete.

---

## 17. Task and Quality-Control Flow

The intended relationship between tasks and the service-order state machine is:

```text
SERVICE ORDER
     │
     ▼
  IN_PROGRESS
     │
     ├── Task A → COMPLETED
     ├── Task B → COMPLETED
     ├── Task C → COMPLETED
     └── Task D → COMPLETED
             │
             ▼
       100% Task Progress
             │
             ▼
       QUALITY_CHECK
             │
       ┌─────┴─────┐
       │           │
      PASS        FAIL
       │           │
       ▼           ▼
  COMPLETED    IN_PROGRESS
                   │
                   ▼
             Corrective Tasks
```

A failed quality check may require existing tasks to be reopened or additional corrective tasks to be created.

---

## 18. Customer Visibility

Customers shall have read-only visibility into relevant tasks belonging to their service orders.

The customer interface may display:

- task title;
- task description where appropriate;
- assigned mechanic;
- task status;
- overall service progress;
- completed task count;
- total task count.

Example:

```text
BMW M4 Competition
Scheduled Maintenance

Progress
████████████░░░░ 75%

3 / 4 tasks completed

✓ Engine oil replacement
✓ Oil filter replacement
✓ Brake inspection
○ Final inspection
```

Customer visibility shall not provide controls for changing task status or assignments.

---

## 19. Mechanic Dashboard

A mechanic's task view should prioritize tasks assigned to that mechanic.

Recommended information:

```text
My Tasks

IN PROGRESS
├── Inspect brake system
└── Cooling system diagnosis

PENDING
├── Replace brake pads
└── Perform final inspection

COMPLETED
└── Vehicle intake inspection
```

Mechanics should also be able to access the parent service order and relevant vehicle information from a task.

---

## 20. Admin Task Management

Admin shall have the broadest task-management capabilities.

Admin may:

- create tasks;
- edit task information;
- assign mechanics;
- reassign mechanics;
- change task status where authorized;
- reopen completed tasks when corrective work is required;
- view all tasks;
- filter tasks by status;
- filter tasks by mechanic;
- filter tasks by service order;
- review task completion before quality checking.

Admin should be able to identify:

- unassigned tasks;
- overdue or stalled tasks where such tracking is implemented;
- incomplete tasks;
- tasks belonging to high-priority service orders.

---

## 21. Task Deletion

Task deletion shall not be treated as a normal method of correcting historical work.

For tasks that have not yet become part of completed historical service records, Admin may remove incorrectly created tasks when appropriate.

Once a task represents performed historical work, the preferred approach is to preserve the task record rather than silently delete it.

Corrective work should generally be represented through:

- reopening the task; or
- creating an additional corrective task.

This preserves the integrity of service history.

---

## 22. Validation Rules

The application shall validate task data before saving.

### Required fields

The following fields are required:

- `service_order_id`
- `title`
- `status`

### Optional fields

The following fields may be null:

- `assigned_mechanic_id`
- `description`
- `completed_at`

### Additional validation

The system shall ensure:

1. the referenced service order exists;
2. the assigned mechanic exists if an assignment is provided;
3. inactive mechanics are not assigned to new work;
4. a task entering `IN_PROGRESS` has an assigned mechanic;
5. a task entering `COMPLETED` has valid completion information;
6. `completed_at` is set when status is `COMPLETED`;
7. `completed_at` is cleared when a completed task is reopened;
8. customers cannot modify task data;
9. mechanics cannot modify tasks belonging to unrelated service orders.

---

## 23. Example Task Set

### Example: BMW M Hybrid V8 Brake System Inspection

**Service Order:**  
`BMW M Hybrid V8 Brake System Inspection`

**Tasks:**

| # | Task | Assigned Mechanic | Status |
|---|---|---|---|
| 1 | Inspect brake system | Daniel Rossi | COMPLETED |
| 2 | Inspect brake discs | Daniel Rossi | COMPLETED |
| 3 | Inspect brake pads | Daniel Rossi | IN_PROGRESS |
| 4 | Check brake fluid | Daniel Rossi | PENDING |
| 5 | Perform brake system test | Daniel Rossi | PENDING |

Progress:

```text
2 / 5 completed = 40%
```

The service order remains:

```text
IN_PROGRESS
```

It cannot enter `QUALITY_CHECK` until all required tasks are completed.

---

## 24. Design Principles

The task system follows these principles:

### 24.1 Tasks represent real work

Each task should correspond to a meaningful workshop activity.

### 24.2 Progress is derived

Progress is calculated from task status rather than manually entered.

### 24.3 Assignment is explicit

Every active task should have a responsible mechanic.

### 24.4 Customers are observers

Customers can monitor progress but cannot alter workshop operations.

### 24.5 Historical work is preserved

Completed work should not be silently erased.

### 24.6 Service orders remain the authoritative workflow

Tasks support the service-order workflow rather than replacing it.

### 24.7 State transitions are controlled

Users should perform defined actions rather than selecting arbitrary status values.

---

## 25. Implementation Requirements

The Flutter application shall:

- display tasks under their parent service order;
- display task status clearly;
- provide role-appropriate task actions;
- calculate task progress dynamically;
- prevent unauthorized task modifications;
- prevent starting unassigned tasks;
- prevent service orders from entering quality checking while required tasks remain incomplete;
- update task timestamps according to lifecycle events;
- reflect task changes in the service-order interface.

The backend shall enforce authorization and data-integrity rules rather than relying exclusively on Flutter UI restrictions.

The task system shall integrate with:

- `service_orders`;
- `mechanics`;
- `service_order_parts`;
- `service_records`;
- `service_order_status_history`.

---

## 26. Related Documents

- `docs/requirements.md`
- `docs/state-machine.md`
- `docs/business-rules.md`
- `docs/role-permissions.md`
- `docs/route-architecture.md`
- `docs/database-schema.md`
- `docs/features/service-orders.md`
- `docs/features/service-progress.md`
- `docs/features/inventory.md`

---

## 27. Specification Baseline

This document establishes the baseline task-system behavior for Pitstop Garage version 1.0.

Future implementation changes shall update this specification when task lifecycle, assignment rules, progress calculation, or task-related permissions materially change.