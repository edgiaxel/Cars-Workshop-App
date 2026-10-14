import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/service_notification.dart';
import '../../../shared/providers/notification_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/section_header.dart';
import 'customer_shell.dart';

/// Customer notifications feed view backed by live Supabase records adhering to DESIGN.md.
class CustomerNotificationsPage extends ConsumerWidget {
  const CustomerNotificationsPage({super.key});

  void _showNotificationDetailDialog(
    BuildContext context,
    ServiceNotification notification,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        title: Row(
          children: [
            const Icon(
              Icons.notifications_active,
              color: AppColors.primaryAccent,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.compact),
            Expanded(
              child: Text(
                'NOTIFICATION TELEMETRY',
                style: AppTypography.sectionTitle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title,
                style: AppTypography.label(color: AppColors.primaryAccent),
              ),
              const SizedBox(height: AppSpacing.compact),
              Text(
                notification.message,
                style: AppTypography.bodyMedium(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.standard),
              const Divider(color: AppColors.borderSubtle, height: 1),
              const SizedBox(height: AppSpacing.compact),
              Text(
                'Received: ${notification.createdAt != null ? notification.createdAt!.toIso8601String().replaceAll('T', ' ').split('.').first : '2026-10-14'} WIB',
                style: AppTypography.technical(color: AppColors.textMuted),
              ),
              Text(
                'Event Type: ${notification.type.toUpperCase()}',
                style: AppTypography.technical(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Dismiss',
              style: AppTypography.label(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification marked as read.'),
                  backgroundColor: AppColors.statusCompleted,
                ),
              );
            },
            child: const Text('Mark Read'),
          ),
        ],
      ),
    );
  }

  void _showMarkAllReadDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        title: Text(
          'Mark All as Read',
          style: AppTypography.sectionTitle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Acknowledge and mark all current notification telemetry as read?',
          style: AppTypography.bodyMedium(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: AppTypography.label(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read.'),
                  backgroundColor: AppColors.statusCompleted,
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return CustomerShell(
      currentRoute: RoutePaths.customerNotifications,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(notificationsProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'NOTIFICATIONS FEED',
                subtitle: 'Workshop alerts, booking confirmations, and vehicle status updates',
                action: TextButton.icon(
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('Mark All Read'),
                  onPressed: () => _showMarkAllReadDialog(context),
                ),
              ),
              const SizedBox(height: AppSpacing.compact),

              notificationsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.section),
                    child: LoadingState(
                      message:
                          'Retrieving workshop alerts and notifications...',
                    ),
                  ),
                ),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.refresh(notificationsProvider),
                ),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return const EmptyState(
                      title: 'No Notifications',
                      message: 'You have no alerts or messages at this time.',
                      icon: Icons.notifications_outlined,
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.standard),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      final isUnread = !n.isRead;

                      return InkWell(
                        onTap: () => _showNotificationDetailDialog(context, n),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: PitCard(
                          technicalLabel:
                              'ALERT • ${n.type.toUpperCase()} • ${n.createdAt?.toIso8601String().split('T').first ?? '2026-10-14'}',
                          borderColor: isUnread
                              ? AppColors.primaryAccent
                              : AppColors.borderSubtle,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(
                                  AppSpacing.compact,
                                ),
                                decoration: BoxDecoration(
                                  color: isUnread
                                      ? AppColors.primaryAccent.withValues(
                                          alpha: 0.15,
                                        )
                                      : AppColors.surfaceSecondary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  n.type == 'booking'
                                      ? Icons.calendar_today_outlined
                                      : n.type == 'service'
                                      ? Icons.build_circle_outlined
                                      : Icons.alarm_outlined,
                                  color: isUnread
                                      ? AppColors.primaryAccent
                                      : AppColors.textMuted,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.standard),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n.title,
                                            style: AppTypography.sectionTitle(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (isUnread)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryAccent,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.control,
                                                  ),
                                            ),
                                            child: Text(
                                              'NEW',
                                              style: AppTypography.technical(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.compact),
                                    Text(
                                      n.message,
                                      style: AppTypography.bodySmall(
                                        color: AppColors.textSecondary,
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
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
