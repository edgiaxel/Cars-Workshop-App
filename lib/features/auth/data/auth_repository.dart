import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../domain/user_profile.dart';
import '../domain/user_role.dart';

/// Abstract contract for authentication data operations.
abstract class IAuthRepository {
  Stream<sb.AuthState> get authStateChanges;
  String? get currentSessionUserEmail;
  sb.User? get currentUser;

  Future<Result<UserProfile>> signInWithPassword(
    String email,
    String password,
  );

  Future<Result<UserProfile>> signUpWithPassword(
    String email,
    String password,
    String fullName, [
    String? phone,
    String customerType = 'individual',
    String? companyName,
  ]);

  Future<Result<UserProfile>> verifyEmailOtp(
    String email,
    String token,
  );

  Future<Result<void>> resendOtp(String email);

  Future<Result<void>> sendPasswordResetEmail(String email);

  Future<Result<void>> resetPassword(
    String token,
    String newPassword, [
    String? email,
  ]);

  Future<Result<void>> signOut();

  Future<Result<UserProfile?>> fetchCurrentUserProfile();
}

/// Supabase implementation of [IAuthRepository].
class AuthRepository implements IAuthRepository {
  final sb.SupabaseClient? _clientOverride;

  AuthRepository([this._clientOverride]);

  sb.SupabaseClient get _client {
    if (_clientOverride != null) return _clientOverride;
    return sb.Supabase.instance.client;
  }

