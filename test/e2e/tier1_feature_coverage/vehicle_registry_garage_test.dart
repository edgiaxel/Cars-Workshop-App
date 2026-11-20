import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../harness/test_harness.dart';
import '../harness/models/e2e_vehicle.dart';
import '../harness/fixtures/seed_fixtures.dart';

void main() {
  setUpAll(() {
    E2ETestHarness.ensureInitialized();
  });

  group('F6 & F8: Vehicle Registry & Customer Garage E2E Tests', () {
    testWidgets('1. Admin vehicle registry lists all registered workshop vehicles', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/vehicles',
      );

      expect(find.byKey(const Key('admin_vehicles_screen')), findsOneWidget);
      expect(find.textContaining('B 1234 CD'), findsOneWidget);
      expect(find.textContaining('Toyota Avanza'), findsOneWidget);
      expect(find.textContaining('D 5678 EF'), findsOneWidget);
      expect(find.textContaining('Honda Civic RS'), findsOneWidget);
    });

    testWidgets('2. Admin registers new vehicle for customer with complete details', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/vehicles',
      );

      await harness.tap(tester, const Key('register_vehicle_button'));
      expect(find.byKey(const Key('vehicle_registration_dialog')), findsOneWidget);

      await harness.enterText(tester, const Key('vehicle_customer_id_input'), 'cust-001');
      await harness.enterText(tester, const Key('vehicle_plate_input'), 'B 7777 WX');
      await harness.enterText(tester, const Key('vehicle_make_input'), 'Mitsubishi');
      await harness.enterText(tester, const Key('vehicle_model_input'), 'Pajero Sport');
      await harness.enterText(tester, const Key('vehicle_year_input'), '2023');
      await harness.enterText(tester, const Key('vehicle_mileage_input'), '15000');
      await harness.enterText(tester, const Key('vehicle_transmission_input'), 'Automatic');
      await harness.tap(tester, const Key('save_vehicle_button'));

      expect(find.textContaining('B 7777 WX'), findsOneWidget);
      expect(find.textContaining('Mitsubishi Pajero Sport'), findsOneWidget);
    });

    testWidgets('3. Plate normalization automatically uppercases and collapses spaces', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/vehicles',
      );

      await harness.tap(tester, const Key('register_vehicle_button'));
      await harness.enterText(tester, const Key('vehicle_plate_input'), '  b   8888   yz  ');
      await harness.enterText(tester, const Key('vehicle_make_input'), 'Hyundai');
      await harness.enterText(tester, const Key('vehicle_model_input'), 'Ioniq 5');
      await harness.tap(tester, const Key('save_vehicle_button'));

      // Expected normalized output: "B 8888 YZ"
      expect(find.textContaining('B 8888 YZ'), findsOneWidget);
    });

    testWidgets('4. Duplicate plate registration across any customer is rejected', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/vehicles',
      );

      // Attempt to register 'B 1234 CD' which already exists in seedFixtures
      await harness.tap(tester, const Key('register_vehicle_button'));
      await harness.enterText(tester, const Key('vehicle_plate_input'), 'b 1234 cd');
      await harness.enterText(tester, const Key('vehicle_make_input'), 'Toyota');
      await harness.enterText(tester, const Key('vehicle_model_input'), 'Fortuner');
      await harness.tap(tester, const Key('save_vehicle_button'));

      expect(find.byKey(const Key('vehicle_form_error')), findsOneWidget);
      expect(find.textContaining('Duplicate license plate: B 1234 CD already exists.'), findsOneWidget);
    });

    testWidgets('5. Vehicle search filter narrows vehicles by plate or model', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/vehicles',
      );

      await harness.enterText(tester, const Key('vehicle_search_field'), 'Civic');

      expect(find.textContaining('Honda Civic RS'), findsOneWidget);
      expect(find.textContaining('Toyota Avanza'), findsNothing);
    });

    testWidgets('6. Customer garage displays vehicles owned by logged-in customer', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.customerUser, // cust-profile-001 owns veh-001 and veh-002
        initialRoute: '/customer/garage',
      );

      expect(find.byKey(const Key('customer_garage_screen')), findsOneWidget);
      expect(find.textContaining('B 1234 CD — Toyota Avanza'), findsOneWidget);
      expect(find.textContaining('D 5678 EF — Honda Civic RS'), findsOneWidget);
    });

    testWidgets('7. Customer garage does not display vehicles belonging to others', (tester) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.customerUser,
        initialRoute: '/customer/garage',
      );

      // guestVehicle belongs to guest-001, not customerUser
      expect(find.textContaining('B 9999 ZZ'), findsNothing);
      expect(find.textContaining('Suzuki Ertiga'), findsNothing);
    });

    testWidgets('8. Customer garage displays empty state when customer has no vehicles', (tester) async {
      final harness = E2ETestHarness(initialVehicles: []); // Empty vehicles table
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.customerUser,
        initialRoute: '/customer/garage',
      );

      expect(find.byKey(const Key('garage_empty_state')), findsOneWidget);
      expect(find.text('No vehicles found in garage.'), findsOneWidget);
    });

    test('9. Vehicle model and normalization helper preserve specification invariants', () {
      final normalized = Vehicle.normalizePlate('  ab   1234   cde  ');
      expect(normalized, equals('AB 1234 CDE'));

      final v = SeedFixtures.vehicle1;
      expect(v.year, inInclusiveRange(1900, 2100));
      expect(v.currentMileage, greaterThanOrEqualTo(0));
      expect(v.transmission, isNotNull);
    });

    test('10. Query vehicles by customer ID returns all vehicles for that customer', () async {
      final harness = E2ETestHarness();
      final vehicles = await harness.vehicleRepo.getVehiclesByCustomerId('cust-001');

      expect(vehicles.length, equals(2));
      expect(vehicles.any((v) => v.licensePlate == 'B 1234 CD'), isTrue);
      expect(vehicles.any((v) => v.licensePlate == 'D 5678 EF'), isTrue);
    });
  });
}
