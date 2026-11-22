import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/inspections/data/models/inspection_model.dart';

void main() {
  group('InspectionStatus enum', () {
    test('fromString parses database values correctly', () {
      expect(InspectionStatus.fromString('assigned'), InspectionStatus.assigned);
      expect(InspectionStatus.fromString('in_progress'), InspectionStatus.inProgress);
      expect(InspectionStatus.fromString('inprogress'), InspectionStatus.inProgress);
      expect(InspectionStatus.fromString('completed'), InspectionStatus.completed);
      expect(InspectionStatus.fromString('reviewed'), InspectionStatus.reviewed);
      expect(InspectionStatus.fromString('unknown'), InspectionStatus.assigned);
      expect(InspectionStatus.fromString(null), InspectionStatus.assigned);
    });

    test('value and displayName return expected values', () {
      expect(InspectionStatus.assigned.value, 'assigned');
      expect(InspectionStatus.assigned.displayName, 'Assigned');
      expect(InspectionStatus.assigned.isAssigned, isTrue);

      expect(InspectionStatus.inProgress.value, 'in_progress');
      expect(InspectionStatus.inProgress.displayName, 'In Progress');
      expect(InspectionStatus.inProgress.isInProgress, isTrue);

      expect(InspectionStatus.completed.value, 'completed');
      expect(InspectionStatus.completed.displayName, 'Completed');
      expect(InspectionStatus.completed.isCompleted, isTrue);

      expect(InspectionStatus.reviewed.value, 'reviewed');
      expect(InspectionStatus.reviewed.displayName, 'Reviewed');
      expect(InspectionStatus.reviewed.isReviewed, isTrue);
    });
  });

  group('InspectionModel', () {
    final fixedTime = DateTime.parse('2026-11-23T10:00:00Z');
    final completedTime = DateTime.parse('2026-11-23T11:30:00Z');

    test('fromJson parses snake_case database row correctly', () {
      final json = {
        'id': 'insp-uuid-1',
        'service_order_id': 'so-uuid-101',
        'mechanic_id': 'mech-uuid-99',
        'status': 'completed',
        'summary': 'Inspection complete. Front pads glazed.',
        'started_at': fixedTime.toIso8601String(),
        'completed_at': completedTime.toIso8601String(),
        'reviewed_by': 'admin-uuid-1',
        'reviewed_at': completedTime.toIso8601String(),
        'created_at': fixedTime.toIso8601String(),
        'updated_at': completedTime.toIso8601String(),
      };

      final model = InspectionModel.fromJson(json);

      expect(model.id, 'insp-uuid-1');
      expect(model.serviceOrderId, 'so-uuid-101');
      expect(model.mechanicId, 'mech-uuid-99');
      expect(model.status, InspectionStatus.completed);
      expect(model.summary, 'Inspection complete. Front pads glazed.');
      expect(model.startedAt, fixedTime);
      expect(model.completedAt, completedTime);
      expect(model.reviewedBy, 'admin-uuid-1');
      expect(model.reviewedAt, completedTime);
    });

    test('toJson serializes model matching schema', () {
      final model = InspectionModel(
        id: 'insp-123',
        serviceOrderId: 'order-456',
        mechanicId: 'mech-789',
        status: InspectionStatus.inProgress,
        summary: 'Under investigation',
        startedAt: fixedTime,
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );

      final json = model.toJson();

      expect(json['id'], 'insp-123');
      expect(json['service_order_id'], 'order-456');
      expect(json['mechanic_id'], 'mech-789');
      expect(json['status'], 'in_progress');
      expect(json['summary'], 'Under investigation');
      expect(json['started_at'], fixedTime.toIso8601String());
    });

    test('copyWith updates specified properties', () {
      final model = InspectionModel(
        id: 'insp-1',
        serviceOrderId: 'order-1',
        status: InspectionStatus.assigned,
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );

      final updated = model.copyWith(
        status: InspectionStatus.completed,
        summary: 'Final check pass',
        completedAt: completedTime,
      );

      expect(updated.id, 'insp-1');
      expect(updated.serviceOrderId, 'order-1');
      expect(updated.status, InspectionStatus.completed);
      expect(updated.summary, 'Final check pass');
      expect(updated.completedAt, completedTime);
    });

    test('equality and hashCode compare field equivalence', () {
      final modelA = InspectionModel(
        id: 'insp-1',
        serviceOrderId: 'order-1',
        status: InspectionStatus.assigned,
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );

      final modelB = InspectionModel(
        id: 'insp-1',
        serviceOrderId: 'order-1',
        status: InspectionStatus.assigned,
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );

      expect(modelA, equals(modelB));
      expect(modelA.hashCode, equals(modelB.hashCode));
    });
  });
}
