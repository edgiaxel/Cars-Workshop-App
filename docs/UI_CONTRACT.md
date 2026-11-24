# PitMate Shared UI & Technical Contract (M6)

## 1. Design Tokens & Visual Hierarchy (Antislop Compliant)
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
- **Antislop Rules**:
  - No em dashes (`—`) in user-facing copy. Use comma, colon, or parentheses.
  - No template 3-card copy-paste or fake terminal blocks.
  - High contrast (WCAG AA 4.5:1 minimum).
  - All interactive elements must trigger functional mutations or navigation.

## 2. Navigation & Layout Strict Rules
- **No Custom Scaffolds/Navbars**: Every screen MUST use `ResponsiveRoleScaffold` with canonical `RoleNavigation`.
- **Navigation Configuration**:
  - Admin: `RoleNavigation.adminNavItems` (13 items, including Reports currentIndex: 11, Reminders currentIndex: 12)
  - Mechanic: `RoleNavigation.mechanicNavItems` (4 items)
  - Customer: `RoleNavigation.customerNavItems` (7 items, including Invoices currentIndex: 4, Tracking currentIndex: 5, Reminders currentIndex: 6)
- **Universal Notification Center**: All roles access `NotificationBellButton` in `ResponsiveRoleScaffold.actions`.
- **Zero Mock Data**: All queries and mutations MUST hit live Supabase tables (`notifications`, `maintenance_reminders`, `service_orders`, `vehicles`, `payments`) and transactional RPCs (`create_notification_event`, `mark_notification_read`, `generate_service_order_reminders`, `get_workshop_daily_metrics`, `get_workshop_monthly_metrics`, `get_customer_service_tracking`).

## 3. Financial & Metrics Standard
- **Integer Cents**: All monetary amounts stored and computed as `BIGINT` cents. No floating-point math.
- **Formatting**: Always format via `CurrencyFormatter.formatIdr(cents)`. Example: `15000000` -> `"Rp 150.000"`.
- **Revenue Distinction**: Always cleanly separate settled payments (`payments.amount_cents` with `payment_status = 'completed'`) from outstanding receivables (`invoices.outstanding_balance_cents`).

## 4. Multi-Agent Isolation Boundaries (M6)
- **Notifications Agent**: Owns `lib/features/notifications/` exclusively.
- **Customer Tracking Agent**: Owns `lib/features/customer_tracking/` exclusively.
- **Reminders Agent**: Owns `lib/features/reminders/` exclusively.
- **Reports Agent**: Owns `lib/features/reports/` exclusively.
- **No Shared File Editing**: Subagents do not edit router or theme files directly. Main orchestrator integrates all routes on `main`.
- **Handoff Output**: Every subagent MUST write `<feature>/HANDOFF.md` upon completion.
