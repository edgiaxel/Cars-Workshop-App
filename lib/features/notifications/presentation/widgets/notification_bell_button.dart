import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:pitmate/features/notifications/presentation/widgets/notification_center_modal.dart';

/// Notification Bell action button for ResponsiveRoleScaffold.
/// Displays live unread count and opens NotificationCenterModal.
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key, this.unreadCount, this.onPressed});

  final int? unreadCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsNotifierProvider);
    final count = unreadCount ?? state.unreadCount;

    return IconButton(
      key: const Key('notification_bell_button'),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: AppColors.accentRed,
        child: const Icon(Icons.notifications_outlined, size: 20),
      ),
      tooltip: 'Notifications ($count)',
      onPressed: onPressed ?? () => NotificationCenterModal.show(context),
    );
  }
}
