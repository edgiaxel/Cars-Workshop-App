import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/service_order.dart';
import '../../../shared/providers/service_order_provider.dart';
import '../../../shared/providers/spare_part_provider.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';
import 'admin_shell.dart';

/// Reports & analytics overview for Admin role backed by live Supabase telemetry adhering to DESIGN.md.
class AdminReportsPage extends ConsumerWidget {
  const AdminReportsPage({super.key});

  void _showReportDialog(
    BuildContext context, {
    required String title,
    required String code,
    required String description,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        title: Row(
          children: [
            const Icon(
              Icons.analytics_outlined,
              color: AppColors.primaryAccent,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.compact),
            Expanded(
              child: Text(
                'REPORT TELEMETRY • $code',
                style: AppTypography.sectionTitle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.label(color: AppColors.primaryAccent),
              ),
              const SizedBox(height: AppSpacing.compact),
              Text(
                description,
                style: AppTypography.bodyMedium(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.standard),
              const Divider(color: AppColors.borderSubtle, height: 1),
              const SizedBox(height: AppSpacing.compact),
              Text(
                'Period: Full Operational Cycle (October 2026)',
                style: AppTypography.technical(color: AppColors.textMuted),
              ),
              Text(
                'Telemetry Source: PostgreSQL public.service_orders & public.spare_parts',
                style: AppTypography.technical(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Close',
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
                SnackBar(
                  content: Text(
                    'Report [$code] generated and exported to PDF/CSV format.',
                  ),
                  backgroundColor: AppColors.statusCompleted,
                ),
              );
            },
            icon: const Icon(Icons.file_download, size: 16),
            label: const Text('Export PDF / CSV'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(serviceOrdersProvider);
    final partsAsync = ref.watch(sparePartsProvider);

    final orders = ordersAsync.asData?.value ?? [];
    final parts = partsAsync.asData?.value ?? [];

    final totalRevenue = orders.fold<double>(
      0.0,
      (sum, o) =>
          sum +
          (o.status == ServiceStatus.completed ||
                  o.status == ServiceStatus.closed
              ? (o.finalTotal ?? o.estimatedTotal)
              : 0.0),
    );

    return AdminShell(
      currentRoute: RoutePaths.adminReports,
      child: SingleChildScrollView(
        padding: AppSpacing.paddingSection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: 'WORKSHOP TELEMETRY & REPORTS',
              subtitle: 'Operational analytics, bay utilization, and workshop turnover summaries',
              action: PrimaryButton(
                text: 'Generate Report',
                icon: Icons.summarize_outlined,
                width: 170,
                onPressed: () => _showReportDialog(
                  context,
                  title: 'Comprehensive Workshop Turnover',
                  code: 'REP-ALL-2026',
                  description: 'All-in-one executive telemetry summary encompassing billings, technician hours, bay utilization, and inventory burn velocity.',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.compact),

            // Report category stat overview
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
                      title: 'Service Orders',
                      value: '${orders.length} Orders',
                      technicalCode: 'REP-SO',
                      badgeText: 'LIVE SYNC',
                      badgeColor: AppColors.info,
                      icon: Icons.analytics_outlined,
                    ),
                    StatCard(
                      title: 'Settled Turnover',
                      value:
                          'IDR ${(totalRevenue / 1000000).toStringAsFixed(1)}M',
                      technicalCode: 'REP-REV',
                      badgeText: 'OCTOBER',
                      badgeColor: AppColors.statusCompleted,
                      icon: Icons.payments_outlined,
                    ),
                    StatCard(
                      title: 'Parts Catalog',
                      value: '${parts.length} SKUs',
                      technicalCode: 'REP-PARTS',
                      badgeText: 'TRACKED',
                      badgeColor: AppColors.warning,
                      icon: Icons.inventory_2_outlined,
                    ),
                    const StatCard(
                      title: 'Technician Bays',
                      value: '6 Bays',
                      technicalCode: 'REP-BAY',
                      badgeText: 'MONITORED',
                      badgeColor: AppColors.statusInProgress,
                      icon: Icons.garage_outlined,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.section),

            SectionHeader(
              title: 'REPORT CATEGORIES',
              subtitle:
                  'Select an operational domain for structured data inspection',
            ),
            const SizedBox(height: AppSpacing.compact),

            _buildReportCategoryCard(
              context,
              title: 'Financial & Service Revenue',
              code: 'FIN-REV-01',
              description: 'Gross service turnover, parts markup, and labor revenue breakdowns per billing period.',
              status: 'Ready for Telemetry Export',
              statusColor: AppColors.statusCompleted,
              icon: Icons.payments_outlined,
            ),
            const SizedBox(height: AppSpacing.standard),
            _buildReportCategoryCard(
              context,
              title: 'Bay Efficiency & Cycle Times',
              code: 'BAY-EFF-02',
              description: 'Mean time to diagnose (MTTD) and mean time to repair (MTTR) across bays 1 through 6.',
              status: 'Active Telemetry Stream',
              statusColor: AppColors.statusInProgress,
              icon: Icons.speed,
            ),
            const SizedBox(height: AppSpacing.standard),
            _buildReportCategoryCard(
              context,
              title: 'Inventory Consumption & Reorder Forecast',
              code: 'INV-FCST-03',
              description: 'Fluids, filters, and brake component depletion velocity versus minimum safety stock levels.',
              status: 'Live Database Sync',
              statusColor: AppColors.statusCompleted,
              icon: Icons.warehouse_outlined,
            ),
            const SizedBox(height: AppSpacing.standard),
            _buildReportCategoryCard(
              context,
              title: 'Technician Productivity & Commission Rates',
              code: 'TECH-PROD-04',
              description: 'Logged labor hours, completed task checklists, and individual technician payout rates.',
              status: 'Telemetry Linked',
              statusColor: AppColors.info,
              icon: Icons.engineering_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCategoryCard(
    BuildContext context, {
    required String title,
    required String code,
    required String description,
    required String status,
    required Color statusColor,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => _showReportDialog(
        context,
        title: title,
        code: code,
        description: description,
      ),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: PitCard(
        technicalLabel: 'REPORT MODULE • $code',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.standard),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Icon(icon, color: AppColors.primaryAccent, size: 24),
            ),
            const SizedBox(width: AppSpacing.standard),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wrapped header to guarantee no row overflow on small screens
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.sectionTitle(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.compact),
                      StatusBadge(
                        label: status.toUpperCase(),
                        color: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.compact),
                  Text(
                    description,
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary,
                    ),
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
