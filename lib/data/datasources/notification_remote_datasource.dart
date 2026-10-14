import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/service_notification.dart';

abstract class NotificationRemoteDataSource {
  Future<List<ServiceNotification>> getNotifications({String? recipientId});
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead(String recipientId);
}

class SupabaseNotificationRemoteDataSource
    implements NotificationRemoteDataSource {
  SupabaseNotificationRemoteDataSource(this._client);
  final SupabaseClient? _client;

  @override
  Future<List<ServiceNotification>> getNotifications({
    String? recipientId,
  }) async {
    if (_client == null) return [];

    var query = _client.from('notifications').select('*');
    if (recipientId != null) {
      query = query.eq('recipient_id', recipientId);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List)
        .map(
          (json) => ServiceNotification.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<void> markAsRead(String id) async {
    if (_client == null) return;
    await _client
        .from('notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  @override
  Future<void> markAllAsRead(String recipientId) async {
    if (_client == null) return;
    await _client
        .from('notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('recipient_id', recipientId);
  }
}
