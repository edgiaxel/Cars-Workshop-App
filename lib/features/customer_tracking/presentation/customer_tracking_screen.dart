import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/core/utils/currency_formatter.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/customer_tracking/data/customer_tracking_repository.dart';
import 'package:pitmate/features/customer_tracking/models/customer_tracking_model.dart';
import 'package:pitmate/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

final customerTrackingRepositoryProvider = Provider<CustomerTrackingRepository>((ref) {
  return CustomerTrackingRepository();
});

class CustomerTrackingScreen extends ConsumerStatefulWidget {
  const CustomerTrackingScreen({super.key, this.serviceOrderId});

  final String? serviceOrderId;

  @override
  ConsumerState<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends ConsumerState<CustomerTrackingScreen> {
  bool _isLoading = true;
  CustomerTrackingSummary _summary = const CustomerTrackingSummary(hasActiveOrder: false);
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  Future<void> _loadTrackingData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(customerTrackingRepositoryProvider);
      final customerId = await repo.getCurrentCustomerId();

      if (customerId != null) {
        final summary = await repo.fetchTrackingSummary(
          customerId: customerId,
          orderId: widget.serviceOrderId,
        );
        if (mounted) {
          setState(() {
            _summary = summary;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _summary = const CustomerTrackingSummary(hasActiveOrder: false);
            _isLoading = false;
          });
        }
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
      RoleNavigation.customerNavItems,
      index,
      currentIndex: 5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final userName = auth is AuthAuthenticated ? auth.userProfile.fullName : 'User';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return ResponsiveRoleScaffold(
      roleTitle: 'Live Vehicle Tracking',
      userName: userName,
      userSubtitle: 'Verified Customer',
      currentIndex: 5,
      onNavIndexChanged: _onNavChanged,
      navItems: RoleNavigation.customerNavItems,
      telemetryNotice: _summary.hasActiveOrder ? 'ACTIVE WORKSHOP TELEMETRY' : null,
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      actions: [
        const NotificationBellButton(),
        IconButton(
          key: const Key('refresh_tracking_button'),
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh Tracking',
          onPressed: _loadTrackingData,
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text('Unable to load tracking', style: AppTypography.headlineSmall(color: textColor)),
                        const SizedBox(height: 6),
                        Text(_errorMessage!, style: AppTypography.bodySmall(color: subtextColor)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTrackingData,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : !_summary.hasActiveOrder
                  ? _buildNoActiveOrderState(context, textColor, subtextColor)
                  : RefreshIndicator(
                      onRefresh: _loadTrackingData,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Vehicle Telemetry Header Card
                            _buildVehicleHeaderCard(context, isDark, textColor, subtextColor, borderColor),
                            const SizedBox(height: 16),

                            // 2. 8-Stage Workshop Lifecycle Stepper
                            _buildLifecycleStepperCard(context, isDark, textColor, subtextColor, borderColor),
                            const SizedBox(height: 16),

                            // 3. Quick Action Cards (Estimate Approval or Invoicing)
                            if (_summary.invoiceId != null || _summary.currentStageIndex >= 6) ...[
                              _buildInvoiceActionCard(context, isDark, textColor, subtextColor),
                              const SizedBox(height: 16),
                            ],

                            if (_summary.currentStageIndex == 3 || _summary.status == 'estimate_pending') ...[
                              _buildEstimateActionCard(context, isDark, textColor, subtextColor),
                              const SizedBox(height: 16),
                            ],

                            // 4. Operations in Progress
                            if (_summary.tasks.isNotEmpty) ...[
                              _buildTasksCard(context, isDark, textColor, subtextColor),
                              const SizedBox(height: 16),
                            ],

                            // 5. Customer Visible Findings
                            if (_summary.findings.isNotEmpty) ...[
                              _buildFindingsCard(context, isDark, textColor, subtextColor),
                            ],
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildNoActiveOrderState(BuildContext context, Color textColor, Color subtextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.garage_outlined, size: 64, color: AppColors.accentRed),
            ),
            const SizedBox(height: 20),
            Text(
              'No Vehicle Currently in Service',
              style: AppTypography.headlineMedium(color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'All previous repairs are completed and delivered. When you check in for a booking, live progress telemetry will appear here.',
              style: AppTypography.bodyMedium(color: subtextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(RoutePaths.bookService),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Book Workshop Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleHeaderCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    final make = _summary.vehicleMake ?? 'Vehicle';
    final model = _summary.vehicleModel ?? '';
    final plate = _summary.licensePlate ?? 'NO PLATE';
    final orderNum = _summary.orderNumber ?? 'SO-ACTIVE';

    return PitCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.roundedSmall,
                  border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.directions_car, color: AppColors.accentRed, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$make $model',
                      style: AppTypography.headlineSmall(color: textColor),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            plate,
                            style: AppTypography.telemetrySmall(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Order: $orderNum',
                          style: AppTypography.bodySmall(color: subtextColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: (_summary.status ?? 'in_progress').toUpperCase(),
                type: _summary.status == 'completed' || _summary.status == 'closed'
                    ? StatusBadgeType.success
                    : StatusBadgeType.inProgress,
              ),
            ],
          ),
          if (_summary.mileageKm != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.speed, size: 16, color: subtextColor),
                const SizedBox(width: 6),
                Text(
                  'Recorded Odometer: ${_summary.mileageKm} KM',
                  style: AppTypography.telemetrySmall(color: subtextColor),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLifecycleStepperCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subtextColor,
    Color borderColor,
  ) {
    return PitCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Workflow Progress',
                style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
              ),
              Text(
                'Stage ${_summary.currentStageIndex + 1} of 8',
                style: AppTypography.telemetrySmall(color: AppColors.accentRed),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _summary.timeline.length,
            itemBuilder: (context, index) {
              final stage = _summary.timeline[index];
              final isLast = index == _summary.timeline.length - 1;
              final isCompleted = stage.completed;
              final isActive = stage.active;

              final Color dotColor = isCompleted
                  ? AppColors.success
                  : isActive
                      ? AppColors.accentRed
                      : borderColor;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stepper Track & Dot
                    Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppColors.success
                                : isActive
                                    ? AppColors.accentRed
                                    : (isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight),
                            border: Border.all(color: dotColor, width: 2),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check, size: 12, color: Colors.white)
                                : isActive
                                    ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: subtextColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: isCompleted ? AppColors.success : borderColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Stage Title and Description
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stage.stage,
                              style: AppTypography.bodyMedium(
                                color: isActive || isCompleted ? textColor : subtextColor,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            if (isActive)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Current workshop stage in progress',
                                  style: AppTypography.telemetrySmall(color: AppColors.accentRed),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceActionCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    final balance = _summary.outstandingBalanceCents ?? 0;
    final total = _summary.totalAmountCents ?? 0;
    final isPaid = balance == 0 && total > 0;

    return PitCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isPaid ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
              borderRadius: AppSpacing.roundedSmall,
            ),
            child: Icon(
              isPaid ? Icons.check_circle_outline : Icons.receipt_long,
              color: isPaid ? AppColors.success : AppColors.warning,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaid ? 'Invoice Settled' : 'Invoice Ready for Payment',
                  style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  isPaid
                      ? 'Total paid: ${CurrencyFormatter.formatIdr(total)}'
                      : 'Outstanding balance: ${CurrencyFormatter.formatIdr(balance)}',
                  style: AppTypography.bodySmall(color: subtextColor),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.go(RoutePaths.customerInvoices),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPaid ? AppColors.graphitePrimary : AppColors.accentRed,
              foregroundColor: Colors.white,
            ),
            child: Text(isPaid ? 'View Receipt' : 'Pay Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateActionCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    return PitCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.12),
              borderRadius: AppSpacing.roundedSmall,
            ),
            child: const Icon(Icons.assignment_turned_in_outlined, color: AppColors.info, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagnostic Estimate Awaiting Approval',
                  style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Review recommended labor operations and replacement parts.',
                  style: AppTypography.bodySmall(color: subtextColor),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.go('${RoutePaths.customerEstimateApproval}?orderId=${_summary.orderId}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    return PitCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Authorized Service Operations',
            style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _summary.tasks.length,
            separatorBuilder: (_, _) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final task = _summary.tasks[index];
              return Row(
                children: [
                  const Icon(Icons.build_circle_outlined, size: 18, color: AppColors.accentRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.taskName,
                      style: AppTypography.bodyMedium(color: textColor),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (task.status == 'completed' ? AppColors.success : AppColors.info)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.status.toUpperCase(),
                      style: AppTypography.telemetrySmall(
                        color: task.status == 'completed' ? AppColors.success : AppColors.info,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFindingsCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    return PitCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Multi-Point Inspection Findings',
            style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _summary.findings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final finding = _summary.findings[index];
              final isHigh = finding.severity == 'critical' || finding.severity == 'high';

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                  borderRadius: AppSpacing.roundedSmall,
                  border: Border.all(
                    color: isHigh ? AppColors.danger.withValues(alpha: 0.4) : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isHigh ? Icons.warning_amber_rounded : Icons.info_outline,
                      size: 20,
                      color: isHigh ? AppColors.danger : AppColors.info,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                finding.itemName,
                                style: AppTypography.labelLarge(color: textColor),
                              ),
                              Text(
                                finding.category.toUpperCase(),
                                style: AppTypography.telemetrySmall(color: subtextColor),
                              ),
                            ],
                          ),
                          if (finding.description != null && finding.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              finding.description!,
                              style: AppTypography.bodySmall(color: subtextColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
