import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/notifications/data/notification_repository.dart';
import 'package:pitmate/features/notifications/models/notification_item.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

class NotificationsState {
  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<NotificationItem> notifications;
  final bool isLoading;
  final String? errorMessage;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  StreamSubscription<List<NotificationItem>>? _streamSubscription;
  late NotificationRepository _repository;

  @override
  NotificationsState build() {
    _repository = ref.watch(notificationRepositoryProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        loadNotifications(next.userProfile.role.name, next.userProfile.id);
      } else {
        _streamSubscription?.cancel();
        state = const NotificationsState();
      }
    }, fireImmediately: true);

    ref.onDispose(() {
      _streamSubscription?.cancel();
    });

    return const NotificationsState();
  }

  Future<void> loadNotifications(String role, String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.fetchNotifications(role: role, userId: userId);
      state = state.copyWith(notifications: items, isLoading: false);

      _streamSubscription?.cancel();
      _streamSubscription = _repository
          .streamNotifications(userId: userId, role: role)
          .listen(
            (updatedList) {
              state = state.copyWith(notifications: updatedList);
            },
            onError: (_) {},
          );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    final updated = state.notifications.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true, readAt: DateTime.now());
      }
      return item;
    }).toList();
    state = state.copyWith(notifications: updated);
    await _repository.markAsRead(id);
  }

  Future<void> markAllAsRead(String userId) async {
    final updated = state.notifications.map((item) {
      return item.copyWith(isRead: true, readAt: DateTime.now());
    }).toList();
    state = state.copyWith(notifications: updated);
    await _repository.markAllAsRead(userId);
  }
}

final notificationsNotifierProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(() {
  return NotificationsNotifier();
});
