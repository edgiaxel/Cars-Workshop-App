import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/data/models/user_profile.dart';
import 'package:pitmate/data/models/user_role.dart';
import 'package:pitmate/features/auth/domain/auth_session_state.dart';

void main() {
  group('AuthSessionState tests', () {
    test('initial factory sets initial state', () {
      final state = AuthSessionState.initial();
      expect(state.status, AuthStatus.initial);
      expect(state.isInitial, isTrue);
      expect(state.isLoading, isTrue);
      expect(state.isAuthenticated, isFalse);
      expect(state.profile, isNull);
      expect(state.errorMessage, isNull);
    });

    test('unauthenticated factory sets unauthenticated state', () {
      final state = AuthSessionState.unauthenticated();
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.isUnauthenticated, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isAuthenticated, isFalse);
    });

    test('loading factory sets loading state', () {
      final state = AuthSessionState.loading(email: 'user@pitmate.co');
      expect(state.status, AuthStatus.loading);
      expect(state.isLoading, isTrue);
      expect(state.email, 'user@pitmate.co');
      expect(state.isAuthenticated, isFalse);
    });

    test('authenticated factory sets authenticated state and role getters', () {
      final profile = UserProfile(
        id: 'usr_1',
        fullName: 'Admin User',
        role: UserRole.admin,
      );

      final state = AuthSessionState.authenticated(
        userId: 'usr_1',
        email: 'admin@pitmate.local',
        profile: profile,
      );

      expect(state.status, AuthStatus.authenticated);
      expect(state.isAuthenticated, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.userId, 'usr_1');
      expect(state.email, 'admin@pitmate.local');
      expect(state.role, UserRole.admin);
      expect(state.isAdmin, isTrue);
      expect(state.isMechanic, isFalse);
      expect(state.isCustomer, isFalse);
    });

    test('error factory sets error status and message', () {
      final state = AuthSessionState.error('Network failure');
      expect(state.status, AuthStatus.error);
      expect(state.hasError, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, 'Network failure');
    });

    test('copyWith updates state selectively', () {
      final original = AuthSessionState.unauthenticated();
      final updated = original.copyWith(
        status: AuthStatus.authenticated,
        userId: 'u-123',
        errorMessage: 'temp warning',
      );

      expect(updated.status, AuthStatus.authenticated);
      expect(updated.userId, 'u-123');
      expect(updated.errorMessage, 'temp warning');
      expect(updated.email, isNull);
    });
  });
}
