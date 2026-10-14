# PitMate — AI Agent Development Guidelines

## 1. Purpose

This document defines how AI coding agents must work on the PitMate project.

PitMate is developed with AI-assisted programming. Agents are expected to assist with implementation while preserving the project's existing architecture, requirements, design system, security model, and development decisions.

The agent is not authorized to redesign the project simply because it has an alternative preference.

The project's source-of-truth documents are:

```text
SPEC.md
ARCHITECTURE.md
DESIGN.md
AGENTS.md
```

These documents must be treated as a coordinated specification.

---

# 2. Core Agent Principle

The agent's primary responsibility is:

> **Implement the requested change with the smallest reasonable amount of disruption to the existing project.**

The agent should prefer:

- Existing architecture over new architecture
- Existing components over duplicate components
- Existing dependencies over new dependencies
- Existing design tokens over arbitrary styling
- Incremental changes over large rewrites
- Explicit requirements over assumptions
- Simple solutions over unnecessary abstractions

The agent must not optimize the project into a fundamentally different architecture without explicit approval.

---

# 3. Mandatory Context Before Implementation

Before making implementation changes, the agent must inspect the relevant project documentation.

At minimum:

```text
SPEC.md
ARCHITECTURE.md
DESIGN.md
AGENTS.md
```

The agent should also inspect:

```text
README.md
```

and relevant source files before modifying them.

If the requested task concerns a specific feature, the agent should inspect that feature's existing implementation before making changes.

---

# 4. Requirements Hierarchy

When requirements conflict, use the following priority:

1. Explicit user instruction
2. `SPEC.md`
3. `ARCHITECTURE.md`
4. `DESIGN.md`
5. `AGENTS.md`
6. Existing implementation
7. Agent preference

The agent must not silently override higher-priority requirements with lower-priority preferences.

If a conflict cannot reasonably be resolved, stop and explain the conflict rather than silently choosing an architecture.

---

# 5. Inspect Before Editing

Before changing code, the agent must understand the relevant existing implementation.

The agent should determine:

- Where the feature currently lives
- Which files are involved
- Which components are already reusable
- Which providers/state objects already exist
- Which repositories/data sources already exist
- Which routes already exist
- Which database structures are involved
- Whether similar functionality already exists elsewhere

The agent should avoid creating duplicate implementations.

---

# 6. Do Not Rewrite Unnecessarily

Do not rewrite entire files when a targeted change is sufficient.

Avoid:

- Rebuilding an entire screen to change one component
- Replacing an existing state-management pattern without reason
- Reorganizing the entire project for a small feature
- Renaming unrelated files
- Refactoring unrelated code
- Replacing working dependencies
- Reformatting unrelated source files

Changes should remain scoped to the requested task.

---

# 7. Feature Development Workflow

New features should generally follow this sequence:

```text
Requirement
    ↓
Existing implementation inspection
    ↓
Data model / database requirements
    ↓
Repository / datasource
    ↓
State management
    ↓
Screen / page
    ↓
Reusable components
    ↓
Loading / Empty / Error / Success states
    ↓
Validation
    ↓
Testing
    ↓
Review
```

Not every feature requires every step, but the agent should explicitly consider each one.

---

# 8. Flutter Architecture Rules

PitMate uses a feature-oriented Flutter architecture.

The agent should respect the existing structure:

```text
lib/
├── main.dart
├── app/
├── core/
├── data/
├── features/
└── shared/
```

Feature-specific code should remain within its relevant feature directory whenever practical.

Shared functionality should only be moved into `core/` or `shared/` when it is genuinely shared.

Do not place feature-specific logic into global folders merely for convenience.

---

# 9. State Management

Riverpod is the project's state-management approach.

The agent should:

- Reuse existing providers where applicable.
- Keep state close to the feature that owns it.
- Avoid unnecessary global state.
- Avoid duplicating server state in unrelated providers.
- Keep UI widgets focused on presentation and interaction.

Do not introduce another state-management framework without explicit approval.

---

# 10. Data Access

UI code should not directly implement backend business logic.

The preferred flow is:

```text
UI
 ↓
Provider / State
 ↓
Repository
 ↓
Datasource
 ↓
Supabase
```

Repositories should hide backend implementation details from UI code.

