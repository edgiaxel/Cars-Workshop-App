import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';

/// Interactive modal sheet displaying role-routed notifications with realtime status.
class NotificationCenterModal extends ConsumerStatefulWidget {
  const NotificationCenterModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationCenterModal(),
    );
  }

  @override
  ConsumerState<NotificationCenterModal> createState() => _NotificationCenterModalState();
}

class _NotificationCenterModalState extends ConsumerState<NotificationCenterModal> {
  bool _filterOnlyUnread = false;

  IconData _iconForType(String type) {
    switch (type) {
      case 'assignment':
        return Icons.handyman_outlined;
      case 'estimate_ready':
        return Icons.receipt_long_outlined;
      case 'qc_result':
        return Icons.fact_check_outlined;
      case 'invoice_issued':
      case 'payment_received':
        return Icons.payments_outlined;
      case 'handover_ready':
        return Icons.key_outlined;
      case 'reminder':
        return Icons.alarm_outlined;
      case 'service_status':
      default:
        return Icons.directions_car_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'qc_result':
      case 'payment_received':
      case 'handover_ready':
        return AppColors.success;
      case 'reminder':
      case 'estimate_ready':
        return AppColors.warning;
      case 'assignment':
      case 'invoice_issued':
        return AppColors.accentRed;
      case 'service_status':
      default:
        return AppColors.info;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final displayedNotifications = _filterOnlyUnread
        ? state.notifications.where((n) => !n.isRead).toList()
        : state.notifications;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Notifications',
                            style: AppTypography.headlineMedium(color: textColor),
                          ),
                          const SizedBox(width: 8),
                          if (state.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentRed,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${state.unreadCount} NEW',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Realtime Connected',
                            style: AppTypography.telemetrySmall(color: subtextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (state.unreadCount > 0)
                  TextButton.icon(
                    key: const Key('mark_all_read_button'),
                    onPressed: () {
                      final auth = ref.read(authNotifierProvider);
                      if (auth is AuthAuthenticated) {
                        ref
                            .read(notificationsNotifierProvider.notifier)
                            .markAllAsRead(auth.userProfile.id);
                      }
                    },
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Mark all read'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accentRed,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Filter Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                ChoiceChip(
                  key: const Key('filter_all_chip'),
                  label: Text('All (${state.notifications.length})'),
                  selected: !_filterOnlyUnread,
                  onSelected: (val) {
                    if (val) setState(() => _filterOnlyUnread = false);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  key: const Key('filter_unread_chip'),
                  label: Text('Unread (${state.unreadCount})'),
                  selected: _filterOnlyUnread,
                  onSelected: (val) {
                    if (val) setState(() => _filterOnlyUnread = true);
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 16, thickness: 1),

          // Notification List
          Expanded(
            child: displayedNotifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_outlined,
                            size: 56,
                            color: subtextColor.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filterOnlyUnread
                                ? 'No unread notifications'
                                : 'No notifications yet',
                            style: AppTypography.headlineSmall(color: textColor),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'All operational updates and vehicle telemetry will appear here.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall(color: subtextColor),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: displayedNotifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = displayedNotifications[index];
                      final typeColor = _colorForType(item.type);

                      return PitCard(
                        padding: const EdgeInsets.all(12),
                        child: InkWell(
                          borderRadius: AppSpacing.roundedMedium,
                          onTap: () {
                            if (!item.isRead) {
                              ref
                                  .read(notificationsNotifierProvider.notifier)
                                  .markAsRead(item.id);
                            }
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Type Icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.12),
                                  borderRadius: AppSpacing.roundedSmall,
                                  border: Border.all(
                                    color: typeColor.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Icon(
                                  _iconForType(item.type),
                                  color: typeColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Text Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: AppTypography.labelLarge(
                                              color: textColor,
                                              fontWeight: item.isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatTimestamp(item.createdAt),
                                          style: AppTypography.telemetrySmall(
                                            color: subtextColor,
                                          ),
                                        ),
                                        if (!item.isRead) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.accentRed,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.message,
                                      style: AppTypography.bodySmall(
                                        color: isDark
                                            ? AppColors.textPrimaryDark.withValues(alpha: 0.85)
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
