# PitMate — 2-Minute Practical Exam Quick Reference

> Keep this cheat sheet open in Antigravity or in a split window during your exam.

---

## 1. Architecture & Data Flow in 1 Diagram

```
[UI: Screen / Sheet]
  │  ▲  ref.watch() receives AsyncValue<List<T>>
  │  │  ref.read().notifier.createRecord(...)
  ▼  │
[Riverpod Notifier] (lib/shared/providers/*_provider.dart)
  │  ▲  calls repository; calls ref.invalidateSelf() on success
  ▼  │
[Repository Layer] (lib/data/repositories/*_repository.dart)
  │  ▲  isolates domain rules from backend SDK
  ▼  │
[Remote Data Source] (lib/data/datasources/*_remote_datasource.dart)
  │  ▲  PostgREST query: client.from('table').select/insert/update/delete
  ▼  │
[Supabase Database] (PostgreSQL tables protected by Row Level Security)
```

---

## 2. The 10 Most Important Files

| File Path | Role in PitMate |
|---|---|
| `lib/main.dart` | `main()` initializes Supabase & mounts `ProviderScope(child: PitMateApp())`. |
| `lib/app/router/app_router.dart` | `evaluateAuthRedirect()` guards the 20 role-based routes. |
| `lib/app/theme/app_colors.dart` | Global palette tokens: `primaryAccent` (`#E10600`), `surfacePrimary`, etc. |
| `lib/app/theme/app_typography.dart` | Text styles (`pageTitle`, `sectionTitle`, `technical`, `bodyMedium`). |
| `lib/shared/widgets/primary_button.dart` | Main action button; handles loading states and bounded width. |
| `lib/shared/widgets/pit_card.dart` | Reusable technical card container used on all list items. |
| `lib/shared/providers/vehicle_provider.dart` | AsyncNotifier handling vehicles list, filtering, and CRUD mutations. |
| `lib/data/repositories/vehicle_repository.dart` | Interface and Supabase repository implementation. |
| `lib/data/datasources/vehicle_remote_datasource.dart` | Direct Supabase SQL queries and table JSON operations. |
| `lib/features/admin/presentation/admin_vehicles_view.dart` | Complete reference screen: SearchFilterBar, ListView, bottom sheet modal. |

---

## 3. Riverpod Cheat Sheet: `watch` vs `read` vs `invalidate`

| Command | Where to Use | Purpose |
|---|---|---|
| `ref.watch(provider)` | Inside `build()` | Rebuilds the widget automatically whenever state changes. |
| `ref.read(provider)` | Inside `onPressed` / callbacks | Reads the current value once without subscribing to updates. |
| `ref.read(provider.notifier)` | Inside event handlers | Accesses notifier methods (`createVehicle`, `setFilter`). |
| `ref.invalidateSelf()` | Inside Notifier methods | Forces the notifier to re-run `build()` and fetch fresh data. |
| `ref.refresh(provider.future)` | In `RefreshIndicator` | Triggers immediate pull-to-refresh reload. |

---

## 4. Common Widget Layout Behaviors

| Widget | Main Behavior | Gotcha / Rule |
|---|---|---|
| `Row` | Horizontal flex layout | **Unbounded width**. Children cannot use `double.infinity` without `Expanded`. |
| `Column` | Vertical flex layout | **Unbounded height**. Cannot put `Expanded` inside a `SingleChildScrollView`. |
| `Expanded` | Consumes all remaining flex space | Only use inside `Row`, `Column`, or `Flex`. |
| `SizedBox` | Enforces exact width/height or spacing | Use for spacing tokens: `SizedBox(height: AppSpacing.standard)`. |
| `Wrap` | Flow layout that breaks lines | Prevents `RenderFlex` overflows on small phone viewports. |
| `ListView.separated` | Recycles off-screen widgets | In scrollable columns, set `shrinkWrap: true` & `physics: NeverScrollableScrollPhysics()`. |

---

## 5. Where to Change What