Avoid putting large Supabase queries directly inside widgets.

---

# 11. Supabase Rules

Supabase is the backend platform for PitMate.

The agent may use:

- Supabase Auth
- PostgreSQL
- Row Level Security
- Storage where required
- Realtime where required

The agent must follow the project's database architecture.

Never expose:

- Supabase service-role keys
- Private credentials
- Server-only secrets

inside the Flutter client.

Client-side configuration must use only values appropriate for a public client application.

---

# 12. Authentication and Authorization

PitMate has three primary roles:

```text
admin
mechanic
customer
```

Authentication and authorization are separate concepts.

Authentication determines:

> Who is the user?

Authorization determines:

> What is the user allowed to do?

The UI may hide features that are irrelevant to a role, but UI hiding is not a security mechanism.

Database access must ultimately be protected through appropriate Row Level Security policies.

---

# 13. Security Rules

The agent must assume that client-side code can be inspected or manipulated by users.

Therefore:

- Never trust role information supplied only by the UI.
- Never rely solely on hidden buttons for authorization.
- Never place privileged credentials in the Flutter application.
- Never bypass RLS simply to make a feature work.
- Never disable security policies as a shortcut during implementation.

If a feature cannot be implemented correctly under the current security model, the agent should report the issue rather than weakening the security model.

---

# 14. Database Changes

Database changes should be deliberate and traceable.

When modifying the database, the agent should consider:

- Tables
- Relationships
- Primary keys
- Foreign keys
- Constraints
- Indexes
- RLS policies
- Insert/update/delete permissions
- Existing data compatibility

Database schema changes should be represented through migration files where the project workflow supports them.

Do not make undocumented destructive database changes.

---

# 15. Business Logic

Business rules must not be scattered randomly across UI widgets.

Examples of business logic include:

- Service status transitions
- Cost calculations
- Mechanic assignment rules
- Inventory quantity changes
- Part usage
- Mechanic earnings
- Booking validation
- Role-based access
- Service completion conditions

Business logic should be placed in an appropriate layer so that it can be reused and tested.

---

# 16. Service Status Rules

Service statuses are part of the application's domain model.

The current workflow is:

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

Not every service must necessarily pass through every state.

The agent must not casually invent new statuses.

If a new status appears necessary, the agent should identify why it is required before introducing it.

---

# 17. Design System Rules

All UI implementation must follow `DESIGN.md`.

Use centralized:

- Colors
- Typography
- Spacing
- Border radius
- Elevation
- Status colors
- Component styles

Do not introduce arbitrary colors such as:

```dart
Colors.red
Colors.blue
Colors.green
```

when an appropriate PitMate design token already exists.

Likewise, avoid arbitrary font sizes, spacing values, and component styling when an existing token is available.

---

# 18. Motorsport Aesthetic Rules

PitMate should feel motorsport-inspired.

However:

> **Do not turn every screen into a racing poster.**

Use motorsport inspiration through:

- Technical typography
- Information hierarchy
- Status indicators
- Progress visualization
- Compact data layouts
- Strong contrast
- Subtle geometric styling

Avoid excessive:

- Checkered flags
- Tire graphics
- Racing stripes
- Neon effects
- Decorative telemetry
- Unnecessary animations
- Automotive imagery

The application remains a workshop management system.

---

# 19. Responsive UI

PitMate is primarily a mobile application.

The agent must consider:

- Small phone screens
- Large phone screens
- Different aspect ratios
- Keyboard appearance
- Safe areas
- Long text
- Dynamic lists
- Touch targets

Do not assume a fixed screen size.

Do not create layouts that depend on hardcoded screen dimensions unless necessary.

---

# 20. UI State Requirements

Screens that retrieve asynchronous data should normally account for:

```text
Loading
Success
Empty
Error
```

For example:

```text
Loading
   ↓
Success ──→ Empty
   │
   └──────→ Error
```

The agent should not leave a screen blank while data is loading.

Empty data is not automatically an error.

Errors should provide a useful recovery action where practical.

---

# 21. Forms and Validation

Forms should validate user input before submitting when appropriate.

Validation should:

- Be understandable
- Identify the problematic field
- Avoid unnecessary technical terminology
- Prevent obviously invalid data
- Provide actionable feedback

