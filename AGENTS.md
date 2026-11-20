# PitMate — Agent Instructions

> **Document:** AGENTS.md  
> **Status:** Approved — 2026-11-20  
> **Version:** 2.0  
> **Last updated:** 2026-11-20  
> **Applies to:** All coding agents, including Antigravity agents and human contributors.

---

# 1. Project Identity

PitMate is a single-workshop automotive workshop management application built with Flutter and Supabase.

The system supports three primary roles:

- **Admin:** Workshop administration, vehicle intake, bookings, workshop dispatch, inventory, finances and reporting.
- **Mechanic:** Assigned service operations, inspection, diagnostics, checklists, parts requests and progress updates.
- **Customer:** Vehicle management, service bookings, repair tracking, invoices, notifications and maintenance reminders.

The application uses a shared Flutter codebase with role-specific experiences.

The backend is powered by Supabase and PostgreSQL.

## Primary Objective

Maintain and develop PitMate into a reliable, maintainable and demonstrable workshop management system.

Prioritize:

1. Correct business logic.
2. Data integrity.
3. Security and authorization.
4. Complete user workflows.
5. Maintainable implementation.
6. Consistent user experience.
7. Automated verification.

Do not prioritize unnecessary architectural complexity or cosmetic improvements over working business functionality.

---

# 2. Canonical Project Documents

The following documents define the project's intended behavior and implementation.

| Document | Authority |
|---|---|
| `PRD.md` | Approved product scope and business requirements |
| `DESIGN.md` | Approved UI/UX behavior and visual specifications |
| `ARCHITECTURE.md` | Technical architecture and engineering decisions |
| `MILESTONE.md` | Development progress and milestone planning |
| `DATABASE_SCHEMA.md` or existing `DB-SCHEMA.md` | Database structure and relationships |
| `CHANGELOG.md` | Historical project changes |
| `README.md` | Project setup and overview |
| `CUSTOMIZATION.md` | UI customization rules, if retained in the repository |
| `TESTING.md` | Testing procedures, if maintained |

## Document Rules

1. Read the relevant sections before implementing a feature.
2. Do not read every document unnecessarily for unrelated tasks.
3. Do not invent missing requirements.
4. If documents conflict, identify the conflict before implementation.
5. Do not silently change approved product behavior.
6. Update canonical documentation when an approved change materially affects it.
7. Do not create duplicate documentation without a demonstrated need.

## Source of Truth

Use the following priority:

1. Explicitly approved user decisions.
2. Current verified repository implementation for existing behavior.
3. Approved PRD and DESIGN requirements.
4. Approved architecture decisions.
5. Milestone and GitHub issue scope.
6. Agent recommendations.

When existing implementation conflicts with approved product requirements, report the conflict and propose a minimal correction.

Do not assume that either the code or documentation is automatically correct.

---

# 3. Repository Preservation Rules

**The existing repository is the starting point.**

Do not treat PitMate as an empty project unless the user explicitly authorizes a separate clean-slate implementation.

## Mandatory Rules

- Inspect before editing.
- Preserve existing working features.
- Preserve useful configurations.
- Preserve existing database migrations.
- Preserve existing Supabase integrations.
- Preserve existing tests.
- Preserve user modifications.
- Preserve existing UI customization conventions.
- Avoid unnecessary file restructuring.
- Avoid replacing working implementations with theoretically cleaner alternatives.

## Destructive Operations

Never perform the following without explicit approval:

- Deleting existing project files.
- Reinitializing the Git repository.
- Replacing the Supabase project.
- Resetting the database.
- Deleting migrations.
- Dropping tables or columns.
- Rewriting migration history.
- Force pushing shared branches.
- Removing existing tests.
- Replacing authentication architecture.
- Performing production database modifications.

Before any destructive operation:

1. Explain what will be affected.
2. Explain why it is necessary.
3. Identify backup and recovery requirements.
4. Obtain explicit user approval.
5. Verify the target environment.

## Clean-Slate Architecture (Version 2.0 Authorized)

