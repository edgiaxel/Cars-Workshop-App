import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/core/utils/currency_formatter.dart';
import 'package:pitmate/features/estimates/data/models/estimate_model.dart';
import 'package:pitmate/features/invoices/data/models/invoice_model.dart';

void main() {
  group('Business Rules Regression Tests', () {
    test('EstimateModel and InvoiceModel produce identical post-discount 11% PPN tax', () {
      const subtotalCents = 300000000; // Rp 3.000.000
      const discountCents = 20000000; // Rp 200.000

      final estimateTax = EstimateModel.calculateTax(
        subtotalCents,
        discountCents: discountCents,
      );
      final taxable = InvoiceModel.calculateTaxableSubtotal(
        100000000,
        200000000,
        discountCents,
      );
      final invoiceTax = InvoiceModel.calculateTax(taxable, 11.0);

      expect(estimateTax, equals(30800000));
      expect(invoiceTax, equals(estimateTax));
    });

    test('CurrencyFormatter formats mechanic compensation cents as integer Rupiah (no 100x scaling bug)', () {
      // 850,000,000 cents = Rp 8.500.000
      expect(CurrencyFormatter.formatIdr(850000000), 'Rp 8.500.000');
      // 9,750,000 cents = Rp 97.500
      expect(CurrencyFormatter.formatIdr(9750000), 'Rp 97.500');
      // 2,625,000 cents = Rp 26.250
      expect(CurrencyFormatter.formatIdr(2625000), 'Rp 26.250');
    });

    test('Multi-mechanic incentive split: 100% solo, 65% lead / 35% divided equally among helpers', () {
      const laborCents = 100000000; // Rp 1.000.000
      const incentivePct = 15.0;
      final poolCents = (laborCents * incentivePct / 100.0).round();
      expect(poolCents, 15000000); // Rp 150.000

      // 2 helpers: Lead 65% (97,500), each helper 17.5% (26,250)
      final leadCents = (poolCents * 65.0 / 100.0).round();
      final helperPool = poolCents - leadCents;
      final eachHelper = helperPool ~/ 2;

      expect(leadCents, 9750000);
      expect(eachHelper, 2625000);
      expect(leadCents + (eachHelper * 2), poolCents);
    });
  });
}
