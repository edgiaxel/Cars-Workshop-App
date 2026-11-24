# Feature Handoff: Auth PKCE Link Recovery & Reset Password

> **Feature:** Supabase Auth Recovery Link & Password Reset (`/reset-password`)  
> **Status:** COMPLETE & VERIFIED  
> **Date:** 2026-11-24  

---

## 1. Files Touched
- `lib/features/auth/presentation/screens/reset_password_screen.dart` (New screen)
- `test/widget/auth/reset_password_screen_test.dart` (New widget test suite)
- `lib/app/router/route_paths.dart` (Added `RoutePaths.resetPassword`)
- `lib/app/router/app_router.dart` (Intercepts `?code=` query param on landing and forwards to `/reset-password?code=...`)
- `lib/features/auth/presentation/screens/forgot_password_screen.dart` (Updated user copy to clarify link dispatch)

## 2. Mechanism & Workaround
- **Issue**: Supabase sends password recovery emails as HTTP links (`http://127.0.0.1:3000/?code=...`) rather than 6-digit OTP codes.
- **Resolution**:
  - `AppRouter` intercepts any URL query parameter `?code=<uuid>` on root landing and redirects to `/reset-password?code=<uuid>`.
  - `ResetPasswordScreen` calls `Supabase.instance.client.auth.exchangeCodeForSession(code)` on mount.
  - User submits new password, which calls `Supabase.instance.client.auth.updateUser(UserAttributes(password: newPassword))` to finalize credential restoration.

## 3. Test Evidence
- `test/widget/auth/reset_password_screen_test.dart`: 2 tests passing.
