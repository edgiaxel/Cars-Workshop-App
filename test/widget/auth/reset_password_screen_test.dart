import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/features/auth/presentation/screens/reset_password_screen.dart';

void main() {
  Widget buildResetPasswordScreen({String? code}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: ResetPasswordScreen(code: code),
    );
  }

  group('ResetPasswordScreen Widget Tests', () {
    testWidgets('renders reset password form with fields and action button', (tester) async {
      await tester.pumpWidget(buildResetPasswordScreen());
      await tester.pumpAndSettle();

      expect(find.text('Set New Password'), findsOneWidget);
      expect(find.text('Choose New Password'), findsOneWidget);
      expect(find.byKey(const Key('reset_password_field')), findsOneWidget);
      expect(find.byKey(const Key('reset_password_confirm_field')), findsOneWidget);
      expect(find.byKey(const Key('reset_password_submit_button')), findsOneWidget);
    });

    testWidgets('validates short password length and mismatched passwords', (tester) async {
      await tester.pumpWidget(buildResetPasswordScreen());
      await tester.pumpAndSettle();

      // Enter too short password
      await tester.enterText(find.byKey(const Key('reset_password_field')), '123');
      await tester.enterText(find.byKey(const Key('reset_password_confirm_field')), '123456');
      await tester.tap(find.byKey(const Key('reset_password_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);

      // Enter mismatched passwords
      await tester.enterText(find.byKey(const Key('reset_password_field')), 'password123');
      await tester.enterText(find.byKey(const Key('reset_password_confirm_field')), 'different123');
      await tester.tap(find.byKey(const Key('reset_password_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
