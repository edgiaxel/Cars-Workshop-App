import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/features/auth/domain/user_profile.dart';
import 'package:pitmate/features/auth/domain/user_role.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/profile/presentation/profile_screen.dart';

class MockAuthNotifier extends AuthNotifier {
  final UserProfile mockProfile;

  MockAuthNotifier(this.mockProfile);

  @override
  AuthState build() {
    return AuthAuthenticated(mockProfile);
  }
}

void main() {
  const testAdminProfile = UserProfile(
    id: 'admin-001',
    role: UserRole.admin,
    fullName: 'Alex Director',
    phoneNumber: '+6281234567890',
    isEmailVerified: true,
  );

  Widget buildProfileScreen({UserProfile profile = testAdminProfile}) {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => MockAuthNotifier(profile)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('renders profile editor with sections, name field and action buttons', (tester) async {
      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Email Address & Verification'), findsOneWidget);
      expect(find.text('Security & Password'), findsOneWidget);

      expect(find.byKey(const Key('profile_name_field')), findsOneWidget);
      expect(find.byKey(const Key('profile_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('profile_save_personal_button')), findsOneWidget);
      expect(find.byKey(const Key('profile_update_email_button')), findsOneWidget);
      expect(find.byKey(const Key('profile_change_password_button')), findsOneWidget);
    });

    testWidgets('validates required name field', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('profile_name_field')));
      await tester.enterText(find.byKey(const Key('profile_name_field')), '');
      await tester.ensureVisible(find.byKey(const Key('profile_save_personal_button')));
      await tester.tap(find.byKey(const Key('profile_save_personal_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your full name'), findsOneWidget);
    });

    testWidgets('validates new email format', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileScreen());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('profile_new_email_field')));
      await tester.enterText(find.byKey(const Key('profile_new_email_field')), 'invalid-email');
      await tester.ensureVisible(find.byKey(const Key('profile_update_email_button')));
      await tester.tap(find.byKey(const Key('profile_update_email_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email format'), findsOneWidget);
    });
  });
}
