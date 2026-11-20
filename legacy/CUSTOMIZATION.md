# PitMate — Customization Source of Truth

## Purpose

This document defines where customizable product presentation values live and how to change them safely. The goal is to make future visual and wording changes possible without searching and editing every screen.

## Canonical code location

All app-side customization definitions belong in:

```text
lib/app/customization/
├── pitmate_palette.dart
├── pitmate_typography.dart
├── pitmate_layout.dart
├── pitmate_status_catalog.dart
├── pitmate_service_catalog.dart
└── pitmate_theme.dart
```

Names can be aligned to existing naming conventions after inspection, but the project must have one canonical layer, not both the old and new token systems running independently.

| File | Owns | Must not own |
|---|---|---|
| `pitmate_palette.dart` | Semantic light/dark colors, borders, surfaces, text colors, semantic status colors | Widget-specific arbitrary literals or database status values |
| `pitmate_typography.dart` | Font families, typography scale, weights, reusable text styles | One-off text styling scattered in screens |
| `pitmate_layout.dart` | Spacing scale, border radii, common sizes, control/tap-target dimensions | Business workflow rules |
| `pitmate_status_catalog.dart` | Display label, group, icon, color, and description mapping for each persisted booking/service/task status | The authority to invent database enum values independently |
| `pitmate_service_catalog.dart` | Controlled service categories, labels, optional icons, display order | Dynamic service-order records or user data |
| `pitmate_theme.dart` | Builds `ThemeData` for light and dark/system behavior and shared component themes | Preference persistence or duplicate palette values |

Theme preference state and Supabase persistence remain in the shared state/provider layer. The provider selects a mode; it does not define colors or create a second theme.

## Authority rules

1. `SPEC.md` defines intended user-visible behavior.
2. `DB-SCHEMA.md` and applied migrations define persisted values, constraints, and authorization.
3. `CUSTOMIZATION.md` defines where app-side customization lives.
4. The `lib/app/customization/` files are the runtime source for visual tokens and display mappings.
5. `DESIGN.md` documents the design intent and approved token values; when code and documentation disagree, stop and reconcile them rather than silently choosing one.
6. Screens consume centralized definitions; they do not define their own status strings, palette colors, font families, or service category lists.

## Adding or changing a status

A status is not just a label. Review all of the following together:

- Database enum/constraint and forward migration.
- Allowed state transitions and authorization rules.
- Model serialization/parsing.
- Repository/provider behavior.
- `pitmate_status_catalog.dart` label, group, color, icon, and accessibility text.
- Queue filters, history, reporting, and notifications that depend on the status.
- Tests and documentation.

Do not introduce a new service status solely to represent a screen section. Queue groups should derive from arrival data and existing service statuses unless a genuine new business state is approved.

## Adding a service category

Add the controlled category in `pitmate_service_catalog.dart` and document whether the category is a UI choice list or a database-enforced domain value. Do not convert currently free-text historical values to a closed enum without a migration/backfill plan.

## Surface Token Resolvers and Dialog Layout

Surface colors for cards and modal dialogs are canonically mapped:
- `surfaceCard`: resolves to `PitmatePalette.darkSurfaceSecondary` (Dark) and `lightSurfaceSecondary` (Light).
- `surfaceBackground`: resolves to `PitmatePalette.darkBackgroundPrimary` (Dark) and `lightBackgroundPrimary` (Light).
- Modal dialogs must strictly adhere to `PitmateLayout.dialogMaxWidth` (480–500 px) with corner radius `16 px` and internally scrollable form bodies.

## Adding a theme token

Add a semantic token to `pitmate_palette.dart`, reference it from `pitmate_theme.dart`, and verify both themes. Avoid names such as `white2` or `darkGray3`; prefer semantic roles such as `surfacePrimary`, `textSecondary`, `borderSubtle`, and `statusWarning`. Check contrast and all shared components before marking the change complete.

## Change workflow

1. Search the existing repository for current tokens and labels.
2. Decide whether the value is product behavior, database contract, or presentation customization.
3. Update the canonical definition and relevant docs.
4. Replace duplicated values in consumers with references to the canonical definition.
5. Add or update tests.
6. Verify both themes and all roles affected.
7. Run analysis/tests/build and report the results.
