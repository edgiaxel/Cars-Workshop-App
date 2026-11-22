import '../../domain/user_profile.dart';

/// Sealed hierarchy representing the application authentication state.
sealed class AuthState {
  const AuthState();
}

/// Initial state before session check completes.
final class AuthInitial extends AuthState {
  const AuthInitial();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthInitial;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AuthInitial()';
}

/// Asynchronous operation in progress.
final class AuthLoading extends AuthState {
  final String? message;

  const AuthLoading({this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthLoading && other.message == message;

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => 'AuthLoading(message: $message)';
}

/// User has no active session.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuthUnauthenticated;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AuthUnauthenticated()';
}

/// Customer registered but has not yet verified email OTP.
final class AuthUnverifiedCustomer extends AuthState {
  final String email;
  final UserProfile? userProfile;

  const AuthUnverifiedCustomer({
    required this.email,
    this.userProfile,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUnverifiedCustomer &&
          other.email == email &&
          other.userProfile == userProfile;

  @override
  int get hashCode => Object.hash(runtimeType, email, userProfile);

  @override
  String toString() =>
      'AuthUnverifiedCustomer(email: $email, profile: $userProfile)';
}

/// User is authenticated and authorized with active profile.
final class AuthAuthenticated extends AuthState {
  final UserProfile userProfile;

  const AuthAuthenticated(this.userProfile);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAuthenticated && other.userProfile == userProfile;

  @override
  int get hashCode => Object.hash(runtimeType, userProfile);

  @override
  String toString() => 'AuthAuthenticated(profile: $userProfile)';
}

/// Authentication operation encountered an error.
final class AuthError extends AuthState {
  final String message;
  final String? code;

  const AuthError(this.message, {this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError &&
          other.message == message &&
          other.code == code;

  @override
  int get hashCode => Object.hash(runtimeType, message, code);

  @override
  String toString() => 'AuthError(message: $message, code: $code)';
}
