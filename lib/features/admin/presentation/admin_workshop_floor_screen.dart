import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/admin/presentation/widgets/dispatch_operations_modal.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:pitmate/features/service_orders/data/models/service_order_model.dart';
import 'package:pitmate/features/service_orders/data/repositories/service_order_repository.dart';
import 'package:pitmate/features/workshop/data/models/workshop_bay_model.dart';
import 'package:pitmate/features/workshop/data/repositories/workshop_bay_repository.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminWorkshopFloorScreen extends ConsumerStatefulWidget {
  const AdminWorkshopFloorScreen({super.key});

  @override
  ConsumerState<AdminWorkshopFloorScreen> createState() =>
      _AdminWorkshopFloorScreenState();
}

class _AdminWorkshopFloorScreenState
    extends ConsumerState<AdminWorkshopFloorScreen> {
  final _bayRepo = WorkshopBayRepository();
  final _orderRepo = ServiceOrderRepository();

  List<WorkshopBayModel> _bays = [];
  List<ServiceOrderModel> _allActiveOrders = [];
  List<ServiceOrderModel> _unassignedOrders = [];
  bool _isLoading = true;
  bool _isInitializingBays = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFloorData();
  }

  SupabaseClient? _tryGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadFloorData() async {
    final client = _tryGetClient();
    if (client == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bays = await _bayRepo.fetchBays();
      final allOrders = await _orderRepo.fetchActiveOrders();

      final occupiedOrderIds = bays
          .map((b) => b.currentServiceOrderId)
          .whereType<String>()
          .toSet();

      final unassigned = allOrders.where((order) {
        return !occupiedOrderIds.contains(order.id) &&
            (order.status == 'estimate_approved' ||
                order.status == 'in_progress' ||
                order.status == 'inspection_pending');
      }).toList();

      if (!mounted) return;
      setState(() {
        _bays = bays;
        _allActiveOrders = allOrders;
        _unassignedOrders = unassigned;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeDefaultBays() async {
    setState(() => _isInitializingBays = true);
    try {
      final bays = await _bayRepo.initializeDefaultBays();
      if (!mounted) return;
      setState(() {
        _bays = bays;
        _isInitializingBays = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Initialized ${bays.length} workshop bays.'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadFloorData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInitializingBays = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize bays: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _openDispatchModal(ServiceOrderModel order) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DispatchOperationsModal(
        serviceOrder: order,
        onDispatched: _loadFloorData,
      ),
    );
  }

  Future<void> _openDispatchModalForBay(WorkshopBayModel bay) async {
    final orderId = bay.currentServiceOrderId;
    if (orderId == null) return;

    ServiceOrderModel? matched;
    for (final order in _allActiveOrders) {
      if (order.id == orderId) {
        matched = order;
        break;
      }
    }
    matched ??= await _orderRepo.fetchOrderById(orderId);
    if (!mounted) return;
    if (matched == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not locate service order details for dispatch.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    await _openDispatchModal(matched);
  }

  Future<void> _showAssignBayModal(ServiceOrderModel order) async {
    if (_bays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No bays initialized yet. Click "INITIALIZE 5 WORKSHOP BAYS" first.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final firstAvailable = _bays.firstWhere(
      (b) => !b.isOccupied || b.currentServiceOrderId == order.id,
      orElse: () => _bays.first,
    );
    int selectedBayNum = firstAvailable.bayNumber;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ASSIGN VEHICLE TO BAY',
                        style: AppTypography.headlineMedium(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.graphitePrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Order: ${order.orderNumber} • ${order.vehicleDescription}',
                    style: AppTypography.bodySmall(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SELECT SERVICE BAY (1 - ${_bays.length})',
                    style: AppTypography.labelSmall(
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<int>(
                    groupValue: selectedBayNum,
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedBayNum = val);
                      }
                    },
                    child: Column(
                      children: _bays.map((existingBay) {
                        final isOccupied = existingBay.isOccupied &&
                            existingBay.currentServiceOrderId != order.id;

                        return RadioListTile<int>(
                          value: existingBay.bayNumber,
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  existingBay.name,
                                  style: AppTypography.labelMedium(
                                    color: isOccupied
                                        ? AppColors.danger
                                        : (isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.graphitePrimary),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isOccupied)
                                StatusBadge.danger('OCCUPIED')
                              else
                                StatusBadge.success('AVAILABLE'),
                            ],
                          ),
                          subtitle:
                              isOccupied && existingBay.vehiclePlate != null
                                  ? Text(
                                      'Current: ${existingBay.vehiclePlate} (${existingBay.currentOrderNumber ?? ''})',
                                      style: const TextStyle(fontSize: 12),
                                    )
                                  : null,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: const Key('btn_confirm_bay_assign'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedSmall,
                      ),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      try {
                        await _bayRepo.assignBay(
                          serviceOrderId: order.id,
                          bayNumber: selectedBayNum,
                        );
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Successfully assigned ${order.orderNumber} to Bay 0$selectedBayNum',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _loadFloorData();
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceAll('Exception: ', ''),
                              ),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'CONFIRM BAY ASSIGNMENT',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final auth = ref.watch(authNotifierProvider);
    final userName =
        auth is AuthAuthenticated ? auth.userProfile.fullName : 'User';

    final totalBays = _bays.length;
    final occupiedCount = _bays.where((b) => b.isOccupied).length;
    final pct = totalBays > 0 ? ((occupiedCount / totalBays) * 100).round() : 0;
    final telemetryNotice = totalBays > 0
        ? '$occupiedCount/$totalBays BAYS ACTIVE ($pct%)'
        : 'NO BAYS CONFIGURED';

    return ResponsiveRoleScaffold(
      roleTitle: 'Workshop Dispatch',
      userName: userName,
      userSubtitle: 'Workshop Director',
      currentIndex: 2,
      onNavIndexChanged: (i) => RoleNavigation.navigate(
        context,
        RoleNavigation.adminNavItems,
        i,
        currentIndex: 2,
      ),
      navItems: RoleNavigation.adminNavItems,
      telemetryNotice: telemetryNotice,
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      actions: [
        const NotificationBellButton(),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: _loadFloorData,
          tooltip: 'Refresh Floor Telemetry',
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
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadFloorData,
                        child: const Text('RETRY'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFloorData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 18.0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1040),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFloorHeader(
                              isDark,
                              textColor,
                              occupiedCount,
                              totalBays,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'PHYSICAL WORKSHOP BAYS',
                              style: AppTypography.labelLarge(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildBaysGrid(isDark, textColor),
                            const SizedBox(height: 24),
                            Text(
                              'UNASSIGNED / AWAITING BAY DISPATCH (${_unassignedOrders.length})',
                              style: AppTypography.labelLarge(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildUnassignedQueue(isDark, textColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildFloorHeader(
    bool isDark,
    Color textColor,
    int occupiedCount,
    int totalBays,
  ) {
    return PitCard(
      accentBorderLeft: AppColors.accentRed,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final iconWidget = Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentRed.withValues(alpha: 0.1),
              borderRadius: AppSpacing.roundedSmall,
            ),
            child: const Icon(
              Icons.precision_manufacturing,
              color: AppColors.accentRed,
              size: 28,
            ),
          );

          final badgeWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: occupiedCount > 0 ? AppColors.warning : AppColors.success,
              borderRadius: AppSpacing.roundedSmall,
            ),
            child: Text(
              totalBays > 0
                  ? '$occupiedCount / $totalBays OCCUPIED'
                  : '0 BAYS INITIALIZED',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    iconWidget,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WORKSHOP OPERATIONS CONSOLE',
                            style: AppTypography.headlineSmall(
                              color: textColor,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'LIVE DISPATCH',
                                style: AppTypography.telemetrySmall(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    badgeWidget,
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Physical bay allocation, conflict detection, and live workload dispatch.',
                  style: AppTypography.bodySmall(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              iconWidget,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'PITMATE BAY OPERATIONS CONSOLE',
                            style: AppTypography.headlineMedium(color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: AppTypography.telemetrySmall(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Physical bay allocation, conflict detection, and live workload dispatch.',
                      style: AppTypography.bodySmall(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              badgeWidget,
            ],
          );
        },
      ),
    );
  }

  Widget _buildBaysGrid(bool isDark, Color textColor) {
    if (_bays.isEmpty) {
      return PitCard(
        accentBorderLeft: AppColors.warning,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warehouse_outlined,
                    color: AppColors.warning,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No workshop bays configured yet.',
                          style: AppTypography.headlineSmall(color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Initialize the 5 standard PitMate service bays to enable bay check-ins and technician job dispatch.',
                          style: AppTypography.bodySmall(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                key: const Key('btn_initialize_bays'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentRed,
                  foregroundColor: Colors.white,
                ),
                icon: _isInitializingBays
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_business_outlined, size: 18),
                label: Text(
                  _isInitializingBays
                      ? 'INITIALIZING BAYS...'
                      : 'INITIALIZE 5 WORKSHOP BAYS',
                ),
                onPressed: _isInitializingBays ? null : _initializeDefaultBays,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 3 : 1;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _bays.map((bay) {
            final cardWidth = constraints.maxWidth > 700
                ? (constraints.maxWidth - (crossAxisCount - 1) * 12) /
                    crossAxisCount
                : constraints.maxWidth;
            final canDispatch =
                bay.isOccupied &&
                bay.currentOrderStatus == 'estimate_approved' &&
                bay.currentServiceOrderId != null;

            return SizedBox(
              width: cardWidth,
              child: PitCard(
                accentBorderLeft:
                    bay.isOccupied ? AppColors.accentRed : AppColors.success,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            bay.name.toUpperCase(),
                            style: AppTypography.labelLarge(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (bay.isOccupied)
                          StatusBadge.danger('OCCUPIED')
                        else
                          StatusBadge.success('AVAILABLE'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (bay.isOccupied) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_car,
                            size: 16,
                            color: AppColors.accentRed,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              bay.vehiclePlate ?? 'Vehicle Assigned',
                              style: AppTypography.headlineSmall(
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bay.vehicleModel ?? 'Vehicle Assigned',
                        style: AppTypography.bodySmall(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order: ${bay.currentOrderNumber ?? ''} (${bay.currentOrderStatus ?? 'active'})',
                        style: AppTypography.telemetrySmall(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      if (canDispatch) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            key: Key('btn_dispatch_bay_${bay.bayNumber}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppSpacing.roundedSmall,
                              ),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: const Text('DISPATCH OPERATIONS'),
                            onPressed: () => _openDispatchModalForBay(bay),
                          ),
                        ),
                      ],
                    ] else ...[
                      Container(
                        height: 54,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ready to receive next vehicle operation.',
                          style: AppTypography.bodySmall(
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildUnassignedQueue(bool isDark, Color textColor) {
    if (_unassignedOrders.isEmpty) {
      return PitCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              'No vehicles currently waiting for bay assignment.',
              style: AppTypography.bodyMedium(
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _unassignedOrders.map((order) {
        final canDispatch = order.status == 'estimate_approved';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PitCard(
            child: LayoutBuilder(
              builder: (context, c) {
                final isCompact = c.maxWidth < 540;
                final iconBox = Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceElevatedDark
                        : AppColors.surfaceElevatedLight,
                    borderRadius: AppSpacing.roundedSmall,
                  ),
                  child: const Icon(Icons.car_repair, size: 24),
                );

                final detailsCol = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.orderNumber} • ${order.vehicleDescription}',
                      style: AppTypography.labelLarge(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Customer: ${order.customerName ?? 'Walk-in'} • Status: ${order.status}',
                      style: AppTypography.bodySmall(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );

                final actionButtons = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: Key('btn_assign_bay_${order.id}'),
                      icon: const Icon(Icons.login, size: 16),
                      label: const Text('ASSIGN BAY'),
                      onPressed: () => _showAssignBayModal(order),
                    ),
                    if (canDispatch)
                      ElevatedButton.icon(
                        key: Key('btn_dispatch_ops_${order.id}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSpacing.roundedSmall,
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('DISPATCH OPERATIONS'),
                        onPressed: () => _openDispatchModal(order),
                      ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          iconBox,
                          const SizedBox(width: 12),
                          Expanded(child: detailsCol),
                        ],
                      ),
                      const SizedBox(height: 10),
                      actionButtons,
                    ],
                  );
                }

                return Row(
                  children: [
                    iconBox,
                    const SizedBox(width: 12),
                    Expanded(child: detailsCol),
                    const SizedBox(width: 12),
                    actionButtons,
                  ],
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}
