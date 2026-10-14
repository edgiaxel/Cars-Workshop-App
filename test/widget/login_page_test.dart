import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/auth/presentation/login_page.dart';

void main() {
  testWidgets(
    'LoginPage renders credentials form and triggers field validations',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginPage())),
      );
      await tester.pumpAndSettle();

      // Verify presence of title and key components
      expect(find.text('Access Workshop Portal'), findsOneWidget);
      expect(find.text('CREDENTIALS'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('SIGN IN'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Do not have an account? Register'), findsOneWidget);

      // Tap SIGN IN with empty fields
      await tester.tap(find.text('SIGN IN'));
      await tester.pumpAndSettle();

      // Verify validation error messages
      expect(find.text('Email address is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      // Enter invalid email format
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Address'),
        'invalid-email-format',
      );
      await tester.tap(find.text('SIGN IN'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    },
  );
}
