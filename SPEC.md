# PitMate — System Specification

## 1. Project Overview

**PitMate** is a mobile car workshop management application built with Flutter and Dart.

The application presents a conventional vehicle workshop through a motorsport-inspired **pit-stop garage** concept. The workshop can service normal customer vehicles as well as high-performance and racing vehicles such as GT3 cars and hypercars.

PitMate represents **one physical workshop only**. Multi-branch management is outside the current scope.

The system supports three primary user roles:

- Admin / Workshop Owner
- Mechanic
- Customer

The application is intended to be publicly accessible to customers. Customers can independently register and manage their accounts, vehicles, bookings, services, and service history.

Mechanic accounts are created and managed by the administrator.

---

# 2. Project Objectives

PitMate aims to provide a centralized system for managing the complete vehicle-service lifecycle:

1. Customer registration and authentication
2. Customer and profile management
3. Vehicle management
4. Service booking
5. Booking approval
6. Mechanic assignment
7. Vehicle inspection
8. Diagnosis
9. Service-task management
10. Checklist management
11. Spare-part requests
12. Spare-part inventory
13. Service progress tracking
14. Service cost estimation
15. Final service cost
16. Payment status
17. Mechanic compensation
18. Service history
19. Maintenance reminders
20. Notifications
21. Workshop reporting

The application should use real database-backed data through Supabase rather than relying on permanently hardcoded application-side mock data.

---

# 3. Technology

## 3.1 Frontend

- Flutter
- Dart

## 3.2 Backend Platform

- Supabase

Supabase provides the primary backend services required by the application, including:

- Authentication
- PostgreSQL database
- Row Level Security
- Database access
- Storage where required
- Realtime capabilities where required

A separate custom backend server is not required for the initial project scope.

## 3.3 Database

PostgreSQL through Supabase.

---

# 4. User Roles

PitMate has three primary roles.

## 4.1 Admin / Workshop Owner

The Admin represents the owner or administrator of the workshop.

The Admin has workshop-wide management access.

Responsibilities include:

- Manage customers
- Manage mechanics
- Manage vehicles
- Review bookings
- Approve or reject bookings
- Assign mechanics
- Manage service orders
- Review inspections and diagnoses
- Approve requested work
- Manage service pricing
- Manage spare-part inventory
- Approve spare-part requests
- Manage mechanic compensation
- Monitor workshop operations
- View workshop-wide service history
- View financial information
- View reports

---

## 4.2 Mechanic

Mechanics perform the technical work on vehicles.

Mechanic accounts are created by the Admin.

Mechanics can:

- Login
- View their schedule
- View assigned vehicles
- View assigned service orders
- View other mechanics assigned to the same service
- Perform inspections
- Record diagnoses
- Create required service tasks
- Use service-task templates
- Create custom tasks
- Complete checklist items
- Update task progress
- Request spare parts
- View relevant inventory availability
- View their own service history
- View their own earnings

Mechanics cannot:

- Create their own public accounts
- Manage other mechanics
- Manage workshop-wide inventory
- Change workshop-wide pricing
- View another mechanic's private earnings
- View unrelated mechanic service history

---

## 4.3 Customer

Customers can independently register through the application.

Customers can:

- Register
- Login
- Manage their profile
- Change their password
- Manage their vehicles
- Create bookings
- View booking status
- View active services
- View service progress
- View service costs
- View service history
- Receive service reminders
- Receive notifications

A customer may own multiple vehicles.

A customer may represent either:

- An individual
- An organization / manufacturer

---

# 5. Account and Authentication

## 5.1 Customer Registration

Customers can independently create an account.

Customer information may include:

- Customer ID
- Name
- Email
- Phone number
- Address
- Customer type

Customer type:

- Individual
- Organization

Organizations may additionally provide an organization/company name.

---

## 5.2 Mechanic Account

Mechanics cannot publicly register.