  @override
  Stream<sb.AuthState> get authStateChanges {
    try {
      return _client.auth.onAuthStateChange;
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  String? get currentSessionUserEmail => currentUser?.email;

  @override
  sb.User? get currentUser {
    try {
      return _client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<UserProfile>> signInWithPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        return const Result.failure(
          AuthException('Authentication failed: no user record returned.'),
        );
      }

      final profileResult = await fetchCurrentUserProfile();
      return await profileResult.when(
        success: (profile) {
          if (profile != null) {
            return Result.success(profile);
          }
          final fallback = UserProfile(
            id: user.id,
            role: UserRole.fromString(user.userMetadata?['role'] as String?),
            fullName: (user.userMetadata?['full_name'] ??
                    user.userMetadata?['fullName'] ??
                    user.email?.split('@').first) as String? ??
                'User',
            phoneNumber: (user.userMetadata?['phone'] ?? user.phone) as String?,
            isEmailVerified: user.emailConfirmedAt != null,
          );
          return Result.success(fallback);
        },
        failure: (err) => Result.failure(err),
      );
    } on sb.AuthException catch (e) {
      return Result.failure(
        AuthException(e.message, code: e.statusCode, originalException: e),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error: ${e.message}', originalException: e),
      );
    } on TimeoutException catch (e) {
      return Result.failure(
        NetworkException('Connection timed out.', originalException: e),
      );
    } catch (e) {
      return Result.failure(
        AuthException('Unexpected sign in failure: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<UserProfile>> signUpWithPassword(
    String email,
    String password,
    String fullName, [
    String? phone,
    String customerType = 'individual',
    String? companyName,
  ]) async {
    try {
      final normalizedEmail = email.trim();
      final response = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'full_name': fullName.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          'role': 'customer',
          'customer_type': customerType,
          if (companyName != null && companyName.trim().isNotEmpty)
            'company_name': companyName.trim(),
        },
      );

      final user = response.user;
      if (user == null) {
        return const Result.failure(
          AuthException('Registration failed: no user returned by server.'),
        );
      }

      final isVerified = user.emailConfirmedAt != null;
      final profile = UserProfile(
        id: user.id,
        role: UserRole.customer,
        fullName: fullName.trim(),
        phoneNumber: phone?.trim(),
        customerType: customerType,
        companyName: companyName?.trim(),
        isEmailVerified: isVerified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Attempt initial profile & customer upsert if authenticated session exists
      if (response.session != null) {
        try {
          await _client.from('profiles').upsert(profile.toJson());
          await _client.from('customers').upsert({
            'profile_id': user.id,
            'full_name': fullName.trim(),
            'phone_number': phone?.trim(),
            'email': normalizedEmail,
            'customer_type': customerType,
            if (companyName != null && companyName.trim().isNotEmpty)
              'company_name': companyName.trim(),
            'is_guest': false,
          });
        } catch (_) {
          // May be handled by server database trigger
        }
      }

      return Result.success(profile);
    } on sb.AuthException catch (e) {
      return Result.failure(
        AuthException(e.message, code: e.statusCode, originalException: e),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error: ${e.message}', originalException: e),
      );
    } on TimeoutException catch (e) {
      return Result.failure(
        NetworkException('Connection timed out.', originalException: e),
      );
    } catch (e) {
      return Result.failure(
        AuthException('Registration error: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<UserProfile>> verifyEmailOtp(
    String email,
    String token,
  ) async {
    try {
      sb.AuthResponse response;
      try {
        response = await _client.auth.verifyOTP(
          type: sb.OtpType.signup,
          token: token.trim(),
          email: email.trim(),
        );
      } on sb.AuthException {
        // Fallback to email verification type if signup type is rejected
        response = await _client.auth.verifyOTP(
          type: sb.OtpType.email,
          token: token.trim(),
          email: email.trim(),
        );
      }

      final user = response.user;
      if (user == null) {
        return const Result.failure(
          AuthException('Verification succeeded but user session is empty.'),
        );
      }

      final profileResult = await fetchCurrentUserProfile();
      return await profileResult.when(
        success: (profile) {
          final updated = (profile ??
                  UserProfile(
                    id: user.id,
                    role: UserRole.customer,
                    fullName: (user.userMetadata?['full_name'] ??
                            email.split('@').first) as String? ??
                        '',
                    phoneNumber: user.userMetadata?['phone'] as String?,
                  ))
              .copyWith(isEmailVerified: true);
          return Result.success(updated);
        },
        failure: (_) => Result.success(
          UserProfile(
            id: user.id,
            role: UserRole.customer,
            fullName: (user.userMetadata?['full_name'] ?? email.split('@').first)
                as String? ??
                '',
            phoneNumber: user.userMetadata?['phone'] as String?,
            isEmailVerified: true,
          ),
        ),
      );
    } on sb.AuthException catch (e) {
      return Result.failure(
        AuthException(e.message, code: e.statusCode, originalException: e),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error: ${e.message}', originalException: e),
      );
    } catch (e) {
      return Result.failure(
        AuthException('OTP verification failed: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<void>> resendOtp(String email) async {
    try {
      await _client.auth.resend(
        type: sb.OtpType.signup,
        email: email.trim(),
      );
      return const Result.success(null);
    } on sb.AuthException catch (e) {
      return Result.failure(
        AuthException(e.message, code: e.statusCode, originalException: e),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error: ${e.message}', originalException: e),
      );
    } catch (e) {
      return Result.failure(
        AuthException('Failed to resend code: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return const Result.success(null);
    } on sb.AuthException catch (e) {
      return Result.failure(
        AuthException(e.message, code: e.statusCode, originalException: e),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error: ${e.message}', originalException: e),
      );
    } catch (e) {
      return Result.failure(
        AuthException('Failed to send reset email: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<void>> resetPassword(
    String token,
    String newPassword, [
    String? email,
  ]) async {
    try {
      if (email != null && email.isNotEmpty) {
        await _client.auth.verifyOTP(
          type: sb.OtpType.recovery,
          token: token.trim(),
          email: email.trim(),
        );
      } else {
        await _client.auth.verifyOTP(
          type: sb.OtpType.recovery,
          tokenHash: token.trim(),
        );
      }

      await _client.auth.updateUser(
        sb.UserAttributes(password: newPassword),
      );
      return const Result.success(null);
    } on sb.AuthException catch (e) {
      return Result.failure(
        AuthException(e.message, code: e.statusCode, originalException: e),
      );
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error: ${e.message}', originalException: e),
      );
    } catch (e) {
      return Result.failure(
        AuthException('Failed to reset password: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Result.success(null);
    } on sb.AuthException catch (e) {
      return Result.failure(
        AuthException(e.message, code: e.statusCode, originalException: e),
      );
    } catch (e) {
      return Result.failure(
        AuthException('Failed to sign out: $e', originalException: e),
      );
    }
  }

  @override
  Future<Result<UserProfile?>> fetchCurrentUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) {
        return const Result.success(null);
      }

      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        final profile = UserProfile.fromJson({
          ...data,
          'is_email_verified': user.emailConfirmedAt != null,
        });
        return Result.success(profile);
      }

      // Fallback from auth metadata when table row does not yet exist
      final fallback = UserProfile(
        id: user.id,
        role: UserRole.fromString(user.userMetadata?['role'] as String?),
        fullName: (user.userMetadata?['full_name'] ??
                user.userMetadata?['fullName'] ??
                user.email?.split('@').first) as String? ??
            'User',
        phoneNumber: (user.userMetadata?['phone'] ?? user.phone) as String?,
        isEmailVerified: user.emailConfirmedAt != null,
      );
      return Result.success(fallback);
    } on SocketException catch (e) {
      return Result.failure(
        NetworkException('Network error: ${e.message}', originalException: e),
      );
    } catch (e) {
      return Result.failure(
        AuthException('Failed to fetch user profile: $e', originalException: e),
      );
    }
  }
}
