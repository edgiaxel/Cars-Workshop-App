import 'package:supabase_flutter/supabase_flutter.dart';

import '../datasources/auth_remote_datasource.dart';
import '../models/user_profile.dart';

/// Repository abstraction separating authentication logic from presentation.
abstract class AuthRepository {
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUpCustomer({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<UserResponse> updatePassword(String newPassword);

  Future<UserProfile?> getUserProfile(String userId);

  Future<UserProfile> ensureCustomerProfile({
    required String userId,
    required String fullName,
    String? phone,
  });

  Stream<AuthState> get authStateChanges;

  Session? get currentSession;

  User? get currentUser;
}

/// Concrete implementation of [AuthRepository] delegating to [AuthRemoteDataSource].
class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _remoteDataSource.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResponse> signUpCustomer({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) {
    return _remoteDataSource.signUpCustomer(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
  }

  @override
  Future<void> signOut() {
    return _remoteDataSource.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _remoteDataSource.resetPasswordForEmail(email);
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) {
    return _remoteDataSource.updatePassword(newPassword);
  }

  @override
  Future<UserProfile?> getUserProfile(String userId) {
    return _remoteDataSource.fetchUserProfile(userId);
  }

  @override
  Future<UserProfile> ensureCustomerProfile({
    required String userId,
    required String fullName,
    String? phone,
  }) {
    return _remoteDataSource.createCustomerProfile(
      userId: userId,
      fullName: fullName,
      phone: phone,
    );
  }

  @override
  Stream<AuthState> get authStateChanges => _remoteDataSource.authStateChanges;

  @override
  Session? get currentSession => _remoteDataSource.currentSession;

  @override
  User? get currentUser => _remoteDataSource.currentUser;
}
