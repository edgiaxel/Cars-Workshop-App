import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../data/auth_repository.dart';
import '../../domain/user_profile.dart';
import '../../domain/user_role.dart';
import 'auth_state.dart';

/// Provider for [IAuthRepository].
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  try {
    return AuthRepository(sb.Supabase.instance.client);
  } catch (_) {
    return AuthRepository();
  }
});

/// Riverpod NotifierProvider managing authentication flow.
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Riverpod [Notifier] managing PitMate auth state.
class AuthNotifier extends Notifier<AuthState> {
  StreamSubscription<sb.AuthState>? _authSubscription;
  late IAuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _init();

    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    return const AuthInitial();
  }

  void _init() {
    _authSubscription?.cancel();
    _authSubscription = _repository.authStateChanges.listen((data) async {
      final session = data.session;
      final event = data.event;

      if (event == sb.AuthChangeEvent.signedOut || session == null) {
        state = const AuthUnauthenticated();
        return;
      }

      await checkAuthStatus();
    });

    // Initial session resolution
    Future.microtask(() => checkAuthStatus());
  }

  /// Verifies active session and loads the corresponding user profile.
  Future<void> checkAuthStatus() async {
    final result = await _repository.fetchCurrentUserProfile();
    result.when(
      success: (profile) {
        if (profile == null) {
          state = const AuthUnauthenticated();
        } else if (!profile.isEmailVerified && profile.role == UserRole.customer) {
          state = AuthUnverifiedCustomer(
            email: _repository.currentSessionUserEmail ?? '',
            userProfile: profile,
          );
        } else {
          state = AuthAuthenticated(profile);
        }
      },
      failure: (_) {
        state = const AuthUnauthenticated();
      },
    );
  }

  /// Sign in with email and password.
  Future<bool> signIn(String email, String password) async {
    state = const AuthLoading(message: 'Signing in...');
    final result = await _repository.signInWithPassword(email, password);
    return result.when(
      success: (profile) {
        if (!profile.isEmailVerified && profile.role == UserRole.customer) {
          state = AuthUnverifiedCustomer(email: email, userProfile: profile);
        } else {
          state = AuthAuthenticated(profile);
        }
        return true;
      },
      failure: (exception) {
        state = AuthError(exception.message, code: exception.code);
        return false;
      },
    );
  }

  /// Register new customer account.
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String customerType = 'individual',
    String? companyName,
  }) async {
    state = const AuthLoading(message: 'Creating account...');
    final result = await _repository.signUpWithPassword(
      email,
      password,
      fullName,
      phone,
      customerType,
      companyName,
    );
    return result.when(
      success: (profile) {
        if (!profile.isEmailVerified) {
          state = AuthUnverifiedCustomer(email: email, userProfile: profile);
        } else {
          state = AuthAuthenticated(profile);
        }
        return true;
      },
      failure: (exception) {
        state = AuthError(exception.message, code: exception.code);
        return false;
      },
    );
  }

  /// Verifies OTP code for user registration.
  Future<bool> verifyOtp(String email, String token) async {
    state = const AuthLoading(message: 'Verifying code...');
    final result = await _repository.verifyEmailOtp(email, token);
    return result.when(
      success: (profile) {
        state = AuthAuthenticated(profile.copyWith(isEmailVerified: true));
        return true;
      },
      failure: (exception) {
        state = AuthError(exception.message, code: exception.code);
        return false;
      },
    );
  }

  /// Requests a fresh OTP token.
  Future<bool> resendOtp(String email) async {
    final result = await _repository.resendOtp(email);
    return result.when(
      success: (_) => true,
      failure: (exception) {
        state = AuthError(exception.message, code: exception.code);
        return false;
      },
    );
  }

  /// Initiates password reset flow.
  Future<bool> sendPasswordReset(String email) async {
    state = const AuthLoading(message: 'Sending password reset email...');
    final result = await _repository.sendPasswordResetEmail(email);
    return result.when(
      success: (_) {
        state = const AuthUnauthenticated();
        return true;
      },
      failure: (exception) {
        state = AuthError(exception.message, code: exception.code);
        return false;
      },
    );
  }

  /// Finalizes password reset with token.
  Future<bool> resetPassword(
    String token,
    String newPassword, [
    String? email,
  ]) async {
    state = const AuthLoading(message: 'Resetting password...');
    final result = await _repository.resetPassword(token, newPassword, email);
    return result.when(
      success: (_) {
        state = const AuthUnauthenticated();
        return true;
      },
      failure: (exception) {
        state = AuthError(exception.message, code: exception.code);
        return false;
      },
    );
  }

  /// Signs out the current user session.
  Future<void> signOut() async {
    state = const AuthLoading(message: 'Signing out...');
    await _repository.signOut();
    state = const AuthUnauthenticated();
  }

  /// Clears error status back to unauthenticated.
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }

  /// Development demo role switcher (disabled in release builds).
  void switchDemoRole(UserRole role) {
    if (!kDebugMode) return;
    final demoProfile = UserProfile(
      id: 'demo-${role.name}-001',
      role: role,
      fullName: 'Demo ${role.displayName}',
      phoneNumber: '+6281234567890',
      isEmailVerified: true,
      createdAt: DateTime.now(),
    );
    state = AuthAuthenticated(demoProfile);
  }
}
