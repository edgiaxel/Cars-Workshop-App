# Pitstop Garage
## System Requirements Specification

**Project:** Cars Workshop App  
**Application Name:** Pitstop Garage  
**Document Version:** 1.0  
**Status:** Baseline Specification  
**Last Updated:** 23 September 2026

---

# 1. Introduction

## 1.1 Purpose

This document defines the functional and non-functional requirements for **Pitstop Garage**, a workshop management application designed to manage vehicle servicing, mechanics, service progress, spare-part inventory, service costs, and service history.

The application is designed around a high-performance and motorsport-oriented workshop concept while remaining capable of managing ordinary road vehicles and individual customers.

The system will provide role-specific functionality for:

- Admin / Workshop Owner
- Mechanic
- Customer / Vehicle Owner

The requirements in this document establish the baseline behavior of the application before implementation.

---

## 1.2 System Objective

Pitstop Garage aims to provide a centralized system for managing workshop operations.

The system shall allow the workshop to:

1. Manage customer information.
2. Manage customer vehicles.
3. Create and manage service orders.
4. Assign service orders to mechanics.
5. Divide service orders into individual mechanic tasks.
6. Track service progress.
7. Manage spare-part inventory.
8. Calculate service cost estimates.
9. Record final service costs.
10. Maintain service history.
11. Record service-status changes.
12. Provide role-specific dashboards.
13. Provide operational and historical reports.
14. Restrict data access according to user roles.

---

# 2. System Scope

## 2.1 In Scope

The system includes:

- Authentication
- Role-based authorization
- Customer management
- Mechanic management
- Vehicle management
- Service-order management
- Mechanic assignment
- Service-task management
- Service-progress tracking
- Spare-part inventory management
- Service-order part usage
- Cost estimation
- Final cost recording
- Service history
- Service-status history
- Dashboard information
- Operational reports
- Role-based data access

## 2.2 Out of Scope

The initial version does not include:

- Online payment processing
- Integration with external accounting systems
- Real-time vehicle telemetry
- ECU diagnostics through physical vehicle interfaces
- Parts purchasing from external suppliers
- Automated supplier ordering
- Customer appointment/calendar synchronization
- Insurance claim processing
- Public customer registration without workshop approval

These features may be considered future extensions.

---

# 3. System Actors

The system contains three application roles.

## 3.1 Admin / Workshop Owner

The Admin manages workshop operations and has the broadest operational access.

Primary responsibilities:

- Manage customers
- Manage mechanics
- Manage vehicles
- Manage service orders
- Assign mechanics
- Manage service tasks
- Manage spare parts
- Manage service costs
- View service history
- View operational reports
- Monitor workshop status

## 3.2 Mechanic

The Mechanic performs assigned service work.

Primary responsibilities:

- View assigned service orders
- View assigned vehicles
- View service information
- Perform assigned tasks
- Update task progress
- Record service findings
- Record parts used
- Update relevant service progress
- Complete service work
- View relevant service history

## 3.3 Customer / Vehicle Owner

The Customer represents the owner or operator of a vehicle.

A customer may represent either:

- A company or organization
- An individual

Primary responsibilities:

- View their own profile
- Manage their own vehicles
- Submit service requests
- View their service orders
- View service progress
- View assigned mechanic information where applicable
- View service estimates
- View final service costs
- View service history

---

# 4. Functional Requirements

## FR-01 Authentication

The system shall provide user authentication through Supabase Auth.

The system shall allow authenticated users to:

- Log in
- Maintain an authenticated session
- Log out

The system shall associate an authenticated user with an application profile.

Each profile shall have exactly one application role:

- ADMIN
- MECHANIC
- CUSTOMER

Unauthenticated users shall not have access to protected application data.

---

## FR-02 Role-Based Authorization

The system shall restrict application functionality according to the authenticated user's role.

The system shall enforce authorization at the database level using Supabase Row Level Security (RLS).