The Admin creates mechanic accounts.

Basic flow:

```text
Admin
  ↓
Create Mechanic Account
  ↓
Assign Mechanic Role
  ↓
Mechanic Receives Credentials
  ↓
Mechanic Logs In
```

---

## 5.3 Admin Account

The Admin account is controlled by the workshop.

The Admin can authenticate and manage the workshop according to the administrator permissions defined by the system.

---

# 6. Vehicle Management

A customer may own multiple vehicles.

Every vehicle belongs to one customer.

## 6.1 Vehicle Information

A vehicle may contain:

- Vehicle ID
- Customer ID
- Brand
- Model
- Year
- Vehicle type
- Vehicle category
- License plate
- Racing unit number
- Current mileage
- Current service status

---

## 6.2 Vehicle Categories

PitMate supports both normal and racing vehicles.

Examples:

### Normal Vehicle

```text
Brand: BMW
Model: M4
Year: 2025
License Plate: D XXXX XXX
```

### Racing Vehicle

```text
Brand: BMW
Model: M Hybrid V8
Year: 2025
Unit Number: #15
```

Normal road vehicles use a license plate.

Racing vehicles may use a racing unit number instead.

---

# 7. Booking System

Customers can submit service bookings for their vehicles.

## 7.1 Booking Flow

```text
Customer Login
      ↓
Select Vehicle
      ↓
Create Booking
      ↓
Enter Service Request
      ↓
Select Preferred Date / Time
      ↓
Submit Booking
      ↓
Admin Reviews Booking
      ↓
Approve / Reject
      ↓
Approved Booking
      ↓
Service Order
      ↓
Mechanic Assignment
```

---

## 7.2 Booking Information

A booking may contain:

- Booking ID
- Customer
- Vehicle
- Requested service
- Customer description
- Preferred date
- Preferred time
- Booking status
- Creation date

---

## 7.3 Booking Status

Initial booking states:

- Requested
- Approved
- Rejected
- Cancelled
- Converted to Service

---

# 8. Service Order

A Service Order represents the actual workshop job.

An approved booking can be converted into a Service Order.

A Service Order contains:

- Service Order ID
- Booking ID
- Customer
- Vehicle
- Assigned mechanics
- Service status
- Inspection
- Diagnosis
- Service tasks
- Checklist
- Required parts
- Used parts
- Labor cost
- Parts cost
- Additional charges
- Estimated total
- Final total
- Start date
- Completion date

---

# 9. Service Workflow

The general service lifecycle is:

```text
Requested
    ↓
Approved
    ↓
Scheduled
    ↓
Inspection
    ↓
Diagnosis
    ↓
Waiting for Approval
    ↓
Waiting for Parts
    ↓
In Progress
    ↓
Completion Review
    ↓
Completed
    ↓
Payment
    ↓
Closed
```

Not every service must use every state.

For example, if no additional parts are required:

```text
Diagnosis
    ↓
Waiting for Approval
    ↓
In Progress
```

---

# 10. Inspection

After the vehicle arrives at the workshop, the assigned mechanic performs an inspection.

Inspection information may include:

- Vehicle condition
- Current mileage
- Detected problems
- Visible damage
- Inspection notes
- Inspection date
- Responsible mechanic

The inspection provides the information required for diagnosis.

---

# 11. Diagnosis

Mechanics determine technical problems based on their inspection.

Diagnosis may contain:

- Problem description
- Severity
- Recommended repair
- Required service
- Required spare parts
- Additional notes

The mechanic determines the technical requirements.

The Admin is responsible for approving the resulting work and associated costs where approval is required.

---

# 12. Service Tasks

Service Tasks represent individual pieces of work required for a service order.

Examples:

- Brake inspection
- Oil replacement
- Brake-fluid replacement
- Tire replacement
- Suspension inspection
- Transmission repair
- Engine inspection
- Engine replacement

---

## 12.1 Task Responsibility

