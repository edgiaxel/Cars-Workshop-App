import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/data/datasources/auth_remote_datasource.dart';
import 'package:pitmate/data/models/user_profile.dart';
import 'package:pitmate/data/models/user_role.dart';
import 'package:pitmate/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  bool signOutCalled = false;
  String? resetPasswordEmail;
  String? updatedPassword;

  final sampleProfile = const UserProfile(
    id: 'user-xyz',
    role: UserRole.customer,
    fullName: 'Test Customer',
  );

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Session? get currentSession => null;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return AuthResponse();
  }

  @override
  Future<AuthResponse> signUpCustomer({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    return AuthResponse();
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    resetPasswordEmail = email;
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    updatedPassword = newPassword;
    return UserResponse.fromJson({'user': null});
  }

  @override
  Future<UserProfile?> fetchUserProfile(String userId) async {
    if (userId == 'user-xyz') return sampleProfile;
    return null;
  }

  @override
  Future<UserProfile> createCustomerProfile({
    required String userId,
    required String fullName,
    String? phone,
  }) async {
    return UserProfile(
      id: userId,
      role: UserRole.customer,
      fullName: fullName,
      phone: phone,
    );
  }
}

void main() {
  group('SupabaseAuthRepository Unit Tests', () {
    late FakeAuthRemoteDataSource fakeDataSource;
    late SupabaseAuthRepository repository;

    setUp(() {
      fakeDataSource = FakeAuthRemoteDataSource();
      repository = SupabaseAuthRepository(fakeDataSource);
    });

    test('getUserProfile returns profile from datasource', () async {
      final profile = await repository.getUserProfile('user-xyz');
      expect(profile, isNotNull);
      expect(profile!.id, 'user-xyz');
      expect(profile.role, UserRole.customer);
      expect(profile.fullName, 'Test Customer');
    });

    test('getUserProfile returns null for unknown user', () async {
      final profile = await repository.getUserProfile('unknown-id');
      expect(profile, isNull);
    });

    test('signOut invokes datasource signOut', () async {
      await repository.signOut();
      expect(fakeDataSource.signOutCalled, isTrue);
    });

    test('sendPasswordResetEmail forwards email to datasource', () async {
      await repository.sendPasswordResetEmail('reset@pitmate.co');
      expect(fakeDataSource.resetPasswordEmail, 'reset@pitmate.co');
    });

    test('updatePassword forwards new password to datasource', () async {
      await repository.updatePassword('newPassword123');
      expect(fakeDataSource.updatedPassword, 'newPassword123');
    });

    test('ensureCustomerProfile creates customer profile', () async {
      final profile = await repository.ensureCustomerProfile(
        userId: 'new-id',
        fullName: 'New Customer',
        phone: '+62812345678',
      );

      expect(profile.id, 'new-id');
      expect(profile.role, UserRole.customer);
      expect(profile.fullName, 'New Customer');
      expect(profile.phone, '+62812345678');
    });
  });
}
