import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/core/utils/currency_formatter.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/mechanic/data/models/mechanic_compensation_model.dart';
import 'package:pitmate/features/mechanic/data/repositories/mechanic_compensation_repository.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

/// Mechanic Personal Earnings & Incentive Ledger Screen (UI-M08).
class MechanicEarningsScreen extends ConsumerStatefulWidget {
  const MechanicEarningsScreen({super.key});

  @override
  ConsumerState<MechanicEarningsScreen> createState() =>
      _MechanicEarningsScreenState();
}

class _MechanicEarningsScreenState
    extends ConsumerState<MechanicEarningsScreen> {
  final MechanicCompensationRepository _compRepo =
      MechanicCompensationRepository();

  bool _isLoading = true;
  MechanicCompensationProfile? _profile;
  List<MechanicEarningAllocation> _allocations = [];
  List<MechanicPayrollAdjustment> _adjustments = [];

  String get _mechanicId {
    final auth = ref.read(authNotifierProvider);
    return auth is AuthAuthenticated ? auth.userProfile.id : '';
  }

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);
    final mechanicId = _mechanicId;
    if (mechanicId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final profiles = await _compRepo.fetchProfiles();
      final myProfile = profiles.firstWhere(
        (p) => p.mechanicId == mechanicId,
        orElse: () => MechanicCompensationProfile(
          mechanicId: mechanicId,
          baseSalaryCents: 0,
          incentivePercentage: 15.0,
          defaultLeadSharePercentage: 65.0,
          updatedAt: DateTime.now(),
          mechanicName: 'Mechanic',
        ),
      );

      final allocations = await _compRepo.fetchAllocationsForMechanic(
        mechanicId,
      );
      final adjustments = await _compRepo.fetchAdjustments(mechanicId);

      if (mounted) {
        setState(() {
          _profile = myProfile;
          _allocations = allocations;
          _adjustments = adjustments;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onNavChanged(int index) {
    RoleNavigation.navigate(
      context,
      RoleNavigation.mechanicNavItems,
      index,
      currentIndex: 3,
    );
  }

  String _formatRp(int cents) => CurrencyFormatter.formatIdr(cents);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.graphitePrimary;

    final baseSalary = _profile?.baseSalaryCents ?? 5000000;
    final totalIncentives = _allocations.fold<int>(
      0,
      (sum, a) => sum + a.allocatedCents,
    );
    final netAdjustments = _adjustments.fold<int>(
      0,
      (sum, a) => sum + (a.isDeduction ? -a.amountCents : a.amountCents),
    );
    final estimatedTotal = baseSalary + totalIncentives + netAdjustments;

    return ResponsiveRoleScaffold(
      roleTitle: 'Mechanic Compensation',
      userName: _profile?.mechanicName ?? 'Max Verstappen',
      userSubtitle: 'Senior Pit Technician',
      currentIndex: 3,
      showBackButton: true,
      onBack: () => context.go(RoutePaths.mechanic),
      onNavIndexChanged: _onNavChanged,
      navItems: RoleNavigation.mechanicNavItems,
      telemetryNotice: 'MONTHLY ESTIMATED: ${_formatRp(estimatedTotal)}',
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Earnings',
          onPressed: _loadEarnings,
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 18.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Primary Highlight Card
                      PitCard(
                        accentBorderLeft: AppColors.success,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ESTIMATED MONTHLY EARNINGS',
                              style: AppTypography.labelSmall(
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatRp(estimatedTotal),
                              style: AppTypography.headlineLarge(
                                color: textColor,
                              ).copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Includes fixed base salary, job completion incentives, and audited performance adjustments.',
                              style: AppTypography.bodySmall(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Telemetry Breakdown Cards
                      LayoutBuilder(
                        builder: (context, c) {
                          final cardWidth = c.maxWidth < 600
                              ? c.maxWidth
                              : (c.maxWidth - 24) / 3;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildMetricCard(
                                'BASE SALARY',
                                _formatRp(baseSalary),
                                AppColors.info,
                                cardWidth,
                              ),
                              _buildMetricCard(
                                'ACCRUED INCENTIVES',
                                _formatRp(totalIncentives),
                                AppColors.success,
                                cardWidth,
                              ),
                              _buildMetricCard(
                                'NET ADJUSTMENTS',
                                '${netAdjustments >= 0 ? "+" : ""}${_formatRp(netAdjustments)}',
                                netAdjustments >= 0
                                    ? AppColors.info
                                    : AppColors.accentRed,
                                cardWidth,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // 3. Completed Operation Incentives
                      Text(
                        'OPERATION INCENTIVES LEDGER',
                        style: AppTypography.labelLarge(color: textColor)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      if (_allocations.isEmpty)
                        PitCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No completed operation incentives accrued yet this billing period.',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._allocations.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: PitCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a.taskTitle ?? 'Operation Task',
                                          style:
                                              AppTypography.labelMedium(
                                                color: textColor,
                                              ).copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Order: ${a.orderNumber ?? "SO-000"} • Role: ${a.roleInTask.toUpperCase()} (${a.sharePercentage}%)',
                                          style: AppTypography.bodySmall(
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '+${_formatRp(a.allocatedCents)}',
                                    style: AppTypography.telemetryMedium(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // 4. Payroll Adjustments
                      Text(
                        'AUDITED PAYROLL ADJUSTMENTS',
                        style: AppTypography.labelLarge(color: textColor)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      if (_adjustments.isEmpty)
                        PitCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No adjustments recorded this period.',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._adjustments.map(
                          (adj) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: PitCard(
                              accentBorderLeft: adj.isDeduction
                                  ? AppColors.accentRed
                                  : AppColors.success,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            StatusBadge(
                                              label: adj.adjustmentType
                                                  .toUpperCase(),
                                              color: adj.isDeduction
                                                  ? AppColors.accentRed
                                                  : AppColors.success,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                adj.reason,
                                                style:
                                                    AppTypography.bodySmall(
                                                      color: textColor,
                                                    ).copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${adj.isDeduction ? "-" : "+"}${_formatRp(adj.amountCents)}',
                                    style: AppTypography.telemetryMedium(
                                      color: adj.isDeduction
                                          ? AppColors.accentRed
                                          : AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    Color accent,
    double cardWidth,
  ) {
    return SizedBox(
      width: cardWidth,
      child: PitCard(
        accentBorderLeft: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.telemetrySmall(
                color: accent,
                fontWeight: FontWeight.w700,
              ).copyWith(fontSize: 11),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.headlineSmall().copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