The Admin assigns mechanics to a Service Order.

After inspection and diagnosis, the mechanic determines the technical tasks required for the vehicle.

A Service Order may contain multiple mechanics and multiple tasks.

Example:

```text
Service Order #001

Mechanic A
 ├── Brake inspection
 └── Brake replacement

Mechanic B
 ├── Suspension inspection
 └── Suspension repair
```

---

# 13. Service Task Templates

PitMate should support predefined service-task templates to reduce repetitive work.

Examples include:

## Oil Change

- Inspect engine oil
- Drain old oil
- Replace oil filter
- Add new oil
- Check oil level
- Final inspection

## Brake Service

- Inspect brake pads
- Inspect brake discs
- Inspect brake fluid
- Inspect brake lines
- Replace required components
- Perform brake test

## Tire Service

- Inspect tire condition
- Check tire pressure
- Inspect wheels
- Replace tire if necessary
- Balance wheel
- Final inspection

Custom tasks can be created for unusual or specialized repairs.

---

# 14. Checklist

Tasks can contain checklist items.

Checklist items may be:

- Generated from a service template
- Added manually for custom work

Example:

```text
[✓] Remove old brake pad
[✓] Install new brake pad
[ ] Inspect brake disc
[ ] Perform brake test
```

Checklist completion contributes to task completion.

---

# 15. Task Status

Service tasks may use:

- Assigned
- Pending
- In Progress
- Waiting for Parts
- Completed
- Cancelled

Mechanics can update the status of tasks assigned to them.

---

# 16. Multiple Mechanics

One Service Order can contain multiple mechanics.

Mechanics may work:

- Independently on separate tasks
- Together on related tasks

Each task records the mechanic responsible for performing it.

This allows the system to determine:

- Who performed the work
- Which tasks were completed
- Which mechanic participated in the service
- Mechanic compensation

---

# 17. Spare-Part Inventory

The Admin manages workshop spare-part inventory.

## 17.1 Spare-Part Information

A spare part may contain:

- Part ID
- Name
- Category
- Brand
- Compatible vehicle information
- Supplier
- Stock quantity
- Unit price
- Minimum stock level
- Inventory status

---

## 17.2 Part Categories

Examples:

- Brake
- Tire
- Engine
- Transmission
- Suspension
- Fluids
- Filters
- Electrical
- Cooling
- Other

---

# 18. Spare-Part Requests

Mechanics can request spare parts required for their service tasks.

Flow:

```text
Mechanic
   ↓
Identify Required Part
   ↓
Check Inventory
   ↓
Request Part
   ↓
Admin Reviews Request
   ↓
Approve / Reject
```

If the required part does not exist in inventory, the service may enter a waiting state.

---

# 19. Waiting for Parts

A service may be postponed when required parts are unavailable.

Example:

```text
Service
  ↓
Diagnosis
  ↓
Required Part Unavailable
  ↓
Waiting for Parts
  ↓
Part Arrives
  ↓
Admin Verifies Part
  ↓
Service Continues
```

The service should retain its previous progress while waiting.

---

# 20. Cost Estimation

The estimated service cost consists of:

```text
Estimated Total
=
Labor Cost
+
Parts Cost
+
Additional Charges
```

The final total may differ from the original estimate if additional approved work is required.

---

## 20.1 Labor Cost

Labor pricing is controlled by the Admin.

Labor may be determined by:

- Service type
- Task
- Fixed service price
- Custom labor price

---

## 20.2 Parts Cost

Parts cost is determined from the inventory unit price and the quantity used.

---

## 20.3 Additional Charges

Additional charges may include:

- Special work
- Emergency work
- Additional service
- Other approved charges

---

# 21. Mechanic Compensation

The Admin controls mechanic compensation.

A mechanic may receive a percentage of applicable labor revenue.

Example:

```text
Labor Revenue = Rp 1,000,000

Mechanic A = 50%
Mechanic B = 35%
```