The clean-slate redesign (Version 2.0) has been explicitly approved and authorized by the user.
The previous Version 1.0 implementation is preserved in `legacy/` for reference.

Rules for Version 2.0:
- Version 1.0 in `legacy/` is non-binding reference material; do not cross-import from `legacy/`.
- Build cleanly following `docs/ARCHITECTURE.md`, `docs/PRD.md`, and `docs/DESIGN.md`.
- Never delete `legacy/` without explicit authorization.
- Version 2.0 uses feature-first modular architecture (`lib/features/`, `lib/app/`, `lib/core/`, `lib/shared/`).

---

# 4. Technology Constraints

## Approved Stack

| Technology | Responsibility |
|---|---|
| Flutter | Application framework |
| Dart | Application language |
| Supabase | Backend platform |
| PostgreSQL | Database |
| Supabase Auth | Authentication |
| Supabase Realtime | Live updates |
| Supabase Storage | File storage where applicable |
| Riverpod | Application state |
| GoRouter | Navigation |
| Git/GitHub | Version control and collaboration |

## Dependency Rules

1. Reuse existing dependencies whenever possible.
2. Do not introduce a dependency for functionality already provided by Flutter or existing packages.
3. Do not add packages merely for convenience without justification.
4. Check package compatibility before introducing new dependencies.
5. Avoid unnecessary dependency upgrades.
6. Do not change major package versions without evaluating impact.
7. Preserve `pubspec.lock`.
8. Document significant dependency changes.

## Backend Rules

- Supabase remains the backend platform.
- Do not introduce a separate Node.js backend without approval.
- Do not introduce microservices.
- Do not introduce Redis, Kubernetes or message brokers without a demonstrated requirement.
- Use PostgreSQL functions for appropriate transactional operations.
- Use Supabase Realtime for relevant live updates.
- Use Edge Functions only when the operation genuinely requires trusted server-side execution.

## Database Rules

- PostgreSQL is the source of truth.
- Use migrations for schema changes.
- Preserve relational integrity.
- Use foreign keys and constraints appropriately.
- Use transactions for critical multi-record operations.
- Preserve historical financial records.
- Maintain inventory movement history.
- Do not trust client-side validation as a security boundary.
- Validate permissions on the backend.

---

# 5. Code Quality Rules

## General Principles

Follow:

- Readability over cleverness.
- Simplicity over unnecessary abstraction.
- Reuse over duplication.
- Explicit behavior over hidden side effects.
- Small changes over broad refactoring.
- Existing project conventions over personal preferences.

## Anti-Slop Rules

Agents must not:

- Generate unnecessary helper classes.
- Create abstractions for one trivial operation without justification.
- Duplicate existing widgets.
- Create unused providers.
- Create speculative features.
- Add placeholder implementations that appear functional.
- Add dependencies to avoid writing a few simple lines.
- Leave dead code after refactoring.
- Introduce generic frameworks for a single feature.
- Suppress errors without understanding them.
- Hide failures with excessive fallback behavior.
- Rewrite unrelated code during a focused task.

## File Organization

Follow the existing repository organization.

The verified baseline uses:

- `lib/app/`
- `lib/core/`
- `lib/features/`
- `lib/shared/`
- `lib/app/customization/`

Do not reorganize these directories simply to match a different architectural preference.

Any proposed structural migration must have a clear benefit and be reviewed first.

## Flutter Rules

- Prefer reusable widgets for genuinely repeated UI patterns.
- Keep business logic outside presentation widgets.
- Use Riverpod consistently.
- Use GoRouter for application navigation.
- Follow existing responsive layout conventions.
- Respect centralized design tokens.
- Use semantic theme colors.
- Handle loading, empty, error and success states.
- Respect minimum touch-target requirements.
- Avoid unnecessary widget nesting.
- Avoid giant screen widgets when meaningful separation is justified.

## Dart Rules

- Use sound null safety.
- Prefer immutable models where appropriate.
- Use clear naming.
- Handle asynchronous operations explicitly.
- Avoid unnecessary dynamic types.
- Avoid force-unwrapping nullable values without justification.
- Dispose of resources appropriately.
- Keep exception handling meaningful.

