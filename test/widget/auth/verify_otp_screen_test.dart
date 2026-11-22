import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/core/errors/app_exception.dart';
import 'package:pitmate/core/utils/result.dart';
import 'package:pitmate/features/auth/data/auth_repository.dart';
import 'package:pitmate/features/auth/domain/user_profile.dart';
import 'package:pitmate/features/auth/domain/user_role.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class FakeOtpAuthRepository implements IAuthRepository {
  final _authStateController = StreamController<sb.AuthState>.broadcast();
  String? verifiedToken;
  String? verifiedEmail;
  String? resentEmail;

  @override
  Stream<sb.AuthState> get authStateChanges => _authStateController.stream;
  @override
  String? get currentSessionUserEmail => null;
  @override
  sb.User? get currentUser => null;

  @override
  Future<Result<UserProfile>> signInWithPassword(String email, String password) async =>
      const Result.failure(AuthException('Not implemented'));
  @override
  Future<Result<UserProfile>> signUpWithPassword(
    String email,
    String password,
    String fullName, [
    String? phone,
    String customerType = 'individual',
    String? companyName,
  ]) async =>
      const Result.failure(AuthException('Not implemented'));

  @override
  Future<Result<UserProfile>> verifyEmailOtp(String email, String token) async {
    verifiedEmail = email;
    verifiedToken = token;
    return Result.success(UserProfile(
      id: 'usr-verified',
      role: UserRole.customer,
      fullName: 'Customer Test',
      isEmailVerified: true,
    ));
  }

  @override
  Future<Result<void>> resendOtp(String email) async {
    resentEmail = email;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async => const Result.success(null);
  @override
  Future<Result<void>> resetPassword(String token, String newPassword, [String? email]) async => const Result.success(null);
  @override
  Future<Result<void>> signOut() async => const Result.success(null);
  @override
  Future<Result<UserProfile?>> fetchCurrentUserProfile() async => const Result.success(null);

  void dispose() => _authStateController.close();
}

void main() {
  late FakeOtpAuthRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeOtpAuthRepository();
  });

  tearDown(() {
    fakeRepo.dispose();
  });

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: const MaterialApp(
        home: VerifyOtpScreen(email: 'verify@pitmate.local'),
      ),
    );
  }

  testWidgets('renders OTP fields and displays target email', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Verify Email'), findsOneWidget);
    expect(find.text('Enter 6-Digit Code'), findsOneWidget);
    expect(find.textContaining('verify@pitmate.local'), findsOneWidget);
    expect(find.byKey(const Key('otp_code_field')), findsOneWidget);
    expect(find.byKey(const Key('otp_submit_button')), findsOneWidget);
    expect(find.byKey(const Key('otp_resend_button')), findsOneWidget);
  });

  testWidgets('submitting 6-digit OTP invokes repository verify', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('otp_code_field')), '123456');
    await tester.pumpAndSettle();

    expect(fakeRepo.verifiedEmail, 'verify@pitmate.local');
    expect(fakeRepo.verifiedToken, '123456');
  });
}
