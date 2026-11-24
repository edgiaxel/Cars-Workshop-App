import 'dart:async';
import 'package:pitmate/features/notifications/models/notification_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for persistent notifications and live realtime subscription.
class NotificationRepository {
  NotificationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetch persistent notifications for user or role.
  Future<List<NotificationItem>> fetchNotifications({
    required String role,
    String? userId,
  }) async {
    try {
      var query = _client.from('notifications').select();
      if (userId != null && userId.isNotEmpty) {
        query = query.or('user_id.eq.$userId,role.eq.$role');
      } else {
        query = query.eq('role', role);
      }

      final response = await query.order('created_at', ascending: false).limit(50);
      final rows = response as List<dynamic>;
      return rows.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Mark single notification as read via RPC.
  Future<bool> markAsRead(String notificationId) async {
    try {
      final res = await _client.rpc(
        'mark_notification_read',
        params: {'p_notification_id': notificationId},
      );
      return res == true;
    } catch (_) {
      try {
        await _client
            .from('notifications')
            .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
            .eq('id', notificationId);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  /// Mark all notifications read for user via RPC.
  Future<int> markAllAsRead(String userId) async {
    try {
      final res = await _client.rpc(
        'mark_all_notifications_read',
        params: {'p_user_id': userId},
      );
      return (res as num?)?.toInt() ?? 0;
    } catch (_) {
      try {
        await _client
            .from('notifications')
            .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
            .eq('user_id', userId)
            .eq('is_read', false);
        return 1;
      } catch (_) {
        return 0;
      }
    }
  }

  /// Stream realtime notification inserts and updates.
  Stream<List<NotificationItem>> streamNotifications({
    required String userId,
    required String role,
  }) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) {
          return rows
              .where((r) => r['user_id'] == userId || r['role'] == role)
              .map((e) => NotificationItem.fromJson(e))
              .toList();
        });
  }
}
