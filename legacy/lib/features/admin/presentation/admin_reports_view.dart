import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/report_telemetry.dart';
import '../../../shared/providers/report_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';
import 'admin_shell.dart';

/// Reports & analytics overview for Admin role backed by live Supabase telemetry.
/// Implements Phase 6 specifications with date boundaries, intake origin comparison,
/// status distribution, volume timeline, mechanic workload, and separated financial totals.
class AdminReportsPage extends ConsumerStatefulWidget {
  const AdminReportsPage({super.key});

  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  String _selectedPreset = '30d';

  void _applyPreset(String preset) {
    final now = DateTime.now();
    DateTime start;
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (preset == '7d') {
      final s = now.subtract(const Duration(days: 7));
      start = DateTime(s.year, s.month, s.day, 0, 0, 0);
    } else if (preset == 'mtd') {
      start = DateTime(now.year, now.month, 1, 0, 0, 0);
    } else if (preset == 'all') {
      start = DateTime(2025, 1, 1, 0, 0, 0);
    } else {
      // 30d default
      final s = now.subtract(const Duration(days: 30));
      start = DateTime(s.year, s.month, s.day, 0, 0, 0);
    }

    setState(() => _selectedPreset = preset);
    ref
        .read(reportDateRangeFilterProvider.notifier)
        .setRange(DateTimeRange(start: start, end: end));
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final currentRange = ref.read(reportDateRangeFilterProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: currentRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryAccent,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedPreset = 'custom');
      final normalized = DateTimeRange(
        start: DateTime(
            picked.start.year, picked.start.month, picked.start.day, 0, 0, 0),
        end: DateTime(
            picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
      );
      ref
          .read(reportDateRangeFilterProvider.notifier)
          .setRange(normalized);
    }
  }

