import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/service_orders/data/models/service_order_model.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

import '../data/models/qc_inspection_model.dart';
import '../data/repositories/qc_repository.dart';

/// Admin Quality Control & Final Sign-Off Screen (M5 - F-014).
///
/// Enables workshop administrators and inspectors to review service orders awaiting
/// Quality Control, verify the 5-point inspection checklist (Mechanical, Fluids,
/// Electrical, Safety, Cosmetics), record pass/fail results, and return vehicles
/// to repair technicians if defects are discovered.
class AdminQcScreen extends ConsumerStatefulWidget {
  const AdminQcScreen({
    super.key,
    this.serviceOrderId,
    this.qcInspectionId,
    this.repository,
  });

  final String? serviceOrderId;
  final String? qcInspectionId;
  final IQcRepository? repository;

  @override
  ConsumerState<AdminQcScreen> createState() => _AdminQcScreenState();
}

class _AdminQcScreenState extends ConsumerState<AdminQcScreen> {
  late final IQcRepository _repository;

  bool _isLoading = true;
  bool _isActionInProgress = false;
  String? _errorMessage;

  List<ServiceOrderModel> _pendingOrders = [];
  ServiceOrderModel? _selectedOrder;
  QcInspectionModel? _activeInspection;

  // Local checklist state for immediate interactive feedback
  final Map<String, bool> _itemPassStatus = {};
  final Map<String, TextEditingController> _itemNoteControllers = {};
  final TextEditingController _generalNotesController = TextEditingController();

