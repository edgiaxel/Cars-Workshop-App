import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/service_orders/data/models/service_order_model.dart';
import 'package:pitmate/features/service_orders/data/repositories/service_order_repository.dart';
import 'package:pitmate/features/workshop/data/models/workshop_bay_model.dart';
import 'package:pitmate/features/workshop/data/repositories/workshop_bay_repository.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

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
  List<ServiceOrderModel> _unassignedOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFloorData();
  }

  Future<void> _loadFloorData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bays = await _bayRepo.fetchBays();
      final allOrders = await _orderRepo.fetchActiveOrders();

      // Filter unassigned orders (orders not assigned to any bay or waiting)
      final occupiedOrderIds =
          bays.map((b) => b.currentServiceOrderId).whereType<String>().toSet();

      final unassigned = allOrders.where((order) {
        return !occupiedOrderIds.contains(order.id) &&
            (order.status == 'estimate_approved' ||
                order.status == 'in_progress' ||
                order.status == 'inspection_pending');
      }).toList();

      setState(() {
        _bays = bays;
        _unassignedOrders = unassigned;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAssignBayModal(ServiceOrderModel order) async {
    int selectedBayNum = 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
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
                    'SELECT SERVICE BAY (1 - 5)',
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
                      children: List.generate(5, (index) {
                        final bayNum = index + 1;
                        final existingBay = _bays.firstWhere(
                          (b) => b.bayNumber == bayNum,
                          orElse: () => WorkshopBayModel(
                            id: '',
                            bayNumber: bayNum,
                            name: 'Bay 0$bayNum',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        );
                        final isOccupied = existingBay.isOccupied &&
                            existingBay.currentServiceOrderId != order.id;

                        return RadioListTile<int>(
                          value: bayNum,
                          title: Row(
                            children: [
                              Text(
                                existingBay.name,
                                style: AppTypography.labelMedium(
                                  color: isOccupied
                                      ? AppColors.danger
                                      : (isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.graphitePrimary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isOccupied)
                                StatusBadge.danger('OCCUPIED')
                              else
                                StatusBadge.success('AVAILABLE'),
                            ],
                          ),
                          subtitle: isOccupied && existingBay.vehiclePlate != null
                              ? Text(
                                  'Current: ${existingBay.vehiclePlate} (${existingBay.currentOrderNumber ?? ''})',
                                  style: const TextStyle(fontSize: 12),
                                )
                              : null,
                        );
                      }),
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
                                  'Successfully assigned ${order.orderNumber} to Bay 0$selectedBayNum'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _loadFloorData();
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
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

    final occupiedCount = _bays.where((b) => b.isOccupied).length;
    final telemetryNotice = '$occupiedCount/5 BAYS ACTIVE (${occupiedCount * 20}%)';

    return ResponsiveRoleScaffold(
      roleTitle: 'Workshop Dispatch',
      userName: 'Toto Wolf',
      userSubtitle: 'Workshop Director',
      currentIndex: 3,
      onNavIndexChanged: (i) {
        if (i == 0) context.go(RoutePaths.admin);
        if (i == 1) context.go(RoutePaths.adminCustomers);
        if (i == 2) context.push(RoutePaths.adminInspectionReview);
      },
      navItems: const [
        RoleNavItem(
            label: 'Overview',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard),
        RoleNavItem(
            label: 'Customers & Fleet',
            icon: Icons.people_outline,
            selectedIcon: Icons.people),
        RoleNavItem(
            label: 'Inspection Review',
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment),
        RoleNavItem(
            label: 'Workshop Floor',
            icon: Icons.garage_outlined,
            selectedIcon: Icons.garage),
      ],
      telemetryNotice: telemetryNotice,
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      actions: [
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
                      const Icon(Icons.error_outline,
                          color: AppColors.danger, size: 40),
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
                        horizontal: 16.0, vertical: 18.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1040),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Live Telemetry Header Banner
                            _buildFloorHeader(isDark, textColor, occupiedCount),
                            const SizedBox(height: 16),

                            // 2. Physical 5-Bay Grid
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

                            // 3. Waiting & Unassigned Vehicles
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

  Widget _buildFloorHeader(bool isDark, Color textColor, int occupiedCount) {
    return PitCard(
      accentBorderLeft: AppColors.accentRed,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentRed.withValues(alpha: 0.1),
              borderRadius: AppSpacing.roundedSmall,
            ),
            child: const Icon(Icons.precision_manufacturing,
                color: AppColors.accentRed, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'PITMATE 5-BAY OPERATIONS CONSOLE',
                      style: AppTypography.headlineMedium(color: textColor),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: occupiedCount > 0 ? AppColors.warning : AppColors.success,
              borderRadius: AppSpacing.roundedSmall,
            ),
            child: Text(
              '$occupiedCount / 5 OCCUPIED',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaysGrid(bool isDark, Color textColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 3 : 1;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _bays.map((bay) {
            final cardWidth = constraints.maxWidth > 700
                ? (constraints.maxWidth - (crossAxisCount - 1) * 12) / crossAxisCount
                : constraints.maxWidth;

            return SizedBox(
              width: cardWidth,
              child: PitCard(
                accentBorderLeft: bay.isOccupied
                    ? AppColors.accentRed
                    : AppColors.success,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bay.name.toUpperCase(),
                          style: AppTypography.labelLarge(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                          const Icon(Icons.directions_car,
                              size: 16, color: AppColors.accentRed),
                          const SizedBox(width: 6),
                          Text(
                            bay.vehiclePlate ?? 'Vehicle Assigned',
                            style: AppTypography.headlineSmall(
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bay.vehicleModel ?? 'Standard Spec',
                        style: AppTypography.bodySmall(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order: ${bay.currentOrderNumber ?? ''}',
                        style: AppTypography.telemetrySmall(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PitCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceElevatedDark
                        : AppColors.surfaceElevatedLight,
                    borderRadius: AppSpacing.roundedSmall,
                  ),
                  child: const Icon(Icons.car_repair, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.orderNumber} • ${order.vehicleDescription}',
                        style: AppTypography.labelLarge(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Customer: ${order.customerName ?? 'Walk-in'} • Status: ${order.status}',
                        style: AppTypography.bodySmall(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  key: Key('btn_assign_bay_${order.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.roundedSmall,
                    ),
                  ),
                  icon: const Icon(Icons.login, size: 16),
                  label: const Text('ASSIGN BAY'),
                  onPressed: () => _showAssignBayModal(order),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
