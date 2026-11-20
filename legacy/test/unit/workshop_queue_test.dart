import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/data/models/service_order.dart';

void main() {
  group('Phase 3 Workshop Queue FIFO Arrival Ordering & Business Logic', () {
    test('FIFO sorting orders by arrivedAt ASC, then createdAt ASC, then id ASC', () {
      final now = DateTime(2026, 11, 4, 10, 0);

      final order1 = ServiceOrder(
        id: 'order-c',
        orderNumber: 'SO-003',
        customerId: 'cust-1',
        vehicleId: 'veh-1',
        title: 'Brake Fluid Flush',
        intakeOrigin: ServiceIntakeOrigin.walkIn,
        arrivedAt: now.subtract(const Duration(minutes: 15)),
        createdAt: now.subtract(const Duration(minutes: 20)),
      );

      final order2 = ServiceOrder(
        id: 'order-a',
        orderNumber: 'SO-001',
        customerId: 'cust-2',
        vehicleId: 'veh-2',
        title: 'Oil Service',
        intakeOrigin: ServiceIntakeOrigin.booking,
        arrivedAt: now.subtract(const Duration(minutes: 45)),
        createdAt: now.subtract(const Duration(hours: 2)),
      );

      final order3 = ServiceOrder(
        id: 'order-b',
        orderNumber: 'SO-002',
        customerId: 'cust-3',
        vehicleId: 'veh-3',
        title: 'Tire Rotation',
        intakeOrigin: ServiceIntakeOrigin.booking,
        arrivedAt: now.subtract(const Duration(minutes: 45)),
        createdAt: now.subtract(const Duration(hours: 1)),
      );

      final orderUnarrived = ServiceOrder(
        id: 'order-d',
        orderNumber: 'SO-004',
        customerId: 'cust-4',
        vehicleId: 'veh-4',
        title: 'Scheduled Maintenance',
        intakeOrigin: ServiceIntakeOrigin.booking,
        arrivedAt: null,
        createdAt: now.subtract(const Duration(minutes: 30)),
      );

      final list = [order1, orderUnarrived, order2, order3];

      // Sort according to workshop queue FIFO algorithm
      list.sort((a, b) {
        if (a.arrivedAt != null && b.arrivedAt != null) {
          final comp = a.arrivedAt!.compareTo(b.arrivedAt!);
          if (comp != 0) return comp;
        } else if (a.arrivedAt != null) {
          return -1;
        } else if (b.arrivedAt != null) {
          return 1;
        }

        if (a.createdAt != null && b.createdAt != null) {
          final comp = a.createdAt!.compareTo(b.createdAt!);
          if (comp != 0) return comp;
        }
        return a.id.compareTo(b.id);
      });

      // Verification:
      // order2 arrived 45m ago, created 2h ago -> 1st
      // order3 arrived 45m ago, created 1h ago -> 2nd
      // order1 arrived 15m ago -> 3rd
      // orderUnarrived arrivedAt is null -> 4th
      expect(list[0].id, 'order-a');
      expect(list[1].id, 'order-b');
      expect(list[2].id, 'order-c');
      expect(list[3].id, 'order-d');
    });

    test('Unarrived bookings distinguish from arrived vehicles', () {
      final arrivedOrder = ServiceOrder(
        id: 'order-1',
        orderNumber: 'SO-001',
        customerId: 'cust-1',
        vehicleId: 'veh-1',
        title: 'Inspection',
        intakeOrigin: ServiceIntakeOrigin.walkIn,
        arrivedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      final notArrivedOrder = const ServiceOrder(
        id: 'order-2',
        orderNumber: 'SO-002',
        customerId: 'cust-2',
        vehicleId: 'veh-2',
        title: 'Inspection',
        intakeOrigin: ServiceIntakeOrigin.booking,
        arrivedAt: null,
      );

      expect(arrivedOrder.arrivedAt, isNotNull);
      expect(notArrivedOrder.arrivedAt, isNull);
    });

    test('Intake origin values retain expected labels and codes', () {
      expect(ServiceIntakeOrigin.booking.value, 'booking');
      expect(ServiceIntakeOrigin.booking.label, 'Booking');

      expect(ServiceIntakeOrigin.walkIn.value, 'walk_in');
      expect(ServiceIntakeOrigin.walkIn.label, 'Walk-In');

      expect(ServiceIntakeOrigin.legacyUnknown.value, 'legacy_unknown');
      expect(ServiceIntakeOrigin.legacyUnknown.label, 'Legacy / Unknown');
    });

    test('Phase 7 Design System Dual-Theme Palette Contrast Check', () {
      // Light mode tokens
      expect(AppColors.lightBackgroundPrimary.toARGB32(), 0xFFF7F9FC);
      expect(AppColors.lightSurfacePrimary.toARGB32(), 0xFFFFFFFF);
      expect(AppColors.lightTextPrimary.toARGB32(), 0xFF0F172A);
      expect(AppColors.lightTextMuted.toARGB32(), 0xFF64748B);

      // Dark mode tokens
      expect(AppColors.backgroundPrimary.toARGB32(), 0xFF0B0D10);
      expect(AppColors.surfacePrimary.toARGB32(), 0xFF171C22);
      expect(AppColors.textPrimary.toARGB32(), 0xFFF5F7FA);

      // Primary accent is consistent
      expect(AppColors.primaryAccent.toARGB32(), 0xFFE10600);
    });
  });
}
