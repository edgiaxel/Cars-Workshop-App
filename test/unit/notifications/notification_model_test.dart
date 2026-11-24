import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/notifications/models/notification_item.dart';

void main() {
  group('NotificationItem Serialization & Operations', () {
    test('fromJson deserializes snake_case database row properly', () {
      final json = {
        'id': 'notif-101',
        'user_id': 'user-001',
        'role': 'customer',
        'title': 'Vehicle Intake Complete',
        'message': 'Your Toyota GR Yaris has been admitted to Bay 01.',
        'type': 'service_status',
        'entity_type': 'service_order',
        'entity_id': 'so-999',
        'is_read': false,
        'read_at': null,
        'metadata': {'bay': 'Bay 01'},
        'created_at': '2026-11-24T10:00:00.000Z',
      };

      final item = NotificationItem.fromJson(json);

      expect(item.id, 'notif-101');
      expect(item.userId, 'user-001');
      expect(item.role, 'customer');
      expect(item.title, 'Vehicle Intake Complete');
      expect(item.message, contains('Toyota GR Yaris'));
      expect(item.type, 'service_status');
      expect(item.entityType, 'service_order');
      expect(item.entityId, 'so-999');
      expect(item.isRead, isFalse);
      expect(item.readAt, isNull);
      expect(item.metadata['bay'], 'Bay 01');
      expect(item.createdAt.year, 2026);
    });

    test('toJson serializes to valid snake_case payload', () {
      final item = NotificationItem(
        id: 'notif-102',
        userId: 'user-002',
        role: 'mechanic',
        title: 'New Task Assignment',
        message: 'Brake pad replacement on Bay 02.',
        type: 'assignment',
        isRead: true,
        readAt: DateTime.parse('2026-11-24T10:30:00.000Z'),
        createdAt: DateTime.parse('2026-11-24T10:00:00.000Z'),
      );

      final json = item.toJson();

      expect(json['id'], 'notif-102');
      expect(json['user_id'], 'user-002');
      expect(json['role'], 'mechanic');
      expect(json['is_read'], isTrue);
      expect(json['read_at'], contains('2026-11-24T10:30:00'));
    });

    test('copyWith updates fields while preserving others', () {
      final item = NotificationItem(
        id: 'notif-103',
        userId: 'user-003',
        role: 'admin',
        title: 'QC Pending',
        message: 'Order SO-101 ready for inspection.',
        type: 'qc_result',
        createdAt: DateTime.now(),
      );

      final updated = item.copyWith(isRead: true, title: 'QC Passed');

      expect(updated.id, 'notif-103');
      expect(updated.isRead, isTrue);
      expect(updated.title, 'QC Passed');
      expect(updated.message, 'Order SO-101 ready for inspection.');
    });
  });
}
