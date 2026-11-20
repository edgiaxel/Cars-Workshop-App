/// Standard application exception representation adhering to ARCHITECTURE.md.
class AppException implements Exception {
  const AppException({required this.message, this.technicalDetails, this.code});

  final String message;
  final String? technicalDetails;
  final String? code;

  @override
  String toString() => 'AppException(message: $message, code: $code)';
}
