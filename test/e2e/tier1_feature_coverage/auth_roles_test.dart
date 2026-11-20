import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/router/route_paths.dart';

import '../harness/test_harness.dart';
import '../harness/fixtures/seed_fixtures.dart';

void main() {
  setUpAll(() {
    E2ETestHarness.ensureInitialized();
  });

  group('F4: Auth & Role-Based Navigation Guards E2E Tests', () {
    testWidgets('1. Unauthenticated access to protected route redirects to /login', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: null, // No session
        initialRoute: RoutePaths.admin,
      );

      // Verify redirected to Login Screen
      expect(find.byKey(const Key('login_screen')), findsOneWidget);
      expect(find.text('Sign In to PitMate'), findsOneWidget);
    });

    testWidgets('2. Authenticated Admin logs in and navigates to /admin workspace', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: null,
        initialRoute: RoutePaths.login,
      );

      // Enter admin credentials
      await harness.enterText(tester, const Key('login_email_input'), 'admin@pitmate.com');
      await harness.enterText(tester, const Key('login_password_input'), 'password123');
      await harness.tap(tester, const Key('login_submit_button'));

      expect(find.text('PitMate — ADMIN'), findsOneWidget);
      expect(find.text('Admin Operations Dashboard'), findsOneWidget);
    });

    testWidgets('3. Authenticated Mechanic logs in and navigates to /mechanic workspace', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: null,
        initialRoute: RoutePaths.login,
      );

      // Enter mechanic credentials
      await harness.enterText(tester, const Key('login_email_input'), 'mechanic@pitmate.com');
      await harness.enterText(tester, const Key('login_password_input'), 'password123');
      await harness.tap(tester, const Key('login_submit_button'));

      expect(find.text('PitMate — MECHANIC'), findsOneWidget);
      expect(find.text('Mechanic Assigned Operations Queue'), findsOneWidget);
    });

    testWidgets('4. Authenticated Customer logs in and navigates to /customer workspace', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: null,
        initialRoute: RoutePaths.login,
      );

      // Enter customer credentials
      await harness.enterText(tester, const Key('login_email_input'), 'budi@example.com');
      await harness.enterText(tester, const Key('login_password_input'), 'password123');
      await harness.tap(tester, const Key('login_submit_button'));

      expect(find.text('PitMate — CUSTOMER'), findsOneWidget);
      expect(find.byKey(const Key('customer_garage_screen')), findsOneWidget);
    });

    testWidgets('5. Customer user attempting to access /admin is blocked by route guard', (tester) async {
      final harness = E2ETestHarness();
      // Pump with customer user already logged in, attempting deep-link to /admin/customers
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.customerUser,
        initialRoute: '/admin/customers',
      );

      expect(find.byKey(const Key('unauthorized_screen')), findsOneWidget);
      expect(find.text('Access Denied'), findsOneWidget);
    });

    testWidgets('6. User sign out clears session and returns to login screen', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: RoutePaths.admin,
      );

      expect(find.text('PitMate — ADMIN'), findsOneWidget);

      // Tap sign out button
      await harness.tap(tester, const Key('sign_out_button'));

      expect(find.byKey(const Key('login_screen')), findsOneWidget);
      expect(harness.authRepo.currentUser, isNull);
    });
  });
}
