import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/router/route_paths.dart';

import '../harness/test_harness.dart';
import '../harness/fixtures/seed_fixtures.dart';

void main() {
  setUpAll(() {
    E2ETestHarness.ensureInitialized();
  });

  group('F3: Responsive Layout Shells E2E Tests', () {
    testWidgets('1. Desktop viewport (>= 1024dp) renders permanent navigation sidebar', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        screenSize: ScreenSizes.desktop,
        initialUser: SeedFixtures.adminUser,
        initialRoute: RoutePaths.admin,
      );

      expect(find.byKey(const Key('desktop_sidebar')), findsOneWidget);
      expect(find.byKey(const Key('tablet_nav_rail')), findsNothing);
      expect(find.byKey(const Key('mobile_bottom_nav')), findsNothing);
    });

    testWidgets('2. Tablet viewport (600 - 1023dp) renders collapsible navigation rail', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        screenSize: ScreenSizes.tablet,
        initialUser: SeedFixtures.adminUser,
        initialRoute: RoutePaths.admin,
      );

      expect(find.byKey(const Key('tablet_nav_rail')), findsOneWidget);
      expect(find.byKey(const Key('desktop_sidebar')), findsNothing);
      expect(find.byKey(const Key('mobile_bottom_nav')), findsNothing);
    });

    testWidgets('3. Mobile viewport (< 600dp) renders bottom navigation bar', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        screenSize: ScreenSizes.mobile,
        initialUser: SeedFixtures.adminUser,
        initialRoute: RoutePaths.admin,
      );

      expect(find.byKey(const Key('mobile_bottom_nav')), findsOneWidget);
      expect(find.byKey(const Key('desktop_sidebar')), findsNothing);
      expect(find.byKey(const Key('tablet_nav_rail')), findsNothing);
    });

    testWidgets('4. Admin shell displays Admin branding and destinations', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        screenSize: ScreenSizes.desktop,
        initialUser: SeedFixtures.adminUser,
        initialRoute: RoutePaths.admin,
      );

      expect(find.text('PitMate — ADMIN'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Vehicles'), findsOneWidget);
    });

    testWidgets('5. Mechanic shell displays Mechanic branding and destinations', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        screenSize: ScreenSizes.desktop,
        initialUser: SeedFixtures.mechanicUser,
        initialRoute: RoutePaths.mechanic,
      );

      expect(find.text('PitMate — MECHANIC'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Diagnostics'), findsOneWidget);
    });

    testWidgets('6. Customer shell displays Customer branding and destinations', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        screenSize: ScreenSizes.desktop,
        initialUser: SeedFixtures.customerUser,
        initialRoute: RoutePaths.customer,
      );

      expect(find.text('PitMate — CUSTOMER'), findsOneWidget);
      expect(find.text('Garage'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
    });
  });
}
