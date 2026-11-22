import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/core/errors/app_exception.dart';
import 'package:pitmate/core/utils/result.dart';
import 'package:pitmate/features/auth/data/auth_repository.dart';
import 'package:pitmate/features/auth/domain/user_profile.dart';
import 'package:pitmate/features/auth/domain/user_role.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class TestMockRepository implements IAuthRepository {
  final _controller = StreamController<sb.AuthState>.broadcast();
  UserProfile? profileToReturn;
  bool failNext = false;

  @override
  Stream<sb.AuthState> get authStateChanges => _controller.stream;
  @override
  String? get currentSessionUserEmail => 'test@pitmate.local';
  @override
  sb.User? get currentUser => null;

  @override
  Future<Result<UserProfile>> signInWithPassword(String email, String password) async {
    if (failNext) return const Result.failure(AuthException('Invalid creds'));
    return Result.success(profileToReturn ?? UserProfile(id: '1', role: UserRole.admin, fullName: 'Admin'));
  }

  @override
  Future<Result<UserProfile>> signUpWithPassword(String email, String password, String fullName, [String? phone]) async {
    if (failNext) return const Result.failure(AuthException('Signup failed'));
    return Result.success(UserProfile(id: '2', role: UserRole.customer, fullName: fullName, isEmailVerified: false));
  }

  @override
  Future<Result<UserProfile>> verifyEmailOtp(String email, String token) async {
    if (failNext) return const Result.failure(AuthException('OTP invalid'));
    return Result.success(UserProfile(id: '2', role: UserRole.customer, fullName: 'Customer', isEmailVerified: true));
  }

  @override
  Future<Result<void>> resendOtp(String email) async => const Result.success(null);
  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async => const Result.success(null);
  @override
  Future<Result<void>> resetPassword(String token, String newPassword, [String? email]) async => const Result.success(null);
  @override
  Future<Result<void>> signOut() async {
    profileToReturn = null;
    return const Result.success(null);
  }

  @override
  Future<Result<UserProfile?>> fetchCurrentUserProfile() async {
    return Result.success(profileToReturn);
  }

  void dispose() => _controller.close();
}

void main() {
  late TestMockRepository testRepo;
  late ProviderContainer container;

  setUp(() {
    testRepo = TestMockRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(testRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    testRepo.dispose();
  });

  test('AuthNotifier initial state is AuthInitial or resolves to Unauthenticated', () async {
    final notifier = container.read(authNotifierProvider.notifier);
    expect(container.read(authNotifierProvider), isA<AuthState>());

    await notifier.checkAuthStatus();
    expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
  });

  test('AuthNotifier signIn transitions to AuthAuthenticated on verified profile', () async {
    final notifier = container.read(authNotifierProvider.notifier);
    testRepo.profileToReturn = UserProfile(
      id: 'admin-1',
      role: UserRole.admin,
      fullName: 'Head Admin',
      isEmailVerified: true,
    );

    final success = await notifier.signIn('admin@pitmate.local', 'Pass123!');
    expect(success, isTrue);

    final state = container.read(authNotifierProvider);
    expect(state, isA<AuthAuthenticated>());
    if (state is AuthAuthenticated) {
      expect(state.userProfile.fullName, 'Head Admin');
      expect(state.userProfile.role, UserRole.admin);
    }
  });

  test('AuthNotifier signIn sets AuthUnverifiedCustomer when customer is unverified', () async {
    final notifier = container.read(authNotifierProvider.notifier);
    testRepo.profileToReturn = UserProfile(
      id: 'cust-1',
      role: UserRole.customer,
      fullName: 'Customer Unverified',
      isEmailVerified: false,
    );

    final success = await notifier.signIn('cust@pitmate.local', 'Pass123!');
    expect(success, isTrue);

    final state = container.read(authNotifierProvider);
    expect(state, isA<AuthUnverifiedCustomer>());
  });

  test('AuthNotifier signOut sets AuthUnauthenticated', () async {
    final notifier = container.read(authNotifierProvider.notifier);
    notifier.switchDemoRole(UserRole.mechanic);
    expect(container.read(authNotifierProvider), isA<AuthAuthenticated>());

    await notifier.signOut();
    expect(container.read(authNotifierProvider), isA<AuthUnauthenticated>());
  });
}
