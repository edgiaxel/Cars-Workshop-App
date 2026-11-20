/// Standardized application exception hierarchy for PitMate v2.0.
sealed class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() =>
      'AppException(message: $message, code: $code, details: $details)';
}

/// Authentication and session errors.
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.details});
}

/// Authorization / Permission denied errors.
class PermissionDeniedException extends AppException {
  const PermissionDeniedException(super.message, {super.code, super.details});
}

/// Validation errors.
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.details});
}

/// Resource not found errors.
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code, super.details});
}

/// Network or remote service errors.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.details});
}

/// Database or transaction failure.
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.details});
}
