/// Standardized currency formatting utility for PitMate.
///
/// Stores and calculates all monetary values in integer cents (minor currency units)
/// to avoid floating-point rounding errors, conforming to PostgreSQL BIGINT precision.
class CurrencyFormatter {
  const CurrencyFormatter._();

  /// Formats integer cents into Indonesian Rupiah display format.
  /// Example: 15000000 cents -> "Rp 150.000"
  /// Example: 349650000 cents -> "Rp 3.496.500"
  static String formatIdr(int cents) {
    final rupiah = (cents / 100).round();
    final isNegative = rupiah < 0;
    final absStr = rupiah.abs().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < absStr.length; i++) {
      if (i > 0 && (absStr.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(absStr[i]);
    }

    final formatted = buffer.toString();
    return isNegative ? '-Rp $formatted' : 'Rp $formatted';
  }

  /// Converts rupiah integer amount (e.g. 150000) to integer cents (15000000).
  static int idrToCents(int rupiah) => rupiah * 100;

  /// Converts integer cents (15000000) to rupiah integer amount (150000).
  static int centsToIdr(int cents) => (cents / 100).round();

  /// Computes 11% PPN tax from taxable subtotal in integer cents.
  static int calculatePpn(int taxableSubtotalCents) {
    if (taxableSubtotalCents <= 0) return 0;
    return (taxableSubtotalCents * 11) ~/ 100;
  }
}
