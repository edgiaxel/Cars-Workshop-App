import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:pitmate/features/workshop/data/models/workshop_bay_model.dart';
import 'package:pitmate/features/workshop/data/repositories/workshop_bay_repository.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin Workshop Overview Screen backed by live Supabase telemetry.
class AdminOverviewScreen extends ConsumerStatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  ConsumerState<AdminOverviewScreen> createState() =>
      _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends ConsumerState<AdminOverviewScreen> {
  final _bayRepo = WorkshopBayRepository();

  bool _isLoading = false;
  String? _errorMessage;
  List<WorkshopBayModel> _bays = [];
  int _activeOrdersCount = 0;
  int _inProgressCount = 0;
  int _awaitingAuthCount = 0;
  int _qcPendingCount = 0;
  int _pendingBookingsCount = 0;
  int _pendingPartRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOverviewData();
  }

  SupabaseClient? _tryGetClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadOverviewData() async {
    final client = _tryGetClient();
    if (client == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bays = await _bayRepo.fetchBays();
      final ordersRes = await client
          .from('service_orders')
          .select('id, status')
          .not('status', 'in', '("closed","cancelled")');
      final bookingsRes = await client
          .from('bookings')
          .select('id')
          .eq('status', 'pending');
      final partReqRes = await client
          .from('part_requests')
          .select('id')
          .eq('status', 'pending');

      final orders = (ordersRes as List).cast<Map<String, dynamic>>();
      final inProgress = orders
          .where((o) => o['status'] == 'in_progress' || o['status'] == 'estimate_approved')
          .length;
      final awaitingAuth =
          orders.where((o) => o['status'] == 'estimate_pending').length;
      final qcPending = orders.where((o) => o['status'] == 'qc_pending').length;

      if (mounted) {
        setState(() {
          _bays = bays;
          _activeOrdersCount = orders.length;
          _inProgressCount = inProgress;
          _awaitingAuthCount = awaitingAuth;
          _qcPendingCount = qcPending;
          _pendingBookingsCount = (bookingsRes as List).length;
          _pendingPartRequestsCount = (partReqRes as List).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _onNavChanged(int index) {
    RoleNavigation.navigate(
      context,
      RoleNavigation.adminNavItems,
      index,
      currentIndex: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.graphitePrimary;
    final auth = ref.watch(authNotifierProvider);
    final userName = auth is AuthAuthenticated ? auth.userProfile.fullName : 'User';

    final occupiedBays = _bays.where((b) => b.isOccupied).toList();
    final totalBays = _bays.length;
    final pct = totalBays > 0 ? ((occupiedBays.length / totalBays) * 100).round() : 0;
    final telemetryNotice = totalBays == 0
        ? '0 BAYS CONFIGURED'
        : '${occupiedBays.length}/$totalBays BAYS ACTIVE ($pct%)';

    return ResponsiveRoleScaffold(
      roleTitle: 'Workshop Dispatch',
      userName: userName,
      userSubtitle: 'Workshop Director',
      currentIndex: 0,
      onNavIndexChanged: _onNavChanged,
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
          onPressed: _loadOverviewData,
          tooltip: 'Refresh Overview',
        ),
        IconButton(
          icon: const Icon(Icons.people_alt_outlined, size: 20),
          onPressed: () => context.go(RoutePaths.adminCustomers),
          tooltip: 'Manage Customers',
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadOverviewData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    PitCard(
                      accentBorderLeft: AppColors.danger,
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodySmall(color: AppColors.danger),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadOverviewData,
                            child: const Text('RETRY'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  PitCard(
                    accentBorderLeft: AppColors.accentRed,
                    onTap: () => context.go(RoutePaths.adminWorkshopFloor),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.garage_outlined,
                          color: AppColors.accentRed,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WORKSHOP FLOOR & BAY DISPATCH CONSOLE',
                                style: AppTypography.labelLarge(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Monitor $totalBays physical bays, detect occupancy conflicts, and dispatch approved operations.',
                                style: AppTypography.bodySmall(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.accentRed,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  PitCard(
                    accentBorderLeft: AppColors.accentRed,
                    onTap: () => context.go(RoutePaths.adminCustomers),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.group_add_outlined,
                          color: AppColors.accentRed,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CUSTOMER REGISTRY & WALK-IN INTAKE',
                                style: AppTypography.labelLarge(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Register walk-in guest vehicles, manage client accounts, or review $_pendingBookingsCount pending bookings.',
                                style: AppTypography.bodySmall(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.accentRed,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  PitCard(
                    key: const Key('card_admin_nav_inventory'),
                    accentBorderLeft: AppColors.info,
                    onTap: () => context.go(RoutePaths.adminInventory),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.info,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INVENTORY & SPARE PARTS CATALOG',
                                style: AppTypography.labelLarge(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Manage stock levels, receive shipments, audit movements, and record adjustments.',
                                style: AppTypography.bodySmall(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.info),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 600;
                      final reqCard = PitCard(
                        key: const Key('card_admin_nav_requests'),
                        accentBorderLeft: AppColors.warning,
                        onTap: () => context.go(RoutePaths.adminPartRequests),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.handyman_outlined,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'FLOOR PART REQUESTS ($_pendingPartRequestsCount)',
                                style: AppTypography.labelMedium(color: textColor)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.warning,
                              size: 18,
                            ),
                          ],
                        ),
                      );

                      final compCard = PitCard(
                        key: const Key('card_admin_nav_compensation'),
                        accentBorderLeft: AppColors.success,
                        onTap: () => context.go(RoutePaths.adminCompensation),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'MECHANIC COMPENSATION',
                                style: AppTypography.labelMedium(color: textColor)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.success,
                              size: 18,
                            ),
                          ],
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            reqCard,
                            const SizedBox(height: 10),
                            compCard,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: reqCard),
                          const SizedBox(width: 12),
                          Expanded(child: compCard),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.accentRed),
                      ),
                    )
                  else ...[
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 600;
                        final kpi1 = PitCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ACTIVE ORDERS',
                                style: AppTypography.labelSmall(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_activeOrdersCount',
                                style: AppTypography.headlineLarge(
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        );

                        final kpi2 = PitCard(
                          padding: const EdgeInsets.all(12),
                          accentBorderLeft: AppColors.accentRed,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IN WORKSHOP',
                                style: AppTypography.labelSmall(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_inProgressCount',
                                style: AppTypography.headlineLarge(
                                  color: AppColors.accentRed,
                                ),
                              ),
                            ],
                          ),
                        );

                        final kpi3 = PitCard(
                          padding: const EdgeInsets.all(12),
                          accentBorderLeft: AppColors.warning,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AWAITING AUTH',
                                style: AppTypography.labelSmall(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_awaitingAuthCount',
                                style: AppTypography.headlineLarge(
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        );

                        final kpi4 = PitCard(
                          padding: const EdgeInsets.all(12),
                          accentBorderLeft: AppColors.success,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'QC READY',
                                style: AppTypography.labelSmall(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_qcPendingCount',
                                style: AppTypography.headlineLarge(
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        );

                        if (isNarrow) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: kpi1),
                                  const SizedBox(width: 10),
                                  Expanded(child: kpi2),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: kpi3),
                                  const SizedBox(width: 10),
                                  Expanded(child: kpi4),
                                ],
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: kpi1),
                            const SizedBox(width: 12),
                            Expanded(child: kpi2),
                            const SizedBox(width: 12),
                            Expanded(child: kpi3),
                            const SizedBox(width: 12),
                            Expanded(child: kpi4),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'ACTIVE SHOP BAYS',
                      style: AppTypography.headlineSmall(color: textColor),
                    ),
                    const SizedBox(height: 10),

                    if (occupiedBays.isEmpty)
                      PitCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.warehouse_outlined,
                              size: 40,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              totalBays == 0
                                  ? 'No workshop bays configured yet.'
                                  : 'All $totalBays workshop bays are currently available.',
                              style: AppTypography.bodyMedium(color: textColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  context.go(RoutePaths.adminWorkshopFloor),
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('OPEN WORKSHOP FLOOR'),
                            ),
                          ],
                        ),
                      )
                    else
                      ...occupiedBays.map(
                        (bay) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PitCard(
                            accentBorderLeft: AppColors.accentRed,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          bay.name.toUpperCase(),
                                          style: AppTypography.headlineSmall(
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        StatusBadge.inProgress(
                                          (bay.currentOrderStatus ?? 'OCCUPIED')
                                              .replaceAll('_', ' ')
                                              .toUpperCase(),
                                          icon: Icons.play_arrow,
                                        ),
                                      ],
                                    ),
                                    if (bay.customerName != null)
                                      Text(
                                        'Client: ${bay.customerName}',
                                        style: AppTypography.bodySmall(
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${bay.vehicleModel ?? 'Vehicle'} [${bay.vehiclePlate ?? '-'}]',
                                  style: AppTypography.labelLarge(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (bay.currentOrderNumber != null)
                                  Text(
                                    'Order: ${bay.currentOrderNumber}',
                                    style: AppTypography.bodySmall(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
