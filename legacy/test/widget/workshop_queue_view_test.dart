import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/data/models/booking.dart';
import 'package:pitmate/data/models/customer.dart';
import 'package:pitmate/data/models/service_order.dart';
import 'package:pitmate/data/models/user_profile.dart';
import 'package:pitmate/data/models/user_role.dart';
import 'package:pitmate/data/models/vehicle.dart';
import 'package:pitmate/features/admin/presentation/admin_queue_view.dart';
import 'package:pitmate/features/auth/domain/auth_session_state.dart';
import 'package:pitmate/shared/providers/auth_provider.dart';
import 'package:pitmate/shared/providers/booking_provider.dart';
import 'package:pitmate/shared/providers/customer_provider.dart';
import 'package:pitmate/shared/providers/service_order_provider.dart';
import 'package:pitmate/shared/providers/vehicle_provider.dart';

import '../helpers/fake_repositories.dart';

class _FakeAuthNotifier extends AuthSessionNotifier {
  _FakeAuthNotifier(this._state);
  final AuthSessionState _state;

  @override
  AuthSessionState build() => _state;
}

void main() {
  group('Phase 3 & Phase 7 Workshop Queue View Widget Tests', () {
    const adminProfile = UserProfile(
      id: 'admin-1',
      role: UserRole.admin,
      fullName: 'Christian Horner',
    );

    final customer1 = Customer(
      id: 'c1',
      profileId: 'p1',
      customerType: 'individual',
      profile: const UserProfile(
        id: 'p1',
        role: UserRole.customer,
        fullName: 'Axel Zeed',
      ),
    );

    const vehicle1 = Vehicle(
      id: 'v1',
      customerId: 'c1',
      make: 'BMW',
      model: 'M3 Touring',
      licensePlate: 'D 1999 AZ',
    );

    final arrivedWaitingOrder = ServiceOrder(
      id: 'so-waiting-1',
      orderNumber: 'SO-101',
      customerId: 'c1',
      vehicleId: 'v1',
      title: 'Oil Service & Brake Inspection',
      status: ServiceStatus.requested,
      intakeOrigin: ServiceIntakeOrigin.walkIn,
      arrivedAt: DateTime.now().subtract(const Duration(minutes: 25)),
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      customer: customer1,
      vehicle: vehicle1,
    );

    final inServiceOrder = ServiceOrder(
      id: 'so-inservice-1',
      orderNumber: 'SO-102',
      customerId: 'c1',
      vehicleId: 'v1',
      title: 'Engine Diagnostics & Spark Plugs',
      status: ServiceStatus.inProgress,
      intakeOrigin: ServiceIntakeOrigin.booking,
      arrivedAt: DateTime.now().subtract(const Duration(minutes: 60)),
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      customer: customer1,
      vehicle: vehicle1,
    );

    final blockedOrder = ServiceOrder(
      id: 'so-blocked-1',
      orderNumber: 'SO-103',
      customerId: 'c1',
      vehicleId: 'v1',
      title: 'Transmission Clutch Overhaul',
      status: ServiceStatus.waitingForParts,
      intakeOrigin: ServiceIntakeOrigin.walkIn,
      arrivedAt: DateTime.now().subtract(const Duration(minutes: 90)),
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      customer: customer1,
      vehicle: vehicle1,
    );

    final upcomingBooking = Booking(
      id: 'bk-upcoming-1',
      customerId: 'c1',
      vehicleId: 'v1',
      requestedService: 'Scheduled 30,000 KM Maintenance',
      status: BookingStatus.scheduled,
      preferredDate: '2026-11-04',
      preferredTime: '11:00 AM',
      customer: customer1,
      vehicle: vehicle1,
    );

    Widget createTestWidget({
      List<ServiceOrder>? orders,
      List<Booking>? bookings,
      Brightness brightness = Brightness.dark,
    }) {
      return ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            () => _FakeAuthNotifier(
              AuthSessionState.authenticated(
                userId: 'admin-1',
                email: 'admin@pitmate.co',
                profile: adminProfile,
              ),
            ),
          ),
          serviceOrderRepositoryProvider.overrideWithValue(
            FakeServiceOrderRepository(orders ?? [arrivedWaitingOrder, inServiceOrder, blockedOrder]),
          ),
          bookingRepositoryProvider.overrideWithValue(
            FakeBookingRepository(bookings ?? [upcomingBooking]),
          ),
          customerRepositoryProvider.overrideWithValue(
            FakeCustomerRepository([customer1]),
          ),
          vehicleRepositoryProvider.overrideWithValue(
            FakeVehicleRepository([vehicle1]),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const AdminQueuePage(),
        ),
      );
    }

    testWidgets('Renders workshop queue header, telemetry metrics, and physical sections', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('WORKSHOP DISPATCH & QUEUE'), findsOneWidget);
      expect(find.text('Live FIFO Queue Control'), findsOneWidget);
      expect(find.text('Admit Walk-In'), findsOneWidget);

      // Section Filter Tabs
      expect(find.text('Waiting'), findsOneWidget);
      expect(find.text('In Service'), findsOneWidget);
      expect(find.text('Blocked'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('All Active'), findsOneWidget);
    });

    testWidgets('Displays intake origin badge, arrival time, and order details in Waiting section', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // By default Waiting tab is selected
      expect(find.text('SO-101'), findsOneWidget);
      expect(find.textContaining('Oil Service & Brake Inspection'), findsOneWidget);
      expect(find.text('WALK-IN'), findsWidgets);
      expect(find.text('Start Inspection'), findsOneWidget);
    });

    testWidgets('Switching to Blocked tab displays blocked orders with hold callout', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Blocked tab
      await tester.tap(find.text('Blocked'));
      await tester.pumpAndSettle();

      expect(find.text('SO-103'), findsOneWidget);
      expect(find.textContaining('Transmission Clutch Overhaul'), findsOneWidget);
      expect(find.textContaining('BLOCKED: Awaiting spare parts'), findsOneWidget);
    });

    testWidgets('Switching to Upcoming tab displays scheduled bookings with Check In action', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Upcoming tab
      await tester.tap(find.text('Upcoming'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Scheduled 30,000 KM Maintenance'), findsOneWidget);
      expect(find.text('BOOKING SCHEDULED'), findsOneWidget);
      expect(find.text('Check In Vehicle'), findsOneWidget);
    });

    testWidgets('Admit Walk-In button opens admission modal sheet', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Admit Walk-In'));
      await tester.pumpAndSettle();

      expect(find.text('ADMIT WALK-IN VEHICLE'), findsOneWidget);
      expect(find.text('Admit Vehicle to Queue'), findsOneWidget);
    });
  });
}
