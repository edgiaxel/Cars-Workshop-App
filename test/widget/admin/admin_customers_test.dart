import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/features/admin/presentation/admin_customers_screen.dart';

void main() {
  Widget buildAdminCustomersScreen() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: const AdminCustomersScreen(),
    );
  }

  group('AdminCustomersScreen', () {
    testWidgets('displays customer registry with registered and guest badges', (tester) async {
      await tester.pumpWidget(buildAdminCustomersScreen());
      await tester.pumpAndSettle();

      expect(find.text('TOTAL IN REGISTRY'), findsOneWidget);
      expect(find.text('REGISTERED CLIENTS'), findsOneWidget);
      expect(find.text('WALK-IN GUESTS'), findsOneWidget);

      expect(find.text('Alex Pratama'), findsOneWidget);
      expect(find.text('REGISTERED CUSTOMER'), findsWidgets);
      expect(find.text('Bambang Soediro (Walk-in)'), findsOneWidget);
      expect(find.text('GUEST CUSTOMER'), findsWidgets);
    });

    testWidgets('filters customers via search input', (tester) async {
      await tester.pumpWidget(buildAdminCustomersScreen());
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byKey(const Key('admin-customer-search-input'));
      await tester.enterText(searchField, 'Bambang');
      await tester.pumpAndSettle();

      expect(find.text('Bambang Soediro (Walk-in)'), findsOneWidget);
      expect(find.text('Alex Pratama'), findsNothing);
    });

    testWidgets('registers walk-in guest via intake modal', (tester) async {
      await tester.pumpWidget(buildAdminCustomersScreen());
      await tester.pumpAndSettle();

      // Open modal
      final newBtn = find.byKey(const Key('new-customer-button'));
      await tester.tap(newBtn);
      await tester.pumpAndSettle();

      expect(find.text('WALK-IN GUEST INTAKE'), findsOneWidget);

      // Fill in details
      await tester.enterText(find.byKey(const Key('guest-name-input')), 'Dewi Lestari');
      await tester.enterText(find.byKey(const Key('guest-phone-input')), '+62 819-0011-2233');
      await tester.enterText(find.byKey(const Key('guest-plate-input')), 'b 4321 kls');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byKey(const Key('submit-guest-intake-button')));
      await tester.pumpAndSettle();

      // Verify added in customer list
      expect(find.text('Dewi Lestari'), findsOneWidget);
      expect(find.text('B 4321 KLS'), findsOneWidget);
      expect(find.text('+62 819-0011-2233'), findsOneWidget);
    });
  });
}
