# Feature Handoff: Customer Service Tracking (VS-21)

> **Feature Branch:** `feature/m6-customer-tracking`  
> **Owned Directory:** `lib/features/customer_tracking/`  
> **Status:** COMPLETE & VERIFIED  

---

## 1. Files Touched & Created
- `lib/features/customer_tracking/models/customer_tracking_model.dart`: Entities for TrackingTimelineStage, TrackingTaskItem, TrackingFindingItem, CustomerTrackingSummary.
- `lib/features/customer_tracking/data/customer_tracking_repository.dart`: Queries Supabase RPC `get_customer_service_tracking` and customer ID lookup.
- `lib/features/customer_tracking/presentation/customer_tracking_screen.dart`: Complete customer tracking experience with vehicle telemetry header, 8-stage progress tracker, tasks card, findings card, and estimate/payment action buttons.
- `test/unit/customer_tracking/customer_tracking_model_test.dart`: Unit tests for sanitized parsing.
- `test/widget/customer_tracking/customer_tracking_screen_test.dart`: Widget tests verifying empty state, active order timeline, and actions.

## 2. Exported Entry Points
- `CustomerTrackingScreen` (`/customer/tracking`, index 5 in `customerNavItems`)
- `CustomerTrackingSummary`
- `customerTrackingRepositoryProvider`

## 3. Database & Schema Alignment
- RPC: `public.get_customer_service_tracking(p_customer_id, p_order_id)`.
- RLS: Verified live on Supabase. Customers only access their own vehicles' sanitized data with zero internal labor rates or mechanic earnings leaked.

## 4. Verification Evidence
- `flutter analyze`: 0 issues found.
- `flutter test test/unit/customer_tracking/ test/widget/customer_tracking/`: All passing.
