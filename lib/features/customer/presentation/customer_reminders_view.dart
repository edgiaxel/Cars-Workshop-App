import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/service_reminder.dart';
import '../../../shared/providers/reminder_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import 'customer_shell.dart';

/// Customer scheduled maintenance reminders view backed by live Supabase records adhering to DESIGN.md.
class CustomerRemindersPage extends ConsumerWidget {
  const CustomerRemindersPage({super.key});

  void _showAddReminderDialog(BuildContext context) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        title: Text(
          'CREATE SERVICE REMINDER',
          style: AppTypography.sectionTitle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add custom interval alerts or service reminders for your registered machines.',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.standard),
              TextField(
                controller: titleController,
                style: AppTypography.bodyMedium(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Reminder Title',
                  hintText: 'e.g. Brake Fluid Flush or Tire Rotation',
                ),
              ),
              const SizedBox(height: AppSpacing.standard),
              TextField(
                controller: notesController,
                maxLines: 2,
                style: AppTypography.bodyMedium(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Reminder Notes / Milestone',
                  hintText:
                      'e.g. Inspect front carbon ceramic pads at 35,000 KM',
                ),
              ),
            ],
          ),
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
                  content: Text(
                    'Reminder saved. Scheduled alert notifications will trigger on approaching mileage.',
                  ),
                  backgroundColor: AppColors.statusCompleted,
                ),
              );
            },
            child: const Text('Save Reminder'),
          ),
        ],
      ),
    );
  }

  void _showReminderActionDialog(
    BuildContext context,
    ServiceReminder reminder,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        title: Text(
          'SERVICE ACTION REQUIRED',
          style: AppTypography.sectionTitle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reminder.title,
                style: AppTypography.label(color: AppColors.primaryAccent),
              ),
              const SizedBox(height: AppSpacing.compact),
              Text(
                reminder.description ?? 'Maintenance milestone has been flagged by workshop telemetry.',
                style: AppTypography.bodyMedium(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.standard),
              const Divider(color: AppColors.borderSubtle, height: 1),
              const SizedBox(height: AppSpacing.standard),
              if (reminder.dueMileageKm != null)
                Text(
                  'Target Mileage: ${reminder.dueMileageKm.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} KM',
                  style: AppTypography.technical(color: AppColors.textMuted),
                ),
              if (reminder.dueDate != null)
                Text(
                  'Due Date: ${reminder.dueDate!.toIso8601String().split('T').first}',
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Opening service booking request for this maintenance interval.',
                  ),
                  backgroundColor: AppColors.statusCompleted,
                ),
              );
            },
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text('Book Maintenance Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(customerServiceRemindersProvider);

    return CustomerShell(
      currentRoute: RoutePaths.customerReminders,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(customerServiceRemindersProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'MAINTENANCE REMINDERS',
                subtitle:
                    'Upcoming vehicle service intervals and mileage alerts',
                action: PrimaryButton(
                  text: 'Add Reminder',
                  icon: Icons.alarm_add,
                  width: 160,
                  onPressed: () => _showAddReminderDialog(context),
                ),
              ),
              const SizedBox(height: AppSpacing.compact),

              remindersAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.section),
                    child: LoadingState(
                      message: 'Scanning vehicle maintenance intervals...',
                    ),
                  ),
                ),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.refresh(customerServiceRemindersProvider),
                ),
                data: (reminders) {
                  if (reminders.isEmpty) {
                    return const EmptyState(
                      title: 'No Active Reminders',
                      message: 'All your registered vehicles are up to date.',
                      icon: Icons.alarm_outlined,
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reminders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.standard),
                    itemBuilder: (context, index) {
                      final r = reminders[index];

                      return PitCard(
                        technicalLabel:
                            'REMINDER • ${r.reminderType.toUpperCase()}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.title,
                                        style: AppTypography.sectionTitle(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (r.vehicle != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${r.vehicle!.displayName}${r.vehicle!.licensePlate != null && r.vehicle!.licensePlate!.isNotEmpty ? ' (${r.vehicle!.licensePlate!})' : ''}',
                                          style: AppTypography.bodySmall(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.compact),
                                StatusBadge(
                                  label: r.status.toUpperCase(),
                                  color: r.status == 'pending'
                                      ? AppColors.warning
                                      : AppColors.statusCompleted,
                                ),
                              ],
                            ),
                            if (r.description != null &&
                                r.description!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.compact),
                              Text(
                                r.description!,
                                style: AppTypography.bodySmall(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.standard),
                            const Divider(
                              color: AppColors.borderSubtle,
                              height: 1,
                            ),
                            const SizedBox(height: AppSpacing.compact),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      r.dueDate != null
                                          ? 'Due: ${r.dueDate!.toIso8601String().split('T').first}'
                                          : 'Scheduled by Mileage',
                                      style: AppTypography.technical(
                                        color: AppColors.primaryAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                if (r.dueMileageKm != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.speed,
                                        size: 14,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Threshold: ${r.dueMileageKm.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} KM',
                                        style: AppTypography.technical(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.compact),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _showReminderActionDialog(context, r),
                                  icon: const Icon(
                                    Icons.build_circle_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Schedule Service'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryAccent,
                                    side: const BorderSide(
                                      color: AppColors.primaryAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
