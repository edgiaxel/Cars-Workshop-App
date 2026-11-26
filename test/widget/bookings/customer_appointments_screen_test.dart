import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/features/bookings/data/models/booking_model.dart';
import 'package:pitmate/features/bookings/data/repositories/booking_repository.dart';
import 'package:pitmate/features/bookings/presentation/screens/customer_appointments_screen.dart';

class _FakeAppointmentsRepository extends BookingRepository {
  _FakeAppointmentsRepository(this.bookings);

  final List<BookingModel> bookings;

  @override
  Future<List<BookingModel>> fetchCustomerBookings(String customerId) async {
    return List.from(bookings);
  }

  @override
  Future<BookingModel> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    String? adminNotes,
  }) async {
    final idx = bookings.indexWhere((b) => b.id == bookingId);
    final updated = bookings[idx].copyWith(status: status, adminNotes: adminNotes);
    bookings[idx] = updated;
    return updated;
  }
}

void main() {
  final sampleBookings = [
    BookingModel(
      id: 'bk-sample-01',
      customerId: 'cust-1',
      vehicleId: 'veh-1',
      bookingDate: DateTime(2026, 11, 25),
      timeSlot: '08:00 - 10:00',
      serviceType: 'Brake Service',
      customerNotes: 'Inspect brake pads',
      status: BookingStatus.confirmed,
      createdAt: DateTime(2026, 11, 20),
      updatedAt: DateTime(2026, 11, 20),
      vehiclePlate: 'B 2044 RFS',
      vehicleMake: 'Toyota',
      vehicleModel: 'GR Yaris',
    ),
    BookingModel(
      id: 'bk-sample-02',
      customerId: 'cust-1',
      vehicleId: 'veh-2',
      bookingDate: DateTime(2026, 11, 27),
      timeSlot: '10:00 - 12:00',
      serviceType: 'Periodic Service',
      customerNotes: '10,000 KM oil change',
      status: BookingStatus.pending,
      createdAt: DateTime(2026, 11, 20),
      updatedAt: DateTime(2026, 11, 20),
      vehiclePlate: 'B 9912 SPO',
      vehicleMake: 'Honda',
      vehicleModel: 'Civic Type R',
    ),
  ];

  Widget buildScreen() {
    final fakeRepo = _FakeAppointmentsRepository(List.from(sampleBookings));
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: CustomerAppointmentsScreen(
          initialCustomerId: 'cust-1',
          initialBookings: List.from(sampleBookings),
          bookingRepository: fakeRepo,
        ),
      ),
    );
  }

  group('CustomerAppointmentsScreen', () {
    testWidgets('renders appointments list with telemetry and vehicle details', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('YOUR WORKSHOP APPOINTMENTS'), findsOneWidget);
      expect(find.text('BRAKE SERVICE'), findsOneWidget);
      expect(find.text('PERIODIC SERVICE'), findsOneWidget);
      expect(find.text('B 2044 RFS'), findsOneWidget);
      expect(find.text('B 9912 SPO'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsWidgets);
      expect(find.text('PENDING REVIEW'), findsWidgets);
    });

    testWidgets('cancels pending appointment with confirmation dialog', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final cancelBtn = find.byKey(const Key('cancel-booking-btn-bk-sample-02'));
      await tester.ensureVisible(cancelBtn);
      await tester.pumpAndSettle();
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(find.text('Cancel Appointment?'), findsOneWidget);

      final confirmBtn = find.byKey(const Key('confirm-cancel-booking-button'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.text('Appointment has been cancelled.'), findsOneWidget);
    });
  });
}