  static const List<String> _canonicalCategories = [
    'Mechanical',
    'Fluids',
    'Electrical',
    'Safety',
    'Cosmetics',
  ];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ref.read(qcRepositoryProvider);
    _loadData();
  }

  @override
  void dispose() {
    _generalNotesController.dispose();
    for (final controller in _itemNoteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ordersResult = await _repository.fetchQcPendingOrders();
      if (!mounted) return;

      if (ordersResult.isFailure) {
        setState(() {
          _errorMessage = ordersResult.exceptionOrNull?.message ?? 'Failed to load QC pending orders';
          _isLoading = false;
        });
        return;
      }

      final orders = ordersResult.dataOrNull ?? [];
      _pendingOrders = orders;

      // Select target order: matching widget parameter or first pending order
      ServiceOrderModel? targetOrder;
      if (widget.serviceOrderId != null) {
        targetOrder = orders.where((o) => o.id == widget.serviceOrderId).firstOrNull;
      }
      targetOrder ??= orders.firstOrNull;
      _selectedOrder = targetOrder;

      if (targetOrder != null) {
        await _loadInspectionForOrder(targetOrder.id);
      } else {
        setState(() {
          _activeInspection = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadInspectionForOrder(String orderId) async {
    final inspResult = widget.qcInspectionId != null
        ? await _repository.fetchInspectionById(widget.qcInspectionId!)
        : await _repository.fetchActiveInspectionForOrder(orderId);

    if (!mounted) return;

    if (inspResult.isSuccess && inspResult.dataOrNull != null) {
      _activeInspection = inspResult.dataOrNull;
      _syncChecklistState();
    } else {
      _activeInspection = null;
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _syncChecklistState() {
    _itemPassStatus.clear();
    for (final controller in _itemNoteControllers.values) {
      controller.dispose();
    }
    _itemNoteControllers.clear();

    if (_activeInspection != null) {
      for (final item in _activeInspection!.items) {
        _itemPassStatus[item.id] = item.isPassed;
        _itemNoteControllers[item.id] = TextEditingController(text: item.notes ?? '');
      }
      _generalNotesController.text = _activeInspection!.notes ?? '';
    }
  }

  Future<void> _initializeInspectionSession() async {
    if (_selectedOrder == null) return;

    setState(() => _isActionInProgress = true);

    String inspectorId = '00000000-0000-0000-0000-000000000000';
    final authState = ref.read(authNotifierProvider);
    if (authState is AuthAuthenticated) {
      inspectorId = authState.userProfile.id;
    }

    final submitRes = await _repository.submitOrderForQc(
      serviceOrderId: _selectedOrder!.id,
      inspectorId: inspectorId,
    );

    if (!mounted) return;

    if (submitRes.isSuccess) {
      await _loadInspectionForOrder(_selectedOrder!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quality Control inspection session initialized.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(submitRes.exceptionOrNull?.message ?? 'Failed to initialize QC session'),
          backgroundColor: AppColors.danger,
        ),
      );
    }

    if (mounted) setState(() => _isActionInProgress = false);
  }

  List<QcChecklistItemModel> _buildUpdatedItemsList() {
    if (_activeInspection == null) return [];
    return _activeInspection!.items.map((item) {
      final isPassed = _itemPassStatus[item.id] ?? item.isPassed;
      final notes = _itemNoteControllers[item.id]?.text.trim();
      return item.copyWith(
        isPassed: isPassed,
        notes: notes?.isEmpty ?? true ? null : notes,
      );
    }).toList();
  }

  Future<void> _passQualityControl() async {
    if (_activeInspection == null) return;

    final updatedItems = _buildUpdatedItemsList();
    final allPassed = updatedItems.isNotEmpty && updatedItems.every((i) => i.isPassed);

    if (!allPassed) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(ctx).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 26),
              const SizedBox(width: AppSpacing.space8),
              Text('Incomplete Checklist Items', style: AppTypography.headlineSmall()),
            ],
          ),
          content: Text(
            'Some checklist items are currently not marked as passed. Are you sure you want to pass Quality Control and mark this service order as completed?',
            style: AppTypography.bodyMedium(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('REVIEW ITEMS', style: AppTypography.labelMedium()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('PROCEED & PASS', style: AppTypography.labelMedium(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    setState(() => _isActionInProgress = true);

    final result = await _repository.recordQcResult(
      qcInspectionId: _activeInspection!.id,
      status: QcStatus.passed,
      notes: _generalNotesController.text.trim().isEmpty ? null : _generalNotesController.text.trim(),
      items: updatedItems,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QC PASSED: Service order ${_selectedOrder?.orderNumber ?? ''} marked as COMPLETED.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.exceptionOrNull?.message ?? 'Failed to record QC result'),
          backgroundColor: AppColors.danger,
        ),
      );
    }

    if (mounted) setState(() => _isActionInProgress = false);
  }

  Future<void> _failAndReturnToRepair() async {
    if (_activeInspection == null) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const _QcCorrectionDialog(),
    );

    if (reason == null || reason.isEmpty) return;

    setState(() => _isActionInProgress = true);

    final updatedItems = _buildUpdatedItemsList();
    // Also save current checklist states
    await _repository.recordQcResult(
      qcInspectionId: _activeInspection!.id,
      status: QcStatus.failed,
      notes: _generalNotesController.text.trim().isEmpty ? null : _generalNotesController.text.trim(),
      failureReason: reason,
      items: updatedItems,
    );

    final returnRes = await _repository.returnToRepairFromQc(
      qcInspectionId: _activeInspection!.id,
      correctionNotes: reason,
    );

    if (!mounted) return;

    if (returnRes.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${_selectedOrder?.orderNumber ?? ''} returned to repair bay with defect notes.'),
          backgroundColor: AppColors.danger,
        ),
      );
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(returnRes.exceptionOrNull?.message ?? 'Failed to return order to repair'),
          backgroundColor: AppColors.danger,
        ),
      );
    }

    if (mounted) setState(() => _isActionInProgress = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    final authState = ref.watch(authNotifierProvider);
    String userName = 'Marcus T.';
    if (authState is AuthAuthenticated) {
      userName = authState.userProfile.fullName;
    }

    return ResponsiveRoleScaffold(
      roleTitle: 'Quality Control',
      userSubtitle: 'Workshop Admin',
      userName: userName,
      currentIndex: 8,
      onNavIndexChanged: (i) => RoleNavigation.navigate(
        context,
        RoleNavigation.adminNavItems,
        i,
        currentIndex: 8,
      ),
      navItems: RoleNavigation.adminNavItems,
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RoutePaths.adminWorkshopFloor);
        }
      },
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      telemetryNotice: _selectedOrder != null
          ? 'QC ACTIVE • ${_selectedOrder!.orderNumber}'
          : 'QC ACTIVE',
      actions: [
        if (_activeInspection != null)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: StatusBadge(
                label: _activeInspection!.status.displayName.toUpperCase(),
                type: _activeInspection!.status.isPassed
                    ? StatusBadgeType.success
                    : _activeInspection!.status.isFailed
                        ? StatusBadgeType.danger
                        : StatusBadgeType.inProgress,
              ),
            ),
          ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView(textColor)
              : _buildMainContent(context, isDark, surfaceColor, borderColor, textColor),
    );
  }

  Widget _buildErrorView(Color textColor) {
    return Center(
      child: Padding(
        padding: AppSpacing.p16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: AppSpacing.space12),
            Text('Error Loading Quality Control', style: AppTypography.headlineSmall(color: textColor)),
            const SizedBox(height: AppSpacing.space8),
            Text(
              _errorMessage ?? '',
              style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space12),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
  ) {
    if (_pendingOrders.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: AppSpacing.p16,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: PitCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_outlined, size: 64, color: AppColors.success),
                  const SizedBox(height: AppSpacing.space12),
                  Text(
                    'No Orders Awaiting Quality Control',
                    style: AppTypography.headlineSmall(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    'All completed vehicle service tasks have been verified, or no service orders are currently in qc_pending status.',
                    style: AppTypography.bodyMedium(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.space24),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('REFRESH QUEUE'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppSpacing.mobileBreakpoint;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Queue of orders in qc_pending
              SizedBox(
                width: 320,
                child: _buildPendingOrdersSidebar(isDark, surfaceColor, borderColor, textColor),
              ),
              Container(width: 1, color: borderColor),
              // Right: Active QC Checklist Workspace
              Expanded(
                child: SingleChildScrollView(
                  padding: AppSpacing.p16,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: _buildInspectionWorkspace(context, isDark, textColor),
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          return SingleChildScrollView(
            padding: AppSpacing.p16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPendingOrdersDropdown(isDark, textColor),
                const SizedBox(height: AppSpacing.space12),
                _buildInspectionWorkspace(context, isDark, textColor),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildPendingOrdersSidebar(
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
  ) {
    return Container(
      color: surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSpacing.p16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.fact_check_outlined, size: 20, color: AppColors.accentRed),
                      const SizedBox(width: AppSpacing.space8),
                      Text(
                        'QC QUEUE',
                        style: AppTypography.labelLarge(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning, width: 1),
                  ),
                  child: Text(
                    '${_pendingOrders.length} PENDING',
                    style: AppTypography.labelSmall(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _pendingOrders.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final order = _pendingOrders[index];
                final isSelected = order.id == _selectedOrder?.id;

                return InkWell(
                  key: Key('qc_order_tile_${order.orderNumber}'),
                  onTap: () {
                    setState(() {
                      _selectedOrder = order;
                      _isLoading = true;
                    });
                    _loadInspectionForOrder(order.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: isSelected
                        ? (isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.surfaceElevatedLight)
                        : Colors.transparent,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accentRed : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order.orderNumber,
                                    style: AppTypography.labelLarge(
                                      color: isSelected ? AppColors.accentRed : textColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    order.assignedBay ?? 'Bay --',
                                    style: AppTypography.bodySmall(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.vehicleDescription,
                                style: AppTypography.bodySmall(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (order.customerName != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  order.customerName!,
                                  style: AppTypography.bodySmall(
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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

  Widget _buildPendingOrdersDropdown(bool isDark, Color textColor) {
    return PitCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SELECT PENDING ORDER FOR QC', style: AppTypography.labelMedium(color: AppColors.accentRed)),
              Text('${_pendingOrders.length} in queue', style: AppTypography.labelSmall()),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          DropdownButtonFormField<String>(
            key: const Key('qc_order_dropdown'),
            initialValue: _selectedOrder?.id,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _pendingOrders.map((order) {
              return DropdownMenuItem<String>(
                value: order.id,
                child: Text('${order.orderNumber} • ${order.vehicleDescription}'),
              );
            }).toList(),
            onChanged: (newId) {
              if (newId == null) return;
              final selected = _pendingOrders.firstWhere((o) => o.id == newId);
              setState(() {
                _selectedOrder = selected;
                _isLoading = true;
              });
              _loadInspectionForOrder(newId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionWorkspace(BuildContext context, bool isDark, Color textColor) {
    if (_selectedOrder == null) {
      return const SizedBox.shrink();
    }

    if (_activeInspection == null) {
      return _buildNoActiveInspectionCard(textColor);
    }

    final items = _activeInspection!.items;
    final totalCount = items.length;
    final passedCount = items.where((i) => _itemPassStatus[i.id] == true).length;
    final progressFraction = totalCount == 0 ? 0.0 : passedCount / totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Vehicle & Order Header Card
        _buildOrderHeaderCard(isDark, textColor, totalCount, passedCount, progressFraction),
        const SizedBox(height: AppSpacing.space12),

        // 2. Checklist Items grouped by Category
        _buildChecklistCategoriesView(isDark, textColor),
        const SizedBox(height: AppSpacing.space12),

        // 3. General Inspection Notes Card
        _buildGeneralNotesCard(isDark, textColor),
        const SizedBox(height: AppSpacing.space24),

        // 4. Action Buttons: PASS and FAIL & RETURN
        _buildActionButtonsBar(context, passedCount, totalCount),
      ],
    );
  }

  Widget _buildNoActiveInspectionCard(Color textColor) {
    return PitCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(Icons.engineering_outlined, size: 48, color: AppColors.warning),
          const SizedBox(height: AppSpacing.space12),
          Text(
            'No Active QC Session for ${_selectedOrder!.orderNumber}',
            style: AppTypography.headlineSmall(color: textColor),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            'Initialize the standardized 5-point Quality Control inspection (Mechanical, Fluids, Electrical, Safety, Cosmetics) for this service order.',
            style: AppTypography.bodySmall(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space12),
          ElevatedButton.icon(
            key: const Key('qc_start_inspection_button'),
            onPressed: _isActionInProgress ? null : _initializeInspectionSession,
            icon: const Icon(Icons.play_arrow_outlined),
            label: _isActionInProgress
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('INITIALIZE QC INSPECTION'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeaderCard(
    bool isDark,
    Color textColor,
    int totalCount,
    int passedCount,
    double progressFraction,
  ) {
    return PitCard(
      accentBorderTop: AppColors.accentRed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _selectedOrder!.orderNumber,
                          style: AppTypography.headlineSmall(
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        StatusBadge(
                          label: 'QC IN PROGRESS',
                          type: StatusBadgeType.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedOrder!.vehicleDescription,
                      style: AppTypography.bodyLarge(
                        color: AppColors.accentRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Bay: ${_selectedOrder!.assignedBay ?? 'Bay 01'}',
                    style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
                  ),
                  if (_selectedOrder!.customerName != null)
                    Text(
                      'Customer: ${_selectedOrder!.customerName}',
                      style: AppTypography.bodySmall(),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.space12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CHECKLIST COMPLETION: $passedCount OF $totalCount VERIFIED',
                style: AppTypography.labelMedium(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${(progressFraction * 100).toInt()}%',
                style: AppTypography.labelLarge(
                  color: progressFraction == 1.0 ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressFraction,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressFraction == 1.0 ? AppColors.success : AppColors.accentRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCategoriesView(bool isDark, Color textColor) {
    final categorizedItems = <String, List<QcChecklistItemModel>>{};
    for (final cat in _canonicalCategories) {
      categorizedItems[cat] = [];
    }

    if (_activeInspection != null) {
      for (final item in _activeInspection!.items) {
        categorizedItems.putIfAbsent(item.category, () => []).add(item);
      }
    }

    return Column(
      children: categorizedItems.entries.map((entry) {
        final categoryName = entry.key;
        final items = entry.value;
        if (items.isEmpty) return const SizedBox.shrink();

        final catPassed = items.where((i) => _itemPassStatus[i.id] == true).length;
        final isAllPassed = catPassed == items.length;

        IconData catIcon;
        switch (categoryName) {
          case 'Mechanical':
            catIcon = Icons.build_circle_outlined;
            break;
          case 'Fluids':
            catIcon = Icons.water_drop_outlined;
            break;
          case 'Electrical':
            catIcon = Icons.bolt_outlined;
            break;
          case 'Safety':
            catIcon = Icons.security_outlined;
            break;
          case 'Cosmetics':
            catIcon = Icons.auto_awesome_outlined;
            break;
          default:
            catIcon = Icons.checklist_outlined;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space12),
          child: PitCard(
            padding: AppSpacing.p16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(catIcon, color: AppColors.accentRed, size: 22),
                        const SizedBox(width: AppSpacing.space8),
                        Text(
                          categoryName.toUpperCase(),
                          style: AppTypography.headlineSmall(
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAllPassed
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isAllPassed ? AppColors.success : AppColors.warning,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$catPassed / ${items.length} PASSED',
                        style: AppTypography.labelSmall(
                          color: isAllPassed ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space8),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.space8),
                ...items.map((item) => _buildChecklistItemRow(item, isDark, textColor)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChecklistItemRow(
    QcChecklistItemModel item,
    bool isDark,
    Color textColor,
  ) {
    final isPassed = _itemPassStatus[item.id] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.itemName,
                  style: AppTypography.bodyMedium(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              // Pass / Fail Toggle Segment
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleOption(
                    key: Key('qc_toggle_fail_${item.id}'),
                    label: 'FAIL',
                    icon: Icons.close,
                    isSelected: !isPassed,
                    activeColor: AppColors.danger,
                    onTap: () {
                      setState(() {
                        _itemPassStatus[item.id] = false;
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildToggleOption(
                    key: Key('qc_toggle_pass_${item.id}'),
                    label: 'PASS',
                    icon: Icons.check,
                    isSelected: isPassed,
                    activeColor: AppColors.success,
                    onTap: () {
                      setState(() {
                        _itemPassStatus[item.id] = true;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          // Optional item-level notes field
          if (!isPassed)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextField(
                key: Key('qc_item_notes_${item.id}'),
                controller: _itemNoteControllers[item.id],
                style: AppTypography.bodySmall(),
                decoration: InputDecoration(
                  hintText: 'Notes / defect observation for ${item.itemName}',
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required Key key,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelSmall(
                color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralNotesCard(bool isDark, Color textColor) {
    return PitCard(
      padding: AppSpacing.p16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes_outlined, size: 20, color: AppColors.accentRed),
              const SizedBox(width: AppSpacing.space8),
              Text(
                'INSPECTOR GENERAL NOTES & SIGN-OFF OBSERVATIONS',
                style: AppTypography.labelMedium(color: textColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          TextField(
            key: const Key('qc_general_notes_input'),
            controller: _generalNotesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add road test observations, cosmetic remarks, or technician feedback...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsBar(
    BuildContext context,
    int passedCount,
    int totalCount,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final passButton = ElevatedButton.icon(
          key: const Key('qc_pass_button'),
          onPressed: _isActionInProgress ? null : _passQualityControl,
          icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
          label: Text(
            'PASS QUALITY CONTROL',
            style: AppTypography.labelLarge(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 2,
          ),
        );

        final returnButton = ElevatedButton.icon(
          key: const Key('qc_fail_return_button'),
          onPressed: _isActionInProgress ? null : _failAndReturnToRepair,
          icon: const Icon(Icons.assignment_return_outlined, color: Colors.white, size: 20),
          label: Text(
            'FAIL & RETURN TO REPAIR',
            style: AppTypography.labelLarge(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 2,
          ),
        );

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              passButton,
              const SizedBox(height: AppSpacing.space12),
              returnButton,
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(child: returnButton),
              const SizedBox(width: AppSpacing.space12),
              Expanded(child: passButton),
            ],
          );
        }
      },
    );
  }
}

class _QcCorrectionDialog extends StatefulWidget {
  const _QcCorrectionDialog();

  @override
  State<_QcCorrectionDialog> createState() => _QcCorrectionDialogState();
}

class _QcCorrectionDialogState extends State<_QcCorrectionDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : AppColors.surfaceLight,
      title: Row(
        children: [
          const Icon(Icons.assignment_return_outlined, color: AppColors.accentRed, size: 26),
          const SizedBox(width: AppSpacing.space8),
          Text('FAIL & RETURN TO REPAIR', style: AppTypography.headlineSmall(color: AppColors.accentRed)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Specify the defect or required rework for the assigned mechanic. The service order will revert to in_progress.',
                  style: AppTypography.bodySmall(),
                ),
                const SizedBox(height: AppSpacing.space12),
                TextFormField(
                  key: const Key('qc_correction_notes_input'),
                  controller: _controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Correction Notes / Defect Details',
                    hintText: 'e.g. Brake pedal spongy under heavy pressure. Bleed lines again.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 5) {
                      return 'Please enter detailed correction notes (min 5 characters).';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('CANCEL', style: AppTypography.labelMedium()),
        ),
        ElevatedButton(
          key: const Key('qc_confirm_return_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentRed,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: Text('RETURN TO REPAIR', style: AppTypography.labelMedium(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