The exact compensation rules are controlled by the Admin.

The mechanic can view their own compensation information.

---

# 22. Mechanic Earnings

Mechanic earnings should record:

- Service Order
- Assigned tasks
- Labor amount
- Compensation percentage
- Earned amount
- Payment status

Possible states:

- Pending
- Earned
- Paid

A mechanic can only view their own earnings.

---

# 23. Service Completion

After all required tasks are completed:

```text
All Required Tasks Complete
        ↓
Admin Reviews Service
        ↓
Calculate Final Cost
        ↓
Customer Receives Final Cost
        ↓
Payment
        ↓
Service Closed
```

The Admin confirms the service completion before the Service Order is closed.

---

# 24. Payment

The initial project does not require a real external payment gateway.

Payment is represented through an application-level payment flow.

Possible payment states:

- Unpaid
- Payment Pending
- Paid
- Failed
- Refunded

The actual external payment-provider integration is outside the current scope.

Customers may conceptually:

- Pay in advance
- Pay at the workshop / after service

The exact payment implementation is part of the final-term implementation.

---

# 25. Service History

Completed services are stored as historical records.

## 25.1 Customer History

Customers can view:

- Vehicle
- Service date
- Service performed
- Mechanics involved
- Parts used
- Cost
- Service result

Customers can only view history belonging to their own vehicles.

---

## 25.2 Mechanic History

Mechanics can view services in which they participated.

They can see:

- Vehicle
- Service date
- Tasks performed
- Service status
- Their assigned work
- Their earnings

Mechanics cannot view unrelated mechanics' service history.

---

## 25.3 Admin History

Admins can view all workshop service history.

---

# 26. Service Reminders

PitMate should support maintenance reminders for customer vehicles.

Examples:

- Oil change
- Brake inspection
- Tire service
- Periodic maintenance
- Other scheduled maintenance

A reminder may be based on:

- Date
- Mileage
- Service type

Customers should receive reminders when their vehicle approaches the configured maintenance requirement.

---

# 27. Notifications

PitMate should provide notifications for important workflow events.

## 27.1 Customer Notifications

Examples:

- Booking submitted
- Booking approved
- Booking rejected
- Service started
- Service progress updated
- Additional work required
- Waiting for parts
- Service completed
- Payment required
- Maintenance reminder

## 27.2 Mechanic Notifications

Examples:

- New service assignment
- New task assignment
- Schedule reminder
- Task update
- Spare-part request result
- Service update

## 27.3 Admin Notifications

Examples:

- New booking
- Service requiring approval
- Spare-part request
- Service completion
- Inventory warning

---

# 28. Dashboard Requirements

## 28.1 Admin Dashboard

The Admin dashboard provides a workshop-wide operational overview.

It should display relevant information such as:

- Active services
- Waiting bookings
- Services in progress
- Completed services
- Waiting-for-parts services
- Today's schedule
- Inventory warnings
- Revenue
- Expenses
- Estimated revenue
- Mechanic workload

Service progress may be represented as a percentage.

Example:

```text
BMW M Hybrid V8
Service Progress
████████████░░░░ 75%
```

---

# 29. Mechanic Dashboard

The Mechanic dashboard focuses on the mechanic's own workload.

It should display:

- Today's assignments
- Upcoming assignments
- Active services
- Assigned vehicles
- Task progress
- Waiting-for-parts tasks
- Completed tasks
- Earnings summary

The mechanic should be able to quickly identify:

- What vehicle they are working on
- When it is scheduled
- What tasks they have
- Who else is assigned
- Current status

---

# 30. Customer Dashboard

The Customer dashboard should display:

- Vehicles
- Active services
- Upcoming bookings
- Service status
- Service progress
- Recent service history
- Service reminders
- Estimated/final costs where applicable

Customers can open an active service to view its current progress.

---

# 31. Reports

