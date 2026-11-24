import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/auth/domain/user_profile.dart';
import 'package:pitmate/features/auth/domain/user_role.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/notifications/models/notification_item.dart';
import 'package:pitmate/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:pitmate/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:pitmate/features/notifications/presentation/widgets/notification_center_modal.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

class FakeNotificationsNotifier extends NotificationsNotifier {
  FakeNotificationsNotifier(this._initialState);

  final NotificationsState _initialState;

  @override
  NotificationsState build() => _initialState;

  @override
  Future<void> loadNotifications(String role, String userId) async {}

  @override
  Future<void> markAsRead(String id) async {
    final updated = state.notifications.map((item) {
      if (item.id == id) return item.copyWith(isRead: true);
      return item;
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final updated =
        state.notifications.map((item) => item.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
  }
}

void main() {
  const testProfile = UserProfile(
    id: 'user-1',
    role: UserRole.customer,
    fullName: 'Test Customer',
  );

  final sampleNotifications = [
    NotificationItem(
      id: 'notif-1',
      userId: 'user-1',
      role: 'customer',
      title: 'Service Order Intake Complete',
      message: 'Your Toyota GR Yaris has arrived at Bay 01.',
      type: 'service_status',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    NotificationItem(
      id: 'notif-2',
      userId: 'user-1',
      role: 'customer',
      title: 'Estimate Prepared',
      message: 'Diagnostic estimate ready for approval.',
      type: 'estimate_ready',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  testWidgets('NotificationBellButton displays unread badge and triggers modal',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthAuthenticated(testProfile)),
          ),
          notificationsNotifierProvider.overrideWith(
            () => FakeNotificationsNotifier(
              NotificationsState(notifications: sampleNotifications),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(56),
              child: SafeArea(
                child: Row(
                  children: [NotificationBellButton()],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('notification_bell_button')), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // 1 unread notification
  });

  testWidgets('NotificationCenterModal renders notification list and filters unread',
      (tester) async {
    final notifier = FakeNotificationsNotifier(
      NotificationsState(notifications: sampleNotifications),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthAuthenticated(testProfile)),
          ),
          notificationsNotifierProvider.overrideWith(() => notifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NotificationCenterModal(),
          ),
        ),
      ),
    );

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('1 NEW'), findsOneWidget);
    expect(find.text('Service Order Intake Complete'), findsOneWidget);
    expect(find.text('Estimate Prepared'), findsOneWidget);

    // Switch to unread filter
    await tester.tap(find.byKey(const Key('filter_unread_chip')));
    await tester.pumpAndSettle();

    expect(find.text('Service Order Intake Complete'), findsOneWidget);
    expect(find.text('Estimate Prepared'), findsNothing);

    // Tap mark all read
    await tester.tap(find.byKey(const Key('mark_all_read_button')));
    await tester.pumpAndSettle();

    expect(notifier.state.unreadCount, 0);
  });
}
