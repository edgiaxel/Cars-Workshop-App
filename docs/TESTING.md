# PitMate — Testing Specification & Procedures

> **Document:** TESTING.md  
> **Status:** Active — Clean Slate  
> **Version:** 2.0  
> **Related:** AGENTS.md, ARCHITECTURE.md, MILESTONE.md  

---

# 1. Testing Philosophy

Automated testing in PitMate protects business logic, data integrity, and role-based security:

1. **State Transitions**: Workflow transitions (Intake → Inspection → Estimate → Dispatch → Repair → QC → Invoiced → Paid → Handover) must be strictly validated.
2. **Financial Precision**: Money calculations, taxes, deposits, and invoice line items must prevent rounding discrepancy.
3. **Inventory Consistency**: Stock balances must always reconcile with the movement ledger.
4. **Security & RLS Boundaries**: Role restrictions (Admin, Mechanic, Customer) must be tested on both client routes and backend queries.

---

# 2. Test Structure

```text
test/
├── unit/            # Business models, calculations, state notifiers
├── widget/          # UI components, forms, role shells, theme rendering
└── integration/     # End-to-end user workflows and Supabase operations
```

---

# 3. Verification Commands

Run static analysis:
```bash
flutter analyze
```

Run test suite:
```bash
flutter test
```

Build verification:
```bash
flutter build web --release
flutter build apk --debug
```

---

# 4. Definition of Done for Tests

- Every new model or business logic module must include unit tests.
- Reusable UI components and role shells must include widget tests covering loading, error, and content states.
- All tests must pass cleanly before milestone completion.

---

# 5. Playwright CLI Localhost Web E2E Verification

For milestone validation, the orchestrator verifies end-to-end user workflows against a running localhost Flutter Web build using the Playwright CLI and automated node scripts (`test_e2e/m7_playwright_test.js`):

### 5.1 Local Server Startup
```bash
# Serve Flutter web release build on port 3000
python3 -m http.server 3000 --directory build/web
```

### 5.2 Responsive Viewport Verification Matrix

All screens are validated across the following viewports with zero horizontal scroll (`scrollWidth == clientWidth`) and zero `RenderFlex` overflow:

| Viewport Category | Width x Height | Status | Notes |
|---|---|---|---|
| Compact Mobile | 320px x 640px | **PASSED** | Minimum width (iPhone SE / compact devices). Bottom bar capped at 4 items. |
| Standard Mobile | 375px x 667px | **PASSED** | Standard mobile portrait. Zero overflow on headers and cards. |
| Large Mobile | 425px x 800px | **PASSED** | Large mobile portrait. Cards stack responsively. |
| Tablet | 768px x 1024px | **PASSED** | Tablet portrait. Top navigation bar with drawer access. |
| Desktop | 1280px x 800px | **PASSED** | Desktop layout. Persistent role sidebar and multi-column grid. |

### 5.3 Automated E2E Test Suite Execution
```bash
node test_e2e/m7_playwright_test.js
```

Verified scenarios:
1. **Multi-Viewport Responsive Check:** Renders `/login` on 320px, 375px, 425px, 768px, 1280px without overflow.
2. **PKCE Password Recovery Interception:** Navigates to `http://127.0.0.1:3000/?code=64aa01ae-06bd-4afe-9f53-f0d4229e8319` and verifies automated redirection to `#/reset-password?code=...`.
3. **Forgot Password Screen:** Verifies email submission flow and confirmation notice.
4. **Registration Flow:** Validates registration form inputs and customer onboarding.
5. **Universal Profile Screen (`/profile`):** Verified on both mobile (320px) and desktop (1280px). Confirms presence of Avatar, Name, Email, Phone, Role badge, Verification status, Password change form.
6. **Role Shells & Mobile Bottom Nav:**
   - Admin shell on 320px: bottom nav capped at 4 items (Overview, Floor, Bookings, Invoices).
   - Customer shell on 320px: bottom nav capped at 4 items (Garage, Book Service, Tracking, Invoices).
   - Mechanic shell on 320px: bottom nav capped at 4 items (My Work, Workspace, Inspection, Earnings).
   - Drawer verified for secondary views.

