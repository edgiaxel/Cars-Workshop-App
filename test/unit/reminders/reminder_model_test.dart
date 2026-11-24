import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/reminders/models/maintenance_reminder.dart';

void main() {
  group('MaintenanceReminder Model Tests', () {
    test('fromJson deserializes snake_case row and joined relation data', () {
      final json = {
        'id': 'rem-101',
        'customer_id': 'cust-01',
        'vehicle_id': 'veh-01',
        'service_order_id': 'so-01',
        'reminder_type': 'scheduled_date',
        'title': '6-Month Routine Health Check',
        'description': 'Inspect fluid levels and brake pads',
        'due_date': '2027-02-24',
        'due_odometer_km': null,
        'status': 'pending',
        'last_notified_at': null,
        'dismissed_at': null,
        'vehicles': {
          'make': 'Toyota',
          'model': 'GR Yaris',
          'license_plate': 'B 1234 TOY',
          'mileage': 10500,
        },
        'customers': {
          'full_name': 'Axel Zeed',
        },
      };

      final reminder = MaintenanceReminder.fromJson(json);

      expect(reminder.id, 'rem-101');
      expect(reminder.customerId, 'cust-01');
      expect(reminder.vehicleId, 'veh-01');
      expect(reminder.reminderType, 'scheduled_date');
      expect(reminder.title, '6-Month Routine Health Check');
      expect(reminder.dueDate?.year, 2027);
      expect(reminder.vehicleMake, 'Toyota');
      expect(reminder.vehicleModel, 'GR Yaris');
      expect(reminder.licensePlate, 'B 1234 TOY');
      expect(reminder.currentMileageKm, 10500);
      expect(reminder.customerName, 'Axel Zeed');
      expect(reminder.status, 'pending');
    });

    test('toJson serializes fields properly', () {
      final reminder = MaintenanceReminder(
        id: 'rem-102',
        customerId: 'cust-02',
        vehicleId: 'veh-02',
        reminderType: 'mileage_odometer',
        title: 'Periodic 15,000 KM Service',
        dueOdometerKm: 15000,
        status: 'notified',
      );

      final json = reminder.toJson();

      expect(json['id'], 'rem-102');
      expect(json['reminder_type'], 'mileage_odometer');
      expect(json['due_odometer_km'], 15000);
      expect(json['status'], 'notified');
    });

    test('copyWith updates specified properties while preserving others', () {
      final reminder = MaintenanceReminder(
        id: 'rem-103',
        customerId: 'cust-03',
        vehicleId: 'veh-03',
        reminderType: 'scheduled_date',
        title: 'Brake Inspection',
        status: 'pending',
      );

      final updated = reminder.copyWith(status: 'dismissed');

      expect(updated.id, 'rem-103');
      expect(updated.status, 'dismissed');
      expect(updated.title, 'Brake Inspection');
    });
  });
}
