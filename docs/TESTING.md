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
