# Feature Handoff: Profile Management (`/profile`)

> **Feature:** User Profile & Credential Management  
> **Status:** COMPLETE & VERIFIED  
> **Date:** 2026-11-24  

---

## 1. Files Touched
- `lib/features/profile/presentation/profile_screen.dart` (New screen)
- `test/widget/profile/profile_screen_test.dart` (New unit & widget test suite)
- `lib/app/router/route_paths.dart` (Added `RoutePaths.profile`)
- `lib/app/router/app_router.dart` (Wired `/profile` to `ProfileScreen`)
- `lib/shared/widgets/responsive_role_scaffold.dart` (Interactive avatar tap navigating to `/profile`)

## 2. Exported Entry Points
- Route: `/profile` (`RoutePaths.profile`)
- Widget: `ProfileScreen`
- Interactive Avatar:
  - Mobile App Bar: `InkWell` with key `'mobile_scaffold_avatar_button'`
  - Desktop Sidebar: `InkWell` with key `'desktop_scaffold_avatar_button'`

## 3. Database & Schema Connections (Zero Mocks)
- **Tables Modified / Queried**:
  - `public.profiles`: Fetches user identity, role, phone, and company; updates `full_name`, `phone_number`, `company_name`, `updated_at`.
  - `public.customers`: Synchronizes `full_name`, `phone_number`, `company_name` when the user has `role = 'customer'`.
  - Supabase Auth:
    - `Supabase.instance.client.auth.updateUser(UserAttributes(data: {...}))` for user metadata.
    - `Supabase.instance.client.auth.updateUser(UserAttributes(email: ...))` for email change with verification dispatch.
    - `Supabase.instance.client.auth.updateUser(UserAttributes(password: ...))` for password updates.

## 4. UI / Antislop & Responsive Rules
- No em dashes (`—`) in copy.
- High contrast, semantic colors (`AppColors.success`, `AppColors.warning`, `AppColors.danger`).
- Responsive `Wrap` layouts on all headers preventing `RenderFlex` overflow even on 320px mobile viewports.

## 5. Test Evidence
- `test/widget/profile/profile_screen_test.dart`: 3 tests passing.
