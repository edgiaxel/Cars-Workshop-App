import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/inventory/data/models/part_request_model.dart';
import 'package:pitmate/features/inventory/data/models/service_task_part_consumption_model.dart';
import 'package:pitmate/features/inventory/data/repositories/part_operations_repository.dart';
import 'package:pitmate/features/service_operations/data/models/service_order_task_model.dart';
import 'package:pitmate/features/service_operations/data/repositories/service_operations_repository.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/pit_error_dialog.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

class OperationWorkspaceScreen extends ConsumerStatefulWidget {
  const OperationWorkspaceScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<OperationWorkspaceScreen> createState() =>
      _OperationWorkspaceScreenState();
}

class _OperationWorkspaceScreenState
    extends ConsumerState<OperationWorkspaceScreen> {
  final _operationsRepo = ServiceOperationsRepository();
  final _partOpsRepo = PartOperationsRepository();

  ServiceOrderTaskModel? _task;
  List<PartRequestModel> _partRequests = [];
  List<ServiceTaskPartConsumptionModel> _consumptions = [];
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

      List<PartRequestModel> reqs = [];
      List<ServiceTaskPartConsumptionModel> cons = [];
      try {
        final allReqs = await _partOpsRepo.fetchRequests(
          serviceOrderId: match.serviceOrderId,
        );
        reqs = allReqs.where((r) => r.taskId == match.id).toList();
        cons = await _partOpsRepo.fetchTaskConsumptions(match.id);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _task = match;
          _partRequests = reqs;
          _consumptions = cons;
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
    final reasonController = TextEditingController(
      text: 'Waiting for parts inspection',
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
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
    final reasonController = TextEditingController(
      text: 'Need two-person caliper bleed procedure',
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        title: const Text('REQUEST ASSISTANCE'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notify lead technician or dispatch for physical assistance:',
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
            ),
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
            content: Text(
              'Assistance request dispatched to workshop director.',
            ),
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
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
            ),
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
            content: Text(
              'Additional finding recorded for admin estimate revision.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.graphitePrimary;

    return ResponsiveRoleScaffold(
      roleTitle: 'Mechanic Telemetry',
      userName: 'Max Verstappen',
      userSubtitle: 'Lead Performance Tech',
      currentIndex: 1,
      showBackButton: true,
      onBack: () => context.go(RoutePaths.mechanic),
      onNavIndexChanged: (i) => RoleNavigation.navigate(
        context,
        RoleNavigation.mechanicNavItems,
        i,
        currentIndex: 1,
      ),
      navItems: RoleNavigation.mechanicNavItems,
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
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.danger,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(_errorMessage!, style: TextStyle(color: textColor)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 18.0,
              ),
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

                      // 3. Parts & Materials Floor Management
                      _buildPartsSection(isDark, textColor),
                      const SizedBox(height: 18),

                      // 4. Operational Action Controls
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
                style: AppTypography.labelSmall(color: statusColor),
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
              const Icon(
                Icons.timer_outlined,
                size: 16,
                color: AppColors.accentRed,
              ),
              const SizedBox(width: 4),
              Text(
                'Est: ${task.estimatedDurationMinutes} MIN',
                style: AppTypography.telemetrySmall(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.directions_car,
                size: 16,
                color: AppColors.textMutedDark,
              ),
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
            style: TextStyle(
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
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
                      ? (isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight)
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
        if (task.status == TaskStatus.pending ||
            task.status == TaskStatus.assigned)
          ElevatedButton.icon(
            key: const Key('btn_start_operation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text(
              'START OPERATION',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                  label: const Text(
                    'PAUSE WORK',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                  label: const Text(
                    'COMPLETE WORK',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
            label: const Text(
              'RESUME OPERATION',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 450;
            final assistBtn = OutlinedButton.icon(
              key: const Key('btn_request_assistance'),
              icon: const Icon(Icons.handyman_outlined, size: 16),
              label: const Text('REQUEST ASSISTANCE'),
              onPressed: _showAssistanceDialog,
            );

            final findingBtn = OutlinedButton.icon(
              key: const Key('btn_report_finding'),
              icon: const Icon(Icons.search, size: 16),
              label: const Text('REPORT FINDING'),
              onPressed: _showAdditionalFindingDialog,
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [assistBtn, const SizedBox(height: 10), findingBtn],
              );
            }

            return Row(
              children: [
                Expanded(child: assistBtn),
                const SizedBox(width: 12),
                Expanded(child: findingBtn),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _openRequestPartDialog() async {
    if (_task == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qtyController = TextEditingController(text: '1');
    final notesController = TextEditingController();

    List<Map<String, dynamic>> catalog = [];
    try {
      catalog = await _partOpsRepo.fetchCatalogForRequest();
    } catch (_) {}

    if (!mounted) return;

    if (catalog.isEmpty) {
      showPitErrorDialog(
        context,
        title: 'CATALOG EMPTY',
        message: 'No active parts found in warehouse catalog.',
        hint: 'Contact workshop admin to configure catalog items.',
      );
      return;
    }

    String selectedPartId = catalog.first['id'] as String;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          backgroundColor: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          title: Text(
            'REQUEST FLOOR PART',
            style: AppTypography.headlineSmall(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.graphitePrimary,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Part from Warehouse Catalog:',
                  style: AppTypography.bodySmall(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedPartId,
                  dropdownColor: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  isExpanded: true,
                  items: catalog.map((p) {
                    final sku = p['sku'] ?? '';
                    final name = p['name'] ?? '';
                    final unit = p['unit_of_measurement'] ?? 'pcs';
                    int avail = 0;
                    if (p['inventory_balances'] != null) {
                      if (p['inventory_balances'] is List &&
                          (p['inventory_balances'] as List).isNotEmpty) {
                        avail =
                            ((p['inventory_balances'] as List)
                                        .first['quantity_available']
                                    as num?)
                                ?.toInt() ??
                            0;
                      } else if (p['inventory_balances'] is Map) {
                        avail =
                            (p['inventory_balances']['quantity_available']
                                    as num?)
                                ?.toInt() ??
                            0;
                      }
                    }
                    return DropdownMenuItem<String>(
                      value: p['id'] as String,
                      child: Text(
                        '[$sku] $name (Avail: $avail $unit)',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedPartId = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('input_request_part_qty'),
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity Required',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('input_request_part_notes'),
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Reason / Specifics (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              key: const Key('btn_submit_part_request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final qty = int.tryParse(qtyController.text.trim()) ?? 0;
                if (qty <= 0) {
                  showPitErrorDialog(
                    ctx,
                    title: 'INVALID QUANTITY',
                    message: 'Quantity must be at least 1 unit.',
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await _partOpsRepo.requestPart(
                    taskId: _task!.id,
                    partId: selectedPartId,
                    quantity: qty,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );
                  if (!mounted) return;
                  _loadTask();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Part request dispatched to workshop inventory.',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  showPitErrorDialog(
                    context,
                    title: 'PART REQUEST FAILED',
                    message: e.toString().replaceAll('Exception: ', ''),
                    hint: 'Check that active service order is open and stock is available.',
                  );
                }
              },
              child: const Text('SUBMIT REQUEST'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRecordConsumptionDialog() async {
    if (_task == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Collect parts that can be consumed (fulfilled requests or catalog)
    List<Map<String, dynamic>> eligibleParts = [];
    for (final req in _partRequests) {
      if (req.quantityFulfilled > 0) {
        eligibleParts.add({
          'id': req.partId,
          'name': req.partName ?? req.partSku ?? 'Part',
          'sku': req.partSku ?? '',
          'unit': req.partUnit ?? 'pcs',
          'max': req.quantityFulfilled,
        });
      }
    }

    if (eligibleParts.isEmpty) {
      try {
        final catalog = await _partOpsRepo.fetchCatalogForRequest();
        for (final p in catalog) {
          eligibleParts.add({
            'id': p['id'] as String,
            'name': p['name'] as String? ?? '',
            'sku': p['sku'] as String? ?? '',
            'unit': p['unit_of_measurement'] as String? ?? 'pcs',
            'max': 100,
          });
        }
      } catch (_) {}
    }

    if (!mounted) return;

    if (eligibleParts.isEmpty) {
      showPitErrorDialog(
        context,
        title: 'NO PARTS ISSUED',
        message:
            'No parts have been fulfilled or issued for this operation yet.',
        hint: 'Submit a part request and wait for admin fulfillment first.',
      );
      return;
    }

    String selectedPartId = eligibleParts.first['id'] as String;
    final consumedController = TextEditingController(text: '1');
    final returnedController = TextEditingController(text: '0');

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          backgroundColor: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          title: Text(
            'RECORD CONSUMPTION & RETURN',
            style: AppTypography.headlineSmall(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.graphitePrimary,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Part:',
                  style: AppTypography.bodySmall(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedPartId,
                  dropdownColor: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  isExpanded: true,
                  items: eligibleParts.map((p) {
                    final sku = p['sku'] ?? '';
                    final name = p['name'] ?? '';
                    final unit = p['unit'] ?? 'pcs';
                    return DropdownMenuItem<String>(
                      value: p['id'] as String,
                      child: Text(
                        '[$sku] $name ($unit)',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedPartId = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('input_consumed_qty'),
                  controller: consumedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Units Consumed / Installed',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('input_returned_qty'),
                  controller: returnedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Units Unused / Returned to Stock',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              key: const Key('btn_submit_part_consumption'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final consumed =
                    int.tryParse(consumedController.text.trim()) ?? -1;
                final returned =
                    int.tryParse(returnedController.text.trim()) ?? -1;
                if (consumed < 0 ||
                    returned < 0 ||
                    (consumed == 0 && returned == 0)) {
                  showPitErrorDialog(
                    ctx,
                    title: 'INVALID QUANTITIES',
                    message: 'Consumed and returned must be non-negative with at least 1 unit recorded.',
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await _partOpsRepo.consumeAndReturnParts(
                    taskId: _task!.id,
                    partId: selectedPartId,
                    consumedQty: consumed,
                    returnedQty: returned,
                  );
                  if (!mounted) return;
                  _loadTask();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Recorded $consumed consumed, $returned returned.',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  showPitErrorDialog(
                    context,
                    title: 'RECORD CONSUMPTION FAILED',
                    message: e.toString().replaceAll('Exception: ', ''),
                    hint: 'Ensure returned and consumed amounts do not exceed issued quantities.',
                  );
                }
              },
              child: const Text('CONFIRM USAGE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartsSection(bool isDark, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              'PARTS & MATERIALS',
              style: AppTypography.labelLarge(color: textColor)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  key: const Key('btn_open_part_request_dialog'),
                  icon: const Icon(Icons.add_shopping_cart, size: 14),
                  label: const Text(
                    'REQUEST PART',
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: _openRequestPartDialog,
                ),
                OutlinedButton.icon(
                  key: const Key('btn_open_part_consumption_dialog'),
                  icon: const Icon(Icons.check_box_outlined, size: 14),
                  label: const Text(
                    'RECORD USAGE',
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: _openRecordConsumptionDialog,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_partRequests.isEmpty && _consumptions.isEmpty)
          PitCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No parts requested or consumed for this operation.',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ),
          ),
        if (_partRequests.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              'FLOOR REQUESTS',
              style: AppTypography.bodySmall(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ..._partRequests.map((req) {
            Color statusColor = AppColors.warning;
            if (req.isFulfilled) statusColor = AppColors.success;
            if (req.isRejected) statusColor = AppColors.accentRed;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: PitCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.partName ?? req.partSku ?? 'Part ${req.partId}',
                            style: AppTypography.labelMedium(color: textColor)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SKU: ${req.partSku ?? "—"} • Qty: ${req.quantityRequested} ${req.partUnit ?? "pcs"} (Fulfilled: ${req.quantityFulfilled})',
                            style: AppTypography.bodySmall(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          if (req.notes != null && req.notes!.isNotEmpty)
                            Text(
                              'Note: ${req.notes}',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: req.status.replaceAll('_', ' ').toUpperCase(),
                      color: statusColor,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        if (_consumptions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              'RECORDED CONSUMPTION',
              style: AppTypography.bodySmall(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ..._consumptions.map((c) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: PitCard(
                accentBorderLeft: AppColors.info,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.partName ?? c.partSku ?? 'Part ${c.partId}',
                            style: AppTypography.labelMedium(color: textColor)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Consumed: ${c.quantityConsumed} ${c.partUnit ?? "pcs"} • Returned: ${c.quantityReturned} ${c.partUnit ?? "pcs"}',
                            style: AppTypography.bodySmall(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rp ${(c.totalCostCents).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                      style: AppTypography.telemetrySmall(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
