import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/core/utils/currency_formatter.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/mechanic/data/models/mechanic_compensation_model.dart';
import 'package:pitmate/features/mechanic/data/repositories/mechanic_compensation_repository.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/pit_error_dialog.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

/// Admin Mechanic Compensation & Payroll Screen (UI-A17).
class AdminMechanicEarningsScreen extends ConsumerStatefulWidget {
  const AdminMechanicEarningsScreen({super.key});

  @override
  ConsumerState<AdminMechanicEarningsScreen> createState() => _AdminMechanicEarningsScreenState();
}

class _AdminMechanicEarningsScreenState extends ConsumerState<AdminMechanicEarningsScreen> {
  final MechanicCompensationRepository _compRepo = MechanicCompensationRepository();

  bool _isLoading = true;
  List<MechanicCompensationProfile> _profiles = [];
  List<MechanicPayrollAdjustment> _adjustments = [];



  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await _compRepo.fetchProfiles();
      final adjustments = await _compRepo.fetchAdjustments();
      if (mounted) {
        setState(() {
          _profiles = profiles;
          _adjustments = adjustments;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _profiles = [];
          _adjustments = [];
          _isLoading = false;
        });
      }
    }
  }

  void _onNavChanged(int index) {
    RoleNavigation.navigate(context, RoleNavigation.adminNavItems, index, currentIndex: 7);
  }

  String _formatRp(int cents) => CurrencyFormatter.formatIdr(cents);

  Future<void> _openEditProfileDialog(MechanicCompensationProfile profile) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final salaryController = TextEditingController(text: profile.baseSalaryCents.toString());
    final incentiveController = TextEditingController(text: profile.incentivePercentage.toStringAsFixed(1));
    final splitController = TextEditingController(text: profile.defaultLeadSharePercentage.toStringAsFixed(1));

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: Text(
          'CONFIGURE COMPENSATION',
          style: AppTypography.headlineSmall(
            color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mechanic: ${profile.mechanicName ?? profile.mechanicId}'),
              const SizedBox(height: 12),
              TextField(
                key: const Key('input_base_salary'),
                controller: salaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Base Salary (Rp)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('input_incentive_percentage'),
                controller: incentiveController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Standard Incentive (% of Labor)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('input_lead_split_percentage'),
                controller: splitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Default Lead Split (%)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            key: const Key('btn_save_compensation_profile'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed, foregroundColor: Colors.white),
            onPressed: () async {
              final salary = int.tryParse(salaryController.text.trim()) ?? -1;
              final incentive = double.tryParse(incentiveController.text.trim()) ?? -1;
              final split = double.tryParse(splitController.text.trim()) ?? -1;

              if (salary < 0 || incentive < 0 || split < 0 || split > 100) {
                showPitErrorDialog(
                  ctx,
                  title: 'INVALID INPUT',
                  message: 'Values must be non-negative, and split must be between 0% and 100%.',
                );
                return;
              }

              Navigator.pop(ctx);
              try {
                await _compRepo.updateProfile(
                  mechanicId: profile.mechanicId,
                  baseSalaryCents: salary,
                  incentivePercentage: incentive,
                  defaultLeadSharePercentage: split,
                );
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Compensation profile updated successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  showPitErrorDialog(
                    context,
                    title: 'UPDATE FAILED',
                    message: e.toString().replaceAll('Exception: ', ''),
                  );
                }
              }
            },
            child: const Text('SAVE SETTINGS'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAdjustmentDialog(String mechanicId, String mechanicName) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedType = 'bonus';
    final amountController = TextEditingController(text: '250000');
    final reasonController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          title: Text(
            'RECORD PAYROLL ADJUSTMENT',
            style: AppTypography.headlineSmall(
              color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mechanic: $mechanicName'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  decoration: const InputDecoration(
                    labelText: 'Adjustment Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'bonus', child: Text('Performance Bonus (+)')),
                    DropdownMenuItem(value: 'deduction', child: Text('Deduction / Tool Charge (-)')),
                    DropdownMenuItem(value: 'adjustment', child: Text('Correction / Audit Adjustment')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('input_adjustment_amount'),
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Adjustment Amount (Rp)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('input_adjustment_reason'),
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Mandatory Audit Reason',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              key: const Key('btn_confirm_adjustment'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
              onPressed: () async {
                final amount = int.tryParse(amountController.text.trim()) ?? 0;
                final reason = reasonController.text.trim();

                if (amount <= 0 || reason.isEmpty) {
                  showPitErrorDialog(
                    ctx,
                    title: 'VALIDATION ERROR',
                    message: 'Amount must be positive and audit reason is strictly required.',
                  );
                  return;
                }

                Navigator.pop(ctx);
                try {
                  await _compRepo.adjustCompensation(
                    mechanicId: mechanicId,
                    amountCents: amount,
                    type: selectedType,
                    reason: reason,
                  );
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payroll adjustment recorded and audited.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    showPitErrorDialog(
                      context,
                      title: 'ADJUSTMENT FAILED',
                      message: e.toString().replaceAll('Exception: ', ''),
                    );
                  }
                }
              },
              child: const Text('RECORD ADJUSTMENT'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    final totalBaseSalary = _profiles.fold<int>(0, (sum, p) => sum + p.baseSalaryCents);
    final totalAdjustments = _adjustments.fold<int>(0, (sum, a) => sum + (a.isDeduction ? -a.amountCents : a.amountCents));

    return ResponsiveRoleScaffold(
      roleTitle: 'Mechanic Compensation',
      userName: 'Toto Wolf',
      userSubtitle: 'Workshop Director',
      currentIndex: 7,
      onNavIndexChanged: _onNavChanged,
      navItems: RoleNavigation.adminNavItems,
      telemetryNotice: '${_profiles.length} ACTIVE TECHNICIANS',
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Metric Telemetry Cards
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildMetricCard(
                                'TOTAL BASE PAYROLL',
                                _formatRp(totalBaseSalary),
                                AppColors.info,
                                isNarrow,
                              ),
                              _buildMetricCard(
                                'NET ADJUSTMENTS',
                                _formatRp(totalAdjustments),
                                totalAdjustments >= 0 ? AppColors.success : AppColors.accentRed,
                                isNarrow,
                              ),
                              _buildMetricCard(
                                'ACTIVE MECHANICS',
                                '${_profiles.length}',
                                AppColors.accentRed,
                                isNarrow,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 2. Profiles Section
                          Text(
                            'TECHNICIAN COMPENSATION PROFILES',
                            style: AppTypography.labelLarge(
                              color: textColor,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          if (_profiles.isEmpty)
                            PitCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text('No mechanic profiles found.', style: TextStyle(color: textColor)),
                              ),
                            )
                          else
                            ..._profiles.map((profile) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: PitCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    profile.mechanicName ?? 'Technician ${profile.mechanicId.substring(0, 8)}',
                                                    style: AppTypography.headlineSmall(color: textColor).copyWith(fontWeight: FontWeight.w700),
                                                  ),
                                                  Text(
                                                    profile.mechanicEmail ?? 'technician@pitmate.com',
                                                    style: AppTypography.bodySmall(
                                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Wrap(
                                              spacing: 8,
                                              children: [
                                                OutlinedButton.icon(
                                                  icon: const Icon(Icons.settings, size: 14),
                                                  label: const Text('CONFIGURE', style: TextStyle(fontSize: 12)),
                                                  onPressed: () => _openEditProfileDialog(profile),
                                                ),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.accentRed,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                  icon: const Icon(Icons.add_circle_outline, size: 14),
                                                  label: const Text('ADJUST', style: TextStyle(fontSize: 12)),
                                                  onPressed: () => _openAdjustmentDialog(
                                                    profile.mechanicId,
                                                    profile.mechanicName ?? 'Technician',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(height: 1),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildDetailCell(
                                                'BASE SALARY',
                                                _formatRp(profile.baseSalaryCents),
                                                textColor,
                                                isDark,
                                              ),
                                            ),
                                            Expanded(
                                              child: _buildDetailCell(
                                                'INCENTIVE RATE',
                                                '${profile.incentivePercentage}% of labor',
                                                textColor,
                                                isDark,
                                              ),
                                            ),
                                            Expanded(
                                              child: _buildDetailCell(
                                                'LEAD SPLIT',
                                                '${profile.defaultLeadSharePercentage}% default',
                                                textColor,
                                                isDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                          const SizedBox(height: 24),

                          // 3. Audit Ledger for Payroll Adjustments
                          Text(
                            'AUDITED PAYROLL ADJUSTMENTS',
                            style: AppTypography.labelLarge(
                              color: textColor,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          if (_adjustments.isEmpty)
                            PitCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text('No payroll adjustments recorded.', style: TextStyle(color: textColor)),
                              ),
                            )
                          else
                            ..._adjustments.map((a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: PitCard(
                                    accentBorderLeft: a.isDeduction ? AppColors.accentRed : AppColors.success,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    a.mechanicName ?? 'Technician',
                                                    style: AppTypography.labelMedium(color: textColor).copyWith(fontWeight: FontWeight.w700),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  StatusBadge(
                                                    label: a.adjustmentType.toUpperCase(),
                                                    color: a.isDeduction ? AppColors.accentRed : AppColors.success,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Reason: ${a.reason}',
                                                style: AppTypography.bodySmall(
                                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${a.isDeduction ? "-" : "+"}${_formatRp(a.amountCents)}',
                                          style: AppTypography.telemetryMedium(
                                            color: a.isDeduction ? AppColors.accentRed : AppColors.success,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color accent, bool isNarrow) {
    return SizedBox(
      width: isNarrow ? double.infinity : 280,
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
              style: AppTypography.headlineSmall().copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCell(String label, String value, Color textColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 0.8,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.telemetrySmall(color: textColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
