import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/auth/domain/auth_session_state.dart';
import 'supabase_provider.dart';

/// Provider for [AuthRemoteDataSource].
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseAuthRemoteDataSource(client);
});

/// Provider for [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final dataSource = ref.watch(authRemoteDataSourceProvider);
  if (dataSource == null) return null;
  return SupabaseAuthRepository(dataSource);
});

/// Notifier managing user authentication, session persistence, and role detection.
class AuthSessionNotifier extends Notifier<AuthSessionState> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  AuthSessionState build() {
    final repository = ref.watch(authRepositoryProvider);
    if (repository == null) {
      return AuthSessionState.unauthenticated();
    }

    // Subscribe to auth state changes for real-time session reaction
    _authSubscription?.cancel();
    _authSubscription = repository.authStateChanges.listen((data) {
      _handleAuthStateChange(data.event, data.session, repository);
    });
    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    // Check for existing persisted session
    final initialSession = repository.currentSession;
    if (initialSession != null) {
      // Defer async profile loading until notifier initialization completes
      Future.microtask(
        () => _loadProfileForUser(initialSession.user, repository),
      );
      return AuthSessionState.initial();
    }

    return AuthSessionState.unauthenticated();
  }

  void _handleAuthStateChange(
    AuthChangeEvent event,
    Session? session,
    AuthRepository repository,
  ) {
    switch (event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
        if (session != null) {
          _loadProfileForUser(session.user, repository);
        }
        break;
      case AuthChangeEvent.signedOut:
        state = AuthSessionState.unauthenticated();
        break;
      case AuthChangeEvent.passwordRecovery:
        // Deep link for password recovery triggered
        if (session != null) {
          _loadProfileForUser(session.user, repository);
        }
        break;
      default:
        break;
    }
  }

  Future<void> _loadProfileForUser(User user, AuthRepository repository) async {
    try {
      var profile = await repository.getUserProfile(user.id);

      // Self-healing: If user exists in Auth but public.profiles was pending confirmation,
      // create default customer profile from metadata.
      if (profile == null) {
        final fullName = user.userMetadata?['full_name'] as String?;
        if (fullName != null && fullName.isNotEmpty) {
          final phone = user.userMetadata?['phone'] as String?;
          profile = await repository.ensureCustomerProfile(
            userId: user.id,
            fullName: fullName,
            phone: phone,
          );
        }
      }

      if (profile != null) {
        state = AuthSessionState.authenticated(
          userId: user.id,
          email: user.email ?? '',
          profile: profile,
        );
      } else {
        state = AuthSessionState.error(
          'Account profile not found in system. Please contact workshop administration.',
        );
      }
    } catch (e) {
      state = AuthSessionState.error(
        'Failed to retrieve profile: ${_formatErrorMessage(e)}',
      );
    }
  }

  /// Sign in with email and password.
  Future<void> signIn({required String email, required String password}) async {
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) {
      state = AuthSessionState.error(
        'Supabase client is unconfigured or unavailable.',
      );
      return;
    }

    state = AuthSessionState.loading(email: email);

    try {
      final response = await repository.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadProfileForUser(response.user!, repository);
      } else {
        state = AuthSessionState.error(
          'Authentication failed. No user returned.',
        );
      }
    } catch (e) {
      state = AuthSessionState.error(_formatErrorMessage(e));
      rethrow;
    }
  }

  /// Register new customer account.
  Future<AuthResponse> signUpCustomer({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) {
      state = AuthSessionState.error(
        'Supabase client is unconfigured or unavailable.',
      );
      throw Exception('Supabase client is unconfigured');
    }

    state = AuthSessionState.loading(email: email);

    try {
      final response = await repository.signUpCustomer(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      if (response.session != null && response.user != null) {
        // Auto-confirmed or immediately authenticated
        await _loadProfileForUser(response.user!, repository);
      } else {
        // Email confirmation required by Supabase
        state = AuthSessionState.unauthenticated();
      }

      return response;
    } catch (e) {
      state = AuthSessionState.error(_formatErrorMessage(e));
      rethrow;
    }
  }

  /// Sign out current session.
  Future<void> signOut() async {
    final repository = ref.read(authRepositoryProvider);
    if (repository != null) {
      try {
        await repository.signOut();
      } catch (_) {
        // Proceed to clear state locally even if network fails
      }
    }
    state = AuthSessionState.unauthenticated();
  }

  /// Send password reset request email.
  Future<void> sendPasswordReset(String email) async {
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase client is unconfigured');
    }

    try {
      await repository.sendPasswordResetEmail(email);
    } catch (e) {
      throw Exception(_formatErrorMessage(e));
    }
  }

  /// Update password for active recovery session.
  Future<void> updatePassword(String newPassword) async {
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase client is unconfigured');
    }

    try {
      await repository.updatePassword(newPassword);
    } catch (e) {
      throw Exception(_formatErrorMessage(e));
    }
  }

  String _formatErrorMessage(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_grant')) {
        return 'Invalid email address or password.';
      }
      if (msg.contains('user not found')) {
        return 'No account registered with this email address.';
      }
      if (msg.contains('rate limit') ||
          msg.contains('over_email_send_rate_limit')) {
        return 'Email rate limit reached. Please wait a few minutes before trying again.';
      }
      if (msg.contains('already registered') ||
          msg.contains('user already exists')) {
        return 'An account with this email address is already registered.';
      }
      return error.message;
    }
    return 'Connection error. Please check your network and try again.';
  }

  // --- Methods retained for direct test manipulation & mock injection ---
  void setAuthenticated({
    required String userId,
    required String email,
    required UserProfile profile,
  }) {
    state = AuthSessionState.authenticated(
      userId: userId,
      email: email,
      profile: profile,
    );
  }

  void setUnauthenticated() {
    state = AuthSessionState.unauthenticated();
  }

  void setError(String message) {
    state = AuthSessionState.error(message);
  }
}

/// Global provider for application authentication state.
final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSessionState>(
      AuthSessionNotifier.new,
    );
