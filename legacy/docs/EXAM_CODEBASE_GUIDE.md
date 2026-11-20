# PitMate — Source Code Understanding & Practical Flutter Exam Guide

> **Target Audience:** Practical Flutter Exam Candidate & Evaluator  
> **Repository:** PitMate (`cars_workshop`)  
> **Milestone Status:** Production Prototype with Supabase Backend & Riverpod State Architecture  
> **Document Purpose:** Grounded technical guide to the actual codebase for live demonstration, code explanation, and on-demand modifications during examination.

---

## Table of Contents
1. [Part 1 — Project Architecture and Directory Map](#part-1--project-architecture-and-directory-map)
2. [Part 2 — The Application's Data Flow](#part-2--the-applications-data-flow)
3. [Part 3 — Understanding Flutter UI Code](#part-3--understanding-flutter-ui-code)
4. [Part 4 — Reusable Widgets and Shared Components](#part-4--reusable-widgets-and-shared-components)
5. [Part 5 — Riverpod and Application State](#part-5--riverpod-and-application-state)
6. [Part 6 — Models, Repositories, and Remote Data Sources](#part-6--models-repositories-and-remote-data-sources)
7. [Part 7 — Authentication, Routing, and Roles](#part-7--authentication-routing-and-roles)
8. [Part 8 — Database and Security](#part-8--database-and-security)
9. [Part 9 — The Change Guide: “If the Lecturer Asks Me to Change X”](#part-9--the-change-guide-if-the-lecturer-asks-me-to-change-x)
10. [Part 10 — Debugging and Tracing](#part-10--debugging-and-tracing)
11. [Part 11 — Exam Rehearsal: 15 Questions & Spoken Model Answers](#part-11--exam-rehearsal-15-questions--spoken-model-answers)
12. [Part 12 — Learning Order & Study Plan](#part-12--learning-order--study-plan)

---

## Part 1 — Project Architecture and Directory Map

### 1.1 Architectural Pattern: Feature-Oriented Clean Architecture with Riverpod
PitMate does **not** follow a simple monolithic Model-View-Controller (MVC) pattern. Instead, it implements a **Feature-Oriented Layered Architecture** with unidirectional data flow powered by Riverpod and repository abstraction:

```
[UI Layer: Widgets / Pages / Sheets]
       │  ▲
       │  │ (ref.watch / AsyncValue data binding)
       ▼  │
[Presentation State: AsyncNotifier / Notifier / FutureProvider]
       │  ▲
       │  │ (calls repository methods / returns domain models)
       ▼  │
[Domain Repository Layer: VehicleRepository, SparePartRepository]
       │  ▲
       │  │ (delegates to data source / isolates domain rules)
       ▼  │
[Data Source Layer: SupabaseVehicleRemoteDataSource]
       │  ▲
       │  │ (PostgREST queries / JSON mapping)
       ▼  │
[Backend: Supabase PostgreSQL Database (Tables + RLS)]
```

### 1.2 Directory Responsibilities & Active Code vs Inactive Placeholders

| Directory Path | Layer / Responsibility | Active Files & Representative Examples | When to Edit This Directory |
|---|---|---|---|
| `lib/main.dart` | Application Bootstrap | `main()` initializes Flutter bindings, connects Supabase, and mounts `ProviderScope`. | To change backend initialization, environment variables, or global provider overrides. |
| `lib/app/` | Global Application Shell & Infrastructure | `app.dart`, `app_config.dart`, `app_router.dart`, `route_paths.dart`, `app_theme.dart`, `app_colors.dart`, `app_spacing.dart`, `app_typography.dart`. | When changing global colors, typography, routes, route guards, or base MaterialApp setup. |
| `lib/data/datasources/` | Remote Backend Communication | `vehicle_remote_datasource.dart`, `spare_part_remote_datasource.dart`, `service_order_remote_datasource.dart`, `booking_remote_datasource.dart`. | When modifying direct Supabase PostgREST queries, table filters, column selects, or joins. |
| `lib/data/repositories/` | Data Access Abstraction Layer | `vehicle_repository.dart`, `spare_part_repository.dart`, `auth_repository.dart`, `customer_repository.dart`. | When changing the contract between UI state and data sources, or adding local caching/offline fallbacks. |
| `lib/data/models/` | Immutable Domain Models & Serialization | `vehicle.dart`, `spare_part.dart`, `service_order.dart`, `booking.dart`, `customer.dart`, `mechanic.dart`, `user_profile.dart`, `user_role.dart`. | When adding or changing database columns, parsing JSON (`fromJson`), or transforming objects to JSON (`toJson`). |
| `lib/shared/providers/` | Riverpod State Management | `vehicle_provider.dart`, `spare_part_provider.dart`, `booking_provider.dart`, `service_order_provider.dart`, `auth_provider.dart`, `supabase_provider.dart`. | When changing reactive state logic, adding filter state, handling AsyncValue lifecycle, or invalidating caches. |
| `lib/shared/widgets/` | Reusable UI Components | `primary_button.dart`, `secondary_button.dart`, `pit_card.dart`, `stat_card.dart`, `status_badge.dart`, `section_header.dart`, `search_filter_bar.dart`, `role_shell_scaffold.dart`, `empty_state.dart`, `error_state.dart`, `loading_state.dart`. | When updating cross-cutting design system components used across multiple role screens. |
| `lib/features/auth/` | Authentication Feature Module | `login_page.dart`, `register_page.dart`, `forgot_password_page.dart`, `landing_page.dart`, `about_page.dart`, `unauthorized_page.dart`. | When modifying the authentication screens, login form fields, or role error splash pages. |
| `lib/features/admin/presentation/` | Admin Role UI Module | `admin_vehicles_view.dart`, `admin_inventory_view.dart`, `admin_services_view.dart`, `admin_bookings_view.dart`, `admin_customers_view.dart`, `admin_mechanics_view.dart`, `admin_reports_view.dart`, `admin_shell_page.dart`. | When changing administrative management views, dialogs/bottom sheets, or master data CRUD views. |
| `lib/features/customer/presentation/` | Customer Role UI Module | `customer_dashboard_view.dart`, `customer_bookings_view.dart`, `customer_vehicles_view.dart`, `customer_history_view.dart`, `customer_profile_view.dart`, `customer_notifications_view.dart`, `customer_reminders_view.dart`. | When changing customer-facing views, booking requests, or vehicle garage views. |
| `lib/features/mechanic/presentation/` | Mechanic Role UI Module | `mechanic_dashboard_view.dart`, `mechanic_services_view.dart`, `mechanic_tasks_view.dart`, `mechanic_history_view.dart`, `mechanic_earnings_view.dart`. | When changing technician workflow, service order progression, telemetry dialogs, or checklist tasks. |

#### Confirmed Unused / Redundant Placeholder Directories
During early scaffolding, generic feature folders were created. In the active implementation, all domain-specific screens are organized cleanly by **role** under `lib/features/admin/`, `lib/features/customer/`, and `lib/features/mechanic/`. The following directories currently contain only `.gitkeep` files and have **zero active code**:
- `lib/features/bookings/` (`.gitkeep` only — active view is `customer_bookings_view.dart` & `admin_bookings_view.dart`)
- `lib/features/earnings/` (`.gitkeep` only — active view is `mechanic_earnings_view.dart`)
- `lib/features/inventory/` (`.gitkeep` only — active view is `admin_inventory_view.dart`)
- `lib/features/notifications/` (`.gitkeep` only — active view is `customer_notifications_view.dart`)
- `lib/features/reminders/` (`.gitkeep` only — active view is `customer_reminders_view.dart`)
- `lib/features/reports/` (`.gitkeep` only — active view is `admin_reports_view.dart`)
- `lib/features/services/` (`.gitkeep` only — active view is `admin_services_view.dart` & `mechanic_services_view.dart`)
- `lib/features/vehicles/` (`.gitkeep` only — active view is `admin_vehicles_view.dart` & `customer_vehicles_view.dart`)
- `lib/core/utils/` (`.gitkeep` only)
- `lib/core/widgets/` (`.gitkeep` only — all reusable widgets live in `lib/shared/widgets/`)
- `lib/shared/models/` (`.gitkeep` only — all models live in `lib/data/models/`)

---

## Part 2 — The Application's Data Flow

PitMate enforces strict unidirectional data flow. The UI never runs raw SQL or queries Supabase directly.

### 2.1 Fetching a List of Records (Fleet Vehicles Example)

```
[AdminVehiclesPage.build]
  │ ref.watch(vehiclesProvider)
  ▼
[VehiclesNotifier.build] in lib/shared/providers/vehicle_provider.dart
  │ calls repository.getVehicles(searchQuery, filterMake)
  ▼
[SupabaseVehicleRepository.getVehicles] in lib/data/repositories/vehicle_repository.dart
  │ delegates to remoteDataSource.fetchVehicles(...)
  ▼
[SupabaseVehicleRemoteDataSource.fetchVehicles] in lib/data/datasources/vehicle_remote_datasource.dart
  │ executes PostgREST query:
  │ _client.from('vehicles').select('*, customers(*, profiles(*))').order('created_at', ascending: false)
  ▼
[Supabase Database: public.vehicles table]
  │ Returns JSON List<Map<String, dynamic>>
  ▼
[Vehicle.fromJson] in lib/data/models/vehicle.dart
  │ Converts raw JSON into immutable List<Vehicle>
  ▼
[VehiclesNotifier state] becomes AsyncData<List<Vehicle>>
  │ triggers UI rebuild
  ▼
[AdminVehiclesPage] renders ListView.separated with PitCard items
```

### 2.2 Creating a Record (Add Vehicle Example)

1. **User Action**: The admin opens the bottom sheet via `_openVehicleDialog()`, enters vehicle specs, and taps the `PrimaryButton` labeled "Register Vehicle".
2. **Form Validation**: `_formKey.currentState!.validate()` ensures required fields (`make`, `model`, `customer_id`) are populated.
3. **Provider Call**:
   ```dart
   await ref.read(vehiclesProvider.notifier).createVehicle(
     customerId: _selectedCustomerId!,
     make: makeController.text.trim(),
     model: modelController.text.trim(),
     variant: variantController.text.trim(),
     modelYear: int.tryParse(yearController.text.trim()),
     licensePlate: plateController.text.trim().toUpperCase(),
     vin: vinController.text.trim().toUpperCase(),
     mileageKm: int.tryParse(mileageController.text.trim()) ?? 0,
     color: colorController.text.trim(),
     notes: notesController.text.trim(),
   );
   ```
4. **Repository Delegation**: `SupabaseVehicleRepository.createVehicle(...)` calls `SupabaseVehicleRemoteDataSource.createVehicle(...)`.
5. **Database Execution**:
   ```dart
   final data = await _client
       .from('vehicles')
       .insert(payload)
       .select('*, customers(*, profiles(*))')
       .single();
   ```
6. **State Invalidation & Refresh**:
   Inside `VehiclesNotifier.createVehicle`, after the record is created, it calls:
   ```dart
   ref.invalidateSelf();
   ```
   `ref.invalidateSelf()` causes `VehiclesNotifier.build()` to re-execute immediately, automatically fetching the latest fleet list from Supabase and updating all watching widgets without requiring manual array manipulation.

### 2.3 Editing a Record (Update Spare Part Example)

1. **Screen**: `AdminInventoryPage` (`lib/features/admin/presentation/admin_inventory_view.dart`).
2. **Trigger**: Card action popup menu or edit icon calls `_openPartDialog(part)`.
3. **Form Prepopulation**: `TextEditingController` instances are initialized with existing part attributes:
   ```dart
   _skuController = TextEditingController(text: widget.part?.sku ?? '');
   _nameController = TextEditingController(text: widget.part?.name ?? '');
   ```
4. **Provider Invocation**:
   ```dart
   await ref.read(sparePartsProvider.notifier).updateSparePart(
     id: widget.part!.id,
     name: _nameController.text.trim(),
     sellingPrice: double.parse(_sellingPriceController.text.trim()),
     minimumStock: int.parse(_minStockController.text.trim()),
   );
   ```
5. **Repository & Data Source**: `SupabaseSparePartRemoteDataSource.updateSparePart` executes:
   ```dart
   final data = await _client
       .from('spare_parts')
       .update(updatePayload)
       .eq('id', id)
       .select('*, inventory_transactions(quantity)')
       .single();
   ```
6. **Refresh**: `ref.invalidateSelf()` refreshes the parts catalog and recalculates inventory transactions.

### 2.4 Deleting a Record (Remove Vehicle Example)

1. **Trigger**: User taps delete icon button on a `PitCard`.
2. **Confirmation**: `_confirmDeleteVehicle(vehicle)` displays a modal confirmation dialog (`AlertDialog`).
3. **Execution**:
   ```dart
   await ref.read(vehiclesProvider.notifier).deleteVehicle(vehicle.id);
   ```
4. **Remote Data Source**:
   ```dart
   await _client.from('vehicles').delete().eq('id', id);
   ```
5. **State Invalidation**: `ref.invalidateSelf()` cleans the deleted vehicle from state, and `AdminVehiclesPage` renders the updated list.

### 2.5 Displaying Loading, Empty, and Error States

Every asynchronous list screen in PitMate uses Riverpod's `AsyncValue.when()` pattern:

```dart
final vehiclesAsync = ref.watch(vehiclesProvider);

return vehiclesAsync.when(
  loading: () => const Center(
    child: LoadingState(message: 'Accessing fleet registry database...'),
  ),
  error: (error, stackTrace) => ErrorState(
    title: 'Failed to load vehicles',
    message: error.toString(),
    onRetry: () => ref.refresh(vehiclesProvider),
  ),
  data: (vehicles) {
    if (vehicles.isEmpty) {
      return const EmptyState(
        title: 'No Vehicles Found',
        message: 'No vehicles match the specified criteria in the garage registry.',
        icon: Icons.directions_car_outlined,
      );
    }
    return ListView.separated(
      itemCount: vehicles.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.standard),
      itemBuilder: (context, index) => PitCard(...),
    );
  },
);
```

---

## Part 3 — Understanding Flutter UI Code

### 3.1 Core Flutter Widgets in PitMate

| Widget | Purpose in PitMate | Layout Effect & Constraints | Where to Edit / PitMate Example |
|---|---|---|---|
| `StatelessWidget` | Immutable presentation widget without internal mutable state. | Does not hold mutable fields; rebuilds only when constructor inputs change or parent rebuilds. | [PitCard](file:///home/axel/Development/FlutterProjects/cars_workshop/lib/shared/widgets/pit_card.dart), [PrimaryButton](file:///home/axel/Development/FlutterProjects/cars_workshop/lib/shared/widgets/primary_button.dart). |
| `StatefulWidget` | Widget maintaining a mutable `State` lifecycle object. | Holds controllers, local dropdown selections, or animation controllers across rebuilds. | [AdminVehiclesPage](file:///home/axel/Development/FlutterProjects/cars_workshop/lib/features/admin/presentation/admin_vehicles_view.dart), `_PartFormDialog`. |
| `build(BuildContext context)` | Framework method describing the widget tree representation. | Called whenever dependencies change or `setState()` is invoked. Must be pure and fast. | Present on all widget classes. |
| `BuildContext` | Handle to the location of a widget in the widget tree. | Used to locate ancestor themes (`Theme.of(context)`), media queries (`MediaQuery.of(context)`), and navigators (`Navigator.of(context)`). | Used in all `build()` methods and modal callbacks. |
| `Scaffold` | Top-level visual layout structure. | Implements drawer, app bar, floating action buttons, and background color. | [RoleShellScaffold](file:///home/axel/Development/FlutterProjects/cars_workshop/lib/shared/widgets/role_shell_scaffold.dart), [AppScaffold](file:///home/axel/Development/FlutterProjects/cars_workshop/lib/shared/widgets/app_scaffold.dart). |
| `SafeArea` | Inset padding avoiding OS status bars and notches. | Automatically applies padding for iPhone notches and Android navigation bars. | Inside [RoleShellScaffold](file:///home/axel/Development/FlutterProjects/cars_workshop/lib/shared/widgets/role_shell_scaffold.dart). |
| `Padding` | Insets its child widget by a specified `EdgeInsets`. | Consumes space within parent constraints before sizing its child. | Used with `AppSpacing.paddingStandard` across all cards and pages. |
| `Container` | Convenience widget combining painting, positioning, and sizing. | Combines `BoxDecoration` (color, border, radius) with optional constraints. | [PitCard](file:///home/axel/Development/FlutterProjects/cars_workshop/lib/shared/widgets/pit_card.dart), [StatusBadge](file:///home/axel/Development/FlutterProjects/cars_workshop/lib/shared/widgets/status_badge.dart). |
| `SizedBox` | Box with fixed width and/or height. | Enforces strict dimensions or creates vertical/horizontal spacing (`SizedBox(height: 16)`). | Used throughout PitMate for consistent whitespace tokens. |
| `Expanded` | Expands a child of a `Row` or `Column` to fill available space. | Forces child flex factor along the main axis. **Never use in unbounded parents**. | Wraps text and search inputs inside header rows. |
| `Flexible` | Sizes child flexibly along main axis without forcing full expansion. | Similar to `Expanded`, but `fit: FlexFit.loose` allows the child to be smaller than the max space. | Inside button text rows to prevent text from overflowing. |
| `Row` | Displays children horizontally. | Unbounded horizontal width. Children cannot request `double.infinity` without `Expanded`. | Card action bars, header bars, metric stats. |
| `Column` | Displays children vertically. | Unbounded vertical height. Children cannot use `Expanded` inside a scroll view without shrinking. | Card bodies, form structures, drawer item lists. |
| `Wrap` | Flow layout that breaks onto multiple lines when horizontal space runs out. | Prevents `RenderFlex` overflow errors when badges or chips exceed container width. | Status chips, tags, or narrow telemetry button rows. |
| `Divider` | A 1-pixel hairline visual separator. | Draws horizontal line with subtle border color (`AppColors.borderSubtle`). | Separates card content from action footers in `PitCard`. |
| `ListView.separated` | Efficient scrolling list builder that recycles viewports. | Lazily constructs only visible items, inserting `separatorBuilder` widgets between them. | Fleet vehicle list, inventory catalog list. |
| `SingleChildScrollView` | Enables scrolling on a single child widget. | Makes a `Column` scrollable when the on-screen keyboard appears. | Top-level body of modal bottom sheets. |

### 3.2 Forms, State Lifecycle, and Callbacks

```dart
// 1. Controller instantiation in State object
final _formKey = GlobalKey<FormState>();
final _makeController = TextEditingController();

// 2. Lifecycle disposal - MANDATORY to avoid memory leaks
@override
void dispose() {
  _makeController.dispose();
  super.dispose();
}

// 3. Validation and async execution
Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return; // Halts if invalid
  
  setState(() => _isLoading = true);
  try {
    await ref.read(vehiclesProvider.notifier).createVehicle(
      make: _makeController.text.trim(),
      ...
    );
    if (mounted) {
      Navigator.pop(context); // Safe pop checking widget mount status
    }
  } catch (e) {
    if (mounted) {
      setState(() => _errorMessage = e.toString());
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

#### What is `mounted`?
When performing asynchronous operations (such as database calls with `await`), the user might navigate back or close the screen before the database response arrives. If code calls `setState()` or `Navigator.pop(context)` on an unmounted `State` whose widget is no longer in the tree, Flutter throws:
`Unhandled Exception: setState() called after dispose()`.
Checking `if (mounted)` ensures the widget is still alive and active before modifying its state or triggering navigation.

### 3.3 Deep Dive: Complete Widget Tree of `AdminVehiclesPage`

To understand how nested widgets compose, here is the exact hierarchy from [admin_vehicles_view.dart](file:///home/axel/Development/FlutterProjects/cars_workshop/lib/features/admin/presentation/admin_vehicles_view.dart):

```
AdminVehiclesPage (ConsumerStatefulWidget)
└── AdminShell (Helper linking RoutePaths.adminVehicles)
    └── RoleShellScaffold
        └── Scaffold (Dark background: #0B0D10)
            ├── AppBar / Navigation Sidebar / Drawer (RoleShellScaffold header)
            └── Body: RefreshIndicator (onRefresh: ref.refresh(vehiclesProvider.future))
                └── SingleChildScrollView (AlwaysScrollableScrollPhysics)
                    └── Padding (AppSpacing.paddingSection = 24.0)
                        └── Column (crossAxisAlignment: CrossAxisAlignment.stretch)
                            ├── Row (Header & Action)
                            │   ├── Expanded
                            │   │   └── SectionHeader (title: 'WORKSHOP FLEET REGISTRY')
                            │   └── SizedBox (width: 140)
                            │       └── PrimaryButton (text: 'Add Car', icon: Icons.add)
                            ├── SizedBox (height: AppSpacing.compact = 8.0)
                            ├── SearchFilterBar (searchHint, filterOptions: ['All', 'BMW', ...])
                            ├── SizedBox (height: AppSpacing.section = 24.0)
                            └── vehiclesAsync.when(...)
                                ├── loading: LoadingState
                                ├── error: ErrorState (onRetry callback)
                                └── data: ListView.separated (shrinkWrap: true, NeverScrollableScrollPhysics)
                                    └── PitCard (Container with border #2D3742 & radius 12.0)
                                        └── Column
                                            ├── Technical Label: 'TELEMETRY-ID • 8-CHAR-UUID'
                                            ├── Row (Car Title & Badge)
                                            │   ├── Icon (Icons.directions_car)
                                            │   ├── Expanded -> Text ('BMW M3 G80')
                                            │   └── StatusBadge (label: 'B 1234 PIT')
                                            ├── Owner Row: Text ('Owner: John Doe')
                                            ├── Notes: Text ('Regular oil change scheduled')
                                            ├── Divider (color: #2D3742, height: 1)
                                            └── Card Action Footer: Row
                                                ├── Text ('Mileage: 12,500 KM')
                                                └── Row (IconButtons)
                                                    ├── IconButton (Edit -> _openVehicleDialog(vehicle))
                                                    └── IconButton (Delete -> _confirmDeleteVehicle(vehicle))
```

---

## Part 4 — Reusable Widgets and Shared Components

### 4.1 PrimaryButton & SecondaryButton

- **File**: `lib/shared/widgets/primary_button.dart` & `secondary_button.dart`
- **Constructor Parameters**:
  - `text` (`String`, required): The button label (automatically displayed in uppercase with letter spacing).
  - `onPressed` (`VoidCallback?`, required): Tap handler. If `null` or `isLoading == true`, button is disabled.
  - `isLoading` (`bool`, default: `false`): Replaces label with a centered `CircularProgressIndicator`.
  - `icon` (`IconData?`, optional): Displays an 18px icon preceding the text.
  - `width` (`double?`, optional): Fixed width constraint. If omitted, the button uses `LayoutBuilder` to expand to `double.infinity` **only when horizontal constraints are bounded**, preventing infinite-width crashes in unbounded `Row` contexts.

#### The Unbounded Flex Trap in Flutter
If you place a widget with `width: double.infinity` directly inside a `Row`, Flutter crashes with:
`BoxConstraints forces an infinite width. A RenderFlex was not laid out`.
Because `Row` has unbounded width, its children cannot ask for infinite width. In PitMate, `PrimaryButton` and `SecondaryButton` use `LayoutBuilder(constraints.hasBoundedWidth)` to safely adapt:
- Inside a vertical `Column`: Expands to full width.
- Inside an unbounded `Row`: Wraps its intrinsic content unless wrapped in `Expanded`.
- Inside dialog actions: Always wrap in `Expanded` inside a `Row`:
  ```dart
  Row(
    children: [
      Expanded(child: SecondaryButton(text: 'Cancel', onPressed: ...)),
      SizedBox(width: 16),
      Expanded(child: PrimaryButton(text: 'Save', onPressed: ...)),
    ],
  )
  ```

### 4.2 PitCard
- **File**: `lib/shared/widgets/pit_card.dart`
- **Purpose**: Unified card panel featuring technical telemetry aesthetic.
- **Parameters**: `child` (`Widget`), `technicalLabel` (`String?`), `padding`, `backgroundColor`, `borderColor`, `onTap`.
- **Global Change**: Changing the border or background in `pit_card.dart` updates **every card across the entire application** (vehicles, inventory, services, bookings, tasks).

### 4.3 SearchFilterBar
- **File**: `lib/shared/widgets/search_filter_bar.dart`
- **Purpose**: Combines debounced text search with horizontal status/category filter chips.
- **Parameters**: `searchHint`, `onSearchChanged`, `filterOptions` (`List<String>`), `selectedFilter`, `onFilterSelected`.

---

## Part 5 — Riverpod and Application State

### 5.1 Riverpod Concepts in PitMate

| Concept | What It Does in PitMate | Where It Is Used |
|---|---|---|
| `Provider<T>` | Read-only synchronous dependency injection. | Injecting `VehicleRepository`, `SupabaseClient`. |
| `FutureProvider<T>` | Asynchronous one-shot data provider. | `currentCustomerProvider`, `currentMechanicProvider`. |
| `AsyncNotifier<T>` | Stateful controller managing asynchronous state (`AsyncValue<T>`) with business logic mutations. | `VehiclesNotifier`, `SparePartsNotifier`, `BookingsNotifier`. |
| `AsyncNotifierProvider` | Connects an `AsyncNotifier` to the Riverpod graph. | `vehiclesProvider`, `sparePartsProvider`, `serviceOrdersProvider`. |
| `ref.watch()` | Subscribes a widget or provider to reactive changes; triggers re-render when state updates. | Inside `build()` methods of UI pages. |
| `ref.read()` | One-time read of a provider without subscribing to updates. | Inside tap handlers (`onPressed`), callbacks, or mutation triggers. |
| `ref.refresh()` | Forces a provider to re-execute immediately and returns its new value. | Inside `RefreshIndicator(onRefresh: () => ref.refresh(vehiclesProvider.future))`. |
| `ref.invalidateSelf()` | Invalidates the current notifier so it re-runs its `build()` method automatically. | Called inside `createVehicle()`, `updateVehicle()`, `deleteVehicle()`. |

### 5.2 AsyncValue State Transitions

```
                    ┌──────────────┐
                    │ AsyncLoading │
                    └──────┬───────┘
                           │
             ┌─────────────┴─────────────┐
             ▼                           ▼
      ┌─────────────┐             ┌────────────┐
      │  AsyncData  │             │ AsyncError │
      │ (List<T>)   │             │  (Object)  │
      └─────────────┘             └────────────┘
```

When user filters or performs a mutation:
1. `state = const AsyncLoading();` (UI renders loading spinner or shimmer).
2. `state = await AsyncValue.guard(() async => repository.getVehicles(...));`
3. If successful: `AsyncData` is set and UI renders the list.
4. If an exception occurs: `AsyncError` is captured without crashing the app, and `ErrorState` is shown.

---

## Part 6 — Models, Repositories, and Remote Data Sources

### 6.1 Serialization: `fromJson` and `toJson`

```dart
// lib/data/models/vehicle.dart
factory Vehicle.fromJson(Map<String, dynamic> json) {
  return Vehicle(
    id: json['id'] as String,
    customerId: json['customer_id'] as String,
    make: json['make'] as String,
    model: json['model'] as String,
    mileageKm: json['mileage_km'] as int? ?? 0,
    licensePlate: json['license_plate'] as String?,
    customer: json['customers'] != null 
        ? Customer.fromJson(json['customers'] as Map<String, dynamic>)
        : null,
  );
}
```

Notice:
- `as String?` or `as int? ?? 0` safely handles null values coming from PostgreSQL.
- Foreign key joins (`customers(*, profiles(*))`) are nested JSON maps parsed recursively by calling the child model's `fromJson`.

### 6.2 Why Separate Repository and Remote Data Source?

- **Remote Data Source** (`lib/data/datasources/`): Handles raw HTTP/PostgREST queries, Supabase table names, SQL joins, and JSON parsing. If the backend changes from Supabase to Firebase or custom REST API, **only this file changes**.
- **Repository** (`lib/data/repositories/`): Exposes clean Dart domain interfaces. It hides backend technology details from the UI and Riverpod providers. It is also the ideal place to add offline caching, network connectivity guards, or data sanitization.

---

## Part 7 — Authentication, Routing, and Roles

### 7.1 The Complete Authentication Flow

```
1. User enters email & password on LoginPage (/login)
2. Tap "Sign In" calls ref.read(authSessionProvider.notifier).signIn(...)
3. SupabaseAuthRemoteDataSource executes client.auth.signInWithPassword(...)
4. Supabase Auth triggers AuthChangeEvent.signedIn
5. AuthSessionNotifier._handleAuthStateChange catches event and fetches profile:
   SELECT * FROM public.profiles WHERE id = user.id
6. AuthSessionState updates to AuthSessionState.authenticated(role: profile.role)
7. AuthRouterListenable detects state update and calls notifyListeners()
8. GoRouter re-evaluates evaluateAuthRedirect():
   If role == UserRole.admin -> redirects to /admin
   If role == UserRole.mechanic -> redirects to /mechanic
   If role == UserRole.customer -> redirects to /customer
```

### 7.2 The 20 Authoritative Routes in PitMate

PitMate defines 20 discrete destinations across 3 role modules:

```dart
// Admin Module (8 routes)
RoutePaths.admin           // /admin (Dashboard)
RoutePaths.adminCustomers  // /admin/customers
RoutePaths.adminMechanics  // /admin/mechanics
RoutePaths.adminVehicles   // /admin/vehicles
RoutePaths.adminBookings   // /admin/bookings
RoutePaths.adminServices   // /admin/services
RoutePaths.adminInventory  // /admin/inventory
RoutePaths.adminReports    // /admin/reports

// Mechanic Module (5 routes)
RoutePaths.mechanic        // /mechanic (Dashboard)
RoutePaths.mechanicServices// /mechanic/services
RoutePaths.mechanicTasks   // /mechanic/tasks
RoutePaths.mechanicHistory // /mechanic/history
RoutePaths.mechanicEarnings// /mechanic/earnings

// Customer Module (7 routes)
RoutePaths.customer        // /customer (Dashboard)
RoutePaths.customerProfile // /customer/profile
RoutePaths.customerVehicles// /customer/vehicles
RoutePaths.customerBookings// /customer/bookings
RoutePaths.customerHistory // /customer/history
RoutePaths.customerNotifications // /customer/notifications
RoutePaths.customerReminders     // /customer/reminders
```

### 7.3 Unauthorized Route Protection
If an authenticated customer types or navigates to `/admin/vehicles`:
1. `evaluateAuthRedirect` in `app_router.dart` detects `isProtectedAdmin && role != UserRole.admin`.
2. It immediately returns `RoutePaths.unauthorized` (`/unauthorized`).
3. `UnauthorizedPage` renders a warning explaining that the current user profile lacks clearance, with a button navigating back to their role's legitimate dashboard.

---

## Part 8 — Database and Security

### 8.1 Database Tables & Domain Relationships

| Table Name | Primary Key | Key Foreign Keys | Purpose |
|---|---|---|---|
| `public.profiles` | `id` (uuid -> `auth.users`) | References Supabase Auth | Stores user role (`admin`, `mechanic`, `customer`), full name, phone. |
| `public.customers` | `id` (uuid) | `profile_id -> profiles.id` | Customer details, address, customer type (`individual`, `commercial`). |
| `public.mechanics` | `id` (uuid) | `profile_id -> profiles.id` | Mechanic technician profile, specialization, active status. |
| `public.vehicles` | `id` (uuid) | `customer_id -> customers.id` | Vehicle specs: make, model, VIN, license plate, mileage. |
| `public.bookings` | `id` (uuid) | `customer_id`, `vehicle_id` | Customer appointment requests with workshop. |
| `public.service_orders` | `id` (uuid) | `customer_id`, `vehicle_id` | Core job ticket tracking 12 workflow service states. |
| `public.service_assignments`| `id` (uuid) | `service_order_id`, `mechanic_id`| Assigns technicians to specific service orders. |
| `public.service_tasks` | `id` (uuid) | `service_order_id` | Granular tasks checklist within a job ticket. |
| `public.spare_parts` | `id` (uuid) | None | Spare parts catalog, SKU, unit costs, selling prices. |
| `public.inventory_transactions`| `id` (uuid) | `part_id -> spare_parts.id` | Stock incoming/outgoing ledger (+/- quantity). |
| `public.service_reminders` | `id` (uuid) | `vehicle_id`, `customer_id` | Predictive maintenance alerts for oil, tires, brakes. |

### 8.2 Row Level Security (RLS) vs UI Route Guards

> **Crucial Distinction for the Exam**:  
> Hiding a button in Flutter or redirecting a route in GoRouter is **client-side UX protection**, NOT security! Any user with an HTTP proxy or SQL client could bypass Flutter.  
> **True security** is enforced at the database layer via PostgreSQL **Row Level Security (RLS)** policies.

To prevent circular dependency recursions between `service_orders`, `vehicles`, and `service_assignments`, PitMate uses **Security Definer** lookup functions:
- `public.is_admin()`: Checks if current `auth.uid()` has `role = 'admin'` in `public.profiles`.
- `public.current_customer_id()`: Returns customer ID associated with logged-in user.
- `public.is_order_assigned_to_current_mechanic(p_order_id)`: Checks whether the order has an active assignment for the calling mechanic.

---

## Part 9 — The Change Guide: “If the Lecturer Asks Me to Change X”

| # | Lecturer's Request | File to Inspect/Edit | Specific Method / Widget | What to Change | What Else May Be Affected | How to Verify |
|---|---|---|---|---|---|---|
| **1** | Change the app's primary accent color (e.g. from Motorsport Red to Blue) | `lib/app/theme/app_colors.dart` | `AppColors.primaryAccent` | Change `Color(0xFFE10600)` to `Color(0xFF2563EB)`. | Updates all primary buttons, active tab highlights, progress indicators, and status badges globally. | Hot Reload; verify button color on login and dashboard. |
| **2** | Change the global font or typography | `lib/app/theme/app_typography.dart` | `AppTypography.displayLarge`, `pageTitle`, etc. | Change `GoogleFonts.spaceGrotesk(...)` to `GoogleFonts.poppins(...)` or `roboto(...)`. | Replaces header fonts throughout the app. | Hot Reload; text immediately updates. |
| **3** | Change a button's label, color, or icon | Target screen (e.g. `lib/features/admin/presentation/admin_vehicles_view.dart`) | `PrimaryButton` in `build()` | Change `text: 'Add Car'` to `text: 'Register Vehicle'`, change `icon: Icons.add` to `Icons.directions_car`. | Only affects this specific button on this page. | Hot Reload; check header button text. |
| **4** | Move a button from the right side of a header to the bottom | Target screen (e.g. `lib/features/admin/presentation/admin_vehicles_view.dart`) | `build()` Column children | Move `PrimaryButton` from the header `Row` to the bottom of the `Column`. | Layout structure changes from horizontal header to stacked vertical. | Hot Reload; verify button appears below list. |
| **5** | Add vertical spacing between two elements | Target screen | Between widgets in `Column` | Insert `const SizedBox(height: AppSpacing.section)` or `SizedBox(height: 24)`. | Pushes following widgets downward. | Hot Reload; visual distance increases. |
| **6** | Make a button full-width vs content-width | Target screen | `PrimaryButton` | Wrap in `SizedBox(width: double.infinity)` for full width, or provide explicit `width: 140` for fixed content width. | If inside an unconstrained `Row`, full-width will crash unless wrapped in `Expanded`. | Hot Reload; check width alignment. |
| **7** | Move search bar above or below the header | Target screen | `build()` Column children | Swap the positions of `SearchFilterBar(...)` and `Row(SectionHeader...)` inside the `Column`. | Search bar moves above title. | Hot Reload; inspect element ordering. |
| **8** | Change a page title or subtitle | Target screen | `SectionHeader` widget | Modify `title: 'FLEET REGISTRY'` and `subtitle: '...'`. | Page header text updates. | Hot Reload; inspect new title. |
| **9** | Add a new field to an Add/Edit form (e.g. Vehicle "Fuel Type") | 1. `lib/features/admin/presentation/admin_vehicles_view.dart`<br>2. `lib/data/datasources/vehicle_remote_datasource.dart` | `_openVehicleDialog` in screen | 1. Add `TextEditingController fuelController`<br>2. Add `TextFormField(controller: fuelController)`<br>3. Pass to `createVehicle(notes: ...)` | Form layout and payload sent to Supabase. | Open bottom sheet, fill field, submit, verify payload. |
| **10** | Change available dropdown filter options | Target screen (e.g. `admin_vehicles_view.dart`) | `SearchFilterBar.filterOptions` | Change `const ['All', 'BMW', 'Aston Martin', 'Toyota', 'Ford']` to add new brand names (e.g. `'Porsche'`). | Adds/removes clickable filter chips. | Hot Reload; tap new chip and verify list filters. |
| **11** | Add or modify form validation rule | Target form (e.g. `admin_inventory_view.dart`) | `TextFormField.validator` | Change `validator: (v) => v == null \|\| v.isEmpty ? 'Required' : null` to add length checks: `if (v.length < 3) return 'Min 3 chars'`. | Prevents form submission if invalid; displays red helper text. | Trigger submit with empty field to see error text. |
| **12** | Change a Dialog to a Modal Bottom Sheet | Target screen (e.g. `customer_bookings_view.dart`) | `_openBookingDialog()` | Replace `showDialog(...)` with `showModalBottomSheet(isScrollControlled: true, context: context, builder: ...)`. | Converts floating dialog into slide-up modal bottom sheet. | Tap button; sheet slides up from bottom. |
| **13** | Change modal scrolling or keyboard padding | Target form sheet | Top-level `Padding` in modal | Add `bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.section` and wrap child in `SingleChildScrollView`. | Modal automatically shifts upward when keyboard appears. | Tap text field; ensure keyboard does not obscure buttons. |
| **14** | Add a field or row to a displayed card | Target screen (e.g. `admin_vehicles_view.dart`) | `PitCard` child `Column` in `ListView.separated` | Add a `Row` with `Icon` and `Text('Color: ${vehicle.color}')`. | Card expands slightly to accommodate new metric row. | Hot Reload; cards render the new field. |
| **15** | Change list sorting or filtering order | `lib/data/datasources/vehicle_remote_datasource.dart` | `fetchVehicles()` | Change `.order('created_at', ascending: false)` to `.order('make', ascending: true)`. | Changes default order returned by Supabase. | Invalidate provider or pull to refresh; verify alphabetical sort. |
| **16** | Change loading or error message | Target screen | `vehiclesAsync.when(...)` | Change `LoadingState(message: 'Loading...')` or `ErrorState(title: 'Custom Title')`. | Changes message shown while waiting or on failure. | Simulate error or slow network to observe message. |
| **17** | Add a new navigation item to a role menu | `lib/features/admin/presentation/admin_shell_page.dart` (or `mechanic_shell_page.dart`) | `destinations` list in `RoleShellScaffold` | Add `RoleShellDestination(label: 'Analytics', route: '/admin/analytics', icon: Icons.analytics)`. | Adds sidebar/drawer item to navigation. | Open drawer; tap new item. |
| **18** | Protect a route or add clearance check | `lib/app/router/app_router.dart` | `evaluateAuthRedirect()` | Add `if (location.startsWith('/admin/secret') && role != UserRole.admin) return RoutePaths.unauthorized;`. | Prevents unauthorized roles from entering path. | Try navigating to route as customer; redirects to unauthorized. |
| **19** | Change which database column appears on screen | 1. `lib/data/models/vehicle.dart`<br>2. Target screen | `Vehicle.displayName` or `Text(vehicle.make)` | Change `Text('${vehicle.make} ${vehicle.model}')` to `Text('${vehicle.modelYear} ${vehicle.make}')`. | Changes displayed string on cards. | Hot Reload; check vehicle cards. |
| **20** | Add field to model and persist to Supabase | 1. `lib/data/models/spare_part.dart`<br>2. `lib/data/datasources/spare_part_remote_datasource.dart` | `SparePart` class & `createSparePart()` | 1. Add `final String? supplier` to model & `fromJson`<br>2. Add `payload['supplier'] = supplier` in remote datasource. | Requires corresponding column in database table. | Run `flutter test test/unit/crud_models_test.dart`. |
| **21** | Change how a list is fetched | `lib/shared/providers/vehicle_provider.dart` | `VehiclesNotifier.build()` | Modify parameters passed to `repository.getVehicles(filterMake: ...)`. | Alters criteria for initial data load. | Pull to refresh; check network records. |
| **22** | Add a create/edit/delete operation | 1. Remote Data Source<br>2. Repository<br>3. Notifier | `VehiclesNotifier` | Add `Future<void> archiveVehicle(String id)` following existing `deleteVehicle` pattern. | Provides new mutation capability. | Call notifier method from UI button. |
| **23** | Refresh the displayed list after mutation | Target screen or Notifier | Inside mutation method | Call `ref.invalidateSelf()` inside Notifier, or `ref.refresh(vehiclesProvider)` in UI. | Forces re-fetch from database and UI re-render. | Insert record; verify it appears in list immediately. |
| **24** | Change button tap action | Target screen | `PrimaryButton.onPressed` | Point `onPressed` callback to a different private method: `onPressed: _handleExportReport`. | Button executes new handler. | Tap button; verify new action executes. |
| **25** | Fix RenderFlex overflow or infinite-width error | Target layout | Parent of problematic widget | 1. If horizontal overflow: wrap text or button in `Expanded` or use `Wrap`.<br>2. If unbounded width: give fixed width (`width: 140`) or use `Expanded`. | Resolves yellow-and-black striped overflow banner. | Hot Reload; check error console is clean. |
| **26** | Diagnose why a dialog does not open | Target screen | Calling method (e.g. `_openVehicleDialog`) | Verify `onPressed` is not null, `showModalBottomSheet` is called, and context is valid and mounted. | Dialog opens as expected. | Click button; observe console logs. |
| **27** | Find why a successful insert does not appear in list | 1. Notifier<br>2. Screen | `createVehicle` in Notifier | Verify `ref.invalidateSelf()` is called, or add `ref.invalidate(vehiclesProvider)` in the caller. | List re-fetches and displays new item. | Add record; check that list auto-updates. |

---

## Part 10 — Debugging and Tracing

### 10.1 Diagnostic Runbook: "If Something Goes Wrong"

#### Symptom 1: Button tapped, but nothing happens
1. **Check callback**: Inspect `onPressed: _isLoading ? null : _submit`. If `_isLoading` is stuck at `true`, the button is disabled.
2. **Check form validation**: If `_formKey.currentState!.validate()` fails, it exits silently. Look at text fields for red error borders.
3. **Check console**: Look for unhandled exceptions or Supabase network timeouts.

#### Symptom 2: Dialog or Bottom Sheet throws `RenderBox was not laid out`
- **Root Cause**: An unbounded widget (like `PrimaryButton` without bounded width) was placed inside an unconstrained horizontal `Row` in the dialog actions.
- **Fix**: Wrap action buttons in `Expanded` inside the `Row`, or pass an explicit `width`.

#### Symptom 3: Insert succeeds in database, but UI does not show the new record
- **Root Cause**: Missing provider invalidation.
- **Fix**: Verify the notifier calls `ref.invalidateSelf()` or the screen calls `ref.invalidate(vehiclesProvider)`.

#### Symptom 4: User logged in, but screen remains stuck on Loading or redirects to Unauthorized
- **Root Cause**: `profiles` table does not contain a row matching `auth.uid()`, or `role` enum in database does not match `UserRole` (`admin`, `mechanic`, `customer`).
- **Fix**: Inspect `AuthSessionNotifier._loadProfileForUser` in `lib/shared/providers/auth_provider.dart`.

### 10.2 Essential Commands for the Exam

```bash
# 1. Check code quality and ensure 0 compilation/lint issues
flutter analyze

# 2. Run the entire test suite (all 62 unit and widget tests)
flutter test

# 3. Run targeted tests if modifying specific modules
flutter test test/unit/design_tokens_test.dart   # Design tokens & colors
flutter test test/unit/route_guard_test.dart     # Role route guards (20 routes)
flutter test test/unit/crud_models_test.dart     # JSON model serialization
flutter test test/widget/login_page_test.dart    # Login validation & UI
```

---

## Part 11 — Exam Rehearsal: 15 Questions & Spoken Model Answers

### Q1: "Explain how this Admin Vehicles page gets its data."
> **Model Answer**:  
> "The `AdminVehiclesPage` watches `vehiclesProvider` using Riverpod's `ref.watch()`. `vehiclesProvider` is an `AsyncNotifier` that queries `VehicleRepository`. The repository delegates to `SupabaseVehicleRemoteDataSource`, which executes a PostgREST query against the `vehicles` table in Supabase joining `customers` and `profiles`. The JSON response is mapped into immutable `Vehicle` models via `Vehicle.fromJson`, and Riverpod returns an `AsyncValue` to the UI, handling loading, error, and data states automatically."  
> *Files to reference*: `lib/features/admin/presentation/admin_vehicles_view.dart`, `lib/shared/providers/vehicle_provider.dart`.

### Q2: "Why did you separate the Repository and Remote Data Source?"
> **Model Answer**:  
> "To enforce separation of concerns and Clean Architecture. The Remote Data Source is coupled to Supabase-specific syntax, table schemas, and PostgREST filters. The Repository exposes pure Dart domain interfaces to our Riverpod providers. If we switch backends or add local SQLite caching in the future, our UI and Riverpod providers do not need to change at all."  
> *Files to reference*: `lib/data/repositories/vehicle_repository.dart`, `lib/data/datasources/vehicle_remote_datasource.dart`.

### Q3: "What happens when I click the 'Add Car' button?"
> **Model Answer**:  
> "Tapping 'Add Car' calls `_openVehicleDialog()`, which invokes `showModalBottomSheet` with `isScrollControlled: true`. The modal renders a form with controllers for make, model, license plate, and customer ID. When submitted, `_formKey.currentState!.validate()` validates the inputs, then calls `ref.read(vehiclesProvider.notifier).createVehicle(...)`. Once Supabase inserts the row, the notifier calls `ref.invalidateSelf()`, which triggers an automatic re-fetch and updates the list on screen."  
> *Files to reference*: `lib/features/admin/presentation/admin_vehicles_view.dart` (lines 70–120).

### Q4: "Can you change this card layout to show the car's color?"
> **Model Answer**:  
> "Yes. In `admin_vehicles_view.dart`, within the `ListView.separated` `itemBuilder`, each item renders a `PitCard`. Inside the card's `Column`, I can add a `Row` displaying `Icon(Icons.palette)` and `Text(vehicle.color ?? 'Standard Livery')` styled with `AppTypography.bodySmall(color: AppColors.textSecondary)`."  
> *Files to reference*: `lib/features/admin/presentation/admin_vehicles_view.dart` (lines 580–605).

### Q5: "How do you validate user input on this form?"
> **Model Answer**:  
> "Each form field is a `TextFormField` wrapped in a `Form` with a `GlobalKey<FormState>`. Each field has a `validator` callback. For example, for the license plate, the validator checks if the trimmed value is empty and returns 'License plate is required'. When `_formKey.currentState!.validate()` is called on submit, Flutter highlights invalid fields in red and aborts the submission."  
> *Files to reference*: `lib/features/admin/presentation/admin_vehicles_view.dart` (lines 200–260).

### Q6: "How do you handle database errors when a request fails?"
> **Model Answer**:  
> "We use `try-catch` blocks in our async notifier methods and guard state with `AsyncValue.guard()`. If Supabase throws a PostgREST exception, Riverpod captures it in `AsyncValue.error`. The UI uses `.when(error: (err, _) => ErrorState(...))` to display a user-friendly error card with a retry button that calls `ref.refresh()`."  
> *Files to reference*: `lib/shared/providers/vehicle_provider.dart` (lines 48–56), `lib/shared/widgets/error_state.dart`.

### Q7: "Why did you choose Riverpod over setState or raw ChangeNotifier?"
> **Model Answer**:  
> "Riverpod provides compile-time safety, isolates business logic outside UI widgets, and handles asynchronous state lifecycles (`loading`, `data`, `error`) seamlessly through `AsyncValue`. Unlike raw `ChangeNotifier`, Riverpod providers can be easily watched, read, mocked during unit testing, and automatically disposed when no longer needed."

### Q8: "What does the `Expanded` widget do in your search header?"
> **Model Answer**:  
> "`Expanded` forces a child of a `Row` or `Column` to take up all remaining available space along the main axis. In our header, `Row` contains an `Expanded(child: SectionHeader(...))` and a fixed `SizedBox(width: 140, child: PrimaryButton(...))`. The `Expanded` ensures the title takes all available width without pushing the button off-screen."  
> *Files to reference*: `lib/features/admin/presentation/admin_vehicles_view.dart` (lines 482–500).

### Q9: "Why is the vehicle list inside a `ListView.separated` instead of a `Column`?"
> **Model Answer**:  
> "`ListView.separated` lazily renders only the widgets currently visible in the viewport, which gives optimal memory usage and 60fps scrolling performance for large fleets. A `Column` would construct every single widget in memory at once regardless of whether it is on screen. `ListView.separated` also cleanly separates cards with standard spacing tokens."

### Q10: "How does the application know the logged-in user's role?"
> **Model Answer**:  
> "When a user logs in via Supabase Auth, `AuthSessionNotifier` catches the `signedIn` event and queries `public.profiles` using the user's `auth.uid()`. The profile contains a `role` string (`admin`, `mechanic`, or `customer`) which is parsed into the typed `UserRole` enum. This is stored in `AuthSessionState` and read by `GoRouter` to determine permissions and dashboard routing."  
> *Files to reference*: `lib/shared/providers/auth_provider.dart` (lines 86–120).

### Q11: "What prevents a Customer from opening the Admin screen?"
> **Model Answer**:  
> "Two layers of defense:  
> 1. Client-side: `evaluateAuthRedirect()` in `app_router.dart` checks if `location.startsWith('/admin')` and `role != UserRole.admin`. If so, it redirects to `/unauthorized`.  
> 2. Database-side: PostgreSQL Row Level Security (RLS) policies evaluate `public.is_admin()`. Even if a customer manipulated Flutter code, Supabase rejects unauthorized table queries with error 42501."  
> *Files to reference*: `lib/app/router/app_router.dart` (lines 92–105).

### Q12: "How would you debug a button that throws `RenderBox was not laid out`?"
> **Model Answer**:  
> "That error means a widget was forced into an infinite constraint by its parent. I check the widget tree for an unbounded horizontal `Row` containing a button with `width: double.infinity`. In PitMate, we resolved this by wrapping our `PrimaryButton` in a `LayoutBuilder` that only expands to infinity when constraints are bounded, and ensuring row actions use `Expanded`."  
> *Files to reference*: `lib/shared/widgets/primary_button.dart` (lines 82–93).

### Q13: "How do you ensure the list refreshes after adding or deleting an item?"
> **Model Answer**:  
> "In Riverpod `AsyncNotifier`, after the repository mutation succeeds, we call `ref.invalidateSelf()`. This marks the provider as stale and re-runs its `build()` method, which re-queries Supabase and pushes the fresh list to all active UI subscribers."  
> *Files to reference*: `lib/shared/providers/vehicle_provider.dart` (line 91).

### Q14: "What files must change if we add a new column to the `vehicles` table?"
> **Model Answer**:  
> "Four files:  
> 1. `lib/data/models/vehicle.dart`: Add field to model, `fromJson`, and `toJson`.  
> 2. `lib/data/datasources/vehicle_remote_datasource.dart`: Add parameter to `createVehicle` and `updateVehicle` payloads.  
> 3. `lib/data/repositories/vehicle_repository.dart`: Update interface and implementation.  
> 4. `lib/features/admin/presentation/admin_vehicles_view.dart`: Add form input field in `_openVehicleDialog` and display on card."

### Q15: "What is the purpose of `WidgetsFlutterBinding.ensureInitialized()` in `main.dart`?"
> **Model Answer**:  
> "It binds the Flutter framework to the platform engine before running async setup code. In our app, we call `await Supabase.initialize()` before `runApp()`. Without `ensureInitialized()`, calling native platform channels before the engine is ready throws a runtime crash."  
> *Files to reference*: `lib/main.dart` (lines 9–11).

---

## Part 12 — Learning Order & Study Plan

### 1. Must Understand (Prioritize First Tonight)
1. **The Core Data Flow**: `admin_vehicles_view.dart` ➔ `vehicle_provider.dart` ➔ `vehicle_repository.dart` ➔ `vehicle_remote_datasource.dart`.
2. **Form Bottom Sheets**: How `_openVehicleDialog` works, how controllers are used, and how `createVehicle` is called.
3. **Riverpod Fundamentals**: Difference between `ref.watch` (in `build`) and `ref.read` (in `onPressed`), and how `ref.invalidateSelf()` triggers list updates.
4. **Layout Troubleshooting**: Why `Expanded` is required inside `Row`, and how `LayoutBuilder` protects buttons.
5. **Role Routing**: How `evaluateAuthRedirect` in `app_router.dart` guards `/admin`, `/mechanic`, and `/customer`.

### 2. Should Understand (Review Next)
1. **Inventory/Spare Parts Catalog**: How stock is calculated from `inventory_transactions` in `spare_part.dart`.
2. **Design Tokens**: `AppColors.primaryAccent`, `AppSpacing`, `AppTypography` in `lib/app/theme/`.
3. **Reusable Widgets**: `PitCard`, `PrimaryButton`, `SecondaryButton`, `SectionHeader`, `SearchFilterBar`.
4. **Testing & Validation**: How to run `flutter analyze` and `flutter test`.

### 3. Only Inspect If Time Remains
1. Deep RLS SQL functions in `supabase/migrations/`.
2. Telemetry dialog in `mechanic_history_view.dart`.
3. Unused placeholder `.gitkeep` folders in `lib/features/`.

---
*Document prepared and verified against the live PitMate codebase.*
