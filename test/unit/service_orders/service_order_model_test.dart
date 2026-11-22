import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/service_orders/data/models/service_order_model.dart';

void main() {
  group('ServiceOrderModel Serialization & Operations', () {
    final now = DateTime.now();

    test('fromJson deserializes snake_case database row and joined relations', () {
      final json = {
        'id': 'so-uuid-1',
        'order_number': 'SO-202611-0001',
        'customer_id': 'cust-uuid-1',
        'vehicle_id': 'veh-uuid-1',
        'booking_id': 'bk-uuid-1',
        'intake_type': 'booking',
        'odometer': 14250,
        'customer_complaint': 'Squeaking brake pads when braking cold',
        'fuel_level': '3/4',
        'initial_notes': 'Technician assigned to hoist B',
        'status': 'inspection_pending',
        'assigned_bay': 'Bay 02',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'customers': {
          'full_name': 'Alex Pratama',
          'phone_number': '+62 812-3456-7890',
        },
        'vehicles': {
          'license_plate': 'B 1234 ABC',
          'make': 'Toyota',
          'model': 'GR Yaris',
        },
      };

      final order = ServiceOrderModel.fromJson(json);

      expect(order.id, 'so-uuid-1');
      expect(order.orderNumber, 'SO-202611-0001');
      expect(order.customerId, 'cust-uuid-1');
      expect(order.vehicleId, 'veh-uuid-1');
      expect(order.bookingId, 'bk-uuid-1');
      expect(order.intakeType, 'booking');
      expect(order.odometer, 14250);
      expect(order.customerComplaint, 'Squeaking brake pads when braking cold');
      expect(order.fuelLevel, '3/4');
      expect(order.initialNotes, 'Technician assigned to hoist B');
      expect(order.status, 'inspection_pending');
      expect(order.assignedBay, 'Bay 02');
      expect(order.customerName, 'Alex Pratama');
      expect(order.customerPhone, '+62 812-3456-7890');
      expect(order.vehiclePlate, 'B 1234 ABC');
      expect(order.vehicleMake, 'Toyota');
      expect(order.vehicleModel, 'GR Yaris');
      expect(order.vehicleDescription, 'Toyota GR Yaris [B 1234 ABC]');
    });

    test('toJson outputs valid map for database queries', () {
      final order = ServiceOrderModel(
        id: 'so-uuid-2',
        orderNumber: 'SO-202611-0002',
        customerId: 'cust-uuid-2',
        vehicleId: 'veh-uuid-2',
        bookingId: null,
        intakeType: 'walk_in',
        odometer: 35000,
        customerComplaint: 'Regular 30k interval oil change',
        fuelLevel: '1/2',
        initialNotes: 'Walk-in guest arrival',
        status: 'intake_pending',
        assignedBay: 'Bay 01',
        createdAt: now,
        updatedAt: now,
      );

      final map = order.toJson();

      expect(map['id'], 'so-uuid-2');
      expect(map['order_number'], 'SO-202611-0002');
      expect(map['customer_id'], 'cust-uuid-2');
      expect(map['vehicle_id'], 'veh-uuid-2');
      expect(map['booking_id'], isNull);
      expect(map['intake_type'], 'walk_in');
      expect(map['odometer'], 35000);
      expect(map['customer_complaint'], 'Regular 30k interval oil change');
      expect(map['fuel_level'], '1/2');
      expect(map['initial_notes'], 'Walk-in guest arrival');
      expect(map['status'], 'intake_pending');
      expect(map['assigned_bay'], 'Bay 01');
    });

    test('copyWith creates modified clone', () {
      final original = ServiceOrderModel(
        id: 'so-01',
        orderNumber: 'SO-202611-0010',
        customerId: 'c-01',
        vehicleId: 'v-01',
        odometer: 20000,
        customerComplaint: 'Engine hesitation',
        createdAt: now,
        updatedAt: now,
      );

      final modified = original.copyWith(
        status: 'inspection_completed',
        assignedBay: 'Bay 03',
        odometer: 20100,
      );

      expect(modified.id, original.id);
      expect(modified.orderNumber, original.orderNumber);
      expect(modified.status, 'inspection_completed');
      expect(modified.assignedBay, 'Bay 03');
      expect(modified.odometer, 20100);
      expect(modified.customerComplaint, original.customerComplaint);
    });

    test('equality and hashCode evaluate equivalent models', () {
      final o1 = ServiceOrderModel(
        id: 'so-eq',
        orderNumber: 'SO-1',
        customerId: 'c-1',
        vehicleId: 'v-1',
        odometer: 1000,
        customerComplaint: 'Oil',
        createdAt: now,
        updatedAt: now,
      );

      final o2 = ServiceOrderModel(
        id: 'so-eq',
        orderNumber: 'SO-1',
        customerId: 'c-1',
        vehicleId: 'v-1',
        odometer: 1000,
        customerComplaint: 'Oil',
        createdAt: now,
        updatedAt: now,
      );

      expect(o1, equals(o2));
      expect(o1.hashCode, equals(o2.hashCode));
    });
  });
}
