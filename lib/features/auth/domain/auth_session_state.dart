import '../../../shared/models/user_profile.dart';
import '../../../shared/models/user_role.dart';

/// State representing user session and authentication status.
class AuthSessionState {
  final UserProfile? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthSessionState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;
  UserRole get role => user?.role ?? UserRole.customer;

  AuthSessionState copyWith({
    UserProfile? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthSessionState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