The Admin should have access to workshop reports.

## 31.1 Service Reports

Reports may include:

- Total services
- Completed services
- Cancelled services
- Active services
- Services by status

## 31.2 Financial Reports

Reports may include:

- Revenue
- Expenses
- Labor cost
- Parts cost
- Additional charges
- Estimated revenue
- Workshop amount

## 31.3 Parts Reports

Reports may include:

- Most-used parts
- Current stock
- Low-stock parts
- Part usage
- Part cost

Examples:

- Brake pad
- Oil filter
- Coolant
- Air filter
- Tire

## 31.4 Customer Reports

Reports may include:

- Total customers
- Returning customers
- Service frequency
- Vehicle count
- Customer service history

---

# 32. Navigation Structure

The application should use role-based navigation.

## 32.1 Public

```text
/
├── landing
├── about
├── login
└── register
```

## 32.2 Customer

```text
/customer
├── dashboard
├── vehicles
├── vehicles/:id
├── bookings
├── bookings/create
├── services
├── services/:id
├── history
├── reminders
├── notifications
└── profile
```

## 32.3 Mechanic

```text
/mechanic
├── dashboard
├── schedule
├── services
├── services/:id
├── tasks
├── tasks/:id
├── inventory
├── earnings
├── history
├── notifications
└── profile
```

## 32.4 Admin

```text
/admin
├── dashboard
├── bookings
├── bookings/:id
├── services
├── services/:id
├── customers
├── customers/:id
├── mechanics
├── mechanics/:id
├── vehicles
├── vehicles/:id
├── inventory
├── inventory/:id
├── parts-requests
├── earnings
├── reports
├── history
├── notifications
└── profile
```

The exact Flutter route implementation is defined in `ARCHITECTURE.md`.

---

# 33. Permission Requirements

Permissions must be enforced by the backend and not only by hiding UI elements.

## 33.1 Customer

A customer can access:

- Their own profile
- Their own vehicles
- Their own bookings
- Their own services
- Their own service history
- Their own notifications
- Their own reminders

A customer cannot access another customer's private data.

---

## 33.2 Mechanic

A mechanic can access:

- Their own profile
- Assigned service orders
- Assigned tasks
- Relevant vehicle information
- Relevant service information
- Relevant inventory information
- Their own earnings
- Their own service history
- Their own notifications

A mechanic cannot access unrelated private mechanic data.

---

## 33.3 Admin

The Admin has workshop-wide operational access.

The Admin can manage:

- Customers
- Mechanics
- Vehicles
- Bookings
- Service orders
- Tasks
- Inventory
- Parts requests
- Costs
- Earnings
- Reports
- Service history

---

# 34. Core Data Entities

The system should contain data corresponding to the following concepts:

```text
Profiles
Customers
Mechanics
Vehicles
Bookings
Service Orders
Service Assignments
Service Tasks
Task Templates
Task Checklists
Spare Parts
Inventory Transactions
Part Requests
Service Parts
Service Costs
Mechanic Earnings
Service History
Notifications
Service Reminders
```

The exact relational database schema is defined separately in `ARCHITECTURE.md` and the database implementation.

---

# 35. Core Relationships

The conceptual relationship is:

```text
Customer
   │
   └── Vehicles
          │
          └── Bookings
                 │
                 └── Service Orders
                        ├── Mechanics
                        ├── Tasks
                        │    └── Checklist
                        ├── Parts
                        ├── Costs
                        └── Earnings
```

Important relationships:

- One customer can own multiple vehicles.
- One vehicle can have multiple bookings.
- A booking may become a service order.
- One service order can have multiple mechanics.
- One service order can have multiple tasks.
- Each task can be assigned to a mechanic.
- One service order can use multiple spare parts.
- A mechanic can participate in multiple service orders.
- A customer can have multiple service reminders.

---

# 36. Business Rules

### BR-001 — Single Workshop