The application interface shall also provide role-appropriate navigation and actions.

Database authorization shall remain authoritative even if a user attempts to access restricted functionality directly.

---

## FR-03 Customer Management

The Admin shall be able to:

- Create customers
- View customers
- Update customers
- Deactivate customers where applicable
- View customer-related vehicles
- View customer-related service orders
- View customer service history

The system shall support two customer types:

- COMPANY
- INDIVIDUAL

Company customers may contain:

- Company name
- Contact person
- Contact information
- Address
- Notes

Individual customers may contain:

- Contact person
- Contact information
- Address
- Notes

---

## FR-04 Mechanic Management

The Admin shall be able to:

- Create mechanic records
- View mechanics
- Update mechanic information
- Assign mechanics to service orders
- Deactivate mechanics

Each mechanic shall have:

- Employee code
- Name
- Specialization
- Contact information
- Hire date
- Active/inactive status

Inactive mechanics shall not be assigned to new service work.

---

## FR-05 Vehicle Management

The system shall maintain vehicle records associated with customers.

A vehicle shall contain:

- Customer
- Brand
- Model
- Year
- Vehicle type
- Registration number where applicable
- Unit number where applicable
- Mileage
- Status
- Notes

The system shall support both ordinary road vehicles and motorsport vehicles.

Supported vehicle types include:

- PASSENGER
- SUV
- TRUCK
- VAN
- MOTORSPORT
- OTHER

A registration number shall be optional because some motorsport vehicles may not have road registration.

A unit number shall be optional and shall represent a workshop, fleet, or racing identifier rather than a road license plate.

---

## FR-06 Service Order Management

The system shall allow service orders to be created for a specific customer and vehicle.

A service order shall contain:

- Customer
- Vehicle
- Assigned mechanic where applicable
- Service type
- Description
- Priority
- Status
- Estimated labor cost
- Estimated parts cost
- Estimated additional cost
- Estimated total
- Final labor cost
- Final parts cost
- Final additional cost
- Final total
- Request timestamp
- Start timestamp
- Completion timestamp

Customers shall be able to submit service requests for their own vehicles.

Admins shall be able to manage service orders.

Mechanics shall be able to access service orders assigned to them.

---

## FR-07 Mechanic Assignment

The Admin shall be able to assign a mechanic to a service order.

A service order may initially have no assigned mechanic.

The system shall prevent inactive mechanics from being assigned to new service work.

The assigned mechanic shall be able to view and work on the associated service order.

---

## FR-08 Service Task Management

A service order shall be capable of containing multiple service tasks.

Each task shall contain:

- Task ID
- Service order
- Assigned mechanic where applicable
- Title
- Description
- Status
- Completion timestamp

Task statuses shall be:

- PENDING
- IN_PROGRESS
- COMPLETED

The Admin shall be able to create, assign, update, and manage tasks.

Mechanics shall be able to update tasks assigned to them.

Customers shall be able to view task progress for their own service orders.

---

## FR-09 Service Progress Tracking

The system shall track service-order progress using a defined service-order state machine.

The primary service workflow shall be:

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

A service order may also enter:

```text
CANCELLED
```

The exact permitted transitions and role permissions shall be defined in `docs/state-machine.md`.

The system shall record service-status changes in `service_order_status_history`.

---

## FR-10 Task-Based Progress

The system shall support progress tracking based on service tasks.

Task completion progress shall be calculated from the number of completed tasks relative to the total number of tasks.

Example:

```text
3 / 5 tasks completed
= 60% progress
```

The application may display this information using a percentage or progress indicator.

The progress value should be derived from task records rather than stored as an independent service-order field.

---

## FR-11 Spare-Part Inventory Management

The Admin shall be able to:

- Add parts
- View parts
- Update parts
- Deactivate parts
- Monitor stock quantities
- Configure minimum stock levels
- View current unit prices

Each part shall have:

