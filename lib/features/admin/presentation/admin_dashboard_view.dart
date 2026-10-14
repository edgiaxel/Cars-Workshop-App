import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/service_order.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/booking_provider.dart';
import '../../../shared/providers/mechanic_provider.dart';
import '../../../shared/providers/service_order_provider.dart';
import '../../../shared/providers/spare_part_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';

/// Admin Control Center Dashboard view adhering to DESIGN.md and backed by live Supabase records.
class AdminDashboardView extends ConsumerWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionProvider);
    final profile = authState.profile;

    final ordersAsync = ref.watch(serviceOrdersProvider);
    final bookingsAsync = ref.watch(bookingsProvider);
    final inventoryAsync = ref.watch(sparePartsProvider);
    final mechanicsAsync = ref.watch(mechanicsProvider);

    final orders = ordersAsync.asData?.value ?? [];
    final bookings = bookingsAsync.asData?.value ?? [];
    final inventory = inventoryAsync.asData?.value ?? [];
    final mechanics = mechanicsAsync.asData?.value ?? [];

    final activeOrdersCount = orders
        .where(
          (o) =>
              o.status == ServiceStatus.inProgress ||
              o.status == ServiceStatus.inspection ||
              o.status == ServiceStatus.diagnosis,
        )
        .length;

    final pendingBookingsCount = bookings
        .where((b) => b.status == BookingStatus.requested)
        .length;

    final lowStockCount = inventory.where((p) => p.isLowStock).length;

    final activeMechanicsCount = mechanics.length;

    final recentOrders = orders.take(5).toList();

    return SingleChildScrollView(
      padding: AppSpacing.paddingSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Welcome Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WORKSHOP CONTROL CENTER',
                      style: AppTypography.technical(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.fullName ?? 'Christian Horner',
                      style: AppTypography.pageTitle(),
                    ),
                    Text(
                      authState.email ?? 'admin@pitmate.co',
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusBadge(
                label: 'CONTROL ACTIVE',
                color: AppColors.primaryAccent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.section),

          // Workshop Telemetry Stat Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final crossAxisCount = isWide ? 4 : 2;

              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppSpacing.standard,
                  mainAxisSpacing: AppSpacing.standard,
                  mainAxisExtent: 150,
                ),
                children: [
                  StatCard(
                    title: 'Active Bays',
                    value: '$activeMechanicsCount / 6',
                    technicalCode: 'BAY-LOAD',
                    badgeText:
                        '${((activeMechanicsCount / 6) * 100).toInt()}% CAPACITY',
                    badgeColor: AppColors.info,
                    icon: Icons.garage_outlined,
                  ),
                  StatCard(
                    title: 'Vehicles in Pit',
                    value: '${orders.length}',
                    technicalCode: 'FLEET-ACT',
                    badgeText: '$activeOrdersCount IN PROGRESS',
                    badgeColor: AppColors.warning,
                    icon: Icons.directions_car_outlined,
                  ),
                  StatCard(
                    title: 'Pending Bookings',
                    value: '$pendingBookingsCount',
                    technicalCode: 'BKG-QUEUE',
                    badgeText: pendingBookingsCount > 0
                        ? 'NEED APPROVAL'
                        : 'ALL CLEARED',
                    badgeColor: pendingBookingsCount > 0
                        ? AppColors.primaryAccent
                        : AppColors.statusCompleted,
                    icon: Icons.calendar_month_outlined,
                  ),
                  StatCard(
                    title: 'Inventory Alerts',
                    value: '$lowStockCount',
                    technicalCode: 'STK-ALERT',
                    badgeText: lowStockCount > 0 ? 'LOW STOCK' : 'OPTIMAL',
                    badgeColor: lowStockCount > 0
                        ? AppColors.error
                        : AppColors.statusCompleted,
                    icon: Icons.inventory_2_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.section),

          // Quick Navigation Shortcuts
          SectionHeader(
            title: 'OPERATIONAL COMMANDS',
            subtitle: 'Immediate access to primary workshop workstations',
          ),
          const SizedBox(height: AppSpacing.compact),
          Wrap(
            spacing: AppSpacing.standard,
            runSpacing: AppSpacing.standard,
            children: [
              _buildQuickAction(
                context,
                title: 'Customer Roster',
                subtitle: 'Manage client accounts',
                icon: Icons.people_outline,
                route: RoutePaths.adminCustomers,
              ),
              _buildQuickAction(
                context,
                title: 'Technician Bays',
                subtitle: 'Mechanic allocations',
                icon: Icons.engineering_outlined,
                route: RoutePaths.adminMechanics,
              ),
              _buildQuickAction(
                context,
                title: 'Service Orders',
                subtitle: 'Active job tickets',
                icon: Icons.build_outlined,
                route: RoutePaths.adminServices,
              ),
              _buildQuickAction(
                context,
                title: 'Parts Catalog',
                subtitle: 'Inventory & stock levels',
                icon: Icons.inventory_2_outlined,
                route: RoutePaths.adminInventory,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.section),

          // Recent Activity / Service Orders Feed
          SectionHeader(
            title: 'LIVE WORKSHOP FEED',
            subtitle: 'Recent service-order telemetry and status transitions',
            action: TextButton.icon(
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View All Services'),
              onPressed: () => context.go(RoutePaths.adminServices),
            ),
          ),
          const SizedBox(height: AppSpacing.compact),

          if (recentOrders.isEmpty)
            const EmptyState(
              title: 'No Recent Service Activity',
              message: 'No service orders recorded in workshop telemetry yet.',
              icon: Icons.build_outlined,
            )
          else
            PitCard(
              technicalLabel: 'TELEMETRY • LIVE ORDERS FEED',
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentOrders.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: AppColors.borderSubtle, height: 16),
                itemBuilder: (context, index) {
                  final order = recentOrders[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.compact),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(
                            AppRadius.control,
                          ),
                        ),
                        child: const Icon(
                          Icons.speed,
                          color: AppColors.primaryAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.standard),
                      Expanded(
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
                                        '${order.orderNumber} • ${order.vehicle?.displayName ?? 'Vehicle'}',
                                        style: AppTypography.label(
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (order.vehicle?.licensePlate !=
                                          null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          order.vehicle!.licensePlate!,
                                          style: AppTypography.technical(
                                            color: AppColors.primaryAccent,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.compact),
                                StatusBadge.forServiceStatus(
                                  order.status.value,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Technician: ${order.mechanicDisplayName} • Client: ${order.customer?.displayName ?? 'Workshop Client'}',
                              style: AppTypography.bodySmall(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.section),

          // Workshop Telemetry Footnote
          Center(
            child: Text(
              'PitMate Control Center • Connected live to Supabase PostgreSQL database',
              style: AppTypography.technical(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
  }) {
    return SizedBox(
      width: 220,
      child: PitCard(
        onTap: () => context.go(route),
        padding: const EdgeInsets.all(AppSpacing.standard),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.compact),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Icon(icon, color: AppColors.primaryAccent, size: 20),
            ),
            const SizedBox(width: AppSpacing.standard),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.label(color: AppColors.textPrimary),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
