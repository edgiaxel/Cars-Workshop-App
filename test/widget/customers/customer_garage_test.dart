import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/features/customers/presentation/customer_garage_screen.dart';

void main() {
  Widget buildGarageScreen() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: const CustomerGarageScreen(),
    );
  }

  group('CustomerGarageScreen', () {
    testWidgets('renders registered vehicles and telemetry badges', (tester) async {
      await tester.pumpWidget(buildGarageScreen());
      await tester.pumpAndSettle();

      expect(find.text('MY VEHICLES'), findsOneWidget);
      expect(find.text('Toyota GR Yaris'), findsOneWidget);
      expect(find.text('B 2044 RFS'), findsOneWidget);
      expect(find.text('Honda Civic Type R (FL5)'), findsOneWidget);
      expect(find.text('B 9912 SPO'), findsOneWidget);
      expect(find.text('BMW 320i F30 LCI'), findsOneWidget);
      expect(find.text('B 3021 RFS'), findsOneWidget);
    });

    testWidgets('detects duplicate plate and displays warning', (tester) async {
      await tester.pumpWidget(buildGarageScreen());
      await tester.pumpAndSettle();

      // Open Add Vehicle Sheet
      final addBtn = find.byKey(const Key('add-vehicle-button'));
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text('ADD VEHICLE TO GARAGE'), findsOneWidget);

      // Enter an already registered plate: "B 2044 RFS" (lowercase to test normalization too)
      final plateInput = find.byKey(const Key('vehicle-plate-input'));
      await tester.enterText(plateInput, 'b 2044 rfs');
      await tester.pumpAndSettle();

      // Check duplicate warning is shown
      expect(find.byKey(const Key('duplicate-plate-warning')), findsOneWidget);
      expect(find.textContaining('DUPLICATE WARNING'), findsOneWidget);

      // Submit button should be disabled
      final submitBtn = tester.widget<ElevatedButton>(
        find.byKey(const Key('submit-add-vehicle-button')),
      );
      expect(submitBtn.onPressed, isNull);
    });

    testWidgets('successfully registers a new vehicle with uppercase normalized plate', (tester) async {
      await tester.pumpWidget(buildGarageScreen());
      await tester.pumpAndSettle();

      // Open Add Vehicle Sheet
      await tester.tap(find.byKey(const Key('add-vehicle-button')));
      await tester.pumpAndSettle();

      // Enter unique plate in lowercase
      await tester.enterText(find.byKey(const Key('vehicle-plate-input')), 'd 7777 gt');
      await tester.enterText(find.byKey(const Key('vehicle-make-input')), 'Porsche');
      await tester.enterText(find.byKey(const Key('vehicle-model-input')), '911 GT3');
      await tester.enterText(find.byKey(const Key('vehicle-year-input')), '2024');
      await tester.enterText(find.byKey(const Key('vehicle-mileage-input')), '3200');
      await tester.pumpAndSettle();

      // Verify no duplicate warning
      expect(find.byKey(const Key('duplicate-plate-warning')), findsNothing);

      // Tap submit
      await tester.tap(find.byKey(const Key('submit-add-vehicle-button')));
      await tester.pumpAndSettle();

      // Modal closed, new vehicle visible in garage list with uppercase normalized plate
      expect(find.text('ADD VEHICLE TO GARAGE'), findsNothing);
      expect(find.text('Porsche 911 GT3'), findsOneWidget);
      expect(find.text('D 7777 GT'), findsOneWidget);
    });
  });
}
