# Pitstop Garage — Cars Workshop App

A Flutter-based **car workshop management application** built for the Mobile Application Programming / Software Engineering project.

**Application:** Pitstop Garage
**Project:** Cars Workshop App
**Version:** 1.0
**Status:** In Development

---

## Overview

Pitstop Garage is a workshop management application designed to manage vehicle servicing operations from service requests through completion.

The application supports three primary roles:

- **Admin** — manages workshop operations, customers, mechanics, vehicles, service orders, inventory, and reports.
- **Mechanic** — performs assigned service work and manages assigned tasks.
- **Customer** — manages owned vehicles, requests services, and monitors service progress and history.

The system is designed around a structured service workflow rather than treating a service order as a simple CRUD record.

```text
Customer / Vehicle
        │
        ▼
  Service Request
        │
        ▼
   Service Order
        │
        ├── Tasks
        ├── Assigned Mechanic
        ├── Parts Used
        ├── Cost Estimate
        └── Progress
        │
        ▼
   Quality Check
        │
        ▼
     Completed
        │
        ▼
  Service History
```

---

# Features

## Authentication & Roles

- Supabase Authentication
- Role-based access
- Admin, Mechanic, and Customer roles
- Protected application routes
- Profile management

## Customer Management

- Customer profiles
- Individual and company customers
- Customer contact information
- Customer vehicle ownership

## Vehicle Management

- Vehicle records
- Vehicle types
- Mileage tracking
- Registration numbers
- Internal unit numbers
- Vehicle service status
- Service history

## Service Orders

- Service requests
- Service-order management
- Priority levels
- Mechanic assignment
- Service status workflow
- Estimated costs
- Final costs
- Service status history

## Task Management

Service orders are divided into individual work tasks.

```text
PENDING
   ↓
IN_PROGRESS
   ↓
COMPLETED
```

Tasks provide the basis for service-progress calculation and quality-check readiness.

## Inventory

- Spare-part management
- Part numbers
- Stock quantities
- Minimum-stock levels
- Low-stock detection
- Part pricing
- Service-order part usage
- Historical unit-price snapshots

## Service History

- Completed service records
- Diagnosis
- Work performed
- Recommendations
- Final service cost
- Vehicle service history

## Dashboard & Reporting

Role-specific dashboards provide relevant operational information.

Admin:

- workshop statistics;
- active services;
- mechanic workload;
- inventory alerts;
- service reports.

Mechanic:

- assigned services;
- assigned tasks;
- active workload;
- relevant vehicle information.

Customer:

- owned vehicles;
- active services;
- service progress;
- service history;
- service costs.

---

# Technology Stack

## Frontend

- **Flutter**
- **Dart**

## Backend

- **Supabase**
- **PostgreSQL**
- **Supabase Auth**
- **Row Level Security (RLS)**

## Development Tools

- Git
- GitHub
- Supabase CLI

Repository:

`edgiaxel/Cars-Workshop-App`

---

# Architecture

The application follows a layered architecture:

```text
┌─────────────────────────────┐
│        Flutter UI           │
├─────────────────────────────┤
│      Feature / State        │
├─────────────────────────────┤
│    Repository / Data Layer  │
├─────────────────────────────┤
│       Supabase Client       │
├─────────────────────────────┤
│ Supabase / PostgreSQL / RLS │
└─────────────────────────────┘
```

Application routing is role-aware:

```text
                    Authentication
                          │
                          ▼
                    User Profile
                          │
                     Determine Role
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
        ADMIN          MECHANIC        CUSTOMER
          │               │               │
          ▼               ▼               ▼
   Admin Dashboard   Mechanic Dashboard  Customer Dashboard
```

Detailed architecture is documented in:

- [`ARCHITECTURE.md`](ARCHITECTURE.md)
- [`DESIGN.md`](DESIGN.md)

---

# Service Order Workflow

Service orders follow a controlled state machine.

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

Cancellation is available from applicable active states.

A quality check may return a service order to `IN_PROGRESS` when corrective work is required.

The complete transition rules are documented in:

[`docs/state-machine.md`](docs/state-machine.md)

---

# Roles

## Admin

Workshop-wide management access.

```text
Customers
Mechanics
Vehicles
Service Orders
Tasks
Inventory
Reports
Service History
```

## Mechanic

Operational access to assigned workshop work.

```text
Assigned Service Orders
Assigned Tasks
Relevant Vehicles
Relevant Parts
Work Progress
Service Information
```

## Customer

Access to owned vehicles and service information.

```text
Own Profile
Own Vehicles
Own Service Orders
Service Progress
Service Costs
Service History
```

Detailed authorization rules are documented in:

[`docs/role-permissions.md`](docs/role-permissions.md)

---

# Database

The database is PostgreSQL managed through Supabase.

Core entities:

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

The database schema is version-controlled through Supabase migrations.

Migration files are located in:

```text
supabase/migrations/
```

Seed data is located in:

```text
supabase/seed.sql
```

Detailed database documentation:

[`docs/database-schema.md`](docs/database-schema.md)

---

# Local Development

## Requirements

Install:

- Flutter SDK
- Dart SDK
- Git
- Supabase CLI

Docker is **not required** for normal remote Supabase development or migration deployment.

Docker is only required when running a complete local Supabase environment.

---

## Clone the Repository

```bash
git clone https://github.com/edgiaxel/Cars-Workshop-App.git
cd Cars-Workshop-App
```

---

## Install Flutter Dependencies

```bash
flutter pub get
```

---

## Supabase Setup

Initialize Supabase locally if required:

```bash
supabase init
```

Link the local project to the remote Supabase project:

```bash
supabase link --project-ref <PROJECT_REF>
```

Do not commit Supabase secrets or service-role credentials to the repository.