- Part number
- Name
- Category
- Brand where applicable
- Description where applicable
- Stock quantity
- Minimum stock
- Unit price
- Supplier where applicable
- Status

Part numbers shall be unique.

---

## FR-12 Service-Order Part Usage

The system shall associate parts used during a service with the relevant service order.

Each service-order part record shall contain:

- Service order
- Part
- Quantity
- Unit-price snapshot

The system shall preserve the unit price at the time the part is recorded for the service.

This prevents future part-price changes from altering historical service costs.

---

## FR-13 Inventory Stock Processing

When parts are consumed for a service order, the system shall reduce the corresponding inventory quantity.

For example:

```text
Current stock
    ↓
Brake Pad Set = 12
    ↓
1 set used
    ↓
New stock
    ↓
Brake Pad Set = 11
```

The system shall prevent stock quantity from becoming negative.

The exact timing and transaction behavior for stock deduction shall be defined in the business rules.

---

## FR-14 Low-Stock Detection

The system shall identify parts whose stock quantity is less than or equal to their configured minimum stock.

The condition shall be:

```text
stock_quantity <= minimum_stock
```

Parts meeting this condition shall be considered low stock.

The Admin dashboard and inventory interface may display low-stock warnings.

---

## FR-15 Service Cost Estimation

The system shall support service cost estimation.

Estimated service cost shall consist of:

```text
Estimated Total
=
Estimated Labor
+ Estimated Parts
+ Estimated Additional Charges
```

Estimated parts cost shall be calculated from the parts associated with the service order.

The system shall maintain estimated values separately from final service costs.

---

## FR-16 Final Service Cost

The system shall record final service costs after service work is completed.

Final service cost shall consist of:

```text
Final Total
=
Final Labor
+ Final Parts
+ Final Additional Charges
```

The system shall preserve the final cost associated with the completed service.

Historical service costs shall not change when current part prices change.

---

## FR-17 Service History

The system shall maintain permanent service history for completed services.

A completed service order shall be associated with a service record containing:

- Service order
- Vehicle
- Mechanic where applicable
- Summary
- Diagnosis where applicable
- Work performed
- Recommendations where applicable
- Final cost
- Completion date

Customers shall be able to view service history belonging to their vehicles.

Admins shall be able to view workshop service history.

Mechanics shall be able to view service history relevant to their work.

---

## FR-18 Service Status History

The system shall record each service-order status change.

Each status-history record shall contain:

- Service order
- Status
- User responsible for the change
- Notes where applicable
- Timestamp

This information shall provide an auditable timeline of service progress.

---

## FR-19 Dashboard

The system shall provide role-specific dashboard information.

### Admin Dashboard

The Admin dashboard shall provide information such as:

- Total active service orders
- Orders by status
- High-priority or urgent orders
- Low-stock parts
- Active mechanics
- Recent service activity
- Revenue or service-cost summaries where applicable

### Mechanic Dashboard

The Mechanic dashboard shall provide:

- Assigned service orders
- Assigned tasks
- Task completion progress
- Priority information
- Current service statuses

### Customer Dashboard

The Customer dashboard shall provide:

- Customer vehicles
- Active service orders
- Current service progress
- Recent service history
- Estimated/final costs where applicable

---

## FR-20 Reporting

The system shall provide operational and historical reports.

Reports may include:

- Service orders by status
- Service orders by priority
- Service history
- Vehicle service history
- Parts inventory
- Low-stock parts
- Service costs
- Completed services
- Mechanic workload

Reports shall use data stored in the system rather than manually entered summary values.

---

# 5. Non-Functional Requirements

## NFR-01 Security

The system shall use Supabase Authentication for user authentication.

The system shall use Row Level Security to enforce database-level authorization.

Users shall only access data permitted by their role and ownership/assignment relationships.

Sensitive authentication credentials shall not be stored in application source code.

