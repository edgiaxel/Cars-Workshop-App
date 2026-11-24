import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/quality_control/data/models/qc_inspection_model.dart';

void main() {
  group('QcStatus enum', () {
    test('fromString parses database values correctly', () {
      expect(QcStatus.fromString('in_progress'), QcStatus.inProgress);
      expect(QcStatus.fromString('inprogress'), QcStatus.inProgress);
      expect(QcStatus.fromString('passed'), QcStatus.passed);
      expect(QcStatus.fromString('failed'), QcStatus.failed);
      expect(QcStatus.fromString('unknown_value'), QcStatus.inProgress);
      expect(QcStatus.fromString(null), QcStatus.inProgress);
    });

    test('value and displayName return expected database and UI strings', () {
      expect(QcStatus.inProgress.value, 'in_progress');
      expect(QcStatus.inProgress.displayName, 'In Progress');
      expect(QcStatus.inProgress.isInProgress, isTrue);
      expect(QcStatus.inProgress.isPassed, isFalse);
      expect(QcStatus.inProgress.isFailed, isFalse);

      expect(QcStatus.passed.value, 'passed');
      expect(QcStatus.passed.displayName, 'Passed');
      expect(QcStatus.passed.isPassed, isTrue);

      expect(QcStatus.failed.value, 'failed');
      expect(QcStatus.failed.displayName, 'Failed');
      expect(QcStatus.failed.isFailed, isTrue);
    });
  });

  group('QcChecklistItemModel', () {
    final fixedTime = DateTime.parse('2026-11-24T10:00:00Z');

    test('fromJson parses snake_case database row correctly', () {
      final json = {
        'id': 'item-101',
        'qc_inspection_id': 'qc-001',
        'category': 'Mechanical',
        'item_name': 'Braking system test & pedal firmness',
        'is_passed': true,
        'notes': 'Firm pedal response',
        'checked_at': fixedTime.toIso8601String(),
      };

      final model = QcChecklistItemModel.fromJson(json);

      expect(model.id, 'item-101');
      expect(model.qcInspectionId, 'qc-001');
      expect(model.category, 'Mechanical');
      expect(model.itemName, 'Braking system test & pedal firmness');
      expect(model.isPassed, isTrue);
      expect(model.notes, 'Firm pedal response');
      expect(model.checkedAt, fixedTime);
    });

    test('toJson serializes model matching database schema', () {
      final model = QcChecklistItemModel(
        id: 'item-102',
        qcInspectionId: 'qc-001',
        category: 'Fluids',
        itemName: 'Engine oil level',
        isPassed: false,
        notes: 'Low oil',
        checkedAt: fixedTime,
      );

      final json = model.toJson();

      expect(json['id'], 'item-102');
      expect(json['qc_inspection_id'], 'qc-001');
      expect(json['category'], 'Fluids');
      expect(json['item_name'], 'Engine oil level');
      expect(json['is_passed'], false);
      expect(json['notes'], 'Low oil');
      expect(json['checked_at'], fixedTime.toIso8601String());
    });

    test('toRpcItemJson produces lightweight payload for record_qc_result RPC', () {
      final model = QcChecklistItemModel(
        id: 'item-103',
        qcInspectionId: 'qc-001',
        category: 'Electrical',
        itemName: 'Headlights',
        isPassed: true,
        notes: null,
      );

      final rpcJson = model.toRpcItemJson();

      expect(rpcJson['id'], 'item-103');
      expect(rpcJson['is_passed'], true);
      expect(rpcJson.containsKey('notes'), isFalse);
    });

    test('copyWith updates specified fields', () {
      final model = QcChecklistItemModel(
        id: 'item-1',
        qcInspectionId: 'qc-1',
        category: 'Safety',
        itemName: 'Wheel nuts torque',
        isPassed: false,
      );

      final updated = model.copyWith(
        isPassed: true,
        notes: 'Torqued to 120Nm',
        checkedAt: fixedTime,
      );

      expect(updated.id, 'item-1');
      expect(updated.isPassed, isTrue);
      expect(updated.notes, 'Torqued to 120Nm');
      expect(updated.checkedAt, fixedTime);
    });

    test('equality and hashCode verify field equivalence', () {
      final a = QcChecklistItemModel(
        id: 'item-1',
        qcInspectionId: 'qc-1',
        category: 'Safety',
        itemName: 'Item A',
      );
      final b = QcChecklistItemModel(
        id: 'item-1',
        qcInspectionId: 'qc-1',
        category: 'Safety',
        itemName: 'Item A',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('QcInspectionModel', () {
    final fixedCreated = DateTime.parse('2026-11-24T09:00:00Z');
    final fixedUpdated = DateTime.parse('2026-11-24T09:30:00Z');
    final fixedCompleted = DateTime.parse('2026-11-24T09:45:00Z');

    test('fromJson parses standalone row without joined relations', () {
      final json = {
        'id': 'qc-uuid-1',
        'service_order_id': 'so-uuid-101',
        'inspector_id': 'inspector-uuid-9',
        'status': 'in_progress',
        'notes': 'Initial road test',
        'failure_reason': null,
        'correction_notes': null,
        'completed_at': null,
        'created_at': fixedCreated.toIso8601String(),
        'updated_at': fixedUpdated.toIso8601String(),
      };

      final model = QcInspectionModel.fromJson(json);

      expect(model.id, 'qc-uuid-1');
      expect(model.serviceOrderId, 'so-uuid-101');
      expect(model.inspectorId, 'inspector-uuid-9');
      expect(model.status, QcStatus.inProgress);
      expect(model.notes, 'Initial road test');
      expect(model.failureReason, isNull);
      expect(model.items, isEmpty);
      expect(model.createdAt, fixedCreated);
      expect(model.updatedAt, fixedUpdated);
    });

    test('fromJson parses joined qc_checklist_items and service_orders relations', () {
      final json = {
        'id': 'qc-uuid-2',
        'service_order_id': 'so-uuid-202',
        'inspector_id': 'inspector-uuid-9',
        'status': 'passed',
        'notes': 'All checks passed',
        'completed_at': fixedCompleted.toIso8601String(),
        'created_at': fixedCreated.toIso8601String(),
        'updated_at': fixedUpdated.toIso8601String(),
        'qc_checklist_items': [
          {
            'id': 'i1',
            'qc_inspection_id': 'qc-uuid-2',
            'category': 'Mechanical',
            'item_name': 'Braking system',
            'is_passed': true,
          },
          {
            'id': 'i2',
            'qc_inspection_id': 'qc-uuid-2',
            'category': 'Fluids',
            'item_name': 'Oil & coolant',
            'is_passed': true,
          },
          {
            'id': 'i3',
            'qc_inspection_id': 'qc-uuid-2',
            'category': 'Electrical',
            'item_name': 'Headlights',
            'is_passed': false,
          },
        ],
        'service_orders': {
          'id': 'so-uuid-202',
          'order_number': 'SO-2026-0045',
          'customer_id': 'cust-1',
          'vehicle_id': 'veh-1',
          'odometer': 35000,
          'customer_complaint': 'Check engine light',
          'status': 'qc_pending',
          'created_at': fixedCreated.toIso8601String(),
          'updated_at': fixedUpdated.toIso8601String(),
          'customers': {
            'full_name': 'Budi Santoso',
            'phone_number': '+62811223344',
          },
          'vehicles': {
            'license_plate': 'B 1234 ABC',
            'make': 'Toyota',
            'model': 'Innova Zenix',
          },
        },
      };

      final model = QcInspectionModel.fromJson(json);

      expect(model.id, 'qc-uuid-2');
      expect(model.status, QcStatus.passed);
      expect(model.items.length, 3);
      expect(model.orderNumber, 'SO-2026-0045');
      expect(model.customerName, 'Budi Santoso');
      expect(model.customerPhone, '+62811223344');
      expect(model.vehiclePlate, 'B 1234 ABC');
      expect(model.vehicleMake, 'Toyota');
      expect(model.vehicleModel, 'Innova Zenix');
      expect(model.vehicleDescription, 'Toyota Innova Zenix [B 1234 ABC]');
      expect(model.serviceOrder, isNotNull);
    });

    test('relational getters compute correct counts, fractions, and category groupings', () {
      final items = [
        const QcChecklistItemModel(
          id: 'i1',
          qcInspectionId: 'qc-1',
          category: 'Mechanical',
          itemName: 'Braking system',
          isPassed: true,
        ),
        const QcChecklistItemModel(
          id: 'i2',
          qcInspectionId: 'qc-1',
          category: 'Mechanical',
          itemName: 'Suspension',
          isPassed: true,
        ),
        const QcChecklistItemModel(
          id: 'i3',
          qcInspectionId: 'qc-1',
          category: 'Fluids',
          itemName: 'Coolant',
          isPassed: false,
        ),
        const QcChecklistItemModel(
          id: 'i4',
          qcInspectionId: 'qc-1',
          category: 'Safety',
          itemName: 'Wheel nuts',
          isPassed: true,
        ),
      ];

      final model = QcInspectionModel(
        id: 'qc-1',
        serviceOrderId: 'so-1',
        inspectorId: 'insp-1',
        status: QcStatus.inProgress,
        createdAt: fixedCreated,
        updatedAt: fixedUpdated,
        items: items,
        vehiclePlate: 'D 8888 XX',
      );

      expect(model.totalItemsCount, 4);
      expect(model.passedItemsCount, 3);
      expect(model.failedItemsCount, 1);
      expect(model.allItemsPassed, isFalse);
      expect(model.progressFraction, 0.75);
      expect(model.vehicleDescription, 'D 8888 XX');

      final grouped = model.itemsByCategory;
      expect(grouped.keys.length, 3);
      expect(grouped['Mechanical']?.length, 2);
      expect(grouped['Fluids']?.length, 1);
      expect(grouped['Safety']?.length, 1);
    });

    test('allItemsPassed returns true when every item is passed', () {
      final items = [
        const QcChecklistItemModel(
          id: 'i1',
          qcInspectionId: 'qc-1',
          category: 'Mechanical',
          itemName: 'Braking',
          isPassed: true,
        ),
        const QcChecklistItemModel(
          id: 'i2',
          qcInspectionId: 'qc-1',
          category: 'Fluids',
          itemName: 'Fluids',
          isPassed: true,
        ),
      ];

      final model = QcInspectionModel(
        id: 'qc-1',
        serviceOrderId: 'so-1',
        inspectorId: 'insp-1',
        status: QcStatus.inProgress,
        createdAt: fixedCreated,
        updatedAt: fixedUpdated,
        items: items,
      );

      expect(model.allItemsPassed, isTrue);
      expect(model.progressFraction, 1.0);
    });

    test('toJson serializes model matching schema', () {
      final model = QcInspectionModel(
        id: 'qc-99',
        serviceOrderId: 'so-88',
        inspectorId: 'insp-77',
        status: QcStatus.failed,
        notes: 'Failed road test',
        failureReason: 'Brake fade',
        correctionNotes: 'Bleed calipers',
        completedAt: fixedCompleted,
        createdAt: fixedCreated,
        updatedAt: fixedUpdated,
      );

      final json = model.toJson();

      expect(json['id'], 'qc-99');
      expect(json['service_order_id'], 'so-88');
      expect(json['inspector_id'], 'insp-77');
      expect(json['status'], 'failed');
      expect(json['notes'], 'Failed road test');
      expect(json['failure_reason'], 'Brake fade');
      expect(json['correction_notes'], 'Bleed calipers');
      expect(json['completed_at'], fixedCompleted.toIso8601String());
    });

    test('copyWith updates specified fields', () {
      final model = QcInspectionModel(
        id: 'qc-1',
        serviceOrderId: 'so-1',
        inspectorId: 'insp-1',
        status: QcStatus.inProgress,
        createdAt: fixedCreated,
        updatedAt: fixedUpdated,
      );

      final updated = model.copyWith(
        status: QcStatus.passed,
        notes: 'Final review approved',
        completedAt: fixedCompleted,
      );

      expect(updated.id, 'qc-1');
      expect(updated.status, QcStatus.passed);
      expect(updated.notes, 'Final review approved');
      expect(updated.completedAt, fixedCompleted);
    });
  });
}
