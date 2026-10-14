import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

/// Contract for authentication and profile data operations with Supabase.
abstract class AuthRemoteDataSource {
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

  Future<void> resetPasswordForEmail(String email);

  Future<UserResponse> updatePassword(String newPassword);

  Future<UserProfile?> fetchUserProfile(String userId);

  Future<UserProfile> createCustomerProfile({
    required String userId,
    required String fullName,
    String? phone,
  });

  Stream<AuthState> get authStateChanges;

  Session? get currentSession;

  User? get currentUser;
}

/// Concrete implementation of [AuthRemoteDataSource] interacting with [SupabaseClient].
class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  const SupabaseAuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<AuthResponse> signUpCustomer({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );

    // If session was immediately established (auto-confirmed or local dev),
    // proactively insert the profile and customer record.
    if (response.user != null && response.session != null) {
      await createCustomerProfile(
        userId: response.user!.id,
        fullName: fullName.trim(),
        phone: phone?.trim(),
      );
    }

    return response;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<UserProfile?> fetchUserProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  @override
  Future<UserProfile> createCustomerProfile({
    required String userId,
    required String fullName,
    String? phone,
  }) async {
    // Insert into public.profiles as 'customer'
    final profileData = await _client
        .from('profiles')
        .upsert({
          'id': userId,
          'role': 'customer',
          'full_name': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'is_active': true,
        })
        .select()
        .single();

    // Insert corresponding customer entity
    await _client.from('customers').upsert({
      'profile_id': userId,
      'customer_type': 'individual',
    }, onConflict: 'profile_id');

    return UserProfile.fromJson(profileData);
  }

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  User? get currentUser => _client.auth.currentUser;
}