The Supabase service-role/secret key shall never be included in the Flutter client application.

---

## NFR-02 Data Integrity

The database shall enforce:

- Primary-key constraints
- Foreign-key constraints
- Unique constraints
- Required fields
- Appropriate default values
- Numeric range constraints
- Valid status values
- Cost consistency constraints

Historical records shall not depend on mutable current inventory prices.

Important historical relationships shall not be casually deleted.

---

## NFR-03 Usability

The application shall provide interfaces appropriate to each user role.

Frequently used information shall be accessible through dashboards and structured navigation.

Service progress shall be visually understandable.

Important conditions such as urgent service orders and low-stock parts shall be clearly identifiable.

---

## NFR-04 Performance

The application should retrieve only the data required for the current screen.

Database queries should use appropriate filtering and indexed relationships.

The application should avoid unnecessarily retrieving complete tables when only a subset of records is required.

---

## NFR-05 Maintainability

The application shall use a modular architecture.

Database schema changes shall be managed through Supabase migrations.

Application functionality shall be organized by feature and responsibility.

Business rules should not be duplicated unnecessarily between the Flutter application and database.

---

## NFR-06 Scalability

The database structure shall support additional:

- Customers
- Vehicles
- Mechanics
- Service orders
- Tasks
- Parts
- Service records

without requiring structural changes for normal growth.

The vehicle model shall support both road vehicles and motorsport vehicles.

---

# 6. Core Business Rules

The following rules establish the baseline business behavior.

## BR-01 Customer Ownership

A customer may access only vehicles and service information belonging to that customer.

## BR-02 Mechanic Assignment

A mechanic may work on service orders assigned to that mechanic.

## BR-03 Service Order Ownership

Every service order shall belong to exactly one customer and one vehicle.

## BR-04 Vehicle Ownership

Every vehicle shall belong to exactly one customer.

## BR-05 Service Tasks

A service order may contain multiple tasks.

## BR-06 Task Progress

Service-order task progress shall be derived from task completion.

## BR-07 Inventory

Part quantities shall not become negative.

## BR-08 Low Stock

A part is considered low stock when:

```text
stock_quantity <= minimum_stock
```

## BR-09 Price Snapshot

The unit price stored in `service_order_parts` represents the price applicable when the part is used for that service.

## BR-10 Estimated Total

```text
estimated_total
=
estimated_labor_cost
+
estimated_parts_cost
+
estimated_additional_cost
```

## BR-11 Final Total

```text
final_total
=
final_labor_cost
+
final_parts_cost
+
final_additional_cost
```

## BR-12 Service Record

A completed service order shall have one associated service record.

## BR-13 Status History

Each service-order status transition shall create a status-history record.

## BR-14 Historical Data

Important completed service information shall remain available for historical reporting.

Detailed rules are defined in:

```text
docs/business-rules.md
```

---

# 7. Service-Order Workflow

The service-order lifecycle shall use the following statuses:

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

The order may also be:

```text
CANCELLED
```

Quality inspection may return a service order to `IN_PROGRESS` when additional work is required.

The exact transition rules, responsible roles, and permitted backward transitions shall be defined separately in:

```text
docs/state-machine.md
```

---

# 8. Role Permission Summary

| Function | Admin | Mechanic | Customer |
|---|---|---|---|
| View own profile | Yes | Yes | Yes |
| Manage customers | Yes | No | No |
| Manage mechanics | Yes | No | No |
| Manage own mechanic information | Yes | Limited | No |
| Manage own vehicles | Yes | No | Yes |
| View assigned vehicles | Yes | Yes | Own only |
| Create service request | Yes | No | Yes |
| Manage service orders | Yes | Assigned | Own |
| Assign mechanic | Yes | No | No |
| Manage service tasks | Yes | Assigned | View |
| Update task status | Yes | Assigned | No |
| Manage inventory | Yes | No | No |
| View relevant parts | Yes | Yes | No |
| Record service parts | Yes | Assigned | No |
| View service history | Yes | Relevant | Own |
| View status history | Yes | Relevant | Own |
| View reports | Yes | Limited | Own information |

