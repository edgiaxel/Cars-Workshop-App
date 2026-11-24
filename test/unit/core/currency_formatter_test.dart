import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('formatIdr formats positive integer cents correctly', () {
      expect(CurrencyFormatter.formatIdr(0), 'Rp 0');
      expect(CurrencyFormatter.formatIdr(15000000), 'Rp 150.000');
      expect(CurrencyFormatter.formatIdr(349650000), 'Rp 3.496.500');
      expect(CurrencyFormatter.formatIdr(1000000000), 'Rp 10.000.000');
    });

    test('formatIdr formats negative integer cents with leading minus', () {
      expect(CurrencyFormatter.formatIdr(-5000000), '-Rp 50.000');
    });

    test('idrToCents and centsToIdr convert accurately', () {
      expect(CurrencyFormatter.idrToCents(150000), 15000000);
      expect(CurrencyFormatter.centsToIdr(15000000), 150000);
    });

    test('calculatePpn calculates 11 percent integer tax correctly', () {
      expect(CurrencyFormatter.calculatePpn(10000000), 1100000);
      expect(CurrencyFormatter.calculatePpn(0), 0);
      expect(CurrencyFormatter.calculatePpn(-1000), 0);
    });
  });
}
