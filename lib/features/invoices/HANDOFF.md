# PitMate Feature Handoff: Invoices & Financial Settlement (Milestone M5)

> **Feature Domain:** Invoicing & Financial Settlement (F-015)  
> **Status:** Implementation Complete & Verified  
> **Date:** 2026-11-24  
> **Branch:** `feature/m5-invoices`  
> **Working Directory:** `/home/axel/Development/FlutterProjects/cars_workshop_invoices`

---

## 1. Scope & Isolation Boundaries
- Strict ownership maintained under:
  - `lib/features/invoices/`
  - `test/unit/invoices/`
  - `test/widget/invoices/`
- Zero modification to shared router, theme, or navigation files.
- Zero mock data in production code: queries and RPCs connect to real Supabase tables (`public.invoices`, `public.invoice_items`, `public.payments`, `public.service_orders`) and database functions (`generate_service_order_invoice`, `record_invoice_payment`).

---

## 2. Implemented Components & Entry Points

### Data Layer (`lib/features/invoices/data/`)
- **`models/invoice_model.dart`**:
  - `InvoiceStatus` enum (`draft`, `issued`, `partially_paid`, `paid`, `cancelled`)
  - `InvoiceItemType` enum (`labor`, `part`, `fee`, `discount`)
  - `PaymentMethod` enum (`cash`, `qris`, `card`, `bank_transfer`)
  - `PaymentStatus` enum (`completed`, `pending`, `failed`, `refunded`)
  - `InvoiceModel`, `InvoiceItemModel`, `PaymentModel` with strict integer cents precision, PostgreSQL BIGINT alignment, 11% PPN tax calculations, cash change calculators, and full JSON serialization/deserialization.
- **`repositories/invoice_repository.dart`**:
  - `IInvoiceRepository` contract & `InvoiceRepository` implementation using `SupabaseClient`.
  - Live query: `fetchInvoices({String? customerId, InvoiceStatus? statusFilter})` with joined `invoice_items`, `payments`, `service_orders`, and `customers`.
  - Live query: `fetchInvoiceById(invoiceId)`, `fetchInvoiceByOrderId(orderId)`, `fetchInvoiceItems(invoiceId)`, `fetchInvoicePayments(invoiceId)`.
  - RPC mutation: `generateInvoice(...)` calling `public.generate_service_order_invoice`.
  - RPC mutation: `recordPayment(...)` calling `public.record_invoice_payment`.
  - Query: `fetchEligibleServiceOrdersForInvoice()`.
  - Provider: `invoiceRepositoryProvider`.

### Presentation Layer (`lib/features/invoices/presentation/`)
- **`admin_invoices_screen.dart`**:
  - Uses `ResponsiveRoleScaffold` with `RoleNavigation.adminNavItems` (`currentIndex: 9`).
  - Metrics overview: Settled Revenue, Outstanding Balance, 11% PPN Tax Collected, Total Invoices.
  - Tab filters: All Invoices, Issued & Unpaid, Paid & Settled with live text search.
  - Parts and labor financial breakdown cards.
  - Interactive "Generate Invoice" modal allowing service order selection, PPN tax, discount, deposit, and insurance adjustments.
  - "Record Payment" modal with multi-channel support (Cash, QRIS, Card, Bank VA) and live cash change calculator.
  - Official high-contrast motorsport digital receipt modal.
- **`customer_invoices_screen.dart`**:
  - Uses `ResponsiveRoleScaffold` with `RoleNavigation.customerNavItems` (`currentIndex: 4`).
  - Outstanding balance due banner with quick "Pay Now" trigger.
  - Tabbed segmentation: Pending Settlement vs Settled History.
  - Simulated 1-click settlement sheet with QRIS dynamic code, saved card, and virtual account channels.
  - Electronic tax invoice details and receipt dialog.

---

## 3. Test Coverage

### Unit Tests (`test/unit/invoices/`)
- **`invoice_calculation_test.dart`**:
  - Integer cents currency conversion precision.
  - `CurrencyFormatter.formatIdr` Indonesian locale compliance.
  - Standard 11% PPN calculation.
  - Taxable subtotal discount deduction.
  - Grand total formula with labor, parts, discount, 11% tax, and insurance deductions.
  - Outstanding balance computation.
  - Cash change calculation with safeguards against negative tenders.
  - Model serialization and deserialization roundtrips.

### Widget Tests (`test/widget/invoices/`)
- **`admin_invoices_screen_test.dart`**:
  - Header, metrics overview, and filter tabs rendering.
  - Invoice card data binding (customer, vehicle, labor, parts, tax, balance).
  - Filter tab switching (All vs Issued vs Paid).
  - Itemized breakdown bottom sheet display.
  - Payment settlement dialog and cash change calculator interaction.
  - Digital receipt dialog with tax header and status stamp.
- **`customer_invoices_screen_test.dart`**:
  - Outstanding balance banner rendering.
  - Invoice card and action buttons.
  - Simulated 1-click payment sheet with payment channel switching.

---

## 4. Verification Commands
```bash
flutter analyze
flutter test test/unit/invoices test/widget/invoices
```
