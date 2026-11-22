import '../errors/app_exception.dart';

/// A value that represents either a success ([Success]) or a failure ([Failure]).
sealed class Result<T> {
  const Result();

  /// Creates a successful [Result] containing [data].
  const factory Result.success(T data) = Success<T>;

  /// Creates a failed [Result] containing an [exception].
  const factory Result.failure(AppException exception) = Failure<T>;

  /// Returns true if this instance represents a successful outcome.
  bool get isSuccess => this is Success<T>;

  /// Returns true if this instance represents a failure outcome.
  bool get isFailure => this is Failure<T>;

  /// Returns the underlying data if successful, or null otherwise.
  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => null,
      };

  /// Returns the underlying exception if failed, or null otherwise.
  AppException? get exceptionOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final exception) => exception,
      };

  /// Pattern-matches over the outcome.
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException exception) failure,
  }) {
    return switch (this) {
      Success<T>(:final data) => success(data),
      Failure<T>(:final exception) => failure(exception),
    };
  }

  /// Maps the success value using [transform].
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success<T>(:final data) => Result.success(transform(data)),
      Failure<T>(:final exception) => Result.failure(exception),
    };
  }
}

/// Successful result holding [data].
final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// Failed result holding an [exception].
final class Failure<T> extends Result<T> {
  final AppException exception;

  const Failure(this.exception);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          exception == other.exception;

  @override
  int get hashCode => exception.hashCode;

  @override
  String toString() => 'Failure($exception)';
}