Do not rely entirely on backend errors to provide user-friendly validation.

Backend constraints must still exist where appropriate.

---

# 22. Error Handling

Errors should be handled deliberately.

The agent should distinguish between:

- Validation errors
- Authentication errors
- Authorization errors
- Network errors
- Database errors
- Unexpected application errors

Do not expose raw stack traces or sensitive backend information to normal users.

Developer-facing logs may contain additional technical information when appropriate.

---

# 23. Navigation Rules

Navigation should use the application's centralized routing architecture.

Do not introduce random navigation mechanisms throughout individual screens.

Role-based route access should be handled consistently.

If a user attempts to access a route they are not authorized to use, the application should respond predictably.

---

# 24. Reusable Components

Before creating a new component, check whether an existing component can be reused.

Create reusable components when:

- The pattern appears multiple times.
- The component represents an important domain concept.
- Centralized styling is beneficial.
- Reuse will meaningfully reduce duplication.

Avoid creating abstractions for one-off elements merely to make the code look architectural.

---

# 25. Dependency Rules

Do not add a package simply because it provides a small convenience.

Before adding a dependency, consider:

1. Does Flutter already provide this capability?
2. Is an existing project dependency capable of handling it?
3. Is the package actively maintained?
4. Does it introduce unnecessary complexity?
5. Is the package actually required?

New dependencies should be justified by a real project requirement.

---

# 26. Code Quality

Generated code must be:

- Readable
- Consistent with existing conventions
- Null-safe
- Reasonably modular
- Testable
- Free of unnecessary duplication

Avoid clever code when straightforward code is easier to understand.

Prefer maintainability over code golf.

---

# 27. Comments

Comments should explain **why**, not simply restate **what** the code does.

Good:

```text
// Keep this query separate because the customer
// must only receive their own service history.
```

Bad:

```text
// Get service history.
```

Avoid excessive comments.

The code itself should normally be understandable.

---

# 28. Testing

The agent should add or update tests when changes affect important behavior.

Relevant testing levels include:

### Unit Tests

For:

- Business logic
- Calculations
- Validation
- Status transitions
- Utility functions

### Widget Tests

For:

- UI behavior
- Forms
- Buttons
- Loading states
- Error states
- Role-specific rendering

### Integration Tests

For important end-to-end flows where practical.

Examples:

```text
Login
Create vehicle
Create booking
Approve service
Assign mechanic
Complete task
Update inventory
Calculate final cost
Complete service
```

Not every small visual change requires a new integration test.

---

# 29. Validation After Changes

After implementation, the agent should validate the affected project.

Depending on the change, validation may include:

```text
flutter analyze
flutter test
flutter build
```

and relevant application testing.

The agent must report validation results accurately.

Never claim that a test passed if it was not actually executed.

---

# 30. Build and Environment Awareness

The agent must inspect the project's existing environment before assuming:

- Flutter version
- Dart version
- Package versions
- Platform configuration
- Supabase configuration
- Build commands

Do not unnecessarily upgrade major dependencies during unrelated feature work.

Avoid changing environment configuration without a clear reason.

---

# 31. Git Rules

Git should preserve meaningful project history.

The agent should avoid committing:

- Secrets
- API keys
- Service-role keys
- Build artifacts
- Temporary files
- Generated caches
- IDE-specific personal configuration unless intentionally tracked

Prefer small, understandable commits when the workflow calls for commits.

Do not rewrite Git history unless explicitly requested.

---

# 32. File Modification Rules

Before modifying a file:

1. Read the relevant section.
2. Understand its purpose.
3. Identify dependencies.
4. Make the smallest reasonable change.
5. Re-check the surrounding code.
6. Run appropriate validation.

Do not blindly replace entire files.

---

# 33. Documentation Rules

If implementation changes architecture or project behavior significantly, update the relevant documentation.

Examples:

- New architecture → update `ARCHITECTURE.md`
- New design pattern → update `DESIGN.md`
- New development rule → update `AGENTS.md`
- New user-facing functionality → update `SPEC.md` if the specification itself changed
- Setup changes → update `README.md`

Documentation should remain synchronized with implementation.

---

# 34. UTS Development Scope

The UTS milestone focuses on establishing the application foundation and major interface structure.

Priority areas include:

