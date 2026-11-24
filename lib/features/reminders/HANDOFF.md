# Feature Handoff: Maintenance Reminders (VS-22)

> **Feature Branch:** `feature/m6-reminders`  
> **Owned Directory:** `lib/features/reminders/`  
> **Status:** COMPLETE & VERIFIED  

---

## 1. Files Touched & Created
- `lib/features/reminders/models/maintenance_reminder.dart`: Domain entity for date and mileage maintenance reminders.
- `lib/features/reminders/data/reminder_repository.dart`: Live Supabase queries with joins, RPC `dismiss_maintenance_reminder`, and RPC `process_due_reminders`.
- `lib/features/reminders/presentation/customer_reminders_screen.dart`: Customer reminder list with countdowns, "Book Service" one-tap routing, and dismissal.
- `lib/features/reminders/presentation/admin_reminders_screen.dart`: Workshop administration queue with status filter chips and batch notification trigger.
- `test/unit/reminders/reminder_model_test.dart`: Serialization and copyWith tests.
- `test/widget/reminders/customer_reminders_screen_test.dart`: Customer reminder list and empty state verification.
- `test/widget/reminders/admin_reminders_screen_test.dart`: Admin queue, filtering, and process-due trigger verification.

## 2. Exported Entry Points
- `CustomerRemindersScreen` (`/customer/reminders`, index 6 in `customerNavItems`)
- `AdminRemindersScreen` (`/admin/reminders`, index 12 in `adminNavItems`)
- `MaintenanceReminder`
- `reminderRepositoryProvider`

## 3. Database & Schema Alignment
- Tables: `public.maintenance_reminders`
- RPCs: `generate_service_order_reminders`, `dismiss_maintenance_reminder`, `process_due_reminders`.
- Verified live on Supabase (`kxvoeqwelcmcvdfwxduu`) with zero mock data.

## 4. Verification Evidence
- `flutter analyze`: 0 issues found.
- `flutter test test/unit/reminders/ test/widget/reminders/`: All passing.
