# Greg Handoff — Stitch Design Audit and Flutter Mapping

Use this prompt after the updated Markdown documents are placed in the PitMate project root and the Stitch MCP connection is available in Antigravity.

---

Read `SPEC.md`, `ARCHITECTURE.md`, `DESIGN.md`, `DB-SCHEMA.md`, `AGENTS.md`, `README.md`, `CUSTOMIZATION.md`, `UAS-PLAN.md`, `STITCH-UI-BRIEF.md`, and this file before doing anything else.

## Task: Stitch design-reference audit only

Inspect the Google Stitch designs available through the connected MCP and compare them with the existing PitMate Flutter application. This is a planning/mapping task only. **Do not modify source code, migrations, `pubspec.yaml`, configuration, or database records yet.**

1. Inventory each available Stitch design/frame and identify whether it represents the design system, login, Admin dashboard, Workshop Queue, Reports, service detail, Mechanic dashboard, Customer dashboard, or reusable components.
2. Compare the references against `DESIGN.md` and `CUSTOMIZATION.md`. Flag conflicting colors, typography, spacing, status treatments, labels, and component variants. Keep the existing PitMate motorsport-red brand accent unless the product owner explicitly approves a rebrand.
3. Inspect the current Flutter source to map each design to the actual screen/widget files and reusable components. Do not guess filenames; report exact paths found in the repository.
4. Identify which reusable Flutter widgets should be reused, which require a targeted refinement, and which are genuinely missing.
5. Identify the current token/theme files and propose a migration plan to the single canonical `lib/app/customization/` layer. Do not create duplicate token systems.
6. For the Queue design, verify that the visual model separates upcoming bookings from arrived vehicles and shows booking/walk-in origin, arrival time, exact service status, and blockers. Do not invent queue statuses or a manual priority system.
7. For Reports, ensure the design supports booking, walk-in, and legacy-unknown as distinct categories and does not imply that mock metrics are live data.
8. Review both light and dark variants with the installed Anti-Slop core and UI skills. Include accessibility, contrast, responsive layout, touch targets, semantic status communication, and realistic empty/loading/error states.
9. Report any design gaps, missing light/dark variants, Stitch MCP limitations, or assets that cannot be accessed.

## Required output

Produce a concise report with:

- Stitch assets found and their identifiers/locations.
- Screen-to-Flutter-file mapping with exact paths.
- Shared components and customization tokens implicated.
- Design-system conflicts or missing variants.
- Anti-Slop findings, grouped by severity.
- Recommended implementation order aligned with `UAS-PLAN.md`.
- Any decisions that require Axel's approval.

Stop after the report. Do not start implementation until the report is reviewed and a specific milestone is approved.
