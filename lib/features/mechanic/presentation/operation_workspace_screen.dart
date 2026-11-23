import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/service_operations/data/models/service_order_task_model.dart';
import 'package:pitmate/features/service_operations/data/repositories/service_operations_repository.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

class OperationWorkspaceScreen extends ConsumerStatefulWidget {
  const OperationWorkspaceScreen({
    super.key,
    required this.taskId,
  });

  final String taskId;

  @override
  ConsumerState<OperationWorkspaceScreen> createState() =>
      _OperationWorkspaceScreenState();
}

class _OperationWorkspaceScreenState
    extends ConsumerState<OperationWorkspaceScreen> {
  final _operationsRepo = ServiceOperationsRepository();

  ServiceOrderTaskModel? _task;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Find task by querying assigned mechanic tasks or matching ID
      // Default mechanic: Max Verstappen
      const mechanicId = '7294334d-7144-4c14-9d28-5f90e48a5fbb';
      final tasks = await _operationsRepo.fetchTasksForMechanic(mechanicId);
      final match = tasks.firstWhere(
        (t) => t.id == widget.taskId,
        orElse: () => tasks.isNotEmpty
            ? tasks.first
            : ServiceOrderTaskModel(
                id: widget.taskId,
                serviceOrderId: '',
                title: 'Operation Not Found',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
      );

      setState(() {
        _task = match;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleStart() async {
    if (_task == null) return;
    try {
      final updated = await _operationsRepo.startTask(taskId: _task!.id);
      setState(() => _task = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operation started. Timer is active.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _showPauseDialog() async {
    final reasonController = TextEditingController(text: 'Waiting for parts inspection');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: const Text('PAUSE OPERATION'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter explicit reason for pausing active execution:'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('input_pause_reason'),
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Pause Reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            key: const Key('btn_confirm_pause_dialog'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CONFIRM PAUSE'),
          ),
        ],
      ),
    );

    if (confirmed == true && _task != null) {
      try {
        final updated = await _operationsRepo.pauseTask(
          taskId: _task!.id,
          reason: reasonController.text.trim(),
        );
        setState(() => _task = updated);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleResume() async {
    if (_task == null) return;
    try {
      final updated = await _operationsRepo.resumeTask(_task!.id);
      setState(() => _task = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleComplete() async {
    if (_task == null) return;
    try {
      final updated = await _operationsRepo.completeTask(_task!.id);
      setState(() => _task = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operation completed! Checklist verified.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _showAssistanceDialog() async {
    final reasonController = TextEditingController(text: 'Need two-person caliper bleed procedure');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: const Text('REQUEST ASSISTANCE'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notify lead technician or dispatch for physical assistance:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Assistance Details',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DISPATCH REQUEST'),
          ),
        ],
      ),
    );

    if (confirmed == true && _task != null) {
      await _operationsRepo.requestAssistance(
        taskId: _task!.id,
        reason: reasonController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assistance request dispatched to workshop director.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _showAdditionalFindingDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: const Text('REPORT ADDITIONAL FINDING'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Finding Title (e.g. Micro-cracks on rotor surface)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observations & Safety Impact',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SUBMIT FINDING'),
          ),
        ],
      ),
    );

    if (confirmed == true && _task != null && titleController.text.isNotEmpty) {
      await _operationsRepo.reportFinding(
        serviceOrderId: _task!.serviceOrderId,
        taskId: _task!.id,
        title: titleController.text.trim(),
        description: descController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Additional finding recorded for admin estimate revision.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    return ResponsiveRoleScaffold(
      roleTitle: 'Mechanic Telemetry',
      userName: 'Max Verstappen',
      userSubtitle: 'Lead Performance Tech',
      currentIndex: 1,
      onNavIndexChanged: (i) {
        if (i == 0) context.go(RoutePaths.mechanic);
      },
      navItems: const [
        RoleNavItem(
            label: 'My Work',
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment),
        RoleNavItem(
            label: 'Active Workspace',
            icon: Icons.precision_manufacturing_outlined,
            selectedIcon: Icons.precision_manufacturing),
      ],
      telemetryNotice: 'OPERATION EXECUTION ONLINE',
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.mechanic),
          tooltip: 'Back to My Work',
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.danger, size: 40),
                      const SizedBox(height: 8),
                      Text(_errorMessage!, style: TextStyle(color: textColor)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 18.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Task Header Focal Card
                          _buildTaskHeaderCard(isDark, textColor),
                          const SizedBox(height: 16),

                          // 2. Technical Checklists
                          Text(
                            'OPERATION TECHNICAL CHECKLIST',
                            style: AppTypography.labelLarge(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildChecklistSection(isDark, textColor),
                          const SizedBox(height: 18),

                          // 3. Operational Action Controls
                          _buildExecutionControls(isDark, textColor),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildTaskHeaderCard(bool isDark, Color textColor) {
    final task = _task!;
    Color statusColor = AppColors.accentRed;
    if (task.isCompleted) statusColor = AppColors.success;
    if (task.isPaused) statusColor = AppColors.warning;

    return PitCard(
      accentBorderLeft: statusColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE WORKSPACE • ${task.status.label.toUpperCase()}',
                style: AppTypography.labelSmall(
                  color: statusColor,
                ),
              ),
              StatusBadge(
                label: task.status.label.toUpperCase(),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: AppTypography.headlineMedium(color: textColor),
          ),
          const SizedBox(height: 4),
          if (task.description != null)
            Text(
              task.description!,
              style: AppTypography.bodySmall(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: AppColors.accentRed),
              const SizedBox(width: 4),
              Text(
                'Est: ${task.estimatedDurationMinutes} MIN',
                style: AppTypography.telemetrySmall(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.directions_car, size: 16, color: AppColors.textMutedDark),
              const SizedBox(width: 4),
              Text(
                task.vehiclePlate ?? 'Vehicle FL5',
                style: AppTypography.telemetrySmall(color: textColor),
              ),
            ],
          ),
          if (task.pauseReason != null && task.isPaused) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: AppSpacing.roundedSmall,
              ),
              child: Text(
                'PAUSE REASON: ${task.pauseReason}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistSection(bool isDark, Color textColor) {
    final checklists = _task?.checklists ?? [];
    if (checklists.isEmpty) {
      return PitCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No checklist items required for this operation.',
            style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
          ),
        ),
      );
    }

    return Column(
      children: checklists.asMap().entries.map((entry) {
        final item = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PitCard(
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                item.itemDescription,
                style: AppTypography.labelMedium(
                  color: item.isCompleted
                      ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
                      : textColor,
                ),
              ),
              value: item.isCompleted,
              activeColor: AppColors.accentRed,
              onChanged: _task?.isCompleted == true
                  ? null
                  : (bool? val) async {
                      if (val != null) {
                        await _operationsRepo.toggleChecklist(
                          checklistId: item.id,
                          isCompleted: val,
                        );
                        _loadTask();
                      }
                    },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExecutionControls(bool isDark, Color textColor) {
    final task = _task!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (task.status == TaskStatus.pending || task.status == TaskStatus.assigned)
          ElevatedButton.icon(
            key: const Key('btn_start_operation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('START OPERATION', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _handleStart,
          )
        else if (task.isInProgress) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('btn_pause_operation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.pause),
                  label: const Text('PAUSE WORK', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _showPauseDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('btn_complete_operation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('COMPLETE WORK', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _handleComplete,
                ),
              ),
            ],
          ),
        ] else if (task.isPaused) ...[
          ElevatedButton.icon(
            key: const Key('btn_resume_operation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('RESUME OPERATION', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _handleResume,
          ),
        ] else if (task.isCompleted) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: AppSpacing.roundedSmall,
            ),
            child: const Center(
              child: Text(
                'OPERATION COMPLETED & VERIFIED',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Support Actions: Assistance & Additional Findings
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('btn_request_assistance'),
                icon: const Icon(Icons.handyman_outlined, size: 16),
                label: const Text('REQUEST ASSISTANCE'),
                onPressed: _showAssistanceDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('btn_report_finding'),
                icon: const Icon(Icons.search, size: 16),
                label: const Text('REPORT FINDING'),
                onPressed: _showAdditionalFindingDialog,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
