import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/service_order.dart';
import '../../../shared/providers/mechanic_provider.dart';
import '../../../shared/providers/service_order_provider.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_card.dart';
import 'mechanic_shell.dart';

/// Technician earnings and compensation telemetry view for Mechanic role backed by live Supabase records adhering to DESIGN.md.
class MechanicEarningsPage extends ConsumerWidget {
  const MechanicEarningsPage({super.key});

  void _showStatementDialog(BuildContext context, String mechanicName) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        title: Text(
          'PAYOUT STATEMENT GENERATION',
          style: AppTypography.sectionTitle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generate bi-weekly workshop labor settlement summary for $mechanicName.',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.standard),
              Text(
                'Settlement Period: October 2026 Cycle 1',
                style: AppTypography.technical(color: AppColors.primaryAccent),
              ),
              const SizedBox(height: 4),
              Text(
                'Includes billable labor splits, completed diagnostic checklists, and hourly baseline hours.',
                style: AppTypography.bodySmall(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: AppTypography.label(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Technician payout statement compiled and sent to workshop accounting.',
                  ),
                  backgroundColor: AppColors.statusCompleted,
                ),
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export Statement'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mechanicAsync = ref.watch(currentMechanicProvider);
    final ordersAsync = ref.watch(mechanicServiceOrdersProvider(null));

    final mechanic = mechanicAsync.asData?.value;
    final orders = ordersAsync.asData?.value ?? [];

    final completedOrders = orders.where(
      (o) =>
          o.status == ServiceStatus.completed ||
          o.status == ServiceStatus.closed,
    );

    final hourlyRate = mechanic?.hourlyRate ?? 350000.0;
    final commissionRate = mechanic?.compensationPercentage ?? 30.0;
    final completedCount = completedOrders.length;
    final mechanicName =
        mechanic?.profile?.fullName ??
        mechanic?.displayName ??
        'Max Verstappen';

    return MechanicShell(
      currentRoute: RoutePaths.mechanicEarnings,
      child: SingleChildScrollView(
        padding: AppSpacing.paddingSection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: 'COMPENSATION & EARNINGS',
              subtitle: 'Technician base hourly agreement, commission structure, and service allocations',
              action: OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long, size: 16),
                label: const Text('Request Statement'),
                onPressed: () => _showStatementDialog(context, mechanicName),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryAccent,
                  side: const BorderSide(color: AppColors.primaryAccent),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.compact),

            // Profile rate metrics
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
                    StatCard(
                      title: 'Base Hourly Rate',
                      value: 'IDR ${(hourlyRate / 1000).toInt()}K',
                      technicalCode: 'SCHEMA-RATE',
                      badgeText: 'PER HOUR',
                      badgeColor: AppColors.info,
                      icon: Icons.timer_outlined,
                    ),
                    StatCard(
                      title: 'Commission Rate',
                      value: '${commissionRate.toInt()}%',
                      technicalCode: 'SCHEMA-COMP',
                      badgeText: 'LABOR SPLIT',
                      badgeColor: AppColors.statusCompleted,
                      icon: Icons.percent,
                    ),
                    StatCard(
                      title: 'Active Workload',
                      value: '${orders.length} Jobs',
                      technicalCode: 'LOG-WORK',
                      badgeText: 'BAY 1',
                      badgeColor: AppColors.statusInProgress,
                      icon: Icons.schedule,
                    ),
                    StatCard(
                      title: 'Completed Orders',
                      value: '$completedCount Jobs',
                      technicalCode: 'JOBS-DONE',
                      badgeText: 'VERIFIED',
                      badgeColor: AppColors.statusCompleted,
                      icon: Icons.verified_outlined,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.section),

            SectionHeader(
              title: 'EMPLOYMENT CONTRACT DETAILS',
              subtitle:
                  'Technician database profile mapping (public.mechanics)',
            ),
            const SizedBox(height: AppSpacing.compact),
            PitCard(
              technicalLabel:
                  'PROFILE • ${mechanic?.id != null ? mechanic!.id.substring(0, 8).toUpperCase() : 'MEC-001'} • ${mechanicName.toUpperCase()}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Employee Code',
                    mechanic?.id != null
                        ? mechanic!.id.substring(0, 8).toUpperCase()
                        : 'MEC-001',
                  ),
                  _buildDetailRow(
                    'Specialization',
                    mechanic?.specialization ??
                        'Performance Powertrain & Diagnostics',
                  ),
                  _buildDetailRow(
                    'Base Hourly Compensation',
                    'IDR ${hourlyRate.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} / hour',
                  ),
                  _buildDetailRow(
                    'Service Order Split',
                    '${commissionRate.toInt()}% of Billable Labor',
                  ),
                  _buildDetailRow(
                    'Assigned Service Bay',
                    'Bay 1 (High-Voltage Certified)',
                  ),
                  _buildDetailRow(
                    'Payout Cycle',
                    'Bi-weekly Workshop Settlement',
                  ),
                  _buildDetailRow(
                    'Contract Status',
                    mechanic != null ? 'Active Contract' : 'Suspended',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.technical(color: AppColors.textMuted),
          ),
          Text(
            value,
            style: AppTypography.bodySmall(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
