import '../../../data/models/user_profile.dart';
import '../../../data/models/user_role.dart';

/// Authentication state stages.
enum AuthStatus { initial, unauthenticated, loading, authenticated, error }

/// Lightweight session abstraction representing current auth and profile state.
class AuthSessionState {
  const AuthSessionState({
    required this.status,
    this.userId,
    this.email,
    this.profile,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? userId;
  final String? email;
  final UserProfile? profile;
  final String? errorMessage;

  bool get isInitial => status == AuthStatus.initial;
  bool get isLoading =>
      status == AuthStatus.loading || status == AuthStatus.initial;
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && profile != null;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get hasError => status == AuthStatus.error;

  UserRole? get role => profile?.role;
  bool get isAdmin => role == UserRole.admin;
  bool get isMechanic => role == UserRole.mechanic;
  bool get isCustomer => role == UserRole.customer;

  factory AuthSessionState.initial() =>
      const AuthSessionState(status: AuthStatus.initial);

  factory AuthSessionState.unauthenticated() =>
      const AuthSessionState(status: AuthStatus.unauthenticated);

  factory AuthSessionState.loading({String? email}) =>
      AuthSessionState(status: AuthStatus.loading, email: email);

  factory AuthSessionState.authenticated({
    required String userId,
    required String email,
    required UserProfile profile,
  }) {
    return AuthSessionState(
      status: AuthStatus.authenticated,
      userId: userId,
      email: email,
      profile: profile,
    );
  }

  factory AuthSessionState.error(String message) {
    return AuthSessionState(status: AuthStatus.error, errorMessage: message);
  }

  AuthSessionState copyWith({
    AuthStatus? status,
    String? userId,
    String? email,
    UserProfile? profile,
    String? errorMessage,
  }) {
    return AuthSessionState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