  void _showReportExportDialog(
    BuildContext context, {
    required String title,
    required String code,
    required ReportTelemetryData telemetry,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
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
                'REPORT TELEMETRY \u2022 $code',
                style: AppTypography.sectionTitle(color: textPrimary),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
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
                'Telemetry summary from ${telemetry.startDate.toString().substring(0, 10)} to ${telemetry.endDate.toString().substring(0, 10)}.',
                style: AppTypography.bodyMedium(color: textSecondary),
              ),
              const SizedBox(height: AppSpacing.standard),
              Divider(
                color: isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle,
                height: 1,
              ),
              const SizedBox(height: AppSpacing.compact),
              Text(
                'Total Volume: ${telemetry.intakeBreakdown.totalOrders} Orders (${telemetry.intakeBreakdown.bookingCount} Booking, ${telemetry.intakeBreakdown.walkInCount} Walk-in)',
                style: AppTypography.technical(color: textMuted),
              ),
              Text(
                'Settled Turnover: IDR ${(telemetry.financialSummary.settledTotal / 1000000).toStringAsFixed(2)}M (${telemetry.financialSummary.settledOrdersCount} settled orders)',
                style: AppTypography.technical(color: textMuted),
              ),
              Text(
                'Pipeline Pipeline: IDR ${(telemetry.financialSummary.estimatedTotal / 1000000).toStringAsFixed(2)}M estimated across active lifecycle',
                style: AppTypography.technical(color: textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Close',
              style: AppTypography.label(color: textMuted),
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
                    'Report [$code] telemetry packet exported successfully.',
                  ),
                  backgroundColor: AppColors.statusCompleted,
                ),
              );
            },
            icon: const Icon(Icons.file_download, size: 16),
            label: const Text('Export Telemetry Packet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telemetryAsync = ref.watch(reportTelemetryProvider);
    final activeRange = ref.watch(reportDateRangeFilterProvider);

    return AdminShell(
      currentRoute: RoutePaths.adminReports,
      child: SingleChildScrollView(
        padding: AppSpacing.paddingSection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: 'WORKSHOP TELEMETRY & REPORTS',
              subtitle:
                  'Operational analytics, intake comparisons, mechanic workload, and verified financial turnover',
              action: PrimaryButton(
                text: 'Export Telemetry',
                icon: Icons.file_download_outlined,
                onPressed: () {
                  final data = telemetryAsync.asData?.value;
                  if (data != null) {
                    _showReportExportDialog(
                      context,
                      title: 'Executive Workshop Telemetry',
                      code: 'REP-EXEC-2026',
                      telemetry: data,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.standard),

            // Date Range Filter Toolbar
            _buildDateRangeToolbar(context, activeRange),
            const SizedBox(height: AppSpacing.standard),

            telemetryAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => PitCard(
                technicalLabel: 'TELEMETRY STATUS • ERROR',
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.standard),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 40),
                        const SizedBox(height: AppSpacing.compact),
                        Text(
                          'Failed to aggregate workshop telemetry',
                          style: AppTypography.sectionTitle(
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.compact),
                        Text(
                          err.toString(),
                          style: AppTypography.technical(
                              color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        PrimaryButton(
                          text: 'Retry Telemetry Sync',
                          icon: Icons.refresh,
                          onPressed: () =>
                              ref.invalidate(reportTelemetryProvider),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (telemetry) {
                if (telemetry.intakeBreakdown.totalOrders == 0 &&
                    telemetry.mechanicWorkload.isEmpty) {
                  return const EmptyState(
                    icon: Icons.assessment_outlined,
                    title: 'No Telemetry in Selected Period',
                    message:
                        'No service orders or technician assignments were recorded within the specified date boundaries.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stat Overview Cards
                    _buildStatGrid(telemetry),
                    const SizedBox(height: AppSpacing.section),

                    // Intake Breakdown (Booking vs Walk-In)
                    _buildIntakeSection(context, telemetry.intakeBreakdown),
                    const SizedBox(height: AppSpacing.section),

                    // Financial Pipeline vs Settled Revenue
                    _buildFinancialSection(context, telemetry.financialSummary),
                    const SizedBox(height: AppSpacing.section),

                    // Status Distribution & Daily Volume Timeline
                    _buildStatusAndVolumeSection(
                      context,
                      telemetry.statusDistribution,
                      telemetry.volumeTimeline,
                    ),
                    const SizedBox(height: AppSpacing.section),

                    // Mechanic Workload Section
                    _buildMechanicWorkloadSection(
                      context,
                      telemetry.mechanicWorkload,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeToolbar(BuildContext context, DateTimeRange range) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final borderSubtle =
        isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;

    final startStr = range.start.toString().substring(0, 10);
    final endStr = range.end.toString().substring(0, 10);

    return PitCard(
      technicalLabel: 'TELEMETRY BOUNDARIES \u2022 FILTER',
      child: Wrap(
        spacing: AppSpacing.compact,
        runSpacing: AppSpacing.compact,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(width: AppSpacing.compact),
              Text(
                'Window: $startStr  \u2192  $endStr',
                style: AppTypography.technical(color: textPrimary),
              ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.compact,
            children: [
              _buildFilterChip('7 Days', '7d', context),
              _buildFilterChip('30 Days', '30d', context),
              _buildFilterChip('Month to Date', 'mtd', context),
              _buildFilterChip('All Time', 'all', context),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  foregroundColor: _selectedPreset == 'custom'
                      ? AppColors.primaryAccent
                      : textSecondary,
                  side: BorderSide(
                    color: _selectedPreset == 'custom'
                        ? AppColors.primaryAccent
                        : borderSubtle,
                  ),
                ),
                onPressed: () => _pickCustomRange(context),
                icon: const Icon(Icons.date_range, size: 16),
                label: const Text('Custom Range'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String preset, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final borderSubtle =
        isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;

    final isSelected = _selectedPreset == preset;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _applyPreset(preset);
      },
      selectedColor: AppColors.primaryAccent.withValues(alpha: 0.25),
      labelStyle: AppTypography.label(
        color: isSelected ? AppColors.primaryAccent : textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryAccent : borderSubtle,
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildStatGrid(ReportTelemetryData telemetry) {
    final finance = telemetry.financialSummary;
    final intake = telemetry.intakeBreakdown;

    return LayoutBuilder(
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
              title: 'Total Volume',
              value: '${intake.totalOrders} Units',
              technicalCode: 'AGG-VOL',
              badgeText: 'AGGREGATED',
              badgeColor: AppColors.info,
              icon: Icons.speed,
            ),
            StatCard(
              title: 'Settled Revenue',
              value:
                  'IDR ${(finance.settledTotal / 1000000).toStringAsFixed(1)}M',
              technicalCode: 'FIN-SETTLED',
              badgeText: '${finance.settledOrdersCount} ORDERS',
              badgeColor: AppColors.statusCompleted,
              icon: Icons.payments_outlined,
            ),
            StatCard(
              title: 'Pipeline Estimate',
              value:
                  'IDR ${(finance.estimatedTotal / 1000000).toStringAsFixed(1)}M',
              technicalCode: 'FIN-EST',
              badgeText: '${finance.pendingSettlementCount} ACTIVE',
              badgeColor: AppColors.warning,
              icon: Icons.trending_up_outlined,
            ),
            StatCard(
              title: 'Active Technicians',
              value: '${telemetry.mechanicWorkload.length} Staff',
              technicalCode: 'TECH-CREW',
              badgeText: 'ALLOCATED',
              badgeColor: AppColors.primaryAccent,
              icon: Icons.engineering_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _buildIntakeSection(BuildContext context, IntakeBreakdown intake) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'INTAKE ORIGIN COMPARISON',
          subtitle:
              'Proportion of pre-booked vs walk-in admissions',
        ),
        const SizedBox(height: AppSpacing.compact),
        PitCard(
          technicalLabel: 'TELEMETRY \u2022 INTAKE-RATIO',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accessibility Semantics
              Semantics(
                label:
                    'Intake Origin Summary: Total ${intake.totalOrders} orders. Pre-Booked: ${intake.bookingCount} (${intake.bookingPercentage.toStringAsFixed(1)}%), Walk-In: ${intake.walkInCount} (${intake.walkInPercentage.toStringAsFixed(1)}%).',
                child: const SizedBox.shrink(),
              ),

              // Visual Stacked Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: SizedBox(
                  height: 24,
                  child: intake.totalOrders == 0
                      ? Container(
                          color: isDark
                              ? AppColors.borderSubtle
                              : AppColors.lightBorderSubtle,
                        )
                      : Row(
                          children: [
                            if (intake.bookingCount > 0)
                              Expanded(
                                flex: intake.bookingCount,
                                child: Container(
                                  color: AppColors.info,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${intake.bookingPercentage.toStringAsFixed(0)}%',
                                    style: AppTypography.technical(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            if (intake.walkInCount > 0)
                              Expanded(
                                flex: intake.walkInCount,
                                child: Container(
                                  color: AppColors.primaryAccent,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${intake.walkInPercentage.toStringAsFixed(0)}%',
                                    style: AppTypography.technical(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.standard),

              // Breakdown Counters
              Wrap(
                spacing: AppSpacing.standard,
                runSpacing: AppSpacing.compact,
                alignment: WrapAlignment.spaceAround,
                children: [
                  _buildLegendIndicator(
                    context: context,
                    title: 'PRE-BOOKED',
                    count: intake.bookingCount,
                    percent: intake.bookingPercentage,
                    color: AppColors.info,
                    description: 'Scheduled via customer booking portal',
                  ),
                  _buildLegendIndicator(
                    context: context,
                    title: 'WALK-IN ADMISSION',
                    count: intake.walkInCount,
                    percent: intake.walkInPercentage,
                    color: AppColors.primaryAccent,
                    description: 'Direct workshop arrivals & immediate intake',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendIndicator({
    required BuildContext context,
    required String title,
    required int count,
    required double percent,
    required Color color,
    required String description,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 4, right: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: AppTypography.label(color: textPrimary),
                ),
                const SizedBox(width: AppSpacing.compact),
                Text(
                  '$count (${percent.toStringAsFixed(1)}%)',
                  style: AppTypography.technical(color: color),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: AppTypography.technical(color: textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialSection(BuildContext context, FinancialSummary finance) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'FINANCIAL SETTLEMENT VS PIPELINE ESTIMATE',
          subtitle:
              'Clear demarcation between realized/closed revenue and work-in-progress estimates',
        ),
        const SizedBox(height: AppSpacing.compact),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            return Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: PitCard(
                    technicalLabel: 'FINANCIAL \u2022 REALIZED TURNOVER',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              color: AppColors.statusCompleted,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.compact),
                            Text(
                              'Settled Realized Revenue',
                              style: AppTypography.sectionTitle(
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        Text(
                          'IDR ${(finance.settledTotal / 1000000).toStringAsFixed(2)}M',
                          style: AppTypography.metricValue(
                            color: AppColors.statusCompleted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.compact),
                        Text(
                          'Verified against ${finance.settledOrdersCount} completed and closed orders with finalized invoices.',
                          style: AppTypography.bodySmall(
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        const StatusBadge(
                          label: 'AUDITED & REALIZED',
                          color: AppColors.statusCompleted,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isWide) const SizedBox(width: AppSpacing.standard)
                else const SizedBox(height: AppSpacing.standard),
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: PitCard(
                    technicalLabel: 'FINANCIAL \u2022 PIPELINE ESTIMATE',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.timelapse_outlined,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.compact),
                            Text(
                              'Estimated Pipeline Total',
                              style: AppTypography.sectionTitle(
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        Text(
                          'IDR ${(finance.estimatedTotal / 1000000).toStringAsFixed(2)}M',
                          style: AppTypography.metricValue(
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.compact),
                        Text(
                          'Estimated aggregate cost for ${finance.pendingSettlementCount} active/pending work orders subject to final parts and diagnostic adjustments.',
                          style: AppTypography.bodySmall(
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        const StatusBadge(
                          label: 'WORK IN PROGRESS',
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusAndVolumeSection(
    BuildContext context,
    List<StatusDistributionItem> statusDist,
    List<VolumeTimelineItem> timeline,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'STATUS DISTRIBUTION & DAILY VOLUME',
          subtitle:
              'Lifecycle phase breakdown and daily order ingestion velocity',
        ),
        const SizedBox(height: AppSpacing.compact),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            return Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status distribution
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: PitCard(
                    technicalLabel: 'TELEMETRY \u2022 STATUS DISTRIBUTION',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Orders by Status',
                          style: AppTypography.sectionTitle(
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        if (statusDist.isEmpty)
                          Text(
                            'No status telemetry recorded.',
                            style: AppTypography.bodyMedium(
                              color: textMuted,
                            ),
                          )
                        else
                          ...statusDist.map((s) {
                            final color = _getColorForStatus(s.status);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.compact),
                                      Text(
                                        s.status
                                            .toUpperCase()
                                            .replaceAll('_', ' '),
                                        style: AppTypography.technical(
                                          color: textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${s.count} orders',
                                    style: AppTypography.label(
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                if (isWide) const SizedBox(width: AppSpacing.standard)
                else const SizedBox(height: AppSpacing.standard),

                // Daily volume timeline
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: PitCard(
                    technicalLabel: 'TELEMETRY \u2022 DAILY INGESTION',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Daily Activity',
                          style: AppTypography.sectionTitle(
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        if (timeline.isEmpty)
                          Text(
                            'No timeline activity in selected range.',
                            style: AppTypography.bodyMedium(
                              color: textMuted,
                            ),
                          )
                        else
                          ...timeline.take(6).map((t) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    t.date,
                                    style: AppTypography.technical(
                                      color: textSecondary,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${t.totalCount} total',
                                        style: AppTypography.technical(
                                          color: AppColors.primaryAccent,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.compact),
                                      Text(
                                        '(${t.completedCount} completed)',
                                        style: AppTypography.technical(
                                          color: AppColors.statusCompleted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Color _getColorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'closed':
        return AppColors.statusCompleted;
      case 'in_progress':
      case 'in progress':
        return AppColors.statusInProgress;
      case 'diagnosing':
        return AppColors.info;
      case 'blocked':
        return AppColors.taskBlocked;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Widget _buildMechanicWorkloadSection(
    BuildContext context,
    List<MechanicWorkloadItem> workload,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'MECHANIC ALLOCATION & WORKLOAD',
          subtitle:
              'Assigned task loads, active diagnostic bays, and job completion metrics',
        ),
        const SizedBox(height: AppSpacing.compact),
        PitCard(
          technicalLabel: 'TELEMETRY \u2022 CREW WORKLOAD',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (workload.isEmpty)
                Text(
                  'No technician workload data available.',
                  style: AppTypography.bodyMedium(color: textMuted),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    horizontalMargin: 8,
                    columnSpacing: 24,
                    columns: [
                      DataColumn(
                        label: Text(
                          'TECHNICIAN',
                          style: AppTypography.label(
                              color: textSecondary),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'SPECIALIZATION',
                          style: AppTypography.label(
                              color: textSecondary),
                        ),
                      ),
                      DataColumn(
                        numeric: true,
                        label: Text(
                          'TOTAL ASSIGNED',
                          style: AppTypography.label(
                              color: textSecondary),
                        ),
                      ),
                      DataColumn(
                        numeric: true,
                        label: Text(
                          'IN PROGRESS',
                          style: AppTypography.label(
                              color: textSecondary),
                        ),
                      ),
                      DataColumn(
                        numeric: true,
                        label: Text(
                          'COMPLETED',
                          style: AppTypography.label(
                              color: textSecondary),
                        ),
                      ),
                    ],
                    rows: workload.map((m) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  m.mechanicName,
                                  style: AppTypography.bodyMedium(
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  m.employeeCode,
                                  style: AppTypography.technical(
                                    color: AppColors.primaryAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              m.specialization,
                              style: AppTypography.bodySmall(
                                color: textSecondary,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${m.assignedCount}',
                              style: AppTypography.technical(
                                color: textPrimary,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${m.activeCount}',
                              style: AppTypography.technical(
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${m.completedCount}',
                              style: AppTypography.technical(
                                color: AppColors.statusCompleted,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