---

# 6. UI Customization Rules

`CUSTOMIZATION.md` is the reference for existing customization conventions.

The reported baseline centralizes visual customization under:

`lib/app/customization/`

Important existing files include:

- `pitmate_palette.dart`
- `pitmate_typography.dart`
- `pitmate_layout.dart`
- `pitmate_status_catalog.dart`
- `pitmate_service_catalog.dart`
- `pitmate_theme.dart`

## Mandatory Rules

1. Reuse existing design tokens.
2. Do not hardcode colors when a semantic token exists.
3. Do not create another palette.
4. Do not introduce inconsistent typography.
5. Preserve dark/light theme support.
6. Respect existing spacing and radius conventions.
7. Preserve status catalog mappings.
8. Do not change global theme behavior for a local visual adjustment.
9. Check all affected role interfaces after modifying shared components.

## Shared Component Warning

The following components have multiple consumers:

- `PitCard`
- `RoleShellScaffold`
- `StatusBadge`

Before changing them:

1. Search for all consumers.
2. Understand their current behavior.
3. Identify visual and functional impact.
4. Test affected screens.
5. Report any intentional behavior changes.

---

# 7. Security Rules

Security is mandatory.

## Authentication

- Use Supabase Auth.
- Never implement custom password storage.
- Never expose authentication tokens.
- Preserve session handling.
- Validate authentication state before protected operations.

## Authorization

Roles:

- Admin.
- Mechanic.
- Customer.

Authorization must be enforced through appropriate backend policies and trusted operations.

Client-side route guards are not sufficient security.

## Row Level Security

- Respect existing RLS policies.
- Do not disable RLS to make a feature work.
- Do not weaken existing access policies without approval.
- Test cross-role access.
- Test customer ownership restrictions.
- Verify mechanic assignment restrictions.
- Verify admin-only operations.

## Credentials

Never:

- Commit service-role keys.
- Commit database passwords.
- Commit access tokens.
- Print secrets in logs.
- Copy credentials into documentation.
- Embed privileged keys in Flutter code.

Use the existing public configuration contract in `lib/app/config/app_config.dart`.

Use environment/build-time configuration where appropriate.

---

# 8. Database and Business Logic Rules

Business correctness takes priority over convenience.

## Workshop Lifecycle

Preserve the distinction between:

- Booking.
- Physical arrival.
- Service order creation.
- Inspection.
- Estimate.
- Customer authorization.
- Mechanic assignment.
- Repair execution.
- Quality control.
- Invoice.
- Payment.
- Vehicle handover.

Do not merge separate business states into one generic status.

## Service Orders

- Prevent duplicate booking check-ins.
- Validate customer and vehicle relationships.
- Preserve intake origin.
- Preserve arrival timestamps.
- Record meaningful status transitions.
- Respect operation dependencies.

## Inventory

- Never update stock without a corresponding transaction record.
- Prevent negative available stock.
- Validate reservation quantities.
- Handle concurrent operations safely.
- Distinguish reserved, issued, consumed and returned stock.
- Preserve movement history.

## Finance

- Do not use floating-point arithmetic for monetary calculations.
- Preserve invoice snapshots.
- Prevent duplicate payments.
- Reconcile deposits and outstanding balances.
- Separate settled revenue from estimated revenue.
- Preserve payment history.
- Audit financial adjustments.

## Mechanic Compensation

- Preserve base salary and incentive distinctions.
- Do not calculate incentives from incomplete operations.
- Preserve contribution allocation history.
- Restrict compensation changes to authorized users.

---

# 9. Agent Task Workflow

Every implementation task follows this process.

## Phase A — Understand

1. Read the assigned GitHub issue or user request.
2. Identify related PRD feature IDs.
3. Read relevant DESIGN sections.
4. Read relevant ARCHITECTURE sections.
5. Inspect the existing implementation.
6. Inspect Git status.
7. Identify dependencies and affected files.

