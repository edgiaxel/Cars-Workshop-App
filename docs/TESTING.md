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

For milestone validation, the orchestrator verifies end-to-end user workflows against a running localhost Flutter Web build using the Playwright CLI (`npx -y playwright-cli`):

### 5.1 Local Server Startup
```bash
# Serve Flutter web build or debug server on port 8080
flutter run -d web-server --web-port=8080 --web-hostname=127.0.0.1
```

### 5.2 Playwright CLI End-to-End Test Workflow
```bash
# 1. Launch browser session
npx -y playwright-cli open http://127.0.0.1:8080

# 2. Inspect active UI snapshot
npx -y playwright-cli snapshot

# 3. Test Customer Booking
npx -y playwright-cli fill <ref_email> "customer@pitmate.com"
npx -y playwright-cli fill <ref_password> "password123"
npx -y playwright-cli click <ref_submit>
npx -y playwright-cli click <ref_book_service>

# 4. Test Admin Intake & Inspection Review
npx -y playwright-cli open http://127.0.0.1:8080
# Login as admin@pitmate.com
# Check in booking or register walk-in -> Service Order generated

# 5. Test Mechanic Inspection Workspace
# Login as mechanic@pitmate.com
# Fill findings, check completeness, submit diagnostic report

# 6. Test Customer Estimate Approval
# Login as customer@pitmate.com
# Review itemized charges -> Approve estimate

# 7. Capture visual proof & close
npx -y playwright-cli screenshot --filename=e2e_m2_exit.png
npx -y playwright-cli close
```

