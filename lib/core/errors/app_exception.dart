/// Base exception hierarchy for PitMate domain and data errors.
sealed class AppException implements Exception {
  final String message;
  final String? code;
  final Object? originalException;

  const AppException(
    this.message, {
    this.code,
    this.originalException,
  });

  @override
  String toString() => '$runtimeType: $message${code != null ? ' (code: $code)' : ''}';
}

/// Authentication and authorization errors.
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.originalException,
  });
}

/// Input or domain model validation errors.
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.code,
    super.originalException,
  });
}

/// Network connectivity, timeout, or server communication errors.
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalException,
  });
}

/// Entity or resource not found.
class NotFoundException extends AppException {
  const NotFoundException(
    super.message, {
    super.code,
    super.originalException,
  });
}

/// Database and persistence errors.
class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.code,
    super.originalException,
  });
}
