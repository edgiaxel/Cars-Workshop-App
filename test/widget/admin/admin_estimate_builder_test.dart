import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/features/admin/presentation/admin_estimate_builder_screen.dart';

void main() {
  Widget buildAdminEstimateBuilderScreen() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AdminEstimateBuilderScreen(),
      ),
    );
  }

  group('AdminEstimateBuilderScreen Tests', () {
    testWidgets('renders service order and vehicle telemetry', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminEstimateBuilderScreen());
      await tester.pumpAndSettle();

      expect(find.text('ESTIMATE BUILDER'), findsWidgets);
      expect(find.text('SERVICE ORDER TELEMETRY'), findsOneWidget);
      expect(find.text('SO-202611-0001'), findsOneWidget);
      expect(find.text('Alex Pratama'), findsOneWidget);
      expect(find.text('Honda Civic Type R (FL5)'), findsOneWidget);
      expect(find.text('B 5678 CIV'), findsOneWidget);
      expect(find.text('Bay 02'), findsOneWidget);
      expect(find.text('8200 KM'), findsOneWidget);
    });

    testWidgets('displays diagnostic findings summary with Add Line action', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminEstimateBuilderScreen());
      await tester.pumpAndSettle();

      expect(find.text('DIAGNOSTIC FINDINGS & INSPECTION SUMMARY'), findsOneWidget);
      expect(find.text('Front Brake Pads (Brembo 4-pot)'), findsOneWidget);
      expect(find.text('URGENT'), findsOneWidget);
      expect(find.text('Brake Fluid Flush & Bleed'), findsOneWidget);
      expect(find.text('Add Line'), findsWidgets);
    });

    testWidgets('renders itemized lines editor with live line totals', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminEstimateBuilderScreen());
      await tester.pumpAndSettle();

      expect(find.text('ITEMIZED LINES EDITOR'), findsOneWidget);
      expect(find.text('Honda OEM Brembo Front Brake Pad Set (FL5)'), findsOneWidget);
      expect(find.text('Motul RBF 660 High-Temp Racing Brake Fluid (500ml)'), findsOneWidget);
      expect(find.text('Front Brake Overhaul & Precision Bleeding Service'), findsOneWidget);

      // Verify line total formatting
      expect(find.text('Rp 2.200.000'), findsOneWidget); // Brembo pad
      expect(find.text('Rp 450.000'), findsOneWidget);   // Motul fluid (2 x Rp 225.000)
      expect(find.text('Rp 500.000'), findsOneWidget);   // Labor
    });

    testWidgets('increments line quantity and updates grand total live', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminEstimateBuilderScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('text_grand_total')), findsOneWidget);
      expect(find.text('Rp 3.496.500'), findsOneWidget);

      // Increment quantity of item 0 (Brembo pad)
      final incBtn = find.byKey(const Key('btn_increment_qty_0'));
      await tester.tap(incBtn);
      await tester.pumpAndSettle();

      // Quantity should become 2
      expect(find.text('2'), findsWidgets);

      // Line total for Brembo should now be 2 x Rp 2.200.000 = Rp 4.400.000
      expect(find.text('Rp 4.400.000'), findsOneWidget);

      // Subtotal becomes: 4.400.000 + 450.000 + 500.000 = 5.350.000
      // 11% Tax = 588.500
      // Grand Total = 5.938.500
      expect(find.text('Rp 5.938.500'), findsOneWidget);
    });

    testWidgets('applies discount and updates grand total', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminEstimateBuilderScreen());
      await tester.pumpAndSettle();

      final discountField = find.byKey(const Key('field_discount_input'));
      expect(discountField, findsOneWidget);

      // Apply Rp 100.000 discount (input 100000)
      await tester.enterText(discountField, '100000');
      await tester.pumpAndSettle();

      // Original total 3.496.500 - 100.000 = 3.396.500
      expect(find.text('Rp 3.396.500'), findsOneWidget);
    });

    testWidgets('adds new line item when clicking + Part button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminEstimateBuilderScreen());
      await tester.pumpAndSettle();

      final addPartBtn = find.byKey(const Key('btn_add_part'));
      await tester.tap(addPartBtn);
      await tester.pumpAndSettle();

      expect(find.text('New Part'), findsOneWidget);
    });

    testWidgets('triggers save draft and publish estimate actions', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminEstimateBuilderScreen());
      await tester.pumpAndSettle();

      final saveDraftBtn = find.byKey(const Key('btn_save_draft'));
      await tester.tap(saveDraftBtn);
      await tester.pumpAndSettle();

      final publishBtn = find.byKey(const Key('btn_publish_estimate'));
      await tester.tap(publishBtn);
      await tester.pumpAndSettle();
    });
  });
}
