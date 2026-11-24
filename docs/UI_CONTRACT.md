# PitMate Shared UI & Technical Contract (M7)

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

## 2. Navigation & Layout Strict Rules (M7 Optimized)
- **No Custom Scaffolds/Navbars**: Every screen MUST use `ResponsiveRoleScaffold` with canonical `RoleNavigation`.
- **Mobile Bottom Navigation Bar Capped at 4 Items**:
  - To prevent layout overflow and squished icons on mobile screens down to 320px, `BottomNavigationBar` MUST contain at most 4 primary items:
    - **Admin Mobile (4 items)**: Overview (`/admin`), Workshop Floor (`/admin/floor`), Bookings (`/admin/bookings`), Invoices (`/admin/invoices`).
    - **Mechanic Mobile (4 items)**: My Work (`/mechanic`), Active Workspace (`/mechanic/operation`), Inspection (`/mechanic/inspection`), Earnings (`/mechanic/earnings`).
    - **Customer Mobile (4 items)**: My Garage (`/customer/garage`), Book Service (`/customer/book-service`), Live Tracking (`/customer/tracking`), Invoices (`/customer/invoices`).
  - All supplementary screens remain fully accessible on mobile via `_buildMobileDrawer` (opened via the menu icon button in the app bar) and on desktop (>=900px) via the permanent sidebar navigation rail.
- **Universal Notification Center**: All roles access `NotificationBellButton` in `ResponsiveRoleScaffold.actions`.
- **Profile Navigation**: Tapping the user avatar in either the mobile app bar or desktop header MUST navigate to `/profile`.

## 3. Financial & Metrics Standard
- **Integer Cents**: All monetary amounts stored and computed as `BIGINT` cents. No floating-point math.
- **Formatting**: Always format via `CurrencyFormatter.formatIdr(cents)`. Example: `15000000` -> `"Rp 150.000"`.
- **Revenue Distinction**: Always cleanly separate settled payments (`payments.amount_cents` with `payment_status = 'completed'`) from outstanding receivables (`invoices.outstanding_balance_cents`).

## 4. Auth & Recovery Contract (PKCE Link Workaround)
- Supabase sends password reset links formatted as `http://127.0.0.1:3000/?code=<uuid>`.
- The root router intercepts any `code` query parameter on landing, calls `Supabase.client.auth.exchangeCodeForSession(code)`, and routes to `/reset-password?code=<uuid>`.
- The `ResetPasswordScreen` renders the new password form, validates minimum length and confirmation match, and calls `Supabase.client.auth.updateUser(UserAttributes(password: newPassword))` to update credentials cleanly.

## 5. Responsive Viewport Standards
- **Lowest Mobile Width (320px)**: Zero horizontal scrolling or `RenderFlex` overflow. All text scales properly without collision.
- **Standard Mobile (375px & 425px)**: Fluid card grids and responsive wrapping for metric badges.
- **Tablet (768px)**: Adaptive column grids (2-column cards, collapsible metrics).
- **Desktop (>=900px - 1024px+)**: Dual-pane layouts with persistent left sidebar navigation and desktop top bar.

## 6. Multi-Agent Isolation Boundaries (M7)
- **Profile & Auth Worktree**: Owns `lib/features/profile/` and `lib/features/auth/presentation/screens/reset_password_screen.dart`.
- **Responsive Navigation Worktree**: Owns `lib/shared/navigation/` and `lib/shared/widgets/responsive_role_scaffold.dart`.
- **Seed & Verification Worktree**: Owns `test_e2e/` and verification runners.
- **Zero Mock Policy**: All features MUST query and mutate live Supabase PostgreSQL backend (`kxvoeqwelcmcvdfwxduu`).
- **Handoff Output**: Every subagent MUST write `<feature>/HANDOFF.md` upon completion.
