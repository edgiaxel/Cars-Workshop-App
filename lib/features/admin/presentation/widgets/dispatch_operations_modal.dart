import 'package:flutter/material.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/service_operations/data/repositories/service_operations_repository.dart';
import 'package:pitmate/features/service_orders/data/models/service_order_model.dart';
import 'package:pitmate/features/workshop/data/models/workshop_bay_model.dart';
import 'package:pitmate/features/workshop/data/repositories/workshop_bay_repository.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DispatchOperationsModal extends StatefulWidget {
  const DispatchOperationsModal({
    super.key,
    required this.serviceOrder,
    required this.onDispatched,
  });

  final ServiceOrderModel serviceOrder;
  final VoidCallback onDispatched;

  @override
  State<DispatchOperationsModal> createState() =>
      _DispatchOperationsModalState();
}

class _DraftOperation {
  _DraftOperation({
    String title = '',
    String description = '',
    this.estimatedDurationMinutes = 45,
    this.priority = 'medium',
    List<String>? checklists,
  })  : titleController = TextEditingController(text: title),
        descriptionController = TextEditingController(text: description),
        durationController =
            TextEditingController(text: estimatedDurationMinutes.toString()),
        checklists = checklists ??
            [
              'Verify component tolerances & safety',
              'Complete operation & torque verification',
            ];

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController durationController;
  int estimatedDurationMinutes;
  String priority;
  final List<String> checklists;

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    durationController.dispose();
  }
}

class _DispatchOperationsModalState extends State<DispatchOperationsModal> {
  final _operationsRepo = ServiceOperationsRepository();
  final _bayRepo = WorkshopBayRepository();

  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _loadError;

  List<Map<String, dynamic>> _mechanics = [];
  List<WorkshopBayModel> _bays = [];
  int? _selectedBayNumber;
  String? _selectedLeadMechanicId;
  final List<_DraftOperation> _operations = [];

  @override
  void initState() {
    super.initState();
    _loadDispatchContext();
  }

  @override
  void dispose() {
    for (final op in _operations) {
      op.dispose();
    }
    super.dispose();
  }

