import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/features/admin/presentation/admin_bookings_screen.dart';
import 'package:pitmate/features/bookings/data/models/booking_model.dart';
import 'package:pitmate/features/bookings/data/repositories/booking_repository.dart';

class _FakeAdminBookingRepository extends BookingRepository {
  _FakeAdminBookingRepository(this.store);

  final List<BookingModel> store;

  @override
  Future<List<BookingModel>> fetchAdminBookings({BookingStatus? status}) async {
    if (status == null) return List.from(store);
    return store.where((b) => b.status == status).toList();
  }

  @override
  Future<BookingModel> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    String? adminNotes,
  }) async {
    final idx = store.indexWhere((b) => b.id == bookingId);
    final updated = store[idx].copyWith(status: status, adminNotes: adminNotes);
    store[idx] = updated;
    return updated;
  }
}

void main() {
  List<BookingModel> buildSampleBookings() => [
        BookingModel(
          id: 'bk-adm-01',
          customerId: 'cust-1',
          vehicleId: 'veh-1',
          bookingDate: DateTime(2026, 11, 25),
          timeSlot: '08:00 - 10:00',
          serviceType: 'Periodic Service',
          customerNotes: 'Routine inspection',
          status: BookingStatus.confirmed,
          createdAt: DateTime(2026, 11, 20),
          updatedAt: DateTime(2026, 11, 20),
          customerName: 'Axel Zeed',
          customerPhone: '+62 812-0000-0001',
          vehiclePlate: 'B 2044 RFS',
          vehicleMake: 'Toyota',
          vehicleModel: 'GR Yaris',
        ),
        BookingModel(
          id: 'bk-adm-02',
          customerId: 'cust-2',
          vehicleId: 'veh-2',
          bookingDate: DateTime(2026, 11, 26),
          timeSlot: '10:00 - 12:00',
          serviceType: 'Brake Service',
          customerNotes: 'Brake check',
          status: BookingStatus.pending,
          createdAt: DateTime(2026, 11, 20),
          updatedAt: DateTime(2026, 11, 20),
          customerName: 'Bambang Soediro',
          customerPhone: '+62 812-0000-0002',
          vehiclePlate: 'B 9912 SPO',
          vehicleMake: 'Honda',
          vehicleModel: 'Civic RS',
        ),
        BookingModel(
          id: 'bk-adm-03',
          customerId: 'cust-3',
          vehicleId: 'veh-3',
          bookingDate: DateTime(2026, 11, 27),
          timeSlot: '13:00 - 15:00',
          serviceType: 'Engine Diagnostics',
          status: BookingStatus.checked_in,
          createdAt: DateTime(2026, 11, 20),
          updatedAt: DateTime(2026, 11, 20),
          customerName: 'Rian Hidayat',
          customerPhone: '+62 812-0000-0003',
          vehiclePlate: 'B 3021 RFS',
          vehicleMake: 'BMW',
          vehicleModel: '320i',
        ),
      ];

  Widget buildScreen() {
    final samples = buildSampleBookings();
    final repo = _FakeAdminBookingRepository(samples);
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: AdminBookingsScreen(
          initialBookings: samples,
          bookingRepository: repo,
        ),
      ),
    );
  }

  group('AdminBookingsScreen', () {
    testWidgets('displays KPI summary tiles and booking cards', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('TOTAL BOOKINGS'), findsOneWidget);
      expect(find.text('PENDING REVIEW'), findsWidgets);
      expect(find.text('CONFIRMED'), findsWidgets);
      expect(find.text('CHECKED IN'), findsWidgets);

      expect(find.text('Axel Zeed'), findsOneWidget);
      expect(find.text('Bambang Soediro'), findsOneWidget);
      expect(find.text('Rian Hidayat'), findsOneWidget);
    });

    testWidgets('filters booking cards via search input', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('admin-booking-search-input'));
      await tester.enterText(searchField, 'Bambang');
      await tester.pumpAndSettle();

      expect(find.text('Bambang Soediro'), findsOneWidget);
      expect(find.text('Axel Zeed'), findsNothing);
    });

    testWidgets('approves pending booking and updates status to confirmed', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final approveBtn = find.byKey(const Key('approve-booking-btn-bk-adm-02'));
      await tester.ensureVisible(approveBtn);
      await tester.pumpAndSettle();
      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Booking for Bambang Soediro confirmed.'), findsOneWidget);
    });

    testWidgets('rejects booking with specified reason', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final rejectBtn = find.byKey(const Key('reject-booking-btn-bk-adm-02'));
      await tester.ensureVisible(rejectBtn);
      await tester.pumpAndSettle();
      await tester.tap(rejectBtn);
      await tester.pumpAndSettle();

      expect(find.text('Reject Booking Request'), findsOneWidget);
      final reasonField = find.byKey(const Key('reject-reason-input'));
      await tester.enterText(reasonField, 'Workshop at maximum bay capacity');
      await tester.pumpAndSettle();

      final confirmRejectBtn = find.byKey(const Key('confirm-reject-booking-button'));
      await tester.tap(confirmRejectBtn);
      await tester.pumpAndSettle();

      expect(find.text('Booking rejected.'), findsOneWidget);
    });

    testWidgets('opens Customer Intake Modal when tapping intake check-in', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final intakeBtn = find.byKey(const Key('intake-checkin-btn-bk-adm-01'));
      await tester.ensureVisible(intakeBtn);
      await tester.pumpAndSettle();
      await tester.tap(intakeBtn);
      await tester.pumpAndSettle();

      expect(find.text('BOOKING INTAKE CHECK-IN'), findsOneWidget);
      expect(find.byKey(const Key('submit-intake-button')), findsOneWidget);
    });

    testWidgets('opens Walk-in Intake Modal via action button', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final newIntakeBtn = find.byKey(const Key('admin-new-walkin-intake-btn'));
      await tester.ensureVisible(newIntakeBtn);
      await tester.pumpAndSettle();
      await tester.tap(newIntakeBtn);
      await tester.pumpAndSettle();

      expect(find.text('WORKSHOP VEHICLE INTAKE'), findsOneWidget);
      expect(find.byKey(const Key('intake-mode-registered')), findsOneWidget);
      expect(find.byKey(const Key('intake-mode-walk-in')), findsOneWidget);
    });
  });
}
