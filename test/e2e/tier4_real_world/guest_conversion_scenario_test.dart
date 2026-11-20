import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../harness/test_harness.dart';
import '../harness/models/e2e_user_profile.dart';
import '../harness/models/e2e_customer.dart';
import '../harness/models/e2e_vehicle.dart';

void main() {
  setUpAll(() {
    E2ETestHarness.ensureInitialized();
  });

  group('Tier 4 Scenario 5: Walk-In Guest Conversion to Registered Account Workflow', () {
    testWidgets('Guest customer converts to registered account while preserving vehicle ownership', (tester) async {
      // Step 1: Pre-populate guest customer and 2 vehicles in the workshop
      final guestCustomer = Customer(
        id: 'guest-joko-100',
        profileId: null,
        name: 'Joko Susilo',
        phone: '081234455667',
        isGuest: true,
      );

      final vehicle1 = Vehicle(
        id: 'veh-joko-01',
        customerId: 'guest-joko-100',
        licensePlate: 'B 3000 JOK',
        make: 'Honda',
        model: 'Jazz RS',
        year: 2018,
        currentMileage: 65000,
      );

      final vehicle2 = Vehicle(
        id: 'veh-joko-02',
        customerId: 'guest-joko-100',
        licensePlate: 'B 4000 JOK',
        make: 'Yamaha',
        model: 'NMAX',
        year: 2021,
        currentMileage: 18000,
      );

      final harness = E2ETestHarness(
        initialCustomers: [guestCustomer],
        initialVehicles: [vehicle1, vehicle2],
      );

      // Verify guest state in repository
      final initialGuestRecord =
          await harness.customerRepo.getCustomerById('guest-joko-100');
      expect(initialGuestRecord.isGuest, isTrue);
      expect(initialGuestRecord.profileId, isNull);

      final initialVehicles =
          await harness.vehicleRepo.getVehiclesByCustomerId('guest-joko-100');
      expect(initialVehicles.length, equals(2));

      // Step 2: Joko registers an authenticated customer account in PitMate
      final registeredUser = await harness.authRepo.signUp(
        email: 'joko.susilo@example.com',
        password: 'password123',
        fullName: 'Joko Susilo',
      );

      expect(registeredUser.role, equals(UserRole.customer));
      expect(registeredUser.id, isNotEmpty);

      // Step 3: Account conversion / linking executed
      final convertedCustomer = await harness.customerRepo.linkProfileToCustomer(
        'guest-joko-100',
        registeredUser.id,
      );

      expect(convertedCustomer.isGuest, isFalse);
      expect(convertedCustomer.profileId, equals(registeredUser.id));

      // Step 4: Customer opens Customer Garage
      await harness.pumpApp(
        tester,
        screenSize: ScreenSizes.mobile,
        initialUser: registeredUser,
        initialRoute: '/customer/garage',
      );

      // Step 5: Verify customer sees both vehicles in their garage
      expect(find.byKey(const Key('customer_garage_screen')), findsOneWidget);
      expect(find.textContaining('B 3000 JOK — Honda Jazz RS'), findsOneWidget);
      expect(find.textContaining('B 4000 JOK — Yamaha NMAX'), findsOneWidget);
    });
  });
}
