import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/router/route_paths.dart';

import '../harness/test_harness.dart';
import '../harness/models/e2e_user_profile.dart';
import '../harness/models/e2e_vehicle.dart';
import '../harness/fixtures/seed_fixtures.dart';

void main() {
  setUpAll(() {
    E2ETestHarness.ensureInitialized();
  });

  group('Tier 3: Cross-Feature Interaction Combinations E2E Tests', () {
    testWidgets(
      '1. Auth + Role Switching: Switching between Admin and Customer changes shell and route guards',
      (tester) async {
        final harness = E2ETestHarness();
        await harness.pumpApp(
          tester,
          initialUser: SeedFixtures.adminUser,
          initialRoute: RoutePaths.admin,
        );

        // Verify in Admin shell
        expect(find.text('PitMate — ADMIN'), findsOneWidget);

        // Sign out
        await harness.tap(tester, const Key('sign_out_button'));
        expect(find.byKey(const Key('login_screen')), findsOneWidget);

        // Log in as Customer
        await harness.enterText(
          tester,
          const Key('login_email_input'),
          'budi@example.com',
        );
        await harness.enterText(
          tester,
          const Key('login_password_input'),
          'password123',
        );
        await harness.tap(tester, const Key('login_submit_button'));

        // Verify in Customer shell
        expect(find.text('PitMate — CUSTOMER'), findsOneWidget);
        expect(find.byKey(const Key('customer_garage_screen')), findsOneWidget);
      },
    );

    testWidgets(
      '2. Guest Intake + Vehicle Registration: Admin registers walk-in guest and immediately links vehicle',
      (tester) async {
        final harness = E2ETestHarness();
        await harness.pumpApp(
          tester,
          initialUser: SeedFixtures.adminUser,
          initialRoute: '/admin/customers',
        );

        // Step 1: Create walk-in guest
        await harness.tap(tester, const Key('add_customer_button'));
        await harness.enterText(
          tester,
          const Key('customer_name_input'),
          'Guest Hendra',
        );
        await harness.enterText(
          tester,
          const Key('customer_phone_input'),
          '081298765432',
        );
        await harness.tap(tester, const Key('is_guest_checkbox'));
        await harness.tap(tester, const Key('save_customer_button'));

        // Verify guest in list
        expect(find.text('Guest Hendra'), findsOneWidget);
        final guestCustomer = (await harness.customerRepo.getCustomers(
          search: 'Hendra',
        )).first;
        expect(guestCustomer.isGuest, isTrue);

        // Step 2: Register vehicle for this guest
        await harness.tap(tester, find.text('Vehicles'));
        expect(find.byKey(const Key('admin_vehicles_screen')), findsOneWidget);

        await harness.tap(tester, const Key('register_vehicle_button'));
        await harness.enterText(
          tester,
          const Key('vehicle_customer_id_input'),
          guestCustomer.id,
        );
        await harness.enterText(
          tester,
          const Key('vehicle_plate_input'),
          'B 4444 HEN',
        );
        await harness.enterText(
          tester,
          const Key('vehicle_make_input'),
          'Daihatsu',
        );
        await harness.enterText(
          tester,
          const Key('vehicle_model_input'),
          'Xenia',
        );
        await harness.tap(tester, const Key('save_vehicle_button'));

        // Verify vehicle registered
        expect(find.textContaining('B 4444 HEN'), findsOneWidget);

        // Verify in vehicle repository that customerId matches guest ID
        final vehicles = await harness.vehicleRepo.getVehiclesByCustomerId(
          guestCustomer.id,
        );
        expect(vehicles.length, equals(1));
        expect(vehicles.first.licensePlate, equals('B 4444 HEN'));
      },
    );

    testWidgets(
      '3. Guest Conversion: Guest profile linked to authenticated user preserves vehicle associations',
      (tester) async {
        final harness = E2ETestHarness();

        // Guest customer 'guest-001' owns 'veh-003' (B 9999 ZZ)
        final guestCustomer = await harness.customerRepo.getCustomerById(
          'guest-001',
        );
        expect(guestCustomer.isGuest, isTrue);
        expect(guestCustomer.profileId, isNull);

        final initialVehicles = await harness.vehicleRepo
            .getVehiclesByCustomerId('guest-001');
        expect(initialVehicles.length, equals(1));
        expect(initialVehicles.first.licensePlate, equals('B 9999 ZZ'));

        // Customer registers with profile ID 'new-user-007'
        final convertedCustomer = await harness.customerRepo
            .linkProfileToCustomer('guest-001', 'new-user-007');
        expect(convertedCustomer.isGuest, isFalse);
        expect(convertedCustomer.profileId, equals('new-user-007'));

        // Launch customer garage with new authenticated user profile
        const convertedUserProfile = UserProfile(
          id: 'new-user-007',
          role: UserRole.customer,
          fullName: 'Joko Converted',
          email: 'joko@pitmate.com',
        );

        await harness.pumpApp(
          tester,
          initialUser: convertedUserProfile,
          initialRoute: '/customer/garage',
        );

        // Verify vehicle B 9999 ZZ is now visible in the garage
        expect(
          find.textContaining('B 9999 ZZ — Suzuki Ertiga'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '4. Duplicate Plate Across Customers: Second customer cannot register already owned plate',
      (tester) async {
        final harness = E2ETestHarness();
        await harness.pumpApp(
          tester,
          initialUser: SeedFixtures.adminUser,
          initialRoute: '/admin/vehicles',
        );

        // B 1234 CD belongs to cust-001. Try to register B 1234 CD for guest-001.
        await harness.tap(tester, const Key('register_vehicle_button'));
        await harness.enterText(
          tester,
          const Key('vehicle_customer_id_input'),
          'guest-001',
        );
        await harness.enterText(
          tester,
          const Key('vehicle_plate_input'),
          'B 1234 CD',
        );
        await harness.enterText(
          tester,
          const Key('vehicle_make_input'),
          'Honda',
        );
        await harness.enterText(
          tester,
          const Key('vehicle_model_input'),
          'Jazz',
        );
        await harness.tap(tester, const Key('save_vehicle_button'));

        expect(find.byKey(const Key('vehicle_form_error')), findsOneWidget);
        expect(
          find.textContaining(
            'Duplicate license plate: B 1234 CD already exists.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('5. Dynamic Theme Persistence across Route Navigation', (
      tester,
    ) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: RoutePaths.admin,
      );

      // Starts in dark mode
      var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, equals(ThemeMode.dark));

      // Toggle to Light mode
      await harness.tap(tester, const Key('theme_toggle_button'));
      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, equals(ThemeMode.light));

      // Navigate to Customers screen
      await harness.tap(tester, find.text('Customers'));
      expect(find.byKey(const Key('admin_customers_screen')), findsOneWidget);

      // Theme remains Light
      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, equals(ThemeMode.light));

      // Navigate to Vehicles screen
      await harness.tap(tester, find.text('Vehicles'));
      expect(find.byKey(const Key('admin_vehicles_screen')), findsOneWidget);

      // Theme remains Light
      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, equals(ThemeMode.light));
    });

    testWidgets(
      '6. Customer Garage immediately updates when Admin adds a vehicle',
      (tester) async {
        final harness = E2ETestHarness();

        // Launch customer garage
        await harness.pumpApp(
          tester,
          initialUser: SeedFixtures.customerUser,
          initialRoute: '/customer/garage',
        );

        // Currently has 2 vehicles: B 1234 CD and D 5678 EF
        expect(find.textContaining('B 1234 CD'), findsOneWidget);
        expect(find.textContaining('D 5678 EF'), findsOneWidget);
        expect(find.textContaining('F 9999 GH'), findsNothing);

        // Admin registers third vehicle for cust-001
        await harness.vehicleRepo.registerVehicle(
          Vehicle(
            id: 'veh-004',
            customerId: 'cust-001',
            licensePlate: 'F 9999 GH',
            make: 'Toyota',
            model: 'Innova Zenix',
            year: 2023,
            currentMileage: 5000,
          ),
        );

        // Customer taps garage refresh button
        await harness.tap(tester, const Key('garage_refresh_button'));

        // Third vehicle is now present
        expect(
          find.textContaining('F 9999 GH — Toyota Innova Zenix'),
          findsOneWidget,
        );
      },
    );
  });
}