- Flutter project foundation
- Application shell
- Navigation
- Authentication interface
- Role-aware interface foundation
- Dashboard interfaces
- Customer interface
- Mechanic interface
- Admin interface
- Vehicle management interface
- Booking interface
- Service interface
- Inventory interface
- Reports/history interface
- Notifications/reminders interface
- Supabase connection
- Database foundation
- Authentication foundation
- Demo data

The agent should avoid prematurely implementing every complex final workflow during the initial UTS milestone.

---

# 35. UAS Development Scope

The later UAS phase should build upon the existing foundation.

Priority areas include:

- Complete service workflows
- Service assignments
- Tasks and checklists
- Inventory transactions
- Part requests
- Service parts
- Cost calculations
- Final cost
- Mechanic earnings
- Service history
- Notifications
- Reminders
- Reports
- RLS policies
- Validation
- Testing
- Final integration

The UAS phase should extend the established architecture rather than replacing it.

---

# 36. Agent Task Protocol

When receiving an implementation request, the agent should follow this process.

## Step 1 — Understand

Identify:

- Requested feature
- User role
- Relevant requirements
- Relevant architecture
- Relevant design rules

## Step 2 — Inspect

Inspect the existing implementation.

Identify:

- Relevant files
- Existing components
- Existing providers
- Existing repositories
- Existing routes
- Existing database structures

## Step 3 — Plan

Create a concise implementation plan.

The plan should identify:

- Files to modify
- Files to create
- Important architectural changes
- Testing requirements

Do not plan unrelated refactoring.

## Step 4 — Implement

Implement the requested feature using the existing architecture.

Prefer incremental changes.

## Step 5 — Validate

Run appropriate:

- Analyzer
- Tests
- Build checks
- Application checks

## Step 6 — Report

Report:

- What changed
- Which files changed
- What was tested
- Any remaining issues
- Any decisions requiring user input

---

# 37. When to Ask for Clarification

The agent should ask for clarification when:

- Requirements directly conflict.
- A destructive database change is required.
- A security decision is ambiguous.
- Multiple fundamentally different architectures are possible.
- A new dependency would significantly affect the project.
- A requested feature contradicts project scope.
- The expected behavior cannot reasonably be inferred.

Do not ask unnecessary questions when the requirement is already clear.

---

# 38. Do Not Invent Requirements

The agent must not invent:

- New user roles
- New business rules
- New service statuses
- New payment systems
- New external integrations
- New backend services
- New features

simply because they seem useful.

If an improvement is discovered, it may be reported as a suggestion, but it should not be silently implemented.

---

# 39. Do Not Over-Engineer

PitMate is a college project, not a multinational enterprise platform.

The architecture should be:

- Structured
- Maintainable
- Secure
- Testable
- Understandable

but not unnecessarily complex.

Avoid introducing:

- Microservices
- Event-driven architecture without a real requirement
- Complex dependency injection frameworks
- Multiple backend layers without purpose
- Excessive design patterns
- Custom frameworks
- Unnecessary abstractions

Use the simplest architecture that satisfies the requirements.

---

# 40. Preserve Existing Work

Existing working functionality should be treated as valuable.

Before changing established functionality, verify:

- Why it exists
- What depends on it
- Whether it is already used elsewhere
- Whether the requested feature actually requires changing it

Do not replace working code simply because the agent would have implemented it differently.

---

# 41. Handling Uncertainty

When uncertain, the agent should:

1. Inspect the repository.
2. Check project documentation.
3. Check existing implementation patterns.
4. Prefer the established project convention.
5. Ask the user if the uncertainty affects an important architectural decision.

The agent should never confidently invent project conventions.

---

# 42. Final Agent Philosophy

PitMate is built collaboratively between the developer and AI agents.

The agent is an implementation partner, not the project owner.

The agent should therefore:

- Understand before changing.
- Reuse before creating.
- Simplify before complicating.
- Validate before claiming success.
- Ask before making major architectural decisions.
- Preserve the project's established direction.
- Keep the code understandable.
- Keep the user in control.

The goal is not to produce the largest amount of code.

The goal is to produce the **right code, in the right place, for the right requirement, without breaking what already works.**

> **Build incrementally.  
> Keep the architecture stable.  
> Make every change intentional.**