import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/service_order.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/mechanic_provider.dart';
import '../../../shared/providers/service_order_provider.dart';
import '../../../shared/providers/task_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';

/// Mechanic Workbench Dashboard view adhering to DESIGN.md and backed by live Supabase records.
class MechanicDashboardView extends ConsumerWidget {
  const MechanicDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionProvider);
    final profile = authState.profile;
    final mechanicAsync = ref.watch(currentMechanicProvider);
    final ordersAsync = ref.watch(mechanicServiceOrdersProvider(null));
    final tasksAsync = ref.watch(mechanicTasksProvider);

    final orders = ordersAsync.asData?.value ?? [];
    final tasks = tasksAsync.asData?.value ?? [];
    final mechanic = mechanicAsync.asData?.value;

    final activeOrder = orders.firstWhere(
      (o) =>
          o.status == ServiceStatus.inProgress ||
          o.status == ServiceStatus.inspection ||
          o.status == ServiceStatus.diagnosis,
      orElse: () => orders.isNotEmpty
          ? orders.first
          : const ServiceOrder(
              id: '',
              orderNumber: 'NONE',
              customerId: '',
              vehicleId: '',
              title: 'No Active Orders',
            ),
    );

    final openTasksCount = tasks.where((t) => t.status != 'completed').length;
    final completedOrdersCount = orders
        .where(
          (o) =>
              o.status == ServiceStatus.completed ||
              o.status == ServiceStatus.closed,
        )
        .length;

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
                      'TECHNICIAN WORKBENCH',
                      style: AppTypography.technical(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.fullName ??
                          mechanic?.profile?.fullName ??
                          'Max Verstappen',
                      style: AppTypography.pageTitle(),
                    ),
                    Text(
                      authState.email ?? 'verstappen@pitmate.co',
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (mechanic?.specialization != null)
                      Text(
                        mechanic!.specialization!,
                        style: AppTypography.technical(
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              StatusBadge(
                label: activeOrder.id.isNotEmpty
                    ? 'BAY 1 ACTIVE'
                    : 'BAY 1 STANDBY',
                color: activeOrder.id.isNotEmpty
                    ? AppColors.statusInProgress
                    : AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.section),

          // Mechanic Workload Metrics
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 4 : 2,
                  crossAxisSpacing: AppSpacing.standard,
                  mainAxisSpacing: AppSpacing.standard,
                  mainAxisExtent: 150,
                ),
                children: [
                  const StatCard(
                    title: 'Active Bay',
                    value: 'Bay 1',
                    technicalCode: 'BAY-ASSIGN',
                    badgeText: 'ONLINE',
                    badgeColor: AppColors.statusCompleted,
                    icon: Icons.garage_outlined,
                  ),
                  StatCard(
                    title: 'Current Job',
                    value: activeOrder.id.isNotEmpty
                        ? activeOrder.orderNumber
                        : 'Standby',
                    technicalCode: 'JOB-ACTIVE',
                    badgeText: activeOrder.id.isNotEmpty
                        ? activeOrder.status.label.toUpperCase()
                        : 'IDLE',
                    badgeColor: activeOrder.id.isNotEmpty
                        ? AppColors.statusInProgress
                        : AppColors.textMuted,
                    icon: Icons.car_repair_outlined,
                  ),
                  StatCard(
                    title: 'Open Tasks',
                    value: '$openTasksCount Tasks',
                    technicalCode: 'TSK-PEND',
                    badgeText: 'CHECKLIST',
                    badgeColor: AppColors.info,
                    icon: Icons.checklist_outlined,
                  ),
                  StatCard(
                    title: 'Completed (All)',
                    value: '$completedOrdersCount Orders',
                    technicalCode: 'JOB-DONE',
                    badgeText: 'VERIFIED',
                    badgeColor: AppColors.statusCompleted,
                    icon: Icons.done_all,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.section),

          // Assigned Work Spotlight (Vehicle on hoist)
          SectionHeader(
            title: 'CURRENT HOIST ASSIGNMENT',
            subtitle: 'Vehicle actively in service bay',
            action: TextButton.icon(
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View All Jobs'),
              onPressed: () => context.go(RoutePaths.mechanicServices),
            ),
          ),
          const SizedBox(height: AppSpacing.compact),

          if (activeOrder.id.isEmpty)
            const EmptyState(
              title: 'No Vehicle on Hoist',
              message:
                  'No service orders are currently in progress in this bay.',
              icon: Icons.garage_outlined,
            )
          else
            PitCard(
              technicalLabel:
                  'ACTIVE HOIST • BAY 1 • ${activeOrder.orderNumber}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.speed,
                        color: AppColors.primaryAccent,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.compact),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeOrder.vehicle?.displayName ??
                                  'Assigned Vehicle',
                              style: AppTypography.sectionTitle(
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (activeOrder.vehicle?.licensePlate != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                activeOrder.vehicle!.licensePlate!,
                                style: AppTypography.technical(
                                  color: AppColors.primaryAccent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.compact),
                      StatusBadge.forServiceStatus(activeOrder.status.value),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.compact),
                  Text(
                    'Client: ${activeOrder.customer?.displayName ?? 'Workshop Client'} • Service: ${activeOrder.title}',
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (activeOrder.description != null &&
                      activeOrder.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      activeOrder.description!,
                      style: AppTypography.bodySmall(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.standard),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: AppSpacing.compact),
                  Wrap(
                    spacing: AppSpacing.section,
                    runSpacing: AppSpacing.compact,
                    children: [
                      _buildMeta(
                        'Priority',
                        'HIGH (BAY 1)',
                        AppColors.statusInProgress,
                      ),
                      _buildMeta(
                        'Scheduled',
                        activeOrder.scheduledStart != null
                            ? activeOrder.scheduledStart!
                                  .toIso8601String()
                                  .split('T')
                                  .first
                            : 'Today',
                        AppColors.textPrimary,
                      ),
                      _buildMeta(
                        'Diagnostics',
                        '$openTasksCount Checklist Items',
                        AppColors.info,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.section),

          // Quick Links
          SectionHeader(
            title: 'WORKBENCH CONTROLS',
            subtitle: 'Direct navigation to technician modules',
          ),
          const SizedBox(height: AppSpacing.compact),
          Wrap(
            spacing: AppSpacing.standard,
            runSpacing: AppSpacing.standard,
            children: [
              _buildQuickCard(
                context,
                title: 'Assigned Services',
                subtitle: 'Active & queued vehicles',
                icon: Icons.car_repair_outlined,
                route: RoutePaths.mechanicServices,
              ),
              _buildQuickCard(
                context,
                title: 'Checklist & Tasks',
                subtitle: 'Diagnostic item checklists',
                icon: Icons.checklist_outlined,
                route: RoutePaths.mechanicTasks,
              ),
              _buildQuickCard(
                context,
                title: 'Earnings Telemetry',
                subtitle: 'Base rates & commission splits',
                icon: Icons.payments_outlined,
                route: RoutePaths.mechanicEarnings,
              ),
              _buildQuickCard(
                context,
                title: 'Service History',
                subtitle: 'Completed vehicle logs',
                icon: Icons.history_outlined,
                route: RoutePaths.mechanicHistory,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeta(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.technical(color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.label(color: color)),
      ],
    );
  }

  Widget _buildQuickCard(
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
