# PitMate Shared UI & Technical Contract (M5)

## 1. Design Tokens & Visual Hierarchy
- **Palette**: Use `AppColors` from `lib/app/theme/app_colors.dart`.
  - Brand Primary: `AppColors.graphitePrimary` (`#1A1D20`), Dark: `AppColors.graphiteDark` (`#111315`).
  - Accent / Action: `AppColors.accentRed` (`#E53935`), Hover: `AppColors.accentRedHover` (`#C62828`).
  - Backgrounds: Dark `AppColors.backgroundDark` (`#121417`), Light `AppColors.backgroundLight` (`#F4F6F8`).
  - Cards / Surface: Dark `AppColors.surfaceDark` (`#1E2228`), Light `AppColors.surfaceLight` (`#FFFFFF`).
  - Borders: Dark `AppColors.borderDark` (`#2E3440`), Light `AppColors.borderLight` (`#E2E8F0`).
  - Status Semantics: Success `AppColors.statusSuccess` (`#2E7D32`), Warning `AppColors.statusWarning` (`#ED6C02`), Error `AppColors.statusError` (`#D32F2F`), Info `AppColors.statusInfo` (`#0288D1`).
- **Typography**: Use `AppTypography` (`lib/app/theme/app_typography.dart`). Never instantiate raw `TextStyle(fontFamily: ...)` or arbitrary sizes.
- **Spacing**: Use `AppSpacing` (`lib/app/theme/app_spacing.dart`). Standard card padding `AppSpacing.cardPadding` (16.0), inner gap `AppSpacing.md` (12.0).
- **Cards & Badges**: Wrap cards in `PitCard`. Use `StatusBadge` for state indicators.

## 2. Navigation & Layout Strict Rules
- **No Custom Scaffolds/Navbars**: Every screen MUST use `ResponsiveRoleScaffold` with canonical `RoleNavigation`.
- **Navigation Configuration**:
  - Admin: `RoleNavigation.adminNavItems`
  - Mechanic: `RoleNavigation.mechanicNavItems`
  - Customer: `RoleNavigation.customerNavItems`
- **Zero Mock Data**: All queries and mutations MUST hit Supabase tables and RPCs via repository pattern with `Supabase.instance.client`.

## 3. Financial Standard
- **Integer Cents**: All monetary amounts are stored as `BIGINT` cents. No floating-point math.
- **Formatting**: Always format via `CurrencyFormatter.formatIdr(cents)` (from `lib/core/utils/currency_formatter.dart`). Example: `15000000` -> `"Rp 150.000"`.
- **Tax**: Standard 11% PPN calculated via integer math `(taxableSubtotalCents * 11) ~/ 100`.

## 4. Multi-Agent Isolation Boundaries
- **QC Agent**: Owns `lib/features/quality_control/` exclusively.
- **Invoicing Agent**: Owns `lib/features/invoices/` exclusively.
- **Handover Agent**: Owns `lib/features/handover/` exclusively.
- **No Shared File Editing**: Subagents do not edit router or theme files directly. Main orchestrator integrates all routes on `main`.
- **Handoff Output**: Every subagent MUST write `<feature>/HANDOFF.md` upon completion.
