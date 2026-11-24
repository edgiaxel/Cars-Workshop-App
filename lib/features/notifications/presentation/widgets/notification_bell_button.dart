import 'package:flutter/material.dart';
import 'package:pitmate/app/theme/app_colors.dart';

/// Notification Bell action button for ResponsiveRoleScaffold.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key, this.unreadCount = 0, this.onPressed});

  final int unreadCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('notification_bell_button'),
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text('$unreadCount'),
        backgroundColor: AppColors.accentRed,
        child: const Icon(Icons.notifications_outlined, size: 20),
      ),
      tooltip: 'Notifications',
      onPressed: onPressed ?? () {},
    );
  }
}
