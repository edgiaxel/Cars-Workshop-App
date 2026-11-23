import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/workshop/data/models/workshop_bay_model.dart';

void main() {
  group('WorkshopBayModel Serialization & Invariant Tests', () {
    test('BayStatus Enum parses correctly', () {
      expect(BayStatus.fromString('available'), BayStatus.available);
      expect(BayStatus.fromString('occupied'), BayStatus.occupied);
      expect(BayStatus.fromString('maintenance'), BayStatus.maintenance);
      expect(BayStatus.fromString('unknown'), BayStatus.available);

      expect(BayStatus.available.toDbString(), 'available');
      expect(BayStatus.occupied.toDbString(), 'occupied');
      expect(BayStatus.maintenance.toDbString(), 'maintenance');

      expect(BayStatus.available.label, 'Available');
      expect(BayStatus.occupied.label, 'Occupied');
      expect(BayStatus.maintenance.label, 'Maintenance');
    });

    test('fromJson and toJson round-trip preserves attributes', () {
      final now = DateTime.now();
      final model = WorkshopBayModel(
        id: 'bay-uuid-01',
        bayNumber: 2,
        name: 'Bay 02 - Diagnostic',
        status: BayStatus.occupied,
        currentServiceOrderId: 'order-uuid-123',
        createdAt: now,
        updatedAt: now,
      );

      final json = model.toJson();
      expect(json['id'], 'bay-uuid-01');
      expect(json['bay_number'], 2);
      expect(json['name'], 'Bay 02 - Diagnostic');
      expect(json['status'], 'occupied');
      expect(json['current_service_order_id'], 'order-uuid-123');

      final from = WorkshopBayModel.fromJson(json);
      expect(from.id, model.id);
      expect(from.bayNumber, model.bayNumber);
      expect(from.isOccupied, true);
      expect(from.isAvailable, false);
    });

    test('copyWith updates specified attributes', () {
      final now = DateTime.now();
      final model = WorkshopBayModel(
        id: 'bay-1',
        bayNumber: 1,
        name: 'Bay 01',
        status: BayStatus.available,
        createdAt: now,
        updatedAt: now,
      );

      final updated = model.copyWith(
        status: BayStatus.occupied,
        currentServiceOrderId: 'order-456',
        vehiclePlate: 'B 1088 PIT',
      );

      expect(updated.status, BayStatus.occupied);
      expect(updated.isOccupied, true);
      expect(updated.currentServiceOrderId, 'order-456');
      expect(updated.vehiclePlate, 'B 1088 PIT');
      expect(updated.bayNumber, 1);
    });
  });
}
