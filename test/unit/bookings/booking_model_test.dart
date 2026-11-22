import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/bookings/data/models/booking_model.dart';

void main() {
  group('BookingStatus Enum', () {
    test('fromString parses all standard database status strings', () {
      expect(BookingStatus.fromString('pending'), equals(BookingStatus.pending));
      expect(BookingStatus.fromString('confirmed'), equals(BookingStatus.confirmed));
      expect(BookingStatus.fromString('cancelled'), equals(BookingStatus.cancelled));
      expect(BookingStatus.fromString('rescheduled'), equals(BookingStatus.rescheduled));
      expect(BookingStatus.fromString('checked_in'), equals(BookingStatus.checked_in));
      expect(BookingStatus.fromString('rejected'), equals(BookingStatus.rejected));
      expect(BookingStatus.fromString(null), equals(BookingStatus.pending));
      expect(BookingStatus.fromString('unknown_status'), equals(BookingStatus.pending));
    });

    test('toDbString serializes to correct database strings', () {
      expect(BookingStatus.pending.toDbString(), 'pending');
      expect(BookingStatus.confirmed.toDbString(), 'confirmed');
      expect(BookingStatus.cancelled.toDbString(), 'cancelled');
      expect(BookingStatus.rescheduled.toDbString(), 'rescheduled');
      expect(BookingStatus.checked_in.toDbString(), 'checked_in');
      expect(BookingStatus.rejected.toDbString(), 'rejected');
    });

    test('label returns human readable capitalized strings', () {
      expect(BookingStatus.pending.label, 'Pending');
      expect(BookingStatus.confirmed.label, 'Confirmed');
      expect(BookingStatus.cancelled.label, 'Cancelled');
      expect(BookingStatus.rescheduled.label, 'Rescheduled');
      expect(BookingStatus.checked_in.label, 'Checked In');
      expect(BookingStatus.rejected.label, 'Rejected');
    });
  });

  group('BookingModel Serialization & Equality', () {
    final now = DateTime.now();
    final testDate = DateTime(2026, 11, 25);

    test('fromJson parses snake_case database schema and joined relations', () {
      final json = {
        'id': 'b-123',
        'customer_id': 'c-456',
        'vehicle_id': 'v-789',
        'booking_date': '2026-11-25',
        'time_slot': '08:00 - 10:00',
        'service_type': 'Brake Service',
        'customer_notes': 'Front brakes grinding',
        'admin_notes': 'Check rotor thickness',
        'status': 'confirmed',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'vehicles': {
          'license_plate': 'B 1234 ABC',
          'make': 'Toyota',
          'model': 'GR Yaris',
        },
        'customers': {
          'full_name': 'Alex Pratama',
          'phone_number': '+62 812-3456-7890',
          'email': 'alex@example.com',
        },
      };

      final model = BookingModel.fromJson(json);

      expect(model.id, 'b-123');
      expect(model.customerId, 'c-456');
      expect(model.vehicleId, 'v-789');
      expect(model.bookingDate.year, 2026);
      expect(model.bookingDate.month, 11);
      expect(model.bookingDate.day, 25);
      expect(model.timeSlot, '08:00 - 10:00');
      expect(model.serviceType, 'Brake Service');
      expect(model.customerNotes, 'Front brakes grinding');
      expect(model.adminNotes, 'Check rotor thickness');
      expect(model.status, BookingStatus.confirmed);
      expect(model.vehiclePlate, 'B 1234 ABC');
      expect(model.vehicleMake, 'Toyota');
      expect(model.vehicleModel, 'GR Yaris');
      expect(model.customerName, 'Alex Pratama');
      expect(model.customerPhone, '+62 812-3456-7890');
      expect(model.customerEmail, 'alex@example.com');
      expect(model.vehicleDescription, 'Toyota GR Yaris [B 1234 ABC]');
    });

    test('toJson produces valid database map with YYYY-MM-DD date format', () {
      final model = BookingModel(
        id: 'b-999',
        customerId: 'c-111',
        vehicleId: 'v-222',
        bookingDate: testDate,
        timeSlot: '13:00 - 15:00',
        serviceType: 'Periodic Service',
        customerNotes: 'Oil change',
        adminNotes: 'Bay 01 reserved',
        status: BookingStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final map = model.toJson();

      expect(map['id'], 'b-999');
      expect(map['customer_id'], 'c-111');
      expect(map['vehicle_id'], 'v-222');
      expect(map['booking_date'], '2026-11-25');
      expect(map['time_slot'], '13:00 - 15:00');
      expect(map['service_type'], 'Periodic Service');
      expect(map['customer_notes'], 'Oil change');
      expect(map['admin_notes'], 'Bay 01 reserved');
      expect(map['status'], 'pending');
    });

    test('copyWith updates specified attributes and preserves others', () {
      final original = BookingModel(
        id: 'b-001',
        customerId: 'c-001',
        vehicleId: 'v-001',
        bookingDate: testDate,
        timeSlot: '10:00 - 12:00',
        serviceType: 'Engine Diagnostics',
        status: BookingStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        status: BookingStatus.confirmed,
        adminNotes: 'Confirmed by manager',
        timeSlot: '15:00 - 17:00',
      );

      expect(updated.id, original.id);
      expect(updated.status, BookingStatus.confirmed);
      expect(updated.adminNotes, 'Confirmed by manager');
      expect(updated.timeSlot, '15:00 - 17:00');
      expect(updated.serviceType, 'Engine Diagnostics');
    });

    test('equality and hashCode evaluate identical models as equal', () {
      final b1 = BookingModel(
        id: 'b-eq',
        customerId: 'c-eq',
        vehicleId: 'v-eq',
        bookingDate: testDate,
        timeSlot: '10:00 - 12:00',
        serviceType: 'Brake Service',
        status: BookingStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final b2 = BookingModel(
        id: 'b-eq',
        customerId: 'c-eq',
        vehicleId: 'v-eq',
        bookingDate: testDate,
        timeSlot: '10:00 - 12:00',
        serviceType: 'Brake Service',
        status: BookingStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      expect(b1, equals(b2));
      expect(b1.hashCode, equals(b2.hashCode));
    });
  });
}
