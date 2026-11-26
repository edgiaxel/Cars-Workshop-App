import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/core/utils/currency_formatter.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

import '../data/models/vehicle_handover_model.dart';
import '../data/repositories/handover_repository.dart';

/// Admin Vehicle Handover Screen (UI-A11).
/// Enables workshop admins to verify pre-delivery checklist, enforce payment
/// settlement or capture authorized override, and execute physical vehicle handover.
class AdminHandoverScreen extends ConsumerStatefulWidget {
  const AdminHandoverScreen({
    super.key,
    this.repository,
    this.initialOrderId,
  });

  final IHandoverRepository? repository;
  final String? initialOrderId;

  @override
  ConsumerState<AdminHandoverScreen> createState() =>
      _AdminHandoverScreenState();
}

class _AdminHandoverScreenState extends ConsumerState<AdminHandoverScreen> {
  late final IHandoverRepository _repository;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<HandoverOrderCandidate> _pendingOrders = [];
  List<HandoverOrderCandidate> _historyOrders = [];
  HandoverOrderCandidate? _selectedOrder;

  // Active view tab: 0 = Pending Handover, 1 = Handover History
  int _activeTab = 0;
  String _searchQuery = '';

  // Checklist state for selected order
  HandoverChecklist _checklist = const HandoverChecklist();
  bool _customerConfirmed = true;
  final TextEditingController _overrideReasonController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ref.read(handoverRepositoryProvider);
    _loadHandoverData();
  }

  @override
  void dispose() {
    _overrideReasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadHandoverData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final queueResult = await _repository.fetchHandoverQueue();
    final historyResult = await _repository.fetchHandoverHistory();

    if (!mounted) return;

    if (queueResult.isSuccess && historyResult.isSuccess) {
      final queue = queueResult.dataOrNull ?? [];
      final history = historyResult.dataOrNull ?? [];

      setState(() {
        _isLoading = false;
        _pendingOrders = queue;
        _historyOrders = history;

        if (widget.initialOrderId != null) {
          final found = queue
              .where((o) => o.orderId == widget.initialOrderId)
              .firstOrNull;
          if (found != null) {
            _selectOrder(found);
          }
        }
      });
    } else {
      final err = queueResult.exceptionOrNull?.message ??
          historyResult.exceptionOrNull?.message ??
          'Failed to load handover orders';
      setState(() {
        _isLoading = false;
        _errorMessage = err;
      });
    }
  }

  void _selectOrder(HandoverOrderCandidate order) {
    setState(() {
      _selectedOrder = order;
      // Pre-fill existing checklist if available, otherwise default to all checked
      if (order.handover != null) {
        _checklist = order.handover!.checklist;
        _customerConfirmed = order.handover!.customerConfirmed;
        _overrideReasonController.text =
            order.handover!.paymentOverrideReason ?? '';
        _notesController.text = order.handover!.notes ?? '';
      } else {
        _checklist = const HandoverChecklist(
          vehicleCleaned: true,
          personalItemsReturned: true,
          oldPartsPresented: true,
          keysReturned: true,
        );
        _customerConfirmed = true;
        _overrideReasonController.clear();
        _notesController.clear();
      }
    });
  }

  void _deselectOrder() {
    setState(() {
      _selectedOrder = null;
    });
  }

  bool get _isOverrideRequired {
    if (_selectedOrder == null) return false;
    return _selectedOrder!.outstandingBalanceCents > 0;
  }

  bool get _isHandoverValid {
    if (_selectedOrder == null) return false;
    if (_selectedOrder!.isHandedOver) return false;
    if (!_checklist.isComplete) return false;
    if (_isOverrideRequired &&
        _overrideReasonController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _submitHandover() async {
    final order = _selectedOrder;
    if (order == null || !_isHandoverValid || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final authState = ref.read(authNotifierProvider);
    final adminId = authState is AuthAuthenticated
        ? authState.userProfile.id
        : '00000000-0000-0000-0000-000000000001';

    final result = await _repository.recordVehicleHandover(
      serviceOrderId: order.orderId,
      adminId: adminId,
      checklist: _checklist,
      customerConfirmed: _customerConfirmed,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      paymentOverrideReason: _overrideReasonController.text.trim().isEmpty
          ? null
          : _overrideReasonController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehicle ${order.vehiclePlate} handed over successfully. Service Order ${order.orderNumber} is closed.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      _deselectOrder();
      await _loadHandoverData();
    } else {
      final err = result.exceptionOrNull?.message ?? 'Failed to record handover';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Handover failed: $err'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  List<HandoverOrderCandidate> get _currentList {
    final list = _activeTab == 0 ? _pendingOrders : _historyOrders;
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase().trim();
    return list.where((o) {
      return o.orderNumber.toLowerCase().contains(q) ||
          o.vehiclePlate.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q) ||
          o.vehicleMake.toLowerCase().contains(q) ||
          o.vehicleModel.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final authState = ref.watch(authNotifierProvider);
    final userName =
        authState is AuthAuthenticated ? authState.userProfile.fullName : 'User';

    final telemetryNotice = _pendingOrders.isEmpty
        ? 'ALL DELIVERIES COMPLETE'
        : '${_pendingOrders.length} READY FOR HANDOVER';

    return ResponsiveRoleScaffold(
      roleTitle: 'Vehicle Handover & Delivery',
      userName: userName,
      userSubtitle: 'Workshop Director',
      currentIndex: 10,
      navItems: RoleNavigation.adminNavItems,
      telemetryNotice: telemetryNotice,
      onNavIndexChanged: (index) {
        RoleNavigation.navigate(
          context,
          RoleNavigation.adminNavItems,
          index,
          currentIndex: 10,
        );
      },
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(textColor),
                const SizedBox(height: AppSpacing.space16),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_errorMessage != null)
                  _buildErrorBanner(_errorMessage!)
                else
                  _buildContent(isDark, textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.key,
                color: AppColors.accentRed,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle Handover & Delivery Verification',
                    style: AppTypography.headlineSmall(
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Verify physical checklist items, inspect payment balance, and execute delivery closure.',
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh Queue',
              onPressed: _loadHandoverData,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space8),
        // Metrics Summary Row
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                label: 'PENDING HANDOVER',
                value: '${_pendingOrders.length}',
                color: _pendingOrders.isNotEmpty
                    ? AppColors.warning
                    : AppColors.success,
                icon: Icons.pending_actions,
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: _buildMetricTile(
                label: 'HANDOVERS CLOSED',
                value: '${_historyOrders.length}',
                color: AppColors.info,
                icon: Icons.task_alt,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return PitCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      accentBorderLeft: color,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall(
                  color: AppColors.textSecondaryDark,
                ),
              ),
              Text(
                value,
                style: AppTypography.headlineSmall(
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return PitCard(
      color: AppColors.danger.withValues(alpha: 0.08),
      borderColor: AppColors.danger.withValues(alpha: 0.4),
      padding: AppSpacing.p16,
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall(color: AppColors.danger),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _loadHandoverData,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, Color textColor) {
    if (_selectedOrder != null) {
      return _buildHandoverForm(isDark, textColor);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildQueueControls(textColor),
        const SizedBox(height: AppSpacing.space8),
        _buildQueueList(isDark, textColor),
      ],
    );
  }

  Widget _buildQueueControls(Color textColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text(
                      'Ready for Handover (${_pendingOrders.length})',
                      style: AppTypography.labelSmall(),
                    ),
                    icon: const Icon(Icons.directions_car, size: 16),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text(
                      'Handover History (${_historyOrders.length})',
                      style: AppTypography.labelSmall(),
                    ),
                    icon: const Icon(Icons.history, size: 16),
                  ),
                ],
                selected: {_activeTab},
                onSelectionChanged: (set) {
                  setState(() {
                    _activeTab = set.first;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search order number, license plate, customer...',
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
      ],
    );
  }

  Widget _buildQueueList(bool isDark, Color textColor) {
    final list = _currentList;

    if (list.isEmpty) {
      return PitCard(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              Icon(
                _activeTab == 0
                    ? Icons.task_alt_outlined
                    : Icons.history_toggle_off,
                size: 48,
                color: AppColors.textSecondaryDark,
              ),
              const SizedBox(height: 12),
              Text(
                _activeTab == 0
                    ? 'No vehicles currently waiting for handover.'
                    : 'No completed handover records found.',
                style: AppTypography.bodyLarge(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _activeTab == 0
                    ? 'Service orders will appear here once quality control (QC) is passed.'
                    : 'Delivered orders will be archived in this history view.',
                style: AppTypography.bodySmall(
                  color: AppColors.textSecondaryDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.space8),
      itemBuilder: (context, index) {
        final order = list[index];
        return _buildOrderCard(order, isDark, textColor);
      },
    );
  }

  Widget _buildOrderCard(
      HandoverOrderCandidate order, bool isDark, Color textColor) {
    final isPending = !order.isHandedOver;
    final isPaid = order.isPaid;

    return PitCard(
      onTap: () => _selectOrder(order),
      accentBorderLeft: isPending
          ? (isPaid ? AppColors.success : AppColors.warning)
          : AppColors.info,
      padding: AppSpacing.p16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isPending
                          ? (isPaid ? AppColors.success : AppColors.warning)
                          : AppColors.info)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_car_outlined,
                  color: isPending
                      ? (isPaid ? AppColors.success : AppColors.warning)
                      : AppColors.info,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.orderNumber,
                          style: AppTypography.bodyLarge(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.plateBackground,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.vehiclePlate,
                            style: AppTypography.telemetrySmall(
                              color: AppColors.plateText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: order.status.toUpperCase(),
                          type: isPending
                              ? StatusBadgeType.inProgress
                              : StatusBadgeType.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.vehicleDescription,
                      style: AppTypography.bodyMedium(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Customer: ${order.customerName}${order.customerPhone != null ? ' • ${order.customerPhone}' : ''}',
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (order.hasInvoice) ...[
                    if (isPaid)
                      StatusBadge.success('PAID IN FULL')
                    else
                      StatusBadge.warning(
                        'UNPAID: ${CurrencyFormatter.formatIdr(order.outstandingBalanceCents)}',
                      ),
                  ] else ...[
                    const StatusBadge(
                      label: 'NO INVOICE',
                      type: StatusBadgeType.neutral,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Odo: ${order.odometer} km',
                    style: AppTypography.labelSmall(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Created: ${order.createdAt.toLocal().toString().substring(0, 16)}',
                style: AppTypography.labelSmall(
                  color: AppColors.textSecondaryDark,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _selectOrder(order),
                icon: Icon(
                  isPending ? Icons.key : Icons.visibility_outlined,
                  size: 16,
                ),
                label: Text(
                  isPending ? 'Process Handover' : 'View Handover',
                  style: AppTypography.labelSmall(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPending
                      ? AppColors.accentRed
                      : AppColors.surfaceElevatedDark,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHandoverForm(bool isDark, Color textColor) {
    final order = _selectedOrder!;
    final isAlreadyDelivered = order.isHandedOver;
    final isPaid = order.isPaid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _deselectOrder,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Queue'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Handover: ${order.orderNumber} • ${order.vehiclePlate}',
                style: AppTypography.bodyLarge(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isAlreadyDelivered)
              StatusBadge.success('DELIVERED & CLOSED')
            else
              StatusBadge.inProgress('READY FOR RELEASE'),
          ],
        ),
        const SizedBox(height: AppSpacing.space16),

        // 1. Vehicle & Customer Summary Card
        PitCard(
          padding: AppSpacing.p16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicle & Intake Information',
                style: AppTypography.labelLarge(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Plate', order.vehiclePlate, textColor),
                        _buildInfoRow('Vehicle',
                            '${order.vehicleMake} ${order.vehicleModel}', textColor),
                        if (order.vehicleYear != null)
                          _buildInfoRow(
                              'Year', '${order.vehicleYear}', textColor),
                        _buildInfoRow(
                            'Odometer', '${order.odometer} km', textColor),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                            'Customer', order.customerName, textColor),
                        _buildInfoRow('Phone',
                            order.customerPhone ?? 'N/A', textColor),
                        _buildInfoRow(
                            'Status', order.status.toUpperCase(), textColor),
                        if (order.customerComplaint != null)
                          _buildInfoRow('Complaint',
                              order.customerComplaint!, textColor),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space16),

        // 2. Financial & Payment Verification Card
        PitCard(
          accentBorderLeft: isPaid ? AppColors.success : AppColors.warning,
          padding: AppSpacing.p16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Financial & Payment Verification',
                      style: AppTypography.labelLarge(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (isPaid)
                    StatusBadge.success('PAYMENT SETTLED')
                  else
                    StatusBadge.warning('OUTSTANDING BALANCE'),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: AppSpacing.p12,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceElevatedLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFinanceCol(
                      'Total Invoiced',
                      CurrencyFormatter.formatIdr(order.totalAmountCents),
                      textColor,
                    ),
                    _buildFinanceCol(
                      'Amount Paid',
                      CurrencyFormatter.formatIdr(order.amountPaidCents),
                      AppColors.success,
                    ),
                    _buildFinanceCol(
                      'Outstanding Balance',
                      CurrencyFormatter.formatIdr(
                          order.outstandingBalanceCents),
                      isPaid ? AppColors.success : AppColors.danger,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (!isPaid) ...[
                Container(
                  padding: AppSpacing.p12,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Incomplete: Authorized Override Required',
                              style: AppTypography.labelMedium(
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'This vehicle has an unpaid balance of ${CurrencyFormatter.formatIdr(order.outstandingBalanceCents)}. '
                              'Handover cannot proceed without entering an authorized override reason (e.g., Fleet Net-30 agreement, invoice deferred by management).',
                              style: AppTypography.bodySmall(
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _overrideReasonController,
                  enabled: !isAlreadyDelivered,
                  decoration: InputDecoration(
                    labelText: 'Payment Override Reason *',
                    hintText:
                        'e.g. Approved corporate net-30 terms by Workshop Director',
                    prefixIcon: const Icon(Icons.shield_outlined, size: 18),
                    border: const OutlineInputBorder(),
                    errorText: (_isOverrideRequired &&
                            _overrideReasonController.text.trim().isEmpty)
                        ? 'Authorized justification required for unpaid vehicle release'
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                ),
              ] else ...[
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Invoice is fully settled. No payment override required.',
                      style: AppTypography.bodySmall(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space16),

        // 3. Pre-Delivery Handover Checklist Card
        PitCard(
          padding: AppSpacing.p16,
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
                        Text(
                          'Pre-Delivery Handover Checklist',
                          style: AppTypography.labelLarge(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'All 4 physical inspection criteria must be verified before release.',
                          style: AppTypography.bodySmall(
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isAlreadyDelivered)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _checklist = const HandoverChecklist(
                            vehicleCleaned: true,
                            personalItemsReturned: true,
                            oldPartsPresented: true,
                            keysReturned: true,
                          );
                        });
                      },
                      icon: const Icon(Icons.select_all, size: 16),
                      label: const Text('Verify All'),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              _buildChecklistTile(
                title: 'Vehicle Cleaned & Sanitized',
                subtitle:
                    'Exterior washed, interior vacuumed, workshop protective steering/seat covers removed.',
                value: _checklist.vehicleCleaned,
                enabled: !isAlreadyDelivered,
                icon: Icons.local_car_wash_outlined,
                onChanged: (v) {
                  setState(() {
                    _checklist =
                        _checklist.copyWith(vehicleCleaned: v ?? false);
                  });
                },
              ),

              _buildChecklistTile(
                title: 'Personal Belongings Returned',
                subtitle:
                    'Customer valuables, cabin items, and trunk contents verified intact and returned.',
                value: _checklist.personalItemsReturned,
                enabled: !isAlreadyDelivered,
                icon: Icons.luggage_outlined,
                onChanged: (v) {
                  setState(() {
                    _checklist = _checklist.copyWith(
                        personalItemsReturned: v ?? false);
                  });
                },
              ),

              _buildChecklistTile(
                title: 'Old / Replaced Parts Handled',
                subtitle:
                    'Worn components presented to customer or disposed according to customer preference.',
                value: _checklist.oldPartsPresented,
                enabled: !isAlreadyDelivered,
                icon: Icons.build_circle_outlined,
                onChanged: (v) {
                  setState(() {
                    _checklist =
                        _checklist.copyWith(oldPartsPresented: v ?? false);
                  });
                },
              ),

              _buildChecklistTile(
                title: 'Ignition Keys & Fob Returned',
                subtitle:
                    'Main ignition key, alarm remote fobs, and vehicle service logbook handed back.',
                value: _checklist.keysReturned,
                enabled: !isAlreadyDelivered,
                icon: Icons.key_outlined,
                onChanged: (v) {
                  setState(() {
                    _checklist = _checklist.copyWith(keysReturned: v ?? false);
                  });
                },
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  StatusBadge(
                    label: _checklist.isComplete
                        ? 'ALL 4 ITEMS VERIFIED'
                        : 'CHECKLIST INCOMPLETE',
                    type: _checklist.isComplete
                        ? StatusBadgeType.success
                        : StatusBadgeType.warning,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space16),

        // 4. Customer Confirmation & Handover Closure Card
        PitCard(
          padding: AppSpacing.p16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Delivery Confirmation',
                style: AppTypography.labelLarge(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),

              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  value: _customerConfirmed,
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.success,
                  title: Text(
                    'Customer Handover Acknowledged',
                    style: AppTypography.bodyMedium(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Customer physically inspected the vehicle, received keys, and agreed with completed operations.',
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  onChanged: isAlreadyDelivered
                      ? null
                      : (val) {
                          setState(() {
                            _customerConfirmed = val;
                          });
                        },
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _notesController,
                enabled: !isAlreadyDelivered,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Handover Notes / Feedback (Optional)',
                  hintText:
                      'Customer remarks, special advice on parts, or next service recommendation...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space24),

        if (!isAlreadyDelivered) ...[
          ElevatedButton.icon(
            onPressed:
                _isHandoverValid && !_isSubmitting ? _submitHandover : null,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.key, size: 20),
            label: Text(
              _isSubmitting
                  ? 'Recording Handover & Closing Order...'
                  : 'Complete Handover & Close Service Order',
              style: AppTypography.bodyLarge(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.graphiteSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          if (!_isHandoverValid) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                !_checklist.isComplete
                    ? 'All 4 pre-delivery checklist items must be checked.'
                    : (_isOverrideRequired &&
                            _overrideReasonController.text.trim().isEmpty)
                        ? 'Authorized override reason required due to unpaid balance.'
                        : '',
                style: AppTypography.labelSmall(
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ] else ...[
          PitCard(
            color: AppColors.success.withValues(alpha: 0.12),
            padding: AppSpacing.p16,
            child: Row(
              children: [
                const Icon(
                  Icons.verified,
                  color: AppColors.success,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Recorded & Order Closed',
                        style: AppTypography.bodyLarge(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        'This vehicle was formally handed over to the customer and the service order is archived as closed.',
                        style: AppTypography.bodySmall(
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChecklistTile({
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required IconData icon,
    required ValueChanged<bool?> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: CheckboxListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        secondary: Icon(
          icon,
          color: value ? AppColors.success : AppColors.textSecondaryDark,
          size: 24,
        ),
        title: Text(
          title,
          style: AppTypography.bodyMedium(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall(
            color: AppColors.textSecondaryDark,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 75,
            child: Text(
              '$label:',
              style: AppTypography.labelSmall(
                color: AppColors.textSecondaryDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall(
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCol(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall(
            color: AppColors.textSecondaryDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.headlineSmall(
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
