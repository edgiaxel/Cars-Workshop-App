import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/models/service_notification.dart';
import '../../data/repositories/notification_repository.dart';
import 'auth_provider.dart';
import 'supabase_provider.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource?>((ref) {
      final client = ref.watch(supabaseClientProvider);
      if (client == null) return null;
      return SupabaseNotificationRemoteDataSource(client);
    });

final notificationRepositoryProvider = Provider<NotificationRepository?>((ref) {
  final dataSource = ref.watch(notificationRemoteDataSourceProvider);
  if (dataSource == null) return null;
  return SupabaseNotificationRepository(dataSource);
});

class NotificationsNotifier extends AsyncNotifier<List<ServiceNotification>> {
  @override
  Future<List<ServiceNotification>> build() async {
    final repository = ref.watch(notificationRepositoryProvider);
    final auth = ref.watch(authSessionProvider);
    if (repository == null || auth.userId == null) return const [];
    return repository.getNotifications(recipientId: auth.userId);
  }

  Future<void> markAsRead(String id) async {
    final repository = ref.read(notificationRepositoryProvider);
    if (repository != null) {
      await repository.markAsRead(id);
      ref.invalidateSelf();
    }
  }

  Future<void> markAllAsRead() async {
    final repository = ref.read(notificationRepositoryProvider);
    final auth = ref.read(authSessionProvider);
    if (repository != null && auth.userId != null) {
      await repository.markAllAsRead(auth.userId!);
      ref.invalidateSelf();
    }
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<ServiceNotification>>(
      NotificationsNotifier.new,
    );
