import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/features/customers/models/customer_vehicle.dart';
import 'package:pitmate/features/customers/presentation/customer_garage_screen.dart';

void main() {
  const sampleVehicles = [
    CustomerVehicle(
      id: 'veh-1',
      make: 'Toyota',
      model: 'GR Yaris',
      year: 2023,
      licensePlate: 'B 2044 RFS',
      mileageKm: 8400,
      trim: '1.6L Turbo',
      colorName: 'White',
      status: VehicleStatus.ready,
    ),
    CustomerVehicle(
      id: 'veh-2',
      make: 'Honda',
      model: 'Civic Type R',
      year: 2024,
      licensePlate: 'B 9912 SPO',
      mileageKm: 14250,
      trim: '2.0L VTEC Turbo',
      colorName: 'Red',
      status: VehicleStatus.inWorkshop,
      activeServiceOrderId: 'SO-202611-0001',
      bayAssignment: 'Bay 01',
    ),
    CustomerVehicle(
      id: 'veh-3',
      make: 'BMW',
      model: '320i F30 LCI',
      year: 2019,
      licensePlate: 'B 3021 RFS',
      mileageKm: 42100,
      trim: 'M Sport',
      colorName: 'Black',
      status: VehicleStatus.ready,
    ),
  ];

  Widget buildGarageScreen({List<CustomerVehicle>? vehicles}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: CustomerGarageScreen(
          initialVehicles: vehicles ?? sampleVehicles,
          onAddVehicleOverride: (vehicle) async {},
        ),
      ),
    );
  }

  group('CustomerGarageScreen', () {
    testWidgets('renders registered vehicles and telemetry badges', (tester) async {
      await tester.pumpWidget(buildGarageScreen());
      await tester.pumpAndSettle();

      expect(find.text('MY VEHICLES'), findsOneWidget);
      expect(find.text('Toyota GR Yaris'), findsOneWidget);
      expect(find.text('B 2044 RFS'), findsOneWidget);
      expect(find.text('Honda Civic Type R'), findsOneWidget);
      expect(find.text('B 9912 SPO'), findsOneWidget);
      expect(find.text('BMW 320i F30 LCI'), findsOneWidget);
      expect(find.text('B 3021 RFS'), findsOneWidget);
    });

    testWidgets('detects duplicate plate and displays warning', (tester) async {
      await tester.pumpWidget(buildGarageScreen());
      await tester.pumpAndSettle();

      final addBtn = find.byKey(const Key('add-vehicle-button'));
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text('ADD VEHICLE TO GARAGE'), findsOneWidget);

      final plateInput = find.byKey(const Key('vehicle-plate-input'));
      await tester.enterText(plateInput, 'b 2044 rfs');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('duplicate-plate-warning')), findsOneWidget);
      expect(find.textContaining('DUPLICATE WARNING'), findsOneWidget);

      final submitBtn = tester.widget<ElevatedButton>(
        find.byKey(const Key('submit-add-vehicle-button')),
      );
      expect(submitBtn.onPressed, isNull);
    });

    testWidgets('successfully registers a new vehicle with uppercase normalized plate', (tester) async {
      await tester.pumpWidget(buildGarageScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-vehicle-button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('vehicle-plate-input')), 'd 7777 gt');
      await tester.enterText(find.byKey(const Key('vehicle-make-input')), 'Porsche');
      await tester.enterText(find.byKey(const Key('vehicle-model-input')), '911 GT3');
      await tester.enterText(find.byKey(const Key('vehicle-year-input')), '2024');
      await tester.enterText(find.byKey(const Key('vehicle-mileage-input')), '3200');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('duplicate-plate-warning')), findsNothing);

      await tester.tap(find.byKey(const Key('submit-add-vehicle-button')));
      await tester.pumpAndSettle();

      expect(find.text('ADD VEHICLE TO GARAGE'), findsNothing);
      expect(find.text('Porsche 911 GT3'), findsOneWidget);
      expect(find.text('D 7777 GT'), findsOneWidget);
    });
  });
}