## Phase B — Plan

For non-trivial tasks, report:

- Objective.
- Current implementation.
- Proposed change.
- Files likely to be affected.
- Dependencies.
- Potential risks.
- Verification strategy.

Do not begin substantial implementation when the scope is ambiguous.

## Phase C — Implement

1. Work only within the assigned scope.
2. Use the agreed branch or worktree.
3. Follow existing conventions.
4. Implement the smallest complete solution.
5. Add or update tests.
6. Avoid unrelated refactoring.
7. Keep the implementation consistent with approved documents.

## Phase D — Verify

Run relevant checks.

At minimum, use the project's established validation commands where applicable:

```bash
flutter analyze
flutter test
```

Run additional tests when database behavior, integration or platform-specific behavior changes.

Do not assume that passing tests prove every business workflow is correct.

## Phase E — Review

Inspect:

- Complete Git diff.
- Changed files.
- Unrelated modifications.
- Error handling.
- Edge cases.
- Security boundaries.
- UI consistency.
- Regression risks.
- Test coverage.

## Phase F — Report

Every completed task must report:

1. Objective.
2. Implementation summary.
3. Files changed.
4. Tests executed.
5. Exact results.
6. Known limitations.
7. Remaining risks.
8. Git branch/commit/PR status, if applicable.
9. Recommended next action.

---

# 10. Verification and Testing

## Existing Baseline

The uploaded discovery report records:

- Flutter analysis: 0 issues.
- Automated tests: 89/89 passing.
- Asset bundle build: successful.

These are historical baseline results, not guarantees about subsequent changes.

## Testing Requirements

### Unit tests

Use for:

- Business calculations.
- State transitions.
- Model serialization.
- Validation.
- Inventory calculations.
- Financial calculations.
- Role logic.

### Widget tests

Use for:

- Shared widgets.
- Forms.
- Navigation.
- Responsive behavior.
- Loading/error states.
- Role-specific screens.

### Integration tests

Use for:

- Authentication.
- Supabase interactions.
- Database RPC operations.
- Workshop lifecycle.
- Cross-role workflows.
- Realtime behavior.

### Regression tests

When modifying an existing feature:

- Preserve its existing test coverage.
- Update affected assertions.
- Add tests for newly introduced behavior.
- Verify related workflows.

## Test Reporting

Never report tests as passed if they were not executed.

Use:

- `PASSED`
- `FAILED`
- `SKIPPED`
- `NOT RUN`
- `BLOCKED`

Include the actual command and relevant output.

---

# 11. Git and GitHub Rules

## Branch Naming

```text
main
develop

feature/<short-name>
fix/<short-name>
refactor/<short-name>
chore/<short-name>
docs/<short-name>
test/<short-name>
```

## Branch Rules

- Never commit unrelated work.
- Do not force-push shared branches.
- Do not bypass required reviews.
- Do not merge unverified changes.
- Do not commit secrets.
- Do not delete existing branches without justification.
- Preserve user changes.

## Commit Convention

Use conventional commit-style messages.

Examples:

```text
feat: add customer vehicle registration

fix: prevent duplicate booking check-in

refactor: simplify inventory repository

test: add service order lifecycle coverage

docs: update workshop architecture

chore: update compatible dependencies
```

## Pull Requests

Every substantial implementation should have:

- Clear objective.
- Linked issue.
- Scope description.
- Acceptance criteria.
- Test evidence.
- Screenshots when UI changes materially.
- Known limitations.

Avoid giant pull requests containing unrelated features.

---

# 12. Parallel Agent Collaboration

Multiple coding agents may be used when tasks are genuinely independent.

## Suggested Responsibilities

| Agent | Responsibility |
|---|---|
| Lead / Integrator | Architecture consistency, task coordination and integration |
| Flutter Agent | UI, widgets, navigation and application state |
| Database Agent | PostgreSQL, migrations, RPCs and RLS |
| QA Agent | Test planning, regression and code review |

These are functional responsibilities, not mandatory separate agents.

## Parallel Work Rules

