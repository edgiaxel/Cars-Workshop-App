import '../datasources/notification_remote_datasource.dart';
import '../models/service_notification.dart';

abstract class NotificationRepository {
  Future<List<ServiceNotification>> getNotifications({String? recipientId});
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead(String recipientId);
}

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this._dataSource);
  final NotificationRemoteDataSource _dataSource;

  @override
  Future<List<ServiceNotification>> getNotifications({String? recipientId}) {
    return _dataSource.getNotifications(recipientId: recipientId);
  }

  @override
  Future<void> markAsRead(String id) {
    return _dataSource.markAsRead(id);
  }

  @override
  Future<void> markAllAsRead(String recipientId) {
    return _dataSource.markAllAsRead(recipientId);
  }
}
