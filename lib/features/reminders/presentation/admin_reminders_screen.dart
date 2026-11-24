import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/reminders/models/maintenance_reminder.dart';
import 'package:pitmate/features/reminders/presentation/customer_reminders_screen.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

class AdminRemindersScreen extends ConsumerStatefulWidget {
  const AdminRemindersScreen({super.key});

  @override
  ConsumerState<AdminRemindersScreen> createState() => _AdminRemindersScreenState();
}

class _AdminRemindersScreenState extends ConsumerState<AdminRemindersScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  String _selectedStatusFilter = 'all';
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
      final list = await repo.fetchAdminReminders(status: _selectedStatusFilter);
      if (mounted) {
        setState(() {
          _reminders = list;
          _isLoading = false;
        });
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

  Future<void> _processDueReminders() async {
    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(reminderRepositoryProvider);
      final count = await repo.processDueReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Processed due reminders: $count customer notifications emitted')),
        );
      }
      _loadReminders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Processing error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _onNavChanged(int index) {
    RoleNavigation.navigate(
      context,
      RoleNavigation.adminNavItems,
      index,
      currentIndex: 12,
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

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final userName = auth is AuthAuthenticated ? auth.userProfile.fullName : 'Toto Wolf';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return ResponsiveRoleScaffold(
      roleTitle: 'Service Reminders Queue',
      userName: userName,
      userSubtitle: 'Workshop Director',
      currentIndex: 12,
      onNavIndexChanged: _onNavChanged,
      navItems: RoleNavigation.adminNavItems,
      telemetryNotice: '${_reminders.length} QUEUED REMINDERS',
      actions: [
        IconButton(
          key: const Key('refresh_admin_reminders_button'),
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh',
          onPressed: _loadReminders,
        ),
      ],
      body: Column(
        children: [
          // Filter and Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          key: const Key('chip_all'),
                          label: const Text('All'),
                          selected: _selectedStatusFilter == 'all',
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedStatusFilter = 'all');
                              _loadReminders();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          key: const Key('chip_pending'),
                          label: const Text('Pending'),
                          selected: _selectedStatusFilter == 'pending',
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedStatusFilter = 'pending');
                              _loadReminders();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          key: const Key('chip_notified'),
                          label: const Text('Notified'),
                          selected: _selectedStatusFilter == 'notified',
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedStatusFilter = 'notified');
                              _loadReminders();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          key: const Key('chip_dismissed'),
                          label: const Text('Dismissed'),
                          selected: _selectedStatusFilter == 'dismissed',
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedStatusFilter = 'dismissed');
                              _loadReminders();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  key: const Key('process_due_reminders_button'),
                  onPressed: _isProcessing ? null : _processDueReminders,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_outlined, size: 16),
                  label: const Text('Process Due'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentRed,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Reminders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Text(_errorMessage!, style: AppTypography.bodyMedium(color: AppColors.danger)),
                      )
                    : _reminders.isEmpty
                        ? Center(
                            child: Text(
                              'No reminders found matching filter',
                              style: AppTypography.bodyMedium(color: subtextColor),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _reminders.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _reminders[index];
                              return PitCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.reminderType == 'mileage_odometer'
                                          ? Icons.speed
                                          : Icons.calendar_today,
                                      color: AppColors.accentRed,
                                      size: 20,
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
                                            '${item.vehicleMake ?? 'Vehicle'} ${item.vehicleModel ?? ''} (${item.licensePlate ?? 'Plate'}) • Customer: ${item.customerName ?? 'Verified Customer'}',
                                            style: AppTypography.bodySmall(color: subtextColor),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.reminderType == 'mileage_odometer'
                                                ? 'Interval Target: ${item.dueOdometerKm} KM'
                                                : 'Due Date: ${item.dueDate?.day}/${item.dueDate?.month}/${item.dueDate?.year}',
                                            style: AppTypography.telemetrySmall(color: AppColors.accentRed),
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
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
