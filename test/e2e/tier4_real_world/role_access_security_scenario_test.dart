import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../harness/test_harness.dart';

void main() {
  setUpAll(() {
    E2ETestHarness.ensureInitialized();
  });

  group('Tier 4 Scenario 3: Multi-Role Session & Route Guard Redirection Workflow', () {
    testWidgets('Unauthenticated redirection, customer role isolation, and admin escalation prevention', (tester) async {
      final harness = E2ETestHarness();

      // Step 1: Unauthenticated direct attempt to access admin customers
      await harness.pumpApp(
        tester,
        initialUser: null,
        initialRoute: '/admin/customers',
      );

      // Verifies route guard caught unauthenticated request and redirected to login
      expect(find.byKey(const Key('login_screen')), findsOneWidget);

      // Step 2: Log in as standard Customer
      await harness.enterText(tester, const Key('login_email_input'), 'customer@example.com');
      await harness.enterText(tester, const Key('login_password_input'), 'password123');
      await harness.tap(tester, const Key('login_submit_button'));

      expect(find.text('PitMate — CUSTOMER'), findsOneWidget);

      // Step 3: Customer attempts deep-link access to Admin workspace
      await harness.goTo(tester, '/admin/vehicles');

      // Verifies route guard blocked customer access to admin routes
      expect(find.byKey(const Key('unauthorized_screen')), findsOneWidget);
      expect(find.text('Access Denied'), findsOneWidget);

      // Step 4: Click return to login button from unauthorized screen
      await harness.tap(tester, const Key('unauthorized_back_button'));
      expect(find.byKey(const Key('login_screen')), findsOneWidget);

      // Step 5: Sign in as Admin
      await harness.enterText(tester, const Key('login_email_input'), 'admin@pitmate.com');
      await harness.enterText(tester, const Key('login_password_input'), 'password123');
      await harness.tap(tester, const Key('login_submit_button'));

      // Verifies Admin now has full access to admin workspace
      expect(find.text('PitMate — ADMIN'), findsOneWidget);
      expect(find.text('Admin Operations Dashboard'), findsOneWidget);
    });
  });
}
