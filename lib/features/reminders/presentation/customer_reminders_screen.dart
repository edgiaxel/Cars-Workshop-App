import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/reminders/data/reminder_repository.dart';
import 'package:pitmate/features/reminders/models/maintenance_reminder.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository();
});

class CustomerRemindersScreen extends ConsumerStatefulWidget {
  const CustomerRemindersScreen({super.key});

  @override
  ConsumerState<CustomerRemindersScreen> createState() => _CustomerRemindersScreenState();
}

class _CustomerRemindersScreenState extends ConsumerState<CustomerRemindersScreen> {
  bool _isLoading = true;
  List<MaintenanceReminder> _reminders = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(reminderRepositoryProvider);
      final customerId = await repo.getCurrentCustomerId();

      if (customerId != null) {
        final list = await repo.fetchCustomerReminders(customerId);
        if (mounted) {
          setState(() {
            _reminders = list;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _reminders = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDismiss(String reminderId) async {
    final repo = ref.read(reminderRepositoryProvider);
    final success = await repo.dismissReminder(reminderId);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maintenance reminder dismissed')),
        );
      }
      _loadReminders();
    }
  }

  void _onNavChanged(int index) {
    RoleNavigation.navigate(
      context,
      RoleNavigation.customerNavItems,
      index,
      currentIndex: 6,
    );
  }

  StatusBadgeType _badgeTypeForStatus(String status) {
    switch (status) {
      case 'notified':
        return StatusBadgeType.warning;
      case 'completed':
        return StatusBadgeType.success;
      case 'dismissed':
        return StatusBadgeType.neutral;
      case 'pending':
      default:
        return StatusBadgeType.inProgress;
    }
  }

  String _formatIntervalText(MaintenanceReminder item) {
    if (item.reminderType == 'mileage_odometer') {
      final dueKm = item.dueOdometerKm ?? 10000;
      final currentKm = item.currentMileageKm ?? 0;
      final diff = dueKm - currentKm;
      if (diff <= 0) {
        return 'Mileage overdue: target $dueKm KM reached';
      }
      return 'Due at $dueKm KM ($diff KM remaining)';
    } else {
      if (item.dueDate == null) return 'Scheduled periodic check';
      final diffDays = item.dueDate!.difference(DateTime.now()).inDays;
      if (diffDays < 0) {
        return 'Overdue by ${diffDays.abs()} days';
      } else if (diffDays == 0) {
        return 'Due today';
      } else {
        return 'Due in $diffDays days (${item.dueDate!.day}/${item.dueDate!.month}/${item.dueDate!.year})';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final userName = auth is AuthAuthenticated ? auth.userProfile.fullName : 'Customer Member';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return ResponsiveRoleScaffold(
      roleTitle: 'Maintenance Reminders',
      userName: userName,
      userSubtitle: 'Verified Customer',
      currentIndex: 6,
      onNavIndexChanged: _onNavChanged,
      navItems: RoleNavigation.customerNavItems,
      telemetryNotice: _reminders.isNotEmpty ? '${_reminders.length} ACTIVE REMINDERS' : null,
      actions: [
        IconButton(
          key: const Key('refresh_reminders_button'),
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh Reminders',
          onPressed: _loadReminders,
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text('Unable to load reminders', style: AppTypography.headlineSmall(color: textColor)),
                        const SizedBox(height: 6),
                        Text(_errorMessage!, style: AppTypography.bodySmall(color: subtextColor)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadReminders, child: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              : _reminders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'All Vehicles Fully Serviced',
                              style: AppTypography.headlineMedium(color: textColor),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No upcoming routine maintenance or interval alerts are pending. Proactive reminders will automatically appear based on time and mileage intervals.',
                              style: AppTypography.bodyMedium(color: subtextColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReminders,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        itemCount: _reminders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _reminders[index];
                          final isOdo = item.reminderType == 'mileage_odometer';

                          return PitCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: (isOdo ? AppColors.warning : AppColors.accentRed)
                                            .withValues(alpha: 0.12),
                                        borderRadius: AppSpacing.roundedSmall,
                                      ),
                                      child: Icon(
                                        isOdo ? Icons.speed : Icons.calendar_today,
                                        color: isOdo ? AppColors.warning : AppColors.accentRed,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: AppTypography.labelLarge(
                                              color: textColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.vehicleMake ?? 'Vehicle'} ${item.vehicleModel ?? ''} • ${item.licensePlate ?? 'Plate'}',
                                            style: AppTypography.telemetrySmall(color: subtextColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusBadge(
                                      label: item.status.toUpperCase(),
                                      type: _badgeTypeForStatus(item.status),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                                    borderRadius: AppSpacing.roundedSmall,
                                    border: Border.all(
                                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, size: 16, color: subtextColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _formatIntervalText(item),
                                          style: AppTypography.bodySmall(
                                            color: textColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (item.description != null && item.description!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    item.description!,
                                    style: AppTypography.bodySmall(color: subtextColor),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => _handleDismiss(item.id),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: subtextColor,
                                      ),
                                      child: const Text('Dismiss'),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        context.go('${RoutePaths.bookService}?vehicleId=${item.vehicleId}');
                                      },
                                      icon: const Icon(Icons.calendar_month, size: 16),
                                      label: const Text('Book Service'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accentRed,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
