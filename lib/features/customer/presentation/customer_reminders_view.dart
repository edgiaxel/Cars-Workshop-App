import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/service_reminder.dart';
import '../../../shared/providers/reminder_provider.dart';
import '../../../shared/providers/vehicle_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import 'customer_shell.dart';

/// Customer scheduled maintenance reminders view backed by live Supabase records adhering to DESIGN.md.
class CustomerRemindersPage extends ConsumerWidget {
  const CustomerRemindersPage({super.key});

  void _showAddReminderDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    final mileageController = TextEditingController();
    String? selectedVehicleId;
    String selectedType = 'service';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 90));
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    String? errorMessage;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.surfaceCard : AppColors.lightSurfaceCard;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    final vehiclesAsync = ref.read(vehiclesProvider);
    final vehicles = vehiclesAsync.asData?.value ?? [];
    if (vehicles.isNotEmpty) {
      selectedVehicleId = vehicles.first.id;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: dialogBg,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.standard),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CREATE SERVICE REMINDER',
                        style: AppTypography.sectionTitle(color: textPrimary),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: textMuted),
                        onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                      ),
                    ],
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.compact),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.compact),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(
                        errorMessage!,
                        style: AppTypography.bodySmall(color: AppColors.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.compact),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Add custom interval alerts or service reminders for your registered machines.',
                              style: AppTypography.bodySmall(
                                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.standard),

                            // Vehicle Selection
                            if (vehicles.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.standard),
                                child: Text(
                                  'No vehicles registered. Please register a vehicle in your Garage first.',
                                  style: AppTypography.bodySmall(color: AppColors.warning),
                                ),
                              )
                            else
                              DropdownButtonFormField<String>(
                                initialValue: selectedVehicleId,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Machine / Vehicle *'),
                                items: vehicles.map((v) {
                                  return DropdownMenuItem(
                                    value: v.id,
                                    child: Text(
                                      '${v.displayName} [${v.identifierLabel}]',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setModalState(() => selectedVehicleId = val);
                                },
                                validator: (val) => val == null ? 'Please select a vehicle' : null,
                              ),
                            const SizedBox(height: AppSpacing.standard),

                            // Title
                            TextFormField(
                              controller: titleController,
                              style: AppTypography.bodyMedium(color: textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Reminder Title *',
                                hintText: 'e.g. Brake Fluid Flush or 30k Maintenance',
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Enter reminder title' : null,
                            ),
                            const SizedBox(height: AppSpacing.standard),

                            // Reminder Type
                            DropdownButtonFormField<String>(
                              initialValue: selectedType,
                              decoration: const InputDecoration(labelText: 'Reminder Type'),
                              items: const [
                                DropdownMenuItem(value: 'service', child: Text('Routine Service')),
                                DropdownMenuItem(value: 'maintenance', child: Text('General Maintenance')),
                                DropdownMenuItem(value: 'inspection', child: Text('Safety Inspection')),
                                DropdownMenuItem(value: 'custom', child: Text('Custom Alert')),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => selectedType = val);
                              },
                            ),
                            const SizedBox(height: AppSpacing.standard),

                            // Due Date Picker Tile
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Target Due Date',
                                style: AppTypography.bodySmall(color: textMuted),
                              ),
                              subtitle: Text(
                                selectedDate.toIso8601String().split('T').first,
                                style: AppTypography.bodyMedium(color: textPrimary),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.calendar_month, color: AppColors.primaryAccent),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                  );
                                  if (picked != null) {
                                    setModalState(() => selectedDate = picked);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.standard),

                            // Target Mileage (Optional)
                            TextFormField(
                              controller: mileageController,
                              keyboardType: TextInputType.number,
                              style: AppTypography.bodyMedium(color: textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Target Mileage KM (Optional)',
                                hintText: 'e.g. 45000',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.standard),

                            // Notes
                            TextFormField(
                              controller: notesController,
                              maxLines: 2,
                              style: AppTypography.bodyMedium(color: textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Notes / Target Specifications',
                                hintText: 'e.g. Inspect front carbon ceramic pads and replace Motul 300V oil',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.standard),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          text: 'Cancel',
                          onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.standard),
                      Expanded(
                        child: PrimaryButton(
                          text: isSaving ? 'Saving...' : 'Save Reminder',
                          isLoading: isSaving,
                          onPressed: isSaving || selectedVehicleId == null
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() {
                                    isSaving = true;
                                    errorMessage = null;
                                  });
                                  try {
                                    final odo = int.tryParse(mileageController.text.trim());
                                    await ref.read(customerServiceRemindersProvider.notifier).createReminder(
                                      vehicleId: selectedVehicleId!,
                                      title: titleController.text.trim(),
                                      reminderType: selectedType,
                                      description: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                      dueDate: selectedDate,
                                      dueMileageKm: odo,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(dialogCtx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Service reminder created and activated successfully.'),
                                          backgroundColor: AppColors.statusCompleted,
                                        ),
                                      );
                                    }
                                  } catch (err) {
                                    setModalState(() {
                                      isSaving = false;
                                      errorMessage = err.toString();
                                    });
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _syncServiceHistory(BuildContext context, WidgetRef ref) async {
    try {
      final count = await ref.read(customerServiceRemindersProvider.notifier).syncFromServiceHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count > 0
                  ? 'Auto-generated $count follow-up reminders based on completed service history.'
                  : 'All vehicles already have active maintenance reminders.',
            ),
            backgroundColor: AppColors.info,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync service history: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showReminderActionDialog(
    BuildContext context,
    ServiceReminder reminder,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          'SERVICE ACTION REQUIRED',
          style: AppTypography.sectionTitle(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final borderSubtle = isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;

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
                action: Wrap(
                  spacing: AppSpacing.compact,
                  runSpacing: AppSpacing.compact,
                  children: [
                    SecondaryButton(
                      text: 'Sync History',
                      icon: Icons.sync,
                      width: 140,
                      onPressed: () => _syncServiceHistory(context, ref),
                    ),
                    PrimaryButton(
                      text: 'Add Reminder',
                      icon: Icons.alarm_add,
                      width: 150,
                      onPressed: () => _showAddReminderDialog(context, ref),
                    ),
                  ],
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
                    return Column(
                      children: [
                        const EmptyState(
                          title: 'No Active Reminders',
                          message:
                              'All your registered vehicles are up to date, or sync with your completed service orders.',
                          icon: Icons.alarm_outlined,
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        Center(
                          child: SecondaryButton(
                            text: 'Generate from Service History',
                            icon: Icons.auto_mode,
                            width: 260,
                            onPressed: () => _syncServiceHistory(context, ref),
                          ),
                        ),
                      ],
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
                                          color: textPrimary,
                                        ),
                                      ),
                                      if (r.vehicle != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${r.vehicle!.displayName}${r.vehicle!.licensePlate != null && r.vehicle!.licensePlate!.isNotEmpty ? ' (${r.vehicle!.licensePlate!})' : ''}',
                                          style: AppTypography.bodySmall(
                                            color: textSecondary,
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
                                  color: textMuted,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.standard),
                            Divider(
                              color: borderSubtle,
                              height: 1,
                            ),
                            const SizedBox(height: AppSpacing.compact),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                      color: textMuted,
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
                                      Icon(
                                        Icons.speed,
                                        size: 14,
                                        color: textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Threshold: ${r.dueMileageKm.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} KM',
                                        style: AppTypography.technical(
                                          color: textMuted,
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