1. One owner per shared file at a time.
2. Assign independent tasks.
3. Identify shared dependencies before starting.
4. Coordinate interfaces before parallel implementation.
5. Avoid concurrent migration edits.
6. Avoid simultaneous modifications to shared models.
7. Use separate branches or worktrees where appropriate.
8. Review each agent's changes before integration.
9. Never merge blindly.

## Agent Handoff Format

Each agent must report:

```markdown
# Agent Handoff

## Assigned Task
[Task ID and objective]

## Status
[Complete / Partial / Blocked]

## Files Changed
- ...

## Implementation
- ...

## Tests
- Command:
- Result:

## Dependencies
- ...

## Known Issues
- ...

## Handoff Notes
- ...
```

---

# 13. Antigravity IDE Instructions

Antigravity is the primary coding environment.

Greg refers to the Gemini coding agent used within Antigravity.

## General Rules

- Use repository-aware context.
- Read this file before substantial implementation.
- Read relevant canonical documents.
- Inspect existing code before changing it.
- Follow the assigned task scope.
- Do not assume the entire repository must be loaded into context.
- Keep implementation and verification evidence traceable.

## Planning

For substantial tasks:

1. Understand the objective.
2. Inspect the affected subsystem.
3. Prepare an implementation plan.
4. Identify shared files.
5. Identify risks.
6. Wait for user approval when the change is consequential.
7. Execute the approved plan.

Small, unambiguous tasks may proceed without a lengthy planning phase.

## Antigravity Configuration

Use the currently supported project-level instruction mechanism.

Do not create speculative configuration files or invent unsupported Antigravity syntax.

This `AGENTS.md` is the canonical project instruction document. Any tool-specific configuration should reference it rather than duplicate it.

---

# 14. Documentation Maintenance

Keep documentation synchronized with actual implementation.

| Document | Update when |
|---|---|
| PRD.md | Approved product behavior or scope changes |
| DESIGN.md | Screen behavior or visual design changes |
| ARCHITECTURE.md | System structure or technical decisions change |
| MILESTONE.md | Progress, blockers or next milestone change |
| Database schema documentation | Tables, relationships, policies or functions change |
| CHANGELOG.md | Meaningful changes are completed |
| README.md | Setup, project overview or usage changes |
| CUSTOMIZATION.md | Design token ownership or customization rules change |

Do not update documents with unverified implementation claims.

Do not mark planned work as completed.

---

# 15. Prohibited Actions

Unless explicitly approved, agents must not:

- Delete working features.
- Replace the existing backend.
- Replace the Supabase project.
- Reset the database.
- Rewrite migration history.
- Introduce a new backend framework.
- Introduce unnecessary dependencies.
- Perform broad unrelated refactoring.
- Disable security policies.
- Expose secrets.
- Modify production data.
- Deploy production builds.
- Make paid service changes.
- Merge unreviewed changes.
- Fabricate tests or implementation evidence.
- Mark incomplete features as complete.

---

# 16. Definition of Done

A task is complete only when:

- [ ] Its objective is satisfied.
- [ ] Acceptance criteria are met.
- [ ] Existing behavior is preserved where required.
- [ ] Relevant tests are added or updated.
- [ ] Relevant checks are executed.
- [ ] Static analysis is clean or existing exceptions are documented.
- [ ] Security boundaries are respected.
- [ ] Git diff is reviewed.
- [ ] Documentation is updated when necessary.
- [ ] Known limitations are reported.
- [ ] The change is ready for review or integration.

A feature is not complete merely because its screen exists.

A database operation is not complete merely because it returns a successful response.

A workflow is complete only when its relevant end-to-end behavior is verified.

---

# 17. Final Instruction

Work incrementally.

Preserve what already works.

Understand before modifying.

Prefer the smallest complete solution.

Never invent evidence.

Never silently expand scope.

When a requirement conflicts with existing implementation or approved documentation, stop and explain the conflict.

The goal is not to produce the largest amount of code.

The goal is to build a reliable PitMate application with maintainable code and verifiable behavior.