---

## Database Migrations

Apply migrations to the linked Supabase project:

```bash
supabase db push
```

If migrations exist out of chronological order and the CLI requires previously skipped migrations to be included:

```bash
supabase db push --include-all
```

Check migration status:

```bash
supabase migration list
```

---

## Seed Data

Demo authentication users must exist in Supabase Auth before running the public-table seed data.

After the required Auth users have been created:

```bash
supabase db push --include-seed
```

The seed populates demo records for:

- profiles;
- customers;
- mechanics;
- vehicles;
- parts;
- service orders;
- tasks;
- service-order parts;
- service records;
- status history.

Demo credentials shall **not** be committed to the repository.

---

# Project Structure

The repository is organized approximately as follows:

```text
cars_workshop/
│
├── lib/
│   ├── app/
│   ├── features/
│   ├── core/
│   └── main.dart
│
├── docs/
│   ├── requirements.md
│   ├── state-machine.md
│   ├── task-system.md
│   ├── business-rules.md
│   ├── role-permissions.md
│   ├── route-architecture.md
│   ├── database-schema.md
│   └── features/
│
├── supabase/
│   ├── migrations/
│   └── seed.sql
│
├── test/
│
├── README.md
├── AGENTS.md
├── ARCHITECTURE.md
└── DESIGN.md
```

The exact Flutter feature structure may evolve as implementation progresses.

---

# Documentation

The repository documentation is organized into several layers.

## Core Requirements

[`docs/requirements.md`](docs/requirements.md)

Defines:

- project scope;
- functional requirements;
- non-functional requirements;
- roles;
- business objectives;
- UTS/UAS scope.

---

## System Workflow

[`docs/state-machine.md`](docs/state-machine.md)

Defines the service-order lifecycle and valid state transitions.

[`docs/task-system.md`](docs/task-system.md)

Defines task lifecycle, assignment, task progress, and quality-check prerequisites.

---

## Business Logic

[`docs/business-rules.md`](docs/business-rules.md)

Defines the operational rules governing:

- customers;
- vehicles;
- service orders;
- tasks;
- inventory;
- costs;
- service history;
- data integrity.

---

## Authorization

[`docs/role-permissions.md`](docs/role-permissions.md)

Defines access boundaries for:

- Admin;
- Mechanic;
- Customer.

---

## Navigation

[`docs/route-architecture.md`](docs/route-architecture.md)

Defines:

- routes;
- role-specific navigation;
- route guards;
- protected resources;
- route parameters;
- navigation behavior.

---

## Technical Architecture

[`ARCHITECTURE.md`](ARCHITECTURE.md)

Defines the application's technical structure and implementation architecture.

[`DESIGN.md`](DESIGN.md)

Defines the visual and UI/UX design system.

---

# Documentation Authority

When implementing a feature, the following order should be used to understand the system:

```text
requirements.md
      ↓
state-machine.md
      ↓
task-system.md
      ↓
business-rules.md
      ↓
role-permissions.md
      ↓
route-architecture.md
      ↓
ARCHITECTURE.md
      ↓
DESIGN.md
      ↓
Feature Documentation
```

More specific technical documentation may describe implementation details, but it shall not silently contradict the core requirements and business rules.

If a requirement changes, the relevant specification shall be updated before changing implementation behavior.

---

# Development Principles

## Backend Is Authoritative

Security and important business rules shall not rely solely on Flutter UI logic.

Supabase/PostgreSQL shall enforce:

- authentication boundaries;
- row-level access;
- ownership;
- assignment restrictions;
- data integrity;
- important workflow constraints.

---

## Preserve Historical Data

Historical workshop information should not be casually deleted.

Entities such as customers, mechanics, vehicles, and parts use inactive states where appropriate.

Completed service records and historical service information should remain available.

---

## Controlled State Changes

Service-order and task statuses shall be changed through defined workflow actions.

The application shall not expose arbitrary status selection when a controlled transition is required.

---

## Role-Aware UI

The UI should only present actions relevant to the current role and current workflow state.

However, UI restrictions are not a substitute for backend authorization.

---

## Keep Business Logic Centralized

Business rules should not be duplicated across unrelated widgets.

Reusable business operations should have a clear implementation location defined by the architecture.

---

# Current Development Status

The project is currently in the **foundation/specification and database phase**.

Completed:

- [x] Project initialized
- [x] Flutter project established
- [x] Supabase project created
- [x] Supabase CLI configured
- [x] Remote project linked
- [x] Initial database schema defined
- [x] Initial migration created
- [x] Database migration deployed
- [x] RLS migration created
- [x] RLS migration deployed
- [x] Authentication demo users created
- [x] Seed data prepared
- [x] Core system requirements documented
- [x] Service state machine documented
- [x] Task system documented
- [x] Business rules documented
- [x] Role permissions documented
- [x] Route architecture documented

In progress:

- [ ] Repository documentation reconciliation
- [ ] Flutter architecture implementation
- [ ] Authentication implementation
- [ ] Role-based routing
- [ ] Dashboard implementation
- [ ] Service-order implementation
- [ ] Task implementation
- [ ] Inventory implementation
- [ ] Reporting implementation
- [ ] UTS prototype completion
- [ ] UAS full functionality

---

# Project Goals

The application should demonstrate practical implementation of:

- mobile application development;
- Flutter and Dart;
- authentication;
- role-based authorization;
- database design;
- CRUD operations;
- relational data;
- service workflows;
- task management;
- inventory management;
- cost calculation;
- reporting;
- secure backend integration.

The final system should function as a coherent workshop-management application rather than a collection of unrelated CRUD screens.

---

# License

This project is developed for academic purposes.

Unless otherwise specified, project source code and assets are intended for the Cars Workshop App academic project.
