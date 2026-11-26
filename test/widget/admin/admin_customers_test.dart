import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/features/admin/presentation/admin_customers_screen.dart';

void main() {
  const sampleCustomers = [
    AdminCustomerEntry(
      id: 'cust-reg-1',
      fullName: 'Axel Zeed',
      phoneNumber: '+62 812-0000-0001',
      email: 'lexazeed@gmail.com',
      customerType: CustomerType.registered,
      accountTier: 'individual',
      vehicles: ['B 2044 RFS'],
      totalVisits: 2,
      lastVisitDate: '2026-11-20',
    ),
    AdminCustomerEntry(
      id: 'cust-guest-1',
      fullName: 'Bambang Soediro (Walk-in)',
      phoneNumber: '+62 812-0000-0002',
      email: 'Walk-in Guest',
      customerType: CustomerType.guest,
      accountTier: 'guest',
      vehicles: ['B 9912 SPO'],
      totalVisits: 1,
      lastVisitDate: '2026-11-21',
    ),
  ];

  Widget buildAdminCustomersScreen() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: AdminCustomersScreen(
          initialCustomers: sampleCustomers,
          onAddCustomerOverride: (payload) async {
            final plate = (payload['license_plate'] as String? ?? '').trim();
            final isGuest = payload['customer_type'] == 'guest';
            return AdminCustomerEntry(
              id: 'cust-added-1',
              fullName: payload['full_name'] as String,
              phoneNumber: payload['phone_number'] as String,
              email: isGuest
                  ? 'Walk-in Guest'
                  : (payload['email'] as String? ?? '-'),
              customerType:
                  isGuest ? CustomerType.guest : CustomerType.registered,
              accountTier: payload['customer_type'] as String? ?? 'individual',
              vehicles: plate.isNotEmpty ? [plate] : const [],
              totalVisits: 0,
              lastVisitDate: 'No visits yet',
            );
          },
        ),
      ),
    );
  }

  group('AdminCustomersScreen', () {
    testWidgets('displays customer registry with registered and guest badges', (tester) async {
      await tester.pumpWidget(buildAdminCustomersScreen());
      await tester.pumpAndSettle();

      expect(find.text('TOTAL IN REGISTRY'), findsOneWidget);
      expect(find.text('REGISTERED CLIENTS'), findsOneWidget);
      expect(find.text('WALK-IN GUESTS'), findsOneWidget);

      expect(find.text('Axel Zeed'), findsOneWidget);
      expect(find.text('REGISTERED CUSTOMER'), findsWidgets);
      expect(find.text('Bambang Soediro (Walk-in)'), findsOneWidget);
      expect(find.text('GUEST CUSTOMER'), findsWidgets);
    });

    testWidgets('filters customers via search input', (tester) async {
      await tester.pumpWidget(buildAdminCustomersScreen());
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('admin-customer-search-input'));
      await tester.enterText(searchField, 'Bambang');
      await tester.pumpAndSettle();

      expect(find.text('Bambang Soediro (Walk-in)'), findsOneWidget);
      expect(find.text('Axel Zeed'), findsNothing);
    });

    testWidgets('registers walk-in guest via intake modal', (tester) async {
      await tester.pumpWidget(buildAdminCustomersScreen());
      await tester.pumpAndSettle();

      final newBtn = find.byKey(const Key('new-customer-button'));
      await tester.tap(newBtn);
      await tester.pumpAndSettle();

      expect(find.text('WALK-IN GUEST INTAKE'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('guest-name-input')), 'Dewi Lestari');
      await tester.enterText(find.byKey(const Key('guest-phone-input')), '+62 819-0011-2233');
      await tester.enterText(find.byKey(const Key('guest-plate-input')), 'b 4321 kls');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit-guest-intake-button')));
      await tester.pumpAndSettle();

      expect(find.text('Dewi Lestari'), findsOneWidget);
      expect(find.text('B 4321 KLS'), findsOneWidget);
      expect(find.text('+62 819-0011-2233'), findsOneWidget);
    });
  });
}
