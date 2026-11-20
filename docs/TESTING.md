# PitMate — Testing Specification & Procedures

> **Document:** TESTING.md  
> **Status:** Approved — 2026-11-20  
> **Version:** 2.0  
> **Last updated:** 2026-11-20  
> **Related:** ARCHITECTURE.md, AGENTS.md, MILESTONE.md  

---

# 1. Testing Philosophy & Objectives

The primary objective of automated testing in PitMate is to guarantee business correctness, data integrity, and role security across the automotive workshop lifecycle.
Cosmetic tests are secondary to reliable verification of:
1. Workshop state transitions (Intake → Inspection → Estimate → Dispatch → Repair → QC → Billing → Handover).
2. Financial calculations (preventing monetary discrepancies or floating-point rounding errors).
3. Inventory balance invariants (guaranteeing physical stock matches the movement ledger).
4. Role-based access control and Row Level Security boundaries.
5. Multi-device responsiveness and error boundary recovery.

---

# 2. Test Pyramid & Distribution

```text
               ▲
              / \
             /E2E\             Integration / E2E Tests (10%)
            /-----\            - Complete workshop lifecycles
           / Widget\           - Realtime multi-client updates
          /  Tests  \          Widget Tests (30%)
         /-----------\         - Role shells, navigation, input forms
        /    Unit     \        - Status badges, responsive cards, themes
       /     Tests     \       Unit Tests (60%)
      /                 \      - Business calculations, models, state providers
     ---------------------     - Status transitions, inventory reconciliation
```

---

# 3. Test Categories and Guidelines

## 3.1 Unit Tests (`test/unit/`)

Unit tests verify standalone logic without launching the Flutter widget tree or communicating over live network sockets.

### Focus Areas
- **Model Serialization**: JSON deserialization and serialization round-trip fidelity for all domain models.
- **Business Math**:
  - Labor + parts totals calculation.
  - Tax computation (exact integer minor units).
  - Discount applications.
  - Cash change computation.
  - Mechanic split commission calculations.
- **State Transitions**:
  - Valid vs invalid status transition guards (e.g. cannot transition directly from `intake` to `invoiced`).
  - Prerequisite operation dependencies.
- **Inventory Ledger Invariants**:
  - Available stock calculation (`quantity_on_hand - quantity_reserved`).
  - Rejection of negative stock transactions.
- **Riverpod State Providers**:
  - State notifier transitions under mocked repository responses.
  - AsyncValue loading, data, and error state transitions.

---

## 3.2 Widget Tests (`test/widget/`)

Widget tests verify presentation widgets, user interaction, form validation, and responsiveness.

### Focus Areas
- **Role Shells**:
  - Navigation items render correctly according to active role (Admin vs Mechanic vs Customer).
- **Forms and Input Validation**:
  - Vehicle registration form checks (valid license plate, year range).
  - Booking creation checks.
  - Payment entry validation (received amount >= payable amount).
- **Theme and Design Tokens**:
  - Dark and Light theme rendering.
  - Contrast ratios and status color badges (`StatusBadge`).
- **State Representation**:
  - Empty states when lists have 0 records.
  - Error cards with retry callbacks when an exception occurs.
  - Progress loaders during async fetch operations.

---

## 3.3 Integration Tests (`test/integration/` and `integration_test/`)

Integration tests verify multi-component interactions, Supabase database contracts, RPC functions, and end-to-end flows.

### Focus Areas
- **Supabase Authentication**:
  - Sign in with email and password.
  - Profile retrieval on session start.
  - Sign out and session cleanup.
- **Row Level Security (RLS)**:
  - Verify customer cannot query administrative financial tables.
  - Verify mechanic cannot edit customer profile or billing line items.
  - Verify admin has operational access.
- **Atomic Database Workflows**:
  - `check_in_booking`: Creates service order and updates booking state atomically.
  - `record_payment`: Records payment and closes invoice if fully settled.
  - `consume_service_parts`: Deducts stock and logs ledger entry in one transaction.

---

# 4. Directory Structure

```text
test/
├── unit/
│   ├── app_config_test.dart
│   ├── auth_session_state_test.dart
│   ├── business_math_test.dart
│   ├── crud_models_test.dart
│   ├── inventory_ledger_test.dart
│   ├── route_guard_test.dart
│   └── workshop_state_machine_test.dart
│
├── widget/
│   ├── app_launch_test.dart
│   ├── login_page_test.dart
│   ├── role_navigation_test.dart
│   ├── status_badge_test.dart
│   └── empty_state_test.dart
│
├── integration/
│   ├── supabase_smoke_test.dart
│   └── rls_security_test.dart
│
├── helpers/
│   ├── fake_repositories.dart
│   └── test_providers.dart
│
└── fixtures/
    ├── booking_fixtures.json
    └── service_order_fixtures.json
```

---

# 5. Verification Commands

All changes must pass static analysis and automated test suites before being merged:

```bash
# 1. Static Analysis
flutter analyze

# 2. Unit and Widget Tests
flutter test

# 3. Integration Tests
flutter test integration_test

# 4. Build Verifications
flutter build apk --debug
flutter build web
```

---

# 6. Definition of Done for Testing

A test suite is acceptable only when:
- Zero analyzer warnings or errors exist (`flutter analyze` returns clean).
- All tests execute deterministically without flaky timing dependencies.
- Negative tests and boundary edge cases (null inputs, zero quantities, network failures) are explicitly covered.
- Test outcomes are reported honestly with exact test run outputs.
