import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/features/bookings/data/models/booking_model.dart';
import 'package:pitmate/features/bookings/data/repositories/booking_repository.dart';
import 'package:pitmate/features/bookings/presentation/screens/book_service_screen.dart';

class _FakeBookServiceRepository extends BookingRepository {
  @override
  Future<BookingModel> createBooking(Map<String, dynamic> data) async {
    return BookingModel(
      id: 'bk-new-1',
      customerId: data['customer_id'] as String? ?? 'cust-1',
      vehicleId: data['vehicle_id'] as String? ?? 'veh-1',
      bookingDate: DateTime.parse(data['booking_date'] as String),
      timeSlot: data['time_slot'] as String,
      serviceType: data['service_type'] as String,
      customerNotes: data['customer_notes'] as String?,
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  const testVehicles = [
    VehicleOption(
      id: 'veh-1',
      licensePlate: 'B 9912 SPO',
      make: 'Honda',
      model: 'Civic Type R',
      year: 2023,
    ),
  ];

  Widget buildScreen({List<VehicleOption>? vehicles}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: BookServiceScreen(
          initialVehicles: vehicles ?? testVehicles,
          initialCustomerId: 'cust-1',
          bookingRepository: _FakeBookServiceRepository(),
        ),
      ),
    );
  }

  group('BookServiceScreen', () {
    testWidgets('renders all booking form sections and controls', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('SCHEDULE SERVICE VISIT'), findsOneWidget);
      expect(find.text('1. SELECT VEHICLE'), findsOneWidget);
      expect(find.text('2. DATE & ARRIVAL WINDOW'), findsOneWidget);
      expect(find.text('3. SERVICE TYPE'), findsOneWidget);
      expect(find.text('4. COMPLAINTS & SPECIFIC REQUESTS'), findsOneWidget);

      expect(find.byKey(const Key('book-service-vehicle-dropdown')), findsOneWidget);
      expect(find.byKey(const Key('book-service-date-picker')), findsOneWidget);
      expect(find.byKey(const Key('book-service-type-dropdown')), findsOneWidget);
      expect(find.byKey(const Key('book-service-complaints-input')), findsOneWidget);
      expect(find.byKey(const Key('submit-booking-button')), findsOneWidget);
    });

    testWidgets('shows honest empty state when customer has zero vehicles', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen(vehicles: const []));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No vehicles registered in your garage yet. Register a vehicle first to book a workshop visit.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('go-to-garage-button')), findsOneWidget);
      expect(find.text('REGISTER A VEHICLE'), findsOneWidget);
    });

    testWidgets('allows selecting time slot choice chip', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final slotChip = find.byKey(const Key('slot-chip-10:00 - 12:00'));
      await tester.ensureVisible(slotChip);
      await tester.pumpAndSettle();
      await tester.tap(slotChip);
      await tester.pumpAndSettle();

      final choiceChip = tester.widget<ChoiceChip>(slotChip);
      expect(choiceChip.selected, isTrue);
    });

    testWidgets('validates required complaints field before submitting', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final submitBtn = find.byKey(const Key('submit-booking-button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please describe the symptoms or reason for service'), findsOneWidget);
    });

    testWidgets('submits booking and displays confirmation dialog', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final complaintsField = find.byKey(const Key('book-service-complaints-input'));
      await tester.ensureVisible(complaintsField);
      await tester.enterText(complaintsField, 'Brake vibration during highway deceleration');
      await tester.pumpAndSettle();

      final submitBtn = find.byKey(const Key('submit-booking-button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Booking Confirmed'), findsOneWidget);
      expect(find.byKey(const Key('booking-success-ok-button')), findsOneWidget);
    });
  });
}
