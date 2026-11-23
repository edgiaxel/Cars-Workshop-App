import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/inventory/data/models/part_request_model.dart';
import 'package:pitmate/features/inventory/data/models/service_task_part_consumption_model.dart';

void main() {
  group('PartRequestModel Unit Tests', () {
    test('Correctly deserializes JSON with joined parts and profile fields', () {
      final json = {
        'id': 'req-1',
        'service_order_id': 'so-100',
        'task_id': 'task-200',
        'part_id': 'part-300',
        'requested_by': 'mech-400',
        'quantity_requested': 4,
        'quantity_fulfilled': 2,
        'status': 'partially_fulfilled',
        'notes': 'Urgent replacement needed',
        'created_at': '2026-11-23T10:00:00Z',
        'updated_at': '2026-11-23T10:15:00Z',
        'parts': {
          'sku': 'NGK-SILZKR7B11',
          'name': 'Laser Iridium Spark Plug',
          'unit_of_measurement': 'pcs',
        },
        'profiles': {
          'full_name': 'Max Verstappen',
        },
      };

      final model = PartRequestModel.fromJson(json);

      expect(model.id, equals('req-1'));
      expect(model.serviceOrderId, equals('so-100'));
      expect(model.taskId, equals('task-200'));
      expect(model.partId, equals('part-300'));
      expect(model.requestedBy, equals('mech-400'));
      expect(model.quantityRequested, equals(4));
      expect(model.quantityFulfilled, equals(2));
      expect(model.remainingQuantity, equals(2));
      expect(model.status, equals('partially_fulfilled'));
      expect(model.isPartiallyFulfilled, isTrue);
      expect(model.isFulfilled, isFalse);
      expect(model.isPending, isFalse);
      expect(model.partSku, equals('NGK-SILZKR7B11'));
      expect(model.partName, equals('Laser Iridium Spark Plug'));
      expect(model.partUnit, equals('pcs'));
      expect(model.requestedByName, equals('Max Verstappen'));
    });

    test('Computes remaining quantity correctly when fully fulfilled', () {
      final model = PartRequestModel(
        id: 'req-2',
        serviceOrderId: 'so-1',
        partId: 'part-1',
        requestedBy: 'mech-1',
        quantityRequested: 3,
        quantityFulfilled: 3,
        status: 'fulfilled',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(model.remainingQuantity, equals(0));
      expect(model.isFulfilled, isTrue);
    });
  });

  group('ServiceTaskPartConsumptionModel Unit Tests', () {
    test('Correctly deserializes JSON with cost snapshots', () {
      final json = {
        'id': 'cons-1',
        'service_order_id': 'so-100',
        'task_id': 'task-200',
        'part_id': 'part-300',
        'quantity_issued': 4,
        'quantity_consumed': 3,
        'quantity_returned': 1,
        'unit_cost_cents': 130000,
        'total_cost_cents': 390000,
        'recorded_by': 'mech-400',
        'created_at': '2026-11-23T11:00:00Z',
        'parts': {
          'sku': 'MOTUL-5W30',
          'name': 'Motul 300V 5W-30 Synthetic',
          'unit_of_measurement': 'liter',
        },
      };

      final model = ServiceTaskPartConsumptionModel.fromJson(json);

      expect(model.id, equals('cons-1'));
      expect(model.quantityIssued, equals(4));
      expect(model.quantityConsumed, equals(3));
      expect(model.quantityReturned, equals(1));
      expect(model.unitCostCents, equals(130000));
      expect(model.totalCostCents, equals(390000));
      expect(model.partSku, equals('MOTUL-5W30'));
      expect(model.partUnit, equals('liter'));
    });
  });
}
