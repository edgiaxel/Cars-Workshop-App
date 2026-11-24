import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:pitmate/features/reports/data/reports_repository.dart';
import 'package:pitmate/features/reports/models/workshop_metrics_model.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  WorkshopDailyMetrics? _dailyMetrics;
  WorkshopMonthlyMetrics? _monthlyMetrics;

  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(reportsRepositoryProvider);
      final daily = await repo.fetchDailyMetrics(_selectedDate);
      final monthly = await repo.fetchMonthlyMetrics(_selectedDate);

      if (mounted) {
        setState(() {
          _dailyMetrics = daily;
          _monthlyMetrics = monthly;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
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
      currentIndex: 11,
    );
  }

  String _formatCurrency(double amount) {
    final formattedNumber = amount.toStringAsFixed(2);
    final parts = formattedNumber.split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInt = intPart.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '\$$formattedInt.$decPart';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final userName =
        auth is AuthAuthenticated ? auth.userProfile.fullName : 'Toto Wolf';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final subtextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return ResponsiveRoleScaffold(
      roleTitle: 'Workshop Reports & Analytics',
      userName: userName,
      userSubtitle: 'Workshop Director',
      currentIndex: 11,
      onNavIndexChanged: _onNavChanged,
      navItems: RoleNavigation.adminNavItems,
      telemetryNotice: 'FINANCIAL TELEMETRY',
      actions: [
        const NotificationBellButton(),
        IconButton(
          key: const Key('refresh_reports_button'),
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh Analytics',
          onPressed: _loadMetrics,
        ),
      ],
      body: Column(
        children: [
          // Subheader with Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.accentRed,
                    unselectedLabelColor: subtextColor,
                    indicatorColor: AppColors.accentRed,
                    indicatorWeight: 3,
                    labelStyle: AppTypography.labelLarge(
                      color: AppColors.accentRed,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: AppTypography.labelLarge(
                      color: subtextColor,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(
                        key: Key('tab_daily_reports'),
                        text: 'Daily Operations',
                      ),
                      Tab(
                        key: Key('tab_monthly_reports'),
                        text: 'Monthly Financials',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.danger,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to Load Workshop Analytics',
                                style: AppTypography.headlineSmall(
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMedium(
                                  color: subtextColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadMetrics,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentRed,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(140, 44),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDailyTab(context),
                          _buildMonthlyTab(context),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTab(BuildContext context) {
    final daily = _dailyMetrics;
    if (daily == null) {
      return const Center(child: Text('No daily data available'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final subtextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return RefreshIndicator(
      onRefresh: _loadMetrics,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE WORKSHOP OVERVIEW',
                style: AppTypography.telemetrySmall(
                  color: AppColors.accentRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Date: ${daily.reportDate.toIso8601String().split('T').first}',
                style: AppTypography.bodySmall(color: subtextColor),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildMetricCard(
                context,
                title: 'ACTIVE SERVICE ORDERS',
                value: '${daily.activeOrdersCount}',
                subtitle: 'In intake, repair or QC',
                icon: Icons.directions_car,
                accentColor: AppColors.info,
                cardKey: 'card_active_orders',
              ),
              _buildMetricCard(
                context,
                title: 'COMPLETED TODAY',
                value: '${daily.completedTodayCount}',
                subtitle: 'Ready for delivery or closed',
                icon: Icons.check_circle_outline,
                accentColor: AppColors.success,
                cardKey: 'card_completed_today',
              ),
              _buildMetricCard(
                context,
                title: 'BAY OCCUPANCY',
                value: '${daily.bayOccupancyRate.toStringAsFixed(1)}%',
                subtitle: '${daily.baysOccupied} of ${daily.totalBays} active bays',
                icon: Icons.garage,
                accentColor: daily.bayOccupancyRate > 80.0
                    ? AppColors.warning
                    : AppColors.accentRed,
                cardKey: 'card_bay_occupancy',
              ),
              _buildMetricCard(
                context,
                title: 'SETTLED REVENUE TODAY',
                value: _formatCurrency(daily.settledRevenue),
                subtitle: 'Cash, Card, QRIS settled',
                icon: Icons.payments_outlined,
                accentColor: AppColors.success,
                cardKey: 'card_settled_revenue',
              ),
            ],
          ),
          const SizedBox(height: 20),

          PitCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.warning,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL OUTSTANDING RECEIVABLES',
                        style: AppTypography.telemetrySmall(
                          color: subtextColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(daily.outstandingReceivables),
                        key: const Key('text_outstanding_receivables'),
                        style: AppTypography.headlineMedium(
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Issued invoices pending full settlement from customers',
                        style: AppTypography.bodySmall(color: subtextColor),
                      ),
                    ],
                  ),
                ),
                const StatusBadge(
                  label: 'Pending Settlement',
                  type: StatusBadgeType.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          PitCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BAY CAPACITY & OCCUPANCY METRIC',
                  style: AppTypography.telemetrySmall(
                    color: subtextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (daily.totalBays > 0)
                        ? (daily.baysOccupied / daily.totalBays).clamp(0.0, 1.0)
                        : 0.0,
                    minHeight: 12,
                    backgroundColor: isDark
                        ? AppColors.surfaceElevatedDark
                        : AppColors.surfaceElevatedLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      daily.bayOccupancyRate > 80.0
                          ? AppColors.warning
                          : AppColors.accentRed,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${daily.baysOccupied} Bays Engaged',
                      style: AppTypography.bodySmall(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${daily.totalBays - daily.baysOccupied} Bays Available',
                      style: AppTypography.bodySmall(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTab(BuildContext context) {
    final monthly = _monthlyMetrics;
    if (monthly == null) {
      return const Center(child: Text('No monthly data available'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final subtextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;

    return RefreshIndicator(
      onRefresh: _loadMetrics,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MONTHLY FINANCIAL PERFORMANCE',
                style: AppTypography.telemetrySmall(
                  color: AppColors.accentRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Period: ${monthly.monthStart.toIso8601String().split('T').first} to ${monthly.monthEnd.toIso8601String().split('T').first}',
                style: AppTypography.bodySmall(color: subtextColor),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildMetricCard(
                context,
                title: 'ORDERS COMPLETED',
                value: '${monthly.totalOrdersCompleted}',
                subtitle: 'Delivered in current month',
                icon: Icons.task_alt,
                accentColor: AppColors.info,
                cardKey: 'card_monthly_completed',
              ),
              _buildMetricCard(
                context,
                title: 'GROSS SETTLED REVENUE',
                value: _formatCurrency(monthly.grossRevenue),
                subtitle: 'Total settled payments',
                icon: Icons.monetization_on_outlined,
                accentColor: AppColors.success,
                cardKey: 'card_gross_revenue',
              ),
              _buildMetricCard(
                context,
                title: 'PARTS COGS CONSUMED',
                value: _formatCurrency(monthly.partsCogs),
                subtitle: 'Direct inventory cost',
                icon: Icons.inventory_2_outlined,
                accentColor: AppColors.warning,
                cardKey: 'card_parts_cogs',
              ),
              _buildMetricCard(
                context,
                title: 'LABOR REVENUE',
                value: _formatCurrency(monthly.laborRevenue),
                subtitle: 'Service operations total',
                icon: Icons.handyman_outlined,
                accentColor: AppColors.accentRed,
                cardKey: 'card_labor_revenue',
              ),
              _buildMetricCard(
                context,
                title: 'GROSS MARGIN',
                value: _formatCurrency(monthly.grossMargin),
                subtitle:
                    'Margin Rate: ${monthly.grossMarginPercentage.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                accentColor: AppColors.success,
                cardKey: 'card_gross_margin',
              ),
            ],
          ),
          const SizedBox(height: 24),

          PitCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star_outline,
                      color: AppColors.accentRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TOP CONSUMED PARTS (BY VOLUME & COGS)',
                      style: AppTypography.telemetrySmall(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (monthly.topConsumedParts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No parts consumption recorded for this period',
                        style: AppTypography.bodyMedium(color: subtextColor),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: monthly.topConsumedParts.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 16, color: borderColor),
                    itemBuilder: (context, index) {
                      final item = monthly.topConsumedParts[index];
                      return Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.accentRed.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: AppTypography.labelMedium(
                                color: AppColors.accentRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: AppTypography.labelLarge(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'SKU: ${item.sku}',
                                  style: AppTypography.bodySmall(
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item.unitsConsumed} units',
                                style: AppTypography.labelMedium(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'COGS: ${_formatCurrency(item.totalCogs)}',
                                style: AppTypography.bodySmall(
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          PitCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.engineering_outlined,
                      color: AppColors.accentRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MECHANIC WORKLOAD & INCENTIVE ALLOCATION',
                      style: AppTypography.telemetrySmall(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (monthly.mechanicWorkload.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No mechanic workload recorded for this period',
                        style: AppTypography.bodyMedium(color: subtextColor),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: monthly.mechanicWorkload.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 16, color: borderColor),
                    itemBuilder: (context, index) {
                      final item = monthly.mechanicWorkload[index];
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: isDark
                                ? AppColors.surfaceElevatedDark
                                : AppColors.surfaceElevatedLight,
                            child: Text(
                              item.fullName.isNotEmpty
                                  ? item.fullName[0].toUpperCase()
                                  : 'M',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.fullName,
                                  style: AppTypography.labelLarge(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${item.completedTasksCount} operations completed',
                                  style: AppTypography.bodySmall(
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatCurrency(item.totalIncentive),
                              style: AppTypography.labelMedium(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String cardKey,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final subtextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SizedBox(
      width: 240,
      child: PitCard(
        key: Key(cardKey),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.telemetrySmall(
                      color: subtextColor,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: accentColor, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTypography.headlineMedium(
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.bodySmall(color: subtextColor),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