The detailed permission model is defined in:

```text
docs/role-permissions.md
```

---

# 9. Data Requirements

The system shall use the following primary application entities:

```text
profiles
customers
mechanics
vehicles
service_orders
service_tasks
parts
service_order_parts
service_records
service_order_status_history
```

The database relationships and constraints are defined in:

```text
docs/database-schema.md
```

The database implementation is managed through Supabase migrations.

---

# 10. Development and Deployment Requirements

The application shall use the following general architecture:

```text
Flutter Application
        ↓
Supabase Flutter SDK
        ↓
Supabase
 ├── Authentication
 ├── PostgreSQL
 ├── Data API
 └── Row Level Security
```

Database schema changes shall be stored as migration files under:

```text
supabase/migrations/
```

Demo/seed data shall be managed through:

```text
supabase/seed.sql
```

The Flutter client shall use a publishable/anonymous client key as appropriate for the Supabase configuration.

Privileged Supabase keys shall not be included in the client application.

---

# 11. UTS / UAS Implementation Strategy

## 11.1 UTS

The UTS version shall prioritize:

- Interface implementation
- Navigation
- Dashboard presentation
- Role-specific pages
- Demonstration of realistic data
- Supabase database connectivity
- Reading actual database records
- Visual service-progress representation
- Inventory presentation
- Service history presentation

Buttons and forms may initially be implemented as interface elements without complete business processing where required by the UTS scope.

The UTS application should nevertheless read demonstration data from Supabase rather than relying entirely on hardcoded UI data.

## 11.2 UAS

The UAS version shall extend the UTS implementation with:

- Functional forms
- Data creation
- Data updates
- Service-order processing
- Mechanic assignment
- Task updates
- Inventory processing
- Cost calculations
- Status transitions
- Service-history generation
- Reporting functionality
- Complete role-based workflows

The UAS implementation shall build upon the existing UTS architecture rather than replacing the application with an unrelated implementation.

---

# 12. System Constraints

The system shall:

1. Use Flutter for the application client.
2. Use Supabase as the backend platform.
3. Use PostgreSQL for persistent application data.
4. Use Supabase Auth for authentication.
5. Use Row Level Security for database authorization.
6. Support three application roles:
   - ADMIN
   - MECHANIC
   - CUSTOMER
7. Support both motorsport and normal road vehicles.
8. Preserve service history.
9. Preserve historical service-order pricing.
10. Maintain referential integrity between related records.
11. Avoid requiring human participants for normal system evaluation where possible.
12. Use realistic seeded data for demonstration and development.

---

# 13. Related Project Documents

| Document | Purpose |
|---|---|
| `docs/database-schema.md` | Database entities, columns, relationships, constraints |
| `docs/state-machine.md` | Service-order statuses and permitted transitions |
| `docs/task-system.md` | Mechanic task behavior and progress calculation |
| `docs/business-rules.md` | Inventory, pricing, service, and operational rules |
| `docs/role-permissions.md` | Detailed role/action authorization |
| `docs/route-architecture.md` | Application pages, routes, actions, and data |
| `docs/features/authentication.md` | Authentication feature |
| `docs/features/service-orders.md` | Service-order feature |
| `docs/features/inventory.md` | Inventory feature |
| `docs/features/service-progress.md` | Service-progress feature |
| `docs/features/reporting.md` | Reporting feature |

---

# 14. Requirement Baseline

This document represents the baseline system requirements for the current version of Pitstop Garage.

Changes to major system behavior, roles, database entities, service workflow, inventory behavior, or authorization rules should be reflected in the relevant project documentation before implementation.

Detailed implementation decisions may evolve during development, but they should remain consistent with the requirements established here unless the requirements are explicitly revised.