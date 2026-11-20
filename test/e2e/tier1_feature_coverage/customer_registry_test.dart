import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../harness/test_harness.dart';
import '../harness/fixtures/seed_fixtures.dart';

void main() {
  setUpAll(() {
    E2ETestHarness.ensureInitialized();
  });

  group('F5 & F7: Customer Registry & Guest Intake E2E Tests', () {
    testWidgets('1. Customer list renders registered and guest customers', (
      tester,
    ) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/customers',
      );

      expect(find.byKey(const Key('admin_customers_screen')), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Walk-in Guest Joko'), findsOneWidget);
    });

    testWidgets('2. Search filter narrows customer list by name query', (
      tester,
    ) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/customers',
      );

      await harness.enterText(
        tester,
        const Key('customer_search_field'),
        'Budi',
      );

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Walk-in Guest Joko'), findsNothing);
    });

    testWidgets('3. Search filter narrows customer list by phone query', (
      tester,
    ) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/customers',
      );

      await harness.enterText(
        tester,
        const Key('customer_search_field'),
        '08987654321',
      );

      expect(find.text('Walk-in Guest Joko'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('4. Guest filter switch shows only walk-in guests', (
      tester,
    ) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/customers',
      );

      // Toggle switch to only guests
      await harness.tap(tester, const Key('guest_filter_switch'));

      expect(find.text('Walk-in Guest Joko'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('5. Admin creates new registered customer with full details', (
      tester,
    ) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/customers',
      );

      await harness.tap(tester, const Key('add_customer_button'));
      expect(find.byKey(const Key('customer_form_dialog')), findsOneWidget);

      await harness.enterText(
        tester,
        const Key('customer_name_input'),
        'Siti Rahma',
      );
      await harness.enterText(
        tester,
        const Key('customer_phone_input'),
        '081399887766',
      );
      await harness.enterText(
        tester,
        const Key('customer_email_input'),
        'siti@example.com',
      );
      await harness.tap(tester, const Key('save_customer_button'));

      expect(find.text('Siti Rahma'), findsOneWidget);
      expect(find.textContaining('081399887766'), findsOneWidget);
    });

    testWidgets(
      '6. Admin creates walk-in guest customer without authentication',
      (tester) async {
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
          'Guest Anton',
        );
        await harness.enterText(
          tester,
          const Key('customer_phone_input'),
          '085544332211',
        );
        await harness.tap(tester, const Key('is_guest_checkbox'));
        await harness.tap(tester, const Key('save_customer_button'));

        expect(find.text('Guest Anton'), findsOneWidget);
        expect(find.text('Walk-In Guest'), findsWidgets);
      },
    );

    testWidgets('7. Validation prevents creating customer with blank name', (
      tester,
    ) async {
      final harness = E2ETestHarness();
      await harness.pumpApp(
        tester,
        initialUser: SeedFixtures.adminUser,
        initialRoute: '/admin/customers',
      );

      await harness.tap(tester, const Key('add_customer_button'));
      await harness.enterText(tester, const Key('customer_name_input'), '   ');
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

    testWidgets('8. Validation prevents creating customer with blank phone', (
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
      await harness.enterText(tester, const Key('customer_phone_input'), '   ');
      await harness.tap(tester, const Key('save_customer_button'));

      expect(find.byKey(const Key('customer_form_error')), findsOneWidget);
      expect(
        find.textContaining('Customer phone cannot be empty.'),
        findsOneWidget,
      );
    });

    test('9. Retrieve customer by profile ID returns linked record', () async {
      final harness = E2ETestHarness();
      final customer = await harness.customerRepo.getCustomerByProfileId(
        'cust-profile-001',
      );

      expect(customer, isNotNull);
      expect(customer!.name, equals('Budi Santoso'));
      expect(customer.isGuest, isFalse);
    });

    test('10. Convert guest customer to registered account updates isGuest and links profileId', () async {
      final harness = E2ETestHarness();
      final initialGuest = await harness.customerRepo.getCustomerById(
        'guest-001',
      );
      expect(initialGuest.isGuest, isTrue);
      expect(initialGuest.profileId, isNull);

      final converted = await harness.customerRepo.linkProfileToCustomer(
        'guest-001',
        'new-profile-999',
      );

      expect(converted.isGuest, isFalse);
      expect(converted.profileId, equals('new-profile-999'));
    });
  });
}