PitMate represents one workshop only.

Multi-branch management is outside the current scope.

### BR-002 — Customer Registration

Customers can create their own accounts.

### BR-003 — Mechanic Registration

Mechanics cannot publicly register.

Mechanic accounts are created by the Admin.

### BR-004 — Vehicle Ownership

Every vehicle belongs to one customer.

### BR-005 — Booking Approval

A customer booking must be reviewed before becoming an active Service Order.

### BR-006 — Mechanic Assignment

The Admin assigns mechanics to Service Orders.

### BR-007 — Multiple Mechanics

A Service Order can contain multiple mechanics.

### BR-008 — Technical Diagnosis

Mechanics determine technical problems and required work through inspection and diagnosis.

### BR-009 — Work Approval

Required work and associated costs must go through the appropriate administrative approval workflow before execution.

### BR-010 — Inventory Control

The Admin controls official workshop inventory.

### BR-011 — Part Requests

Mechanics can request required parts.

The Admin approves or rejects the request.

### BR-012 — Service Completion

A Service Order cannot be closed while required work remains incomplete.

### BR-013 — Mechanic Privacy

Mechanics cannot view another mechanic's private earnings or unrelated work history.

### BR-014 — Customer Privacy

Customers cannot access another customer's private information.

### BR-015 — Cost Calculation

Final service cost consists of applicable labor, parts, and additional charges.

---

# 37. UTS / Midterm Scope

The UTS focuses on the application interface, navigation, database foundation, and initial integration.

## 37.1 Included

- Flutter project foundation
- Application navigation
- Landing page
- About page
- Login UI
- Registration UI
- Role-based screen structure
- Admin dashboard UI
- Mechanic dashboard UI
- Customer dashboard UI
- Vehicle screens
- Booking screens
- Service screens
- Mechanic screens
- Inventory screens
- Reports UI
- Service-history UI
- Notification UI
- Service-reminder UI
- PitMate design system
- Supabase project connection
- Database schema foundation
- Authentication foundation
- Database-backed demonstration data

## 37.2 UTS Data Requirement

The application should already communicate with Supabase.

Permanent hardcoded Dart mock data should not be used as the application's intended data architecture.

Demo/sample records may be inserted into Supabase for UI demonstration.

The goal is to establish the real data architecture early so that the final implementation can extend the existing system rather than replacing mock-data architecture later.

## 37.3 UTS Implementation Limit

The complete business workflow does not need to be finished during UTS.

The following may remain partially implemented:

- Full service processing
- Complete mechanic task workflow
- Complete inventory transactions
- Complete cost calculations
- Payment processing
- Automated notifications
- Complete reporting logic

These are primarily final-term implementation responsibilities.

---

# 38. UAS / Final Scope

The final version should provide a functional implementation of the core workshop workflow.

Expected final functionality:

- Authentication
- Role-based authorization
- Customer registration
- Mechanic account creation
- Vehicle management
- Booking
- Booking approval
- Service-order creation
- Mechanic assignment
- Inspection
- Diagnosis
- Service-task management
- Checklist management
- Spare-part requests
- Inventory management
- Cost estimation
- Final cost
- Payment-state simulation
- Service progress
- Service completion
- Mechanic earnings
- Service history
- Maintenance reminders
- Notifications
- Reports
- Supabase-backed workflows
- Database security

---

# 39. Non-Functional Requirements

## NFR-001 — Usability

The application should be understandable and usable on mobile devices.

## NFR-002 — Visual Consistency

The application must follow the PitMate design system.

## NFR-003 — Performance

The application should avoid unnecessary database queries and unnecessary UI rebuilding.

## NFR-004 — Security

User data must be protected through authentication and Row Level Security.

## NFR-005 — Maintainability

The application should separate:

- UI
- State management
- Data access
- Models
- Routing
- Authentication
- Business logic

## NFR-006 — Scalability