  SupabaseClient? _tryGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadDispatchContext() async {
    setState(() {
      _isLoadingData = true;
      _loadError = null;
    });

    final client = _tryGetClient();
    if (client == null) {
      setState(() {
        _isLoadingData = false;
        _loadError = 'Supabase is not initialized.';
      });
      return;
    }

    try {
      // Load real mechanic profiles and physical bays in parallel
      final mechanicsFuture = client
          .from('profiles')
          .select('id, full_name, phone_number')
          .eq('role', 'mechanic')
          .order('full_name', ascending: true);

      final baysFuture = _bayRepo.fetchBays();

      final estimateFuture = client
          .from('estimates')
          .select('id, status')
          .eq('service_order_id', widget.serviceOrder.id)
          .neq('status', 'superseded')
          .order('revision_number', ascending: false)
          .limit(1)
          .maybeSingle();

      final results = await Future.wait<dynamic>([
        mechanicsFuture.then((r) => r),
        baysFuture,
        estimateFuture.then((r) => r),
      ]);

      final mechList = List<Map<String, dynamic>>.from(results[0] as List);
      final baysList = results[1] as List<WorkshopBayModel>;
      final estMap = results[2] as Map<String, dynamic>?;

      List<Map<String, dynamic>> approvedItems = [];
      if (estMap != null && estMap['id'] != null) {
        final itemsRaw = await client
            .from('estimate_items')
            .select()
            .eq('estimate_id', estMap['id'] as String)
            .eq('authorization_status', 'approved')
            .order('created_at', ascending: true);
        approvedItems = List<Map<String, dynamic>>.from(itemsRaw as List);
      }

      // Resolve default bay: bay already holding this order -> assignedBay string -> first available bay
      int? initialBayNum;
      for (final bay in baysList) {
        if (bay.currentServiceOrderId == widget.serviceOrder.id) {
          initialBayNum = bay.bayNumber;
          break;
        }
      }
      if (initialBayNum == null && widget.serviceOrder.assignedBay != null) {
        final match = RegExp(r'(\d+)').firstMatch(
          widget.serviceOrder.assignedBay!,
        );
        if (match != null) {
          final parsed = int.tryParse(match.group(1) ?? '');
          if (parsed != null && baysList.any((b) => b.bayNumber == parsed)) {
            initialBayNum = parsed;
          }
        }
      }
      if (initialBayNum == null && baysList.isNotEmpty) {
        final availableBay = baysList.cast<WorkshopBayModel?>().firstWhere(
              (b) => b != null && b.isAvailable,
              orElse: () => baysList.first,
            );
        initialBayNum = availableBay?.bayNumber;
      }

      for (final op in _operations) {
        op.dispose();
      }
      _operations.clear();

      if (approvedItems.isNotEmpty) {
        for (final item in approvedItems) {
          final desc = (item['description'] as String? ?? '').trim();
          final type = (item['item_type'] as String? ?? 'service').trim();
          _operations.add(
            _DraftOperation(
              title: desc.isNotEmpty ? desc : 'Approved $type Operation',
              description: 'Execute approved ${type.toUpperCase()} work: $desc',
              estimatedDurationMinutes: type == 'labor' ? 60 : 45,
              priority: 'medium',
              checklists: [
                'Verify specs & prepare components for $desc',
                'Complete work and confirm safety check',
              ],
            ),
          );
        }
      } else {
        _operations.add(
          _DraftOperation(
            title: widget.serviceOrder.customerComplaint.isNotEmpty
                ? 'Service: ${widget.serviceOrder.customerComplaint}'
                : '',
            description: '',
            estimatedDurationMinutes: 60,
            priority: 'medium',
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _mechanics = mechList;
        _bays = baysList;
        _selectedBayNumber = initialBayNum;
        _selectedLeadMechanicId =
            mechList.isNotEmpty ? mechList.first['id'] as String? : null;
        _isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoadingData = false;
      });
    }
  }

  void _addOperation() {
    setState(() {
      _operations.add(_DraftOperation());
    });
  }

  void _removeOperation(int index) {
    if (_operations.length <= 1) return;
    setState(() {
      final removed = _operations.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _addChecklistPrompt(int opIndex) async {
    final controller = TextEditingController();
    final step = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Checklist Step'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Torque caliper bolts to spec',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('ADD'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (step != null && step.isNotEmpty && mounted) {
      setState(() {
        _operations[opIndex].checklists.add(step);
      });
    }
  }

  Future<void> _submitDispatch() async {
    if (_selectedLeadMechanicId == null || _selectedLeadMechanicId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a lead mechanic before dispatching.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (_selectedBayNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a workshop bay before dispatching.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final payloadTasks = <Map<String, dynamic>>[];
    for (final op in _operations) {
      final title = op.titleController.text.trim();
      if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Every operation must have a non-empty title.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
      final mins =
          int.tryParse(op.durationController.text.trim()) ??
          op.estimatedDurationMinutes;
      final cleanChecklists =
          op.checklists.map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
      if (cleanChecklists.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Add at least one checklist step for "$title".'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      payloadTasks.add({
        'title': title,
        'description': op.descriptionController.text.trim(),
        'assigned_mechanic_id': _selectedLeadMechanicId,
        'estimated_duration_minutes': mins > 0 ? mins : 30,
        'priority': op.priority,
        'checklists': cleanChecklists,
      });
    }

    setState(() => _isSubmitting = true);
    try {
      await _operationsRepo.dispatchOperations(
        serviceOrderId: widget.serviceOrder.id,
        leadMechanicId: _selectedLeadMechanicId,
        bayNumber: _selectedBayNumber,
        tasks: payloadTasks,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully dispatched ${payloadTasks.length} operation(s) to Bay 0$_selectedBayNumber!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onDispatched();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dispatch error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppColors.danger,
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
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLarge),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 740),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DISPATCH REPAIR OPERATIONS',
                          style: AppTypography.headlineMedium(color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.serviceOrder.orderNumber} • ${widget.serviceOrder.vehicleDescription}',
                          style: AppTypography.telemetrySmall(
                            color: AppColors.accentRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: _isLoadingData
                    ? const Center(child: CircularProgressIndicator())
                    : _loadError != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.danger,
                                  size: 36,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _loadError!,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall(
                                    color: AppColors.danger,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadDispatchContext,
                                  child: const Text('RETRY'),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isNarrow = constraints.maxWidth < 520;
                                    final bayField = _buildBayDropdown(
                                      isDark,
                                      textColor,
                                    );
                                    final mechField = _buildMechanicDropdown(
                                      isDark,
                                      textColor,
                                    );
                                    if (isNarrow) {
                                      return Column(
                                        children: [
                                          bayField,
                                          const SizedBox(height: 12),
                                          mechField,
                                        ],
                                      );
                                    }
                                    return Row(
                                      children: [
                                        Expanded(child: bayField),
                                        const SizedBox(width: 16),
                                        Expanded(child: mechField),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'OPERATIONS & CHECKLISTS (${_operations.length})',
                                      style: AppTypography.labelSmall(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton.icon(
                                      key: const Key('btn_add_dispatch_op'),
                                      onPressed: _addOperation,
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('ADD OPERATION'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...List.generate(_operations.length, (idx) {
                                  return _buildOperationEditor(
                                    idx,
                                    isDark,
                                    textColor,
                                  );
                                }),
                              ],
                            ),
                          ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    key: const Key('btn_confirm_dispatch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedSmall,
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _isSubmitting
                          ? 'DISPATCHING...'
                          : 'CONFIRM & DISPATCH WORK',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed:
                        (_isLoadingData ||
                                _isSubmitting ||
                                _bays.isEmpty ||
                                _mechanics.isEmpty)
                            ? null
                            : _submitDispatch,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBayDropdown(bool isDark, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TARGET WORKSHOP BAY',
          style: AppTypography.labelSmall(
            color: isDark
                ? AppColors.textMutedDark
                : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(height: 6),
        if (_bays.isEmpty)
          Text(
            'No bays initialized. Initialize bays on Workshop Floor first.',
            style: AppTypography.bodySmall(color: AppColors.danger),
          )
        else
          DropdownButtonFormField<int>(
            key: const Key('dropdown_dispatch_bay'),
            initialValue: _selectedBayNumber,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: AppSpacing.roundedSmall,
              ),
            ),
            items: _bays.map((bay) {
              final occupiedElsewhere = bay.isOccupied &&
                  bay.currentServiceOrderId != widget.serviceOrder.id;
              return DropdownMenuItem<int>(
                value: bay.bayNumber,
                child: Text(
                  occupiedElsewhere
                      ? '${bay.name} (Occupied: ${bay.currentOrderNumber ?? ''})'
                      : '${bay.name} (${bay.status.label})',
                  style: TextStyle(fontSize: 13, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedBayNumber = v),
          ),
      ],
    );
  }

  Widget _buildMechanicDropdown(bool isDark, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LEAD MECHANIC',
          style: AppTypography.labelSmall(
            color: isDark
                ? AppColors.textMutedDark
                : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(height: 6),
        if (_mechanics.isEmpty)
          Text(
            'No mechanic profiles found.',
            style: AppTypography.bodySmall(color: AppColors.danger),
          )
        else
          DropdownButtonFormField<String>(
            key: const Key('dropdown_dispatch_mechanic'),
            initialValue: _selectedLeadMechanicId,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: AppSpacing.roundedSmall,
              ),
            ),
            items: _mechanics.map((m) {
              final id = m['id'] as String;
              final name = (m['full_name'] as String?) ?? 'Mechanic';
              return DropdownMenuItem<String>(
                value: id,
                child: Text(
                  name,
                  style: TextStyle(fontSize: 13, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedLeadMechanicId = v),
          ),
      ],
    );
  }

  Widget _buildOperationEditor(int idx, bool isDark, Color textColor) {
    final op = _operations[idx];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PitCard(
        padding: const EdgeInsets.all(14),
        accentBorderLeft: AppColors.info,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'TASK ${idx + 1}',
                  style: AppTypography.labelSmall(
                    color: AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_operations.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.danger,
                    ),
                    tooltip: 'Remove Operation',
                    onPressed: () => _removeOperation(idx),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: Key('input_dispatch_op_title_$idx'),
              controller: op.titleController,
              decoration: const InputDecoration(
                labelText: 'Operation Title',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: Key('input_dispatch_op_desc_$idx'),
              controller: op.descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Instructions / Technical Notes',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: op.durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Est. Minutes',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: op.priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('LOW')),
                      DropdownMenuItem(value: 'medium', child: Text('MEDIUM')),
                      DropdownMenuItem(value: 'high', child: Text('HIGH')),
                      DropdownMenuItem(value: 'urgent', child: Text('URGENT')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => op.priority = val);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CHECKLIST ITEMS (${op.checklists.length}):',
                  style: AppTypography.labelSmall(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                TextButton(
                  onPressed: () => _addChecklistPrompt(idx),
                  child: const Text('+ Add Step'),
                ),
              ],
            ),
            ...op.checklists.asMap().entries.map((entry) {
              final stepIdx = entry.key;
              final stepLabel = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_box_outline_blank,
                      size: 14,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        stepLabel,
                        style: AppTypography.bodySmall(color: textColor),
                      ),
                    ),
                    if (op.checklists.length > 1)
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close, size: 14),
                        onPressed: () {
                          setState(() => op.checklists.removeAt(stepIdx));
                        },
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
