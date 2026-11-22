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
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:pitmate/features/auth/presentation/screens/login_screen.dart';
import 'package:pitmate/features/auth/presentation/screens/register_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Deterministic in-memory fake repository for widget tests.
class FakeAuthRepository implements IAuthRepository {
  final _authStateController = StreamController<sb.AuthState>.broadcast();
  UserProfile? currentProfile;
  bool shouldFailSignIn = false;
  String? lastSignInEmail;
  String? lastSignInPassword;

  @override
  Stream<sb.AuthState> get authStateChanges => _authStateController.stream;

  @override
  String? get currentSessionUserEmail =>
      currentProfile != null ? 'test@pitmate.local' : null;

  @override
  sb.User? get currentUser => null;

  @override
  Future<Result<UserProfile>> signInWithPassword(
    String email,
    String password,
  ) async {
    lastSignInEmail = email;
    lastSignInPassword = password;

    if (shouldFailSignIn) {
      return const Result.failure(
        AuthException(
          'Invalid credentials provided.',
          code: 'invalid_credentials',
        ),
      );
    }

    final profile = UserProfile(
      id: 'test-user-id',
      role: UserRole.admin,
      fullName: 'Test Admin',
      phoneNumber: '+6281234567890',
      isEmailVerified: true,
    );
    currentProfile = profile;
    return Result.success(profile);
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
    final profile = UserProfile(
      id: 'new-user-id',
      role: UserRole.customer,
      fullName: fullName,
      phoneNumber: phone,
      isEmailVerified: false,
    );
    return Result.success(profile);
  }

  @override
  Future<Result<UserProfile>> verifyEmailOtp(String email, String token) async {
    final profile = UserProfile(
      id: 'verified-user-id',
      role: UserRole.customer,
      fullName: 'Customer User',
      isEmailVerified: true,
    );
    currentProfile = profile;
    return Result.success(profile);
  }

  @override
  Future<Result<void>> resendOtp(String email) async {
    return const Result.success(null);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    return const Result.success(null);
  }

  @override
  Future<Result<void>> resetPassword(
    String token,
    String newPassword, [
    String? email,
  ]) async {
    return const Result.success(null);
  }

  @override
  Future<Result<void>> signOut() async {
    currentProfile = null;
    return const Result.success(null);
  }

  @override
  Future<Result<UserProfile?>> fetchCurrentUserProfile() async {
    return Result.success(currentProfile);
  }

  void dispose() {
    _authStateController.close();
  }
}

void main() {
  late FakeAuthRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeAuthRepository();
  });

  tearDown(() {
    fakeRepo.dispose();
  });

  Widget buildTestApp({FakeAuthRepository? repo}) {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo ?? fakeRepo)],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('renders all essential login elements', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // App header
    expect(find.text('PITMATE'), findsOneWidget);
    expect(find.text('Automotive Workshop Management'), findsOneWidget);

    // Form inputs and buttons
    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(find.byKey(const Key('login_password_field')), findsOneWidget);
    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    expect(find.byKey(const Key('forgot_password_button')), findsOneWidget);
    expect(find.byKey(const Key('login_to_register_button')), findsOneWidget);

    // Demo switcher chips
    expect(find.byKey(const Key('demo_role_admin')), findsOneWidget);
    expect(find.byKey(const Key('demo_role_mechanic')), findsOneWidget);
    expect(find.byKey(const Key('demo_role_customer')), findsOneWidget);
  });

  testWidgets('validates empty inputs on submit', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('validates email format and password length', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'invalid-email',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      '123',
    );

    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  testWidgets('toggles password visibility', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final textFieldBefore = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('login_password_field')),
        matching: find.byType(TextField),
      ),
    );
    expect(textFieldBefore.obscureText, isTrue);

    await tester.tap(find.byKey(const Key('login_password_toggle')));
    await tester.pumpAndSettle();

    final textFieldAfter = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('login_password_field')),
        matching: find.byType(TextField),
      ),
    );
    expect(textFieldAfter.obscureText, isFalse);
  });

  testWidgets(
    'quick demo role switcher populates credentials and switches role',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Admin Demo chip
      await tester.ensureVisible(find.byKey(const Key('demo_role_admin')));
      await tester.tap(find.byKey(const Key('demo_role_admin')));
      await tester.pumpAndSettle();

      final emailField = tester.widget<TextFormField>(
        find.byKey(const Key('login_email_field')),
      );
      expect(emailField.controller?.text, 'admin@pitmate.co');

      final state = container.read(authNotifierProvider);
      expect(state, isA<AuthAuthenticated>());
      if (state is AuthAuthenticated) {
        expect(state.userProfile.role, UserRole.admin);
      }
    },
  );

  testWidgets('successful sign in invokes repository and signs in user', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'user@pitmate.local',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'Password123',
    );

    await tester.ensureVisible(find.byKey(const Key('login_submit_button')));
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(fakeRepo.lastSignInEmail, 'user@pitmate.local');
    expect(fakeRepo.lastSignInPassword, 'Password123');
  });

  testWidgets('failed sign in displays error in SnackBar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    fakeRepo.shouldFailSignIn = true;

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'wrong@pitmate.local',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'WrongPassword',
    );

    await tester.ensureVisible(find.byKey(const Key('login_submit_button')));
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials provided.'), findsOneWidget);
  });

  testWidgets('navigation to register screen works', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('login_to_register_button')),
    );
    await tester.tap(find.byKey(const Key('login_to_register_button')));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('Join PitMate'), findsOneWidget);
  });

  testWidgets('navigation to forgot password screen works', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('forgot_password_button')));
    await tester.tap(find.byKey(const Key('forgot_password_button')));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
  });
}
