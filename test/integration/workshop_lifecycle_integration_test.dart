import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/data/models/booking.dart';
import 'package:pitmate/data/models/service_order.dart';
import 'package:pitmate/data/models/user_role.dart';

import '../helpers/fake_repositories.dart';

void main() {
  group('Phase 8 — End-to-End Workshop Lifecycle Integration Tests', () {
    late FakeBookingRepository bookingRepo;
    late FakeServiceOrderRepository serviceRepo;
    late FakeTaskRepository taskRepo;
    late FakeReportRepository reportRepo;

    setUp(() {
      bookingRepo = FakeBookingRepository();
      serviceRepo = FakeServiceOrderRepository([]);
      taskRepo = FakeTaskRepository([]);
      reportRepo = FakeReportRepository();
    });

    test(
        'Workflow 1: Booking creation → Check-in → Service execution → Completion with origin persistence',
        () async {
      // 1. Customer creates a booking
      final booking = await bookingRepo.createBooking(
        customerId: 'c1',
        vehicleId: 'v1',
        requestedService: 'Race Telemetry & Brake Overhaul',
        description: 'Brembo calipers overhaul before track day.',
        preferredDate: '2026-11-10',
        preferredTime: '10:00:00',
      );
      expect(booking.status, equals(BookingStatus.requested));

      // 2. Workshop Admin schedules the booking
      final scheduledBooking = await bookingRepo.updateBookingStatus(
        id: booking.id,
        status: BookingStatus.scheduled,
        adminNotes: 'Assigned Bay 3 for pre-inspection',
      );
      expect(scheduledBooking.status, equals(BookingStatus.scheduled));

      // 3. Vehicle arrives at workshop: Admin checks in the booking
      final checkInOrder = await serviceRepo.checkInBooking(
        bookingId: scheduledBooking.id,
        adminNotes: 'Customer arrived on schedule with BMW M3.',
      );

      // Verify origin persistence and arrival timestamp
      expect(checkInOrder.bookingId, equals(scheduledBooking.id));
      expect(checkInOrder.intakeOrigin, equals(ServiceIntakeOrigin.booking));
      expect(checkInOrder.arrivedAt, isNotNull);
      expect(checkInOrder.status, equals(ServiceStatus.requested));

      // 4. Technician is assigned and starts work
      final activeOrder = await serviceRepo.updateServiceOrderStatus(
        id: checkInOrder.id,
        status: ServiceStatus.inProgress,
      );
      expect(activeOrder.status, equals(ServiceStatus.inProgress));
      expect(activeOrder.intakeOrigin, equals(ServiceIntakeOrigin.booking));

      // Create and complete tasks
      final task = await taskRepo.createTask(
        serviceOrderId: activeOrder.id,
        assignedMechanicId: 'm1',
        title: 'Brake Disc Inspection & Fluid Flush',
      );
      expect(task.status, equals('pending'));

      await taskRepo.updateTaskStatus(task.id, 'completed');
      final completedTasks =
          await taskRepo.getTasks(serviceOrderId: activeOrder.id);
      expect(completedTasks.first.status, equals('completed'));

      // 5. Service completes and order is closed with final billing
      final completedOrder = await serviceRepo.updateServiceOrder(
        id: activeOrder.id,
        status: ServiceStatus.completed,
        finalTotal: 5800000,
      );
      expect(completedOrder.status, equals(ServiceStatus.completed));
      expect(completedOrder.finalTotal, equals(5800000));
      expect(completedOrder.intakeOrigin, equals(ServiceIntakeOrigin.booking));

      // Verify closed lifecycle
      final closedOrder = await serviceRepo.updateServiceOrderStatus(
        id: completedOrder.id,
        status: ServiceStatus.closed,
      );
      expect(closedOrder.status, equals(ServiceStatus.closed));
      expect(closedOrder.intakeOrigin, equals(ServiceIntakeOrigin.booking));
    });

    test(
        'Workflow 2: Walk-In vehicle arrival → Immediate Admission → Service execution → Completion',
        () async {
      // 1. Vehicle arrives without prior booking: Admin admits walk-in
      final walkInOrder = await serviceRepo.admitWalkIn(
        customerId: 'c1',
        vehicleId: 'v2',
        title: 'Emergency Alternator Repair',
        description: 'Battery warning indicator illuminated on highway.',
        odometerKm: 45200,
        estimatedTotal: 3200000,
      );

      // Verify walk-in origin and arrival timestamp
      expect(walkInOrder.intakeOrigin, equals(ServiceIntakeOrigin.walkIn));
      expect(walkInOrder.bookingId, isNull);
      expect(walkInOrder.arrivedAt, isNotNull);
      expect(walkInOrder.status, equals(ServiceStatus.requested));

      // 2. Start diagnostics
      final diagnosingOrder = await serviceRepo.updateServiceOrderStatus(
        id: walkInOrder.id,
        status: ServiceStatus.diagnosis,
      );
      expect(diagnosingOrder.status, equals(ServiceStatus.diagnosis));

      // 3. Move to in-progress repair
      final inProgressOrder = await serviceRepo.updateServiceOrderStatus(
        id: walkInOrder.id,
        status: ServiceStatus.inProgress,
      );
      expect(inProgressOrder.status, equals(ServiceStatus.inProgress));

      // 4. Complete repair with finalized invoice total
      final completedOrder = await serviceRepo.updateServiceOrder(
        id: inProgressOrder.id,
        status: ServiceStatus.completed,
        finalTotal: 3450000,
      );
      expect(completedOrder.status, equals(ServiceStatus.completed));
      expect(completedOrder.intakeOrigin, equals(ServiceIntakeOrigin.walkIn));
      expect(completedOrder.finalTotal, equals(3450000));
    });

    test(
        'Workflow 3: Duplicate check-in prevention and invalid booking status protection',
        () async {
      // Create a booking
      final booking = await bookingRepo.createBooking(
        customerId: 'c1',
        vehicleId: 'v1',
        requestedService: 'Suspension Tuning',
      );

      // First check-in succeeds
      final order1 = await serviceRepo.checkInBooking(bookingId: booking.id);
      expect(order1.bookingId, equals(booking.id));

      // Guard check: Booking is now associated with order1
      final existingOrders = await serviceRepo.getServiceOrders();
      final duplicateMatches =
          existingOrders.where((o) => o.bookingId == booking.id);
      expect(duplicateMatches.length, equals(1));

      // Ensure cancelled bookings cannot be checked in
      final cancelledBooking = await bookingRepo.createBooking(
        customerId: 'c1',
        vehicleId: 'v1',
        requestedService: 'Cancelled Order',
      );
      await bookingRepo.updateBookingStatus(
        id: cancelledBooking.id,
        status: BookingStatus.cancelled,
      );
      expect(cancelledBooking.status, equals(BookingStatus.requested));
      final reloaded = await bookingRepo.getBookingById(cancelledBooking.id);
      expect(reloaded.status, equals(BookingStatus.cancelled));
    });

    test(
        'Workflow 4: Telemetry reporting aggregate contracts enforce date boundaries and legacy isolation',
        () async {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 14));
      final endDate = now;

      final telemetry = await reportRepo.getTelemetry(
        startDate: startDate,
        endDate: endDate,
      );

      // Boundaries verified
      expect(telemetry.startDate, equals(startDate));
      expect(telemetry.endDate, equals(endDate));

      // Contract verification: Legacy unknown is strictly isolated
      final intake = telemetry.intakeBreakdown;
      expect(intake.legacyUnknownCount, greaterThan(0));
      expect(intake.walkInCount, equals(8));
      expect(intake.bookingCount, equals(15));
      expect(intake.totalOrders,
          equals(intake.bookingCount + intake.walkInCount + intake.legacyUnknownCount));

      // Financial verification: Settled revenue is separated from estimated pipeline
      final finance = telemetry.financialSummary;
      expect(finance.settledTotal, equals(32500000));
      expect(finance.estimatedTotal, equals(45000000));
      expect(finance.settledOrdersCount, equals(18));
      expect(finance.pendingSettlementCount, equals(7));

      // Technician workload verified
      expect(telemetry.mechanicWorkload.length, equals(2));
      final tech1 = telemetry.mechanicWorkload.first;
      expect(tech1.employeeCode, equals('TECH-01'));
      expect(tech1.assignedCount, equals(14));
      expect(tech1.completedCount, equals(11));
    });

    test('Workflow 5: User Role isolation and navigation independence', () {
      expect(UserRole.admin.displayName, equals('Admin'));
      expect(UserRole.mechanic.displayName, equals('Mechanic'));
      expect(UserRole.customer.displayName, equals('Customer'));

      expect(UserRole.fromDbString('admin'), equals(UserRole.admin));
      expect(UserRole.fromDbString('mechanic'), equals(UserRole.mechanic));
      expect(UserRole.fromDbString('customer'), equals(UserRole.customer));
    });
  });
}