The architecture should allow future features to be added without requiring a complete rewrite.

---

# 40. Design Direction

PitMate uses a motorsport and endurance-racing visual language inspired by modern WEC interfaces.

The visual direction includes:

- Glass-like surfaces
- Transparent panels
- Technical information displays
- Motorsport-inspired typography
- Data-oriented layouts
- Strong information hierarchy
- Status indicators
- Progress indicators
- Racing-inspired visual accents
- Dark interface foundations

The design should prioritize readability over decoration.

The interface should not become overloaded with unnecessary graphics, numbers, or effects.

Detailed visual rules belong in `DESIGN.md`.

---

# 41. Out of Scope

The following are outside the current project scope:

- Multiple workshop branches
- Real external payment gateway integration
- External accounting software
- Automated parts purchasing
- External supplier API integration
- ECU diagnostic hardware
- OBD hardware integration
- Automatic vehicle telemetry
- GPS tracking
- Insurance integration
- Real manufacturer system integration
- Real racing-team fleet APIs
- Online marketplace
- Customer-to-mechanic private messaging
- Full payroll system
- Advanced taxation/accounting system
- Real-time vehicle telemetry
- External appointment synchronization

These features may be considered future extensions but are not required for the current academic project.

---

# 42. Documentation Structure

The project documentation should initially be limited to:

```text
SPEC.md
ARCHITECTURE.md
DESIGN.md
AGENTS.md
README.md
```

## SPEC.md

Defines:

- What the application is
- What users can do
- Business workflows
- Requirements
- Business rules
- Scope
- Permissions
- Navigation
- Functional requirements

## ARCHITECTURE.md

Defines how the application is implemented.

## DESIGN.md

Defines the visual design system.

## AGENTS.md

Defines rules and instructions for AI coding agents.

## README.md

Provides a human-facing project overview and setup guide.

Additional documentation should only be created when it provides information that cannot reasonably belong in these files.

---

# 43. Source of Truth

When implementation decisions conflict, use the following priority:

```text
1. Explicit project requirements
2. SPEC.md
3. ARCHITECTURE.md
4. DESIGN.md
5. AGENTS.md
6. Existing implementation
```

Existing code must not override the documented requirements simply because it already exists.

---

# 44. Definition of Done

A feature is considered complete when:

- Required UI exists
- Navigation works
- Required data model exists
- Supabase integration exists where required
- Permissions are enforced
- Loading states exist
- Error states exist
- Empty states exist
- Basic validation exists
- Relevant tests exist where practical
- Implementation follows the project architecture
- Implementation follows the design system
- Implementation does not violate this specification

---

# 45. Project Development Principle

PitMate should be developed incrementally.

The general development sequence is:

```text
Specification
    ↓
Architecture
    ↓
Design
    ↓
Agent Instructions
    ↓
README
    ↓
Flutter Project Foundation
    ↓
Supabase Foundation
    ↓
Authentication
    ↓
Role-Based Access
    ↓
UTS UI + Database Integration
    ↓
Final-Term Business Workflows
```

The application should not be generated as one massive implementation.

Each major feature should be implemented, tested, and validated before proceeding to the next feature.

---

# 46. Final Product Concept

PitMate is a single-workshop mobile management system that combines conventional automotive workshop management with a motorsport pit-stop concept.

The system connects:

```text
                 PITMATE
                    │
          ┌─────────┼─────────┐
          │         │         │
        ADMIN    MECHANIC  CUSTOMER
          │         │         │
          └─────────┼─────────┘
                    │
             SERVICE WORKFLOW
                    │
       ┌────────────┼────────────┐
       │            │            │
    VEHICLES      TASKS        PARTS
       │            │            │
       └────────────┼────────────┘
                    │
              COST / HISTORY
                    │
                 REPORTS
```

The core objective is to provide a complete, maintainable, database-backed workshop workflow while maintaining a distinctive motorsport-oriented user experience.