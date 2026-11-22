import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/estimates/data/models/estimate_item_model.dart';
import 'package:pitmate/features/estimates/data/models/estimate_model.dart';

void main() {
  group('Estimate Monetary & Calculation Tests', () {
    test('money in cents integer precision representation', () {
      // 1 IDR = 100 cents
      const idrAmount = 2200000; // Rp 2.200.000
      final cents = EstimateModel.idrToCents(idrAmount);
      expect(cents, 220000000);
      expect(EstimateModel.centsToIdr(cents), idrAmount);
    });

    test('11% PPN tax calculation accurately calculates integer cents', () {
      // Subtotal: 315,000,000 cents (Rp 3.150.000)
      // 11% PPN: 315,000,000 * 0.11 = 34,650,000 cents (Rp 346.500)
      const subtotalCents = 315000000;
      final tax = EstimateModel.calculateTax(subtotalCents);
      expect(tax, 34650000);

      // Edge cases: 0 subtotal, negative subtotal
      expect(EstimateModel.calculateTax(0), 0);
      expect(EstimateModel.calculateTax(-1000), 0);

      // Rounding check
      expect(EstimateModel.calculateTax(100), 11);
      expect(EstimateModel.calculateTax(99), 11);
      expect(EstimateModel.calculateTax(90), 10);
    });

    test('grand total calculation accounts for subtotal, 11% tax, and discount', () {
      const subtotal = 315000000;
      const tax = 34650000;
      const discount = 15000000; // Rp 150.000 discount

      final total = EstimateModel.calculateGrandTotal(subtotal, tax, discount);
      expect(total, 334650000);

      // With zero discount
      expect(EstimateModel.calculateGrandTotal(subtotal, tax, 0), 349650000);

      // Discount exceeding subtotal + tax does not become negative
      expect(EstimateModel.calculateGrandTotal(100, 11, 200), 0);
    });

    test('calculateSubtotalFromItems sums line totals correctly', () {
      final items = [
        EstimateItemModel.create(
          description: 'Honda OEM Brembo Front Brake Pad Set (FL5)',
          quantity: 1,
          unitPriceCents: 220000000,
        ),
        EstimateItemModel.create(
          description: 'Motul RBF 660 High-Temp Racing Brake Fluid (500ml)',
          quantity: 2,
          unitPriceCents: 22500000,
        ),
        EstimateItemModel.create(
          description: 'Front Brake Overhaul & Precision Bleeding Service',
          quantity: 1,
          unitPriceCents: 50000000,
        ),
      ];

      expect(items[0].totalPriceCents, 220000000);
      expect(items[1].totalPriceCents, 45000000);
      expect(items[2].totalPriceCents, 50000000);

      final subtotal = EstimateModel.calculateSubtotalFromItems(items);
      expect(subtotal, 315000000);

      final tax = EstimateModel.calculateTax(subtotal);
      expect(tax, 34650000);

      final grandTotal = EstimateModel.calculateGrandTotal(subtotal, tax, 0);
      expect(grandTotal, 349650000);
    });

    test('formatIdr formats currency with Indonesian dot separators', () {
      expect(EstimateModel.formatIdr(349650000), 'Rp 3.496.500');
      expect(EstimateModel.formatIdr(315000000), 'Rp 3.150.000');
      expect(EstimateModel.formatIdr(34650000), 'Rp 346.500');
      expect(EstimateModel.formatIdr(220000000), 'Rp 2.200.000');
      expect(EstimateModel.formatIdr(45000000), 'Rp 450.000');
      expect(EstimateModel.formatIdr(50000000), 'Rp 500.000');
      expect(EstimateModel.formatIdr(0), 'Rp 0');
      expect(EstimateModel.formatIdr(-15000000), '-Rp 150.000');
    });

    test('reconciles with M2 seed specification values', () {
      // Seed values:
      // Subtotal = 315,000,000 cents
      // Tax = 34,650,000 cents
      // Total = 349,650,000 cents
      const seedSubtotal = 315000000;
      const seedTax = 34650000;
      const seedTotal = 349650000;

      final calculatedTax = EstimateModel.calculateTax(seedSubtotal);
      final calculatedTotal = EstimateModel.calculateGrandTotal(seedSubtotal, calculatedTax, 0);

      expect(calculatedTax, equals(seedTax));
      expect(calculatedTotal, equals(seedTotal));
      expect(EstimateModel.formatIdr(calculatedTotal), equals('Rp 3.496.500'));
    });
  });
}
