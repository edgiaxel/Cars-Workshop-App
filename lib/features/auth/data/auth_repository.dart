import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../app/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/models/user_role.dart';

abstract class AuthRepository {
  Future<UserProfile> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  });

  Future<void> verifyOtp({
    required String email,
    required String token,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();

  Future<UserProfile?> getCurrentProfile();

  Stream<UserProfile?> watchAuthState();
}

class SupabaseAuthRepository implements AuthRepository {
  supa.SupabaseClient get _client => supa.Supabase.instance.client;

  @override
  Future<UserProfile> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (!AppConfig.isSupabaseConfigured) {
      throw const AuthException('Supabase credentials not configured');
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Authentication failed: No user returned');
      }

      final profile = await _fetchProfile(user.id);
      return profile;
    } on supa.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException('Sign in failed: $e');
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    if (!AppConfig.isSupabaseConfigured) {
      throw const AuthException('Supabase credentials not configured');
    }

    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          if (phone != null) 'phone_number': phone.trim(),
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Registration failed: User not created');
      }

      await _client.from('profiles').upsert({
        'id': user.id,
        'role': 'customer',
        'full_name': fullName.trim(),
        'phone_number': phone?.trim(),
      });
    } on supa.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException('Registration failed: $e');
    }
  }

  @override
  Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    if (!AppConfig.isSupabaseConfigured) {
      throw const AuthException('Supabase credentials not configured');
    }

    try {
      await _client.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: supa.OtpType.signup,
      );
    } on supa.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException('OTP verification failed: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (!AppConfig.isSupabaseConfigured) {
      throw const AuthException('Supabase credentials not configured');
    }

    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on supa.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException('Password reset failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    if (AppConfig.isSupabaseConfigured) {
      await _client.auth.signOut();
    }
  }

  @override
  Future<UserProfile?> getCurrentProfile() async {
    if (!AppConfig.isSupabaseConfigured) return null;

    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      return await _fetchProfile(user.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<UserProfile?> watchAuthState() {
    if (!AppConfig.isSupabaseConfigured) {
      return Stream.value(null);
    }

    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      try {
        return await _fetchProfile(user.id);
      } catch (_) {
        return null;
      }
    });
  }

  Future<UserProfile> _fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      return UserProfile(
        id: userId,
        role: UserRole.customer,
        fullName: 'Customer',
      );
    }

    return UserProfile.fromJson(data);
  }
}
