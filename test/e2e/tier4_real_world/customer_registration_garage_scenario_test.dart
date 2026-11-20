import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/router/route_paths.dart';

import '../harness/test_harness.dart';
import '../harness/models/e2e_customer.dart';
import '../harness/models/e2e_vehicle.dart';

void main() {
  setUpAll(() {
    E2ETestHarness.ensureInitialized();
  });

  group('Tier 4 Scenario 2: Customer Registration & Garage Onboarding Workflow', () {
    testWidgets('Full flow from self-service registration to garage view with registered vehicle', (tester) async {
      final harness = E2ETestHarness(initialCustomers: [], initialVehicles: []);

      // Step 1: Customer arrives at Login screen
      await harness.pumpApp(
        tester,
        screenSize: ScreenSizes.mobile,
        initialRoute: RoutePaths.login,
      );

      expect(find.byKey(const Key('login_screen')), findsOneWidget);

      // Step 2: Navigate to Register screen
      await harness.tap(tester, const Key('register_link_button'));
      expect(find.byKey(const Key('register_screen')), findsOneWidget);

      // Step 3: Fill registration form
      await harness.enterText(tester, const Key('register_name_input'), 'Dewi Lestari');
      await harness.enterText(tester, const Key('register_email_input'), 'dewi@example.com');
      await harness.enterText(tester, const Key('register_password_input'), 'secure123');
      await harness.tap(tester, const Key('register_submit_button'));

      // Step 4: System lands customer in their garage shell
      expect(find.text('PitMate — CUSTOMER'), findsOneWidget);
      expect(find.byKey(const Key('customer_garage_screen')), findsOneWidget);

      final registeredUser = harness.authRepo.currentUser;
      expect(registeredUser, isNotNull);
      expect(registeredUser!.email, equals('dewi@example.com'));

      // Initially no linked customer profile
      expect(find.byKey(const Key('garage_no_profile_state')), findsOneWidget);

      // Step 5: Workshop admin links profile and registers customer vehicle
      final newCustomer = await harness.customerRepo.createCustomer(
        Customer(
          id: 'cust-dewi',
          profileId: registeredUser.id,
          name: 'Dewi Lestari',
          phone: '081299887766',
          email: 'dewi@example.com',
          isGuest: false,
        ),
      );

      await harness.vehicleRepo.registerVehicle(
        Vehicle(
          id: 'veh-dewi-01',
          customerId: newCustomer.id,
          licensePlate: 'D 2024 DEW',
          make: 'Honda',
          model: 'HR-V Turbo',
          year: 2024,
          currentMileage: 2500,
          transmission: 'CVT',
        ),
      );

      // Step 6: Customer taps refresh in garage
      await harness.tap(tester, const Key('garage_refresh_button'));

      // Step 7: Garage now displays newly registered vehicle
      expect(find.textContaining('D 2024 DEW — Honda HR-V Turbo'), findsOneWidget);
      expect(find.textContaining('Year: 2024 | Mileage: 2500 km'), findsOneWidget);
    });
  });
}
