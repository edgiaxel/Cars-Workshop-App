import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/router/route_paths.dart';

import '../harness/test_harness.dart';
import '../harness/fixtures/seed_fixtures.dart';

void main() {
  setUpAll(() {
    E2ETestHarness.ensureInitialized();
  });

  group('Tier 4 Scenario 1: Admin Walk-in Guest & Vehicle Intake Workflow', () {
    testWidgets('Complete walk-in intake flow from dashboard to customer & vehicle creation', (tester) async {
      final harness = E2ETestHarness();

      // Step 1: Admin launches into operational dashboard
      await harness.pumpApp(
        tester,
        screenSize: ScreenSizes.desktop,
        initialUser: SeedFixtures.adminUser,
        initialRoute: RoutePaths.admin,
      );

      expect(find.text('PitMate — ADMIN'), findsOneWidget);
      expect(find.text('Admin Operations Dashboard'), findsOneWidget);

      // Step 2: Navigate to Customers view via sidebar
      await harness.tap(tester, find.text('Customers'));
      expect(find.byKey(const Key('admin_customers_screen')), findsOneWidget);

      // Step 3: Open Add Customer dialog for walk-in guest intake
      await harness.tap(tester, const Key('add_customer_button'));
      expect(find.byKey(const Key('customer_form_dialog')), findsOneWidget);

      await harness.enterText(tester, const Key('customer_name_input'), 'Pak Bambang');
      await harness.enterText(tester, const Key('customer_phone_input'), '081233445566');
      await harness.tap(tester, const Key('is_guest_checkbox')); // Mark as walk-in guest
      await harness.tap(tester, const Key('save_customer_button'));

      // Verify customer appears in admin list
      expect(find.text('Pak Bambang'), findsOneWidget);

      final createdCustomer =
          (await harness.customerRepo.getCustomers(search: 'Bambang')).first;
      expect(createdCustomer.isGuest, isTrue);
      expect(createdCustomer.profileId, isNull);

      // Step 4: Navigate to Vehicles view via sidebar
      await harness.tap(tester, find.text('Vehicles'));
      expect(find.byKey(const Key('admin_vehicles_screen')), findsOneWidget);

      // Step 5: Register vehicle for the newly created guest customer
      await harness.tap(tester, const Key('register_vehicle_button'));
      expect(find.byKey(const Key('vehicle_registration_dialog')), findsOneWidget);

      await harness.enterText(tester, const Key('vehicle_customer_id_input'), createdCustomer.id);
      await harness.enterText(tester, const Key('vehicle_plate_input'), '  b  1982  wz  '); // test raw plate
      await harness.enterText(tester, const Key('vehicle_make_input'), 'Daihatsu');
      await harness.enterText(tester, const Key('vehicle_model_input'), 'Terios R');
      await harness.enterText(tester, const Key('vehicle_year_input'), '2021');
      await harness.enterText(tester, const Key('vehicle_mileage_input'), '32000');
      await harness.enterText(tester, const Key('vehicle_transmission_input'), 'Manual');
      await harness.tap(tester, const Key('save_vehicle_button'));

      // Step 6: Verify vehicle is listed with normalized plate
      expect(find.textContaining('B 1982 WZ — Daihatsu Terios R'), findsOneWidget);
      expect(find.textContaining('Year: 2021 | Odometer: 32000 km | Transmission: Manual'), findsOneWidget);

      // Step 7: Verify vehicle repository association
      final guestVehicles = await harness.vehicleRepo.getVehiclesByCustomerId(createdCustomer.id);
      expect(guestVehicles.length, equals(1));
      expect(guestVehicles.first.licensePlate, equals('B 1982 WZ'));
    });
  });
}
