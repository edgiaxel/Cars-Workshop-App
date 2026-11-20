import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/auth/presentation/register_page.dart';

void main() {
  testWidgets('RegisterPage renders form and triggers validation errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RegisterPage())),
    );
    await tester.pumpAndSettle();

    // Verify key fields
    expect(find.text('Create PitMate Account'), findsOneWidget);
    expect(find.text('NEW ACCOUNT'), findsOneWidget);
    expect(find.text('Full Name / Company'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Phone Number (Optional)'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('REGISTER ACCOUNT'), findsOneWidget);

    // Tap submit with empty fields
    await tester.ensureVisible(find.text('REGISTER ACCOUNT'));
    await tester.tap(find.text('REGISTER ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Email address is required'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);

    // Test password mismatch
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full Name / Company'),
      'Axel Zeed',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email Address'),
      'lexazeed@gmail.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Password'),
      'differentPassword',
    );

    await tester.ensureVisible(find.text('REGISTER ACCOUNT'));
    await tester.tap(find.text('REGISTER ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });
}
