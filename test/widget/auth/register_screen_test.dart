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
import 'package:pitmate/features/auth/presentation/screens/register_screen.dart';
import 'package:pitmate/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class FakeRegisterAuthRepository implements IAuthRepository {
  final _authStateController = StreamController<sb.AuthState>.broadcast();
  bool shouldFailSignUp = false;
  String? registeredEmail;
  String? registeredFullName;

  @override
  Stream<sb.AuthState> get authStateChanges => _authStateController.stream;

  @override
  String? get currentSessionUserEmail => null;

  @override
  sb.User? get currentUser => null;

  @override
  Future<Result<UserProfile>> signInWithPassword(String email, String password) async {
    return const Result.failure(AuthException('Not implemented'));
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
    registeredEmail = email;
    registeredFullName = fullName;

    if (shouldFailSignUp) {
      return const Result.failure(AuthException('Email already registered', code: 'user_already_exists'));
    }

    final profile = UserProfile(
      id: 'reg-user-123',
      role: UserRole.customer,
      fullName: fullName,
      phoneNumber: phone,
      isEmailVerified: false,
    );
    return Result.success(profile);
  }

  @override
  Future<Result<UserProfile>> verifyEmailOtp(String email, String token) async {
    return const Result.failure(AuthException('Not implemented'));
  }

  @override
  Future<Result<void>> resendOtp(String email) async => const Result.success(null);
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
  late FakeRegisterAuthRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeRegisterAuthRepository();
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
        home: RegisterScreen(),
      ),
    );
  }

  testWidgets('renders all register form fields', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Join PitMate'), findsOneWidget);
    expect(find.byKey(const Key('register_name_field')), findsOneWidget);
    expect(find.byKey(const Key('register_phone_field')), findsOneWidget);
    expect(find.byKey(const Key('register_email_field')), findsOneWidget);
    expect(find.byKey(const Key('register_password_field')), findsOneWidget);
    expect(find.byKey(const Key('register_submit_button')), findsOneWidget);
  });

  testWidgets('validates required fields on register submit', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your full name'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter a password'), findsOneWidget);
  });

  testWidgets('successful registration redirects to VerifyOtpScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('register_name_field')), 'Ahmad Dhani');
    await tester.enterText(find.byKey(const Key('register_email_field')), 'ahmad@pitmate.local');
    await tester.enterText(find.byKey(const Key('register_password_field')), 'SecurePass123!');

    await tester.ensureVisible(find.byKey(const Key('register_submit_button')));
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();

    expect(fakeRepo.registeredEmail, 'ahmad@pitmate.local');
    expect(fakeRepo.registeredFullName, 'Ahmad Dhani');
    expect(find.byType(VerifyOtpScreen), findsOneWidget);
    expect(find.text('Enter 6-Digit Code'), findsOneWidget);
  });
}