| If You Need to Change... | Go to This File |
|---|---|
| Primary accent color (Motorsport Red) | `lib/app/theme/app_colors.dart` (`AppColors.primaryAccent`) |
| Global fonts / text sizes | `lib/app/theme/app_typography.dart` (`GoogleFonts.spaceGrotesk(...)`) |
| Spacing / Padding tokens | `lib/app/theme/app_spacing.dart` (`AppSpacing.standard = 16.0`) |
| Navigation item / Menu route | `lib/app/router/route_paths.dart` & `admin_shell_page.dart` |
| Route protection / Redirect logic | `lib/app/router/app_router.dart` (`evaluateAuthRedirect`) |
| Form fields & input validation | Target presentation file (e.g. `_openVehicleDialog` in `admin_vehicles_view.dart`) |
| Data filtering / Sorting logic | `lib/data/datasources/*_remote_datasource.dart` (`.order(...)`, `.ilike(...)`) |
| Database columns / JSON parsing | `lib/data/models/*model*.dart` (`fromJson` & `toJson`) |

---

## 6. How to Trace Any Add / Edit / Delete in 30 Seconds

```
1. Screen: Find the button's `onPressed` ➔ calls `_openXDialog()` or `_confirmDeleteX()`.
2. Form: Find `_formKey.currentState!.validate()` ➔ reads text field controllers.
3. Notifier: Finds `ref.read(xProvider.notifier).createX(...)` or `deleteX(...)`.
4. Remote Data Source: Finds `_client.from('table_name').insert(...)` or `.delete()`.
5. Refresh: Verifies `ref.invalidateSelf()` is called so the UI updates automatically.
```

---

## 7. Fast Debugging Checklist

- [ ] **Yellow/Black Striped Error**: `RenderFlex overflowed`. Wrap the overflowing child in `Expanded`, `Flexible`, or replace `Row` with `Wrap`.
- [ ] **RenderBox was not laid out**: A widget asked for infinite width in an unconstrained `Row`. Wrap button in `Expanded` or give fixed `width: 140`.
- [ ] **Button does nothing when clicked**: Check if `onPressed` is null, if `_isLoading` is true, or if `_formKey.currentState!.validate()` failed silently.
- [ ] **Data saved to DB but list does not update**: Check if the notifier called `ref.invalidateSelf()` or if you need `ref.invalidate(myProvider)`.
- [ ] **Red screen / Unhandled Exception**: Look at terminal output for the first line with your file path (`lib/...`).

---

## 8. Essential Terminal Commands

```bash
# Verify code health (must show 0 errors)
flutter analyze

# Run all 62 unit and widget tests
flutter test

# Run a specific test quickly
flutter test test/unit/crud_models_test.dart
flutter test test/unit/route_guard_test.dart
```

---

## 9. Compact "Lecturer Asks X ➔ Inspect Y" Lookup

| Lecturer Request | Target File & Widget | Quick Fix |
|---|---|---|
| "Change the button color" | `lib/app/theme/app_colors.dart` | Edit `primaryAccent` (global) OR `ElevatedButton.styleFrom(backgroundColor: ...)` (local). |
| "Add a field to this form" | Target screen (e.g. `admin_vehicles_view.dart`) | Add `TextEditingController`, add `TextFormField`, pass to `createVehicle(...)`. |
| "Add validation (e.g. min 5 chars)" | Target `TextFormField` in screen | `validator: (v) => v!.length < 5 ? 'Min 5 characters required' : null`. |
| "Move button to bottom" | Target screen `build()` | Cut `PrimaryButton` from `Row` and paste at the bottom of the `Column`. |
| "Change a card's border/radius" | `lib/shared/widgets/pit_card.dart` | Change `BorderRadius.circular(AppRadius.card)` or `border: Border.all(...)`. |
| "Change list order" | Remote data source (`fetchVehicles`) | Change `.order('created_at', ascending: false)` to `.order('make', ascending: true)`. |
| "Add an item to the side menu" | `admin_shell_page.dart` | Add `RoleShellDestination(label: 'New', route: '...', icon: Icons.star)` to list. |
| "Fix keyboard covering text input"| Modal bottom sheet container | Add `padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24)`. |

---
*Keep calm. You built and verified every layer of this system.*
