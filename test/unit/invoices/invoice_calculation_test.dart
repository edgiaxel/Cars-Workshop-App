import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/core/utils/currency_formatter.dart';
import 'package:pitmate/features/invoices/data/models/invoice_model.dart';

void main() {
  group('Invoicing & Financial Settlement Unit Tests', () {
    test('integer cents currency conversion maintains exact integer precision', () {
      // 1 IDR = 100 integer cents
      const idrAmount = 1500000; // Rp 1.500.000
      final cents = CurrencyFormatter.idrToCents(idrAmount);
      expect(cents, 150000000);
      expect(CurrencyFormatter.centsToIdr(cents), idrAmount);

      expect(CurrencyFormatter.idrToCents(0), 0);
      expect(CurrencyFormatter.centsToIdr(0), 0);
    });

    test('CurrencyFormatter.formatIdr formats currency according to Indonesian locale standard', () {
      expect(CurrencyFormatter.formatIdr(15000000), 'Rp 150.000');
      expect(CurrencyFormatter.formatIdr(349650000), 'Rp 3.496.500');
      expect(CurrencyFormatter.formatIdr(220000000), 'Rp 2.200.000');
      expect(CurrencyFormatter.formatIdr(0), 'Rp 0');
      expect(CurrencyFormatter.formatIdr(-15000000), '-Rp 150.000');
    });

    test('11% PPN tax calculation adheres strictly to Indonesian tax regulations', () {
      // 315,000,000 cents * 0.11 = 34,650,000 cents
      const taxableSubtotal = 315000000;
      final ppn = CurrencyFormatter.calculatePpn(taxableSubtotal);
      expect(ppn, 34650000);

      final modelTax = InvoiceModel.calculateTax(taxableSubtotal, 11.0);
      expect(modelTax, 34650000);

      // Edge cases
      expect(CurrencyFormatter.calculatePpn(0), 0);
      expect(CurrencyFormatter.calculatePpn(-5000), 0);
      expect(InvoiceModel.calculateTax(0), 0);
      expect(InvoiceModel.calculateTax(-1000), 0);

      // Small integer truncation check: 100 cents * 11% = 11 cents
      expect(CurrencyFormatter.calculatePpn(100), 11);
      expect(CurrencyFormatter.calculatePpn(99), 10); // 99 * 11 / 100 = 10.89 -> 10 integer division
    });

    test('taxable subtotal correctly applies discount before PPN tax', () {
      const laborCents = 150000000; // Rp 1.500.000
      const partsCents = 200000000; // Rp 2.000.000
      const discountCents = 50000000; // Rp 500.000 discount

      final taxable = InvoiceModel.calculateTaxableSubtotal(laborCents, partsCents, discountCents);
      expect(taxable, 300000000); // 350m - 50m = 300m

      // Discount exceeding subtotal clamps to 0
      final zeroTaxable = InvoiceModel.calculateTaxableSubtotal(5000, 5000, 20000);
      expect(zeroTaxable, 0);
    });

    test('grand total calculation accounts for labor, parts, discount, 11% tax, and insurance', () {
      const labor = 100000000; // Rp 1.000.000
      const parts = 200000000; // Rp 2.000.000
      const discount = 20000000; // Rp 200.000
      // Taxable = 280,000,000 cents (Rp 2.800.000)
      // 11% PPN = 30,800,000 cents (Rp 308.000)
      // Total before insurance = 310,800,000 cents (Rp 3.108.000)
      const insurance = 50000000; // Rp 500.000 insurance coverage

      final total = InvoiceModel.calculateGrandTotal(
        subtotalLaborCents: labor,
        subtotalPartsCents: parts,
        discountCents: discount,
        insuranceCoverageCents: insurance,
        taxPercent: 11.0,
      );

      expect(total, 260800000); // 310.8m - 50m = 260.8m (Rp 2.608.000)
    });

    test('outstanding balance calculation handles full, partial, and zero balances', () {
      const totalAmount = 349650000;

      // Unpaid
      expect(InvoiceModel.calculateOutstandingBalance(totalAmount, 0), 349650000);

      // Partially paid (e.g. Rp 1.000.000 deposit)
      expect(InvoiceModel.calculateOutstandingBalance(totalAmount, 100000000), 249650000);

      // Fully paid
      expect(InvoiceModel.calculateOutstandingBalance(totalAmount, 349650000), 0);

      // Overpayment clamps to 0
      expect(InvoiceModel.calculateOutstandingBalance(totalAmount, 400000000), 0);
    });

    test('cash change calculation computes accurate change and safeguards negative tenders', () {
      const dueCents = 349650000; // Rp 3.496.500

      // Exact cash tendered
      expect(InvoiceModel.calculateCashChange(349650000, dueCents), 0);

      // Rounded cash tendered: Rp 3.500.000 (350,000,000 cents)
      final change = InvoiceModel.calculateCashChange(350000000, dueCents);
      expect(change, 350000); // Rp 3.500 change
      expect(CurrencyFormatter.formatIdr(change), 'Rp 3.500');

      // Cash tendered less than due amount returns 0 change
      expect(InvoiceModel.calculateCashChange(300000000, dueCents), 0);
    });

    test('InvoiceItemModel serialization and deserialization roundtrip', () {
      final now = DateTime.now();
      final item = InvoiceItemModel(
        id: 'item-1',
        invoiceId: 'inv-1',
        itemType: InvoiceItemType.labor,
        description: 'Front Brake Overhaul',
        quantity: 2,
        unitPriceCents: 25000000,
        totalPriceCents: 50000000,
        partId: null,
        taskId: 'task-1',
        createdAt: now,
      );

      final json = item.toJson();
      expect(json['item_type'], 'labor');
      expect(json['quantity'], 2);
      expect(json['total_price_cents'], 50000000);

      final parsed = InvoiceItemModel.fromJson(json);
      expect(parsed.id, item.id);
      expect(parsed.itemType, InvoiceItemType.labor);
      expect(parsed.totalPriceCents, item.totalPriceCents);
    });

    test('PaymentModel serialization and deserialization roundtrip', () {
      final now = DateTime.now();
      final payment = PaymentModel(
        id: 'pay-1',
        paymentNumber: 'PAY-20261124-1001',
        invoiceId: 'inv-1',
        amountCents: 349650000,
        paymentMethod: PaymentMethod.qris,
        paymentStatus: PaymentStatus.completed,
        referenceNumber: 'QRIS-REF-9988',
        cashTenderedCents: null,
        changeGivenCents: 0,
        recordedBy: 'admin-1',
        createdAt: now,
      );

      final json = payment.toJson();
      expect(json['payment_method'], 'qris');
      expect(json['payment_status'], 'completed');
      expect(json['amount_cents'], 349650000);

      final parsed = PaymentModel.fromJson(json);
      expect(parsed.paymentNumber, payment.paymentNumber);
      expect(parsed.paymentMethod, PaymentMethod.qris);
      expect(parsed.amountCents, payment.amountCents);
    });

    test('InvoiceModel parses joined tables and computes derived telemetry', () {
      final now = DateTime.now();
      final rawDbRow = {
        'id': 'inv-uuid-1',
        'invoice_number': 'INV-20261124-0042',
        'service_order_id': 'order-uuid-1',
        'customer_id': 'cust-uuid-1',
        'status': 'issued',
        'subtotal_labor_cents': 150000000,
        'subtotal_parts_cents': 200000000,
        'tax_percent': 11.00,
        'tax_amount_cents': 38500000,
        'discount_cents': 0,
        'deposit_applied_cents': 50000000,
        'insurance_coverage_cents': 0,
        'total_amount_cents': 388500000,
        'amount_paid_cents': 50000000,
        'outstanding_balance_cents': 338500000,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'customers': {
          'id': 'cust-uuid-1',
          'full_name': 'Alex Pratama',
          'phone_number': '+62 812-3456-7890',
        },
        'service_orders': {
          'id': 'order-uuid-1',
          'order_number': 'SO-202611-0001',
          'vehicles': {
            'license_plate': 'B 5678 CIV',
            'make': 'Honda',
            'model': 'Civic Type R (FL5)',
          },
        },
        'invoice_items': [
          {
            'id': 'item-1',
            'invoice_id': 'inv-uuid-1',
            'item_type': 'labor',
            'description': 'Inspection & Overhaul',
            'quantity': 1,
            'unit_price_cents': 150000000,
            'total_price_cents': 150000000,
          },
        ],
      };

      final invoice = InvoiceModel.fromJson(rawDbRow);

      expect(invoice.invoiceNumber, 'INV-20261124-0042');
      expect(invoice.customerName, 'Alex Pratama');
      expect(invoice.customerPhone, '+62 812-3456-7890');
      expect(invoice.orderNumber, 'SO-202611-0001');
      expect(invoice.vehiclePlate, 'B 5678 CIV');
      expect(invoice.vehicleModel, 'Honda Civic Type R (FL5)');
      expect(invoice.items.length, 1);
      expect(invoice.subtotalCents, 350000000);
      expect(invoice.formattedTotal, 'Rp 3.885.000');
      expect(invoice.formattedOutstanding, 'Rp 3.385.000');
      expect(invoice.isPaid, false);
      expect(invoice.isPartiallyPaid, true);
    });
  });
}
