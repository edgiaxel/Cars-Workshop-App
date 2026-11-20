import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../harness/test_harness.dart';
import '../harness/fixtures/seed_fixtures.dart';

void main() {
  setUpAll(() {
    E2ETestHarness.ensureInitialized();
  });

  group('Tier 2: Boundary Value Analysis & Corner Inputs E2E Tests', () {
    testWidgets('1. Empty customer name triggers validation error', (
      tester,
    ) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/customers',
      );

      await harness.tap(tester, const Key('add_customer_button'));
      await harness.enterText(tester, const Key('customer_name_input'), '');
      await harness.enterText(
        tester,
        const Key('customer_phone_input'),
        '08123456789',
      );
      await harness.tap(tester, const Key('save_customer_button'));

      expect(find.byKey(const Key('customer_form_error')), findsOneWidget);
      expect(
        find.textContaining('Customer name cannot be empty.'),
        findsOneWidget,
      );
    });

    testWidgets('2. Whitespace-only customer phone triggers validation error', (
      tester,
    ) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/customers',
      );

      await harness.tap(tester, const Key('add_customer_button'));
      await harness.enterText(
        tester,
        const Key('customer_name_input'),
        'Valid Name',
      );
      await harness.enterText(
        tester,
        const Key('customer_phone_input'),
        '     ',
      );
      await harness.tap(tester, const Key('save_customer_button'));

      expect(find.byKey(const Key('customer_form_error')), findsOneWidget);
      expect(
        find.textContaining('Customer phone cannot be empty.'),
        findsOneWidget,
      );
    });

    testWidgets('3. Malformed email address triggers validation error', (
      tester,
    ) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/customers',
      );

      await harness.tap(tester, const Key('add_customer_button'));
      await harness.enterText(
        tester,
        const Key('customer_name_input'),
        'Valid Customer',
      );
      await harness.enterText(
        tester,
        const Key('customer_phone_input'),
        '08123456789',
      );
      await harness.enterText(
        tester,
        const Key('customer_email_input'),
        'malformed-email-without-at',
      );
      await harness.tap(tester, const Key('save_customer_button'));

      expect(find.byKey(const Key('customer_form_error')), findsOneWidget);
      expect(find.textContaining('Invalid email format.'), findsOneWidget);
    });

    testWidgets('4. Empty optional email is accepted without error', (
      tester,
    ) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/customers',
      );

      await harness.tap(tester, const Key('add_customer_button'));
      await harness.enterText(
        tester,
        const Key('customer_name_input'),
        'Customer Without Email',
      );
      await harness.enterText(
        tester,
        const Key('customer_phone_input'),
        '081999888777',
      );
      await harness.enterText(tester, const Key('customer_email_input'), '');
      await harness.tap(tester, const Key('save_customer_button'));

      expect(find.byKey(const Key('customer_form_error')), findsNothing);
      expect(find.text('Customer Without Email'), findsOneWidget);
    });

    testWidgets('5. Boundary year 1900 is accepted as valid', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/vehicles',
      );

      await harness.tap(tester, const Key('register_vehicle_button'));
      await harness.enterText(
        tester,
        const Key('vehicle_plate_input'),
        'B 1900 CL',
      );
      await harness.enterText(tester, const Key('vehicle_make_input'), 'Ford');
      await harness.enterText(
        tester,
        const Key('vehicle_model_input'),
        'Model T',
      );
      await harness.enterText(tester, const Key('vehicle_year_input'), '1900');
      await harness.tap(tester, const Key('save_vehicle_button'));

      expect(find.byKey(const Key('vehicle_form_error')), findsNothing);
      expect(find.textContaining('B 1900 CL'), findsOneWidget);
      expect(find.textContaining('Year: 1900'), findsOneWidget);
    });

    testWidgets('6. Boundary year 2100 is accepted as valid', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/vehicles',
      );

      await harness.tap(tester, const Key('register_vehicle_button'));
      await harness.enterText(
        tester,
        const Key('vehicle_plate_input'),
        'B 2100 FX',
      );
      await harness.enterText(tester, const Key('vehicle_make_input'), 'Tesla');
      await harness.enterText(
        tester,
        const Key('vehicle_model_input'),
        'Cybertruck Future',
      );
      await harness.enterText(tester, const Key('vehicle_year_input'), '2100');
      await harness.tap(tester, const Key('save_vehicle_button'));

      expect(find.byKey(const Key('vehicle_form_error')), findsNothing);
      expect(find.textContaining('B 2100 FX'), findsOneWidget);
      expect(find.textContaining('Year: 2100'), findsOneWidget);
    });

    testWidgets(
      '7. Year below boundary (1899) is rejected with validation error',
      (tester) async {
        final harness = E2ETestHarness();
        await harness.pumpApp(
          tester,
          initialUser: SeedFixtures.adminUser,
          initialRoute: '/admin/vehicles',
        );

        await harness.tap(tester, const Key('register_vehicle_button'));
        await harness.enterText(
          tester,
          const Key('vehicle_plate_input'),
          'B 1899 INV',
        );
        await harness.enterText(
          tester,
          const Key('vehicle_make_input'),
          'Ancient',
        );
        await harness.enterText(
          tester,
          const Key('vehicle_model_input'),
          'Cart',
        );
        await harness.enterText(
          tester,
          const Key('vehicle_year_input'),
          '1899',
        );
        await harness.tap(tester, const Key('save_vehicle_button'));

        expect(find.byKey(const Key('vehicle_form_error')), findsOneWidget);
        expect(
          find.textContaining('Vehicle year must be between 1900 and 2100.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '8. Year above boundary (2101) is rejected with validation error',
      (tester) async {
        final harness = E2ETestHarness();
        await harness.pumpApp(
          tester,
          initialUser: SeedFixtures.adminUser,
          initialRoute: '/admin/vehicles',
        );

        await harness.tap(tester, const Key('register_vehicle_button'));
        await harness.enterText(
          tester,
          const Key('vehicle_plate_input'),
          'B 2101 INV',
        );
        await harness.enterText(
          tester,
          const Key('vehicle_make_input'),
          'SciFi',
        );
        await harness.enterText(
          tester,
          const Key('vehicle_model_input'),
          'Hovercar',
        );
        await harness.enterText(
          tester,
          const Key('vehicle_year_input'),
          '2101',
        );
        await harness.tap(tester, const Key('save_vehicle_button'));

        expect(find.byKey(const Key('vehicle_form_error')), findsOneWidget);
        expect(
          find.textContaining('Vehicle year must be between 1900 and 2100.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '9. Negative odometer mileage (-500) is rejected with validation error',
      (tester) async {
        final harness = E2ETestHarness();
        await harness.pumpApp(
          tester,
          initialUser: SeedFixtures.adminUser,
          initialRoute: '/admin/vehicles',
        );

        await harness.tap(tester, const Key('register_vehicle_button'));
        await harness.enterText(
          tester,
          const Key('vehicle_plate_input'),
          'B 9999 NEG',
        );
        await harness.enterText(
          tester,
          const Key('vehicle_make_input'),
          'Toyota',
        );
        await harness.enterText(
          tester,
          const Key('vehicle_model_input'),
          'Corolla',
        );
        await harness.enterText(
          tester,
          const Key('vehicle_year_input'),
          '2020',
        );
        await harness.enterText(
          tester,
          const Key('vehicle_mileage_input'),
          '-500',
        );
        await harness.tap(tester, const Key('save_vehicle_button'));

        expect(find.byKey(const Key('vehicle_form_error')), findsOneWidget);
        expect(
          find.textContaining('Odometer mileage cannot be negative.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('10. Zero odometer mileage (0 km brand new car) is accepted', (
      tester,
    ) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/vehicles',
      );

      await harness.tap(tester, const Key('register_vehicle_button'));
      await harness.enterText(
        tester,
        const Key('vehicle_plate_input'),
        'B 0000 NEW',
      );
      await harness.enterText(tester, const Key('vehicle_make_input'), 'BMW');
      await harness.enterText(
        tester,
        const Key('vehicle_model_input'),
        'M3 Competition',
      );
      await harness.enterText(tester, const Key('vehicle_year_input'), '2024');
      await harness.enterText(tester, const Key('vehicle_mileage_input'), '0');
      await harness.tap(tester, const Key('save_vehicle_button'));

      expect(find.byKey(const Key('vehicle_form_error')), findsNothing);
      expect(find.textContaining('B 0000 NEW'), findsOneWidget);
      expect(find.textContaining('Odometer: 0 km'), findsOneWidget);
    });

    testWidgets(
      '11. Extreme string lengths (255 chars) render without UI overflow',
      (tester) async {
        final longName = 'A' * 255;
        final harness = E2ETestHarness();
        await harness.pumpApp(
          tester,
          initialUser: SeedFixtures.adminUser,
          initialRoute: '/admin/customers',
        );

        await harness.tap(tester, const Key('add_customer_button'));
        await harness.enterText(
          tester,
          const Key('customer_name_input'),
          longName,
        );
        await harness.enterText(
          tester,
          const Key('customer_phone_input'),
          '08123456789',
        );
        await harness.tap(tester, const Key('save_customer_button'));

        expect(find.byKey(const Key('customer_form_error')), findsNothing);
        expect(find.text(longName), findsOneWidget);
        // Verify no Flutter render overflow occurred
        expect(tester.takeException(), isNull);
      },
    );
  });
}
