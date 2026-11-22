import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../inspections/data/models/inspection_finding_model.dart';
import '../../inspections/data/models/inspection_model.dart';
import '../../inspections/data/models/service_order_telemetry.dart';
import '../../inspections/data/repositories/inspection_repository.dart';

/// Admin Inspection & Diagnostic Review Screen (UI-A08).
/// Allows workshop admins and service advisors to review technician diagnostic findings,
/// view critical severity alerts, and initiate estimate preparation.
class AdminInspectionReviewScreen extends ConsumerStatefulWidget {
  const AdminInspectionReviewScreen({
    super.key,
    this.serviceOrderId,
    this.inspectionId,
    this.repository,
    this.onCreateEstimate,
  });

  final String? serviceOrderId;
  final String? inspectionId;
  final IInspectionRepository? repository;
  final VoidCallback? onCreateEstimate;

  @override
  ConsumerState<AdminInspectionReviewScreen> createState() =>
      _AdminInspectionReviewScreenState();
}

class _AdminInspectionReviewScreenState
    extends ConsumerState<AdminInspectionReviewScreen> {
  late final IInspectionRepository _repository;
  bool _isLoading = true;

  InspectionModel? _inspection;
  ServiceOrderTelemetry? _telemetry;
  List<InspectionFinding> _findings = [];
  String _activeFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ref.read(inspectionRepositoryProvider);
    _loadReviewData();
  }

  Future<void> _loadReviewData() async {
    setState(() {
      _isLoading = true;
    });

    final orderId = widget.serviceOrderId ?? 'SO-2026-0143';

    try {
      // 1. Fetch telemetry
      final telemetryResult = await _repository.fetchOrderTelemetry(orderId);
      if (telemetryResult.isSuccess && telemetryResult.dataOrNull != null) {
        _telemetry = telemetryResult.dataOrNull;
      } else {
        _telemetry = const ServiceOrderTelemetry(
          orderId: 'SO-2026-0143',
          orderNumber: 'SO-2026-0143',
          customerName: 'Alex Pratama',
          customerPhone: '+62 812-9988-7766',
          licensePlate: 'B 9912 SPO',
          make: 'Honda',
          model: 'Civic Type R (FL5)',
          year: 2023,
          odometer: 14250,
          customerComplaint:
              'Brake judder at high speeds, spongy pedal feel on deceleration',
          assignedBay: 'Bay 02 • Hoist B',
          fuelLevel: '75%',
          status: 'estimate_pending',
        );
      }

      // 2. Fetch inspection
      if (widget.inspectionId != null) {
        final inspRes = await _repository.fetchInspectionById(widget.inspectionId!);
        if (inspRes.isSuccess) {
          _inspection = inspRes.dataOrNull;
        }
      } else {
        final inspRes = await _repository.fetchInspectionByOrderId(orderId);
        if (inspRes.isSuccess) {
          _inspection = inspRes.dataOrNull;
        }
      }

      // Fallback inspection if not found or demo
      _inspection ??= InspectionModel(
        id: 'insp-demo-0143',
        serviceOrderId: orderId,
        mechanicId: 'mech-dian',
        status: InspectionStatus.completed,
        summary:
            'Front braking system requires immediate pad replacement and rotor skimming due to high-temperature glazing. Powertrain and battery in excellent condition.',
        startedAt: DateTime.now().subtract(const Duration(hours: 2)),
        completedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      // 3. Fetch findings
      final findingsRes = await _repository.fetchInspectionFindings(_inspection!.id);
      if (findingsRes.isSuccess && findingsRes.dataOrNull != null && findingsRes.dataOrNull!.isNotEmpty) {
        _findings = findingsRes.dataOrNull!;
      } else {
        // Fallback demo findings
        _findings = [
          InspectionFinding(
            id: 'find-1',
            inspectionId: _inspection!.id,
            category: 'Powertrain',
            itemName: 'Engine Oil',
            condition: FindingCondition.good,
            severity: SeverityLevel.low,
            notes: 'Oil level at max mark, clean amber color.',
            recommendedAction: 'Next oil service due at 20,000 KM.',
            createdAt: DateTime.now(),
          ),
          InspectionFinding(
            id: 'find-2',
            inspectionId: _inspection!.id,
            category: 'Brakes & Suspension',
            itemName: 'Front Brake Pads',
            condition: FindingCondition.critical,
            severity: SeverityLevel.urgent,
            notes: 'Pad material down to 2.5mm (service limit 3.0mm). Heat glaze on inner pads.',
            recommendedAction: 'Replace front brake pad set with Brembo track/street compound.',
            createdAt: DateTime.now(),
          ),
          InspectionFinding(
            id: 'find-3',
            inspectionId: _inspection!.id,
            category: 'Brakes & Suspension',
            itemName: 'Rotors',
            condition: FindingCondition.fair,
            severity: SeverityLevel.medium,
            notes: 'Brake judder caused by uneven surface deposits. Thickness within spec (30.8mm).',
            recommendedAction: 'Precision on-car rotor skimming / resurfacing.',
            createdAt: DateTime.now(),
          ),
          InspectionFinding(
            id: 'find-4',
            inspectionId: _inspection!.id,
            category: 'Electrical & Battery',
            itemName: 'Battery Health',
            condition: FindingCondition.good,
            severity: SeverityLevel.low,
            notes: 'Resting voltage 12.6V, cranking healthy.',
            recommendedAction: 'Pass - no action required.',
            createdAt: DateTime.now(),
          ),
          InspectionFinding(
            id: 'find-5',
            inspectionId: _inspection!.id,
            category: 'Fluids & Filters',
            itemName: 'Cabin Filter',
            condition: FindingCondition.fair,
            severity: SeverityLevel.low,
            notes: 'Dust build-up noted inside pleats.',
            recommendedAction: 'Replace activated carbon cabin pollen filter.',
            createdAt: DateTime.now(),
          ),
          InspectionFinding(
            id: 'find-6',
            inspectionId: _inspection!.id,
            category: 'Tires & Chassis',
            itemName: 'Tire Tread Depth',
            condition: FindingCondition.good,
            severity: SeverityLevel.low,
            notes: '5.2mm remaining uniformly across Michelin Pilot Sport 4S.',
            recommendedAction: 'Pass.',
            createdAt: DateTime.now(),
          ),
        ];
      }
    } catch (_) {
      // Fallback data already populated
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int get _criticalCount =>
      _findings.where((f) => f.condition == FindingCondition.critical).length;
  int get _fairCount =>
      _findings.where((f) => f.condition == FindingCondition.fair).length;
  int get _goodCount =>
      _findings.where((f) => f.condition == FindingCondition.good).length;

  List<InspectionFinding> get _filteredFindings {
    switch (_activeFilter) {
      case 'CRITICAL':
        return _findings
            .where((f) => f.condition == FindingCondition.critical)
            .toList();
      case 'FAIR':
        return _findings
            .where((f) => f.condition == FindingCondition.fair)
            .toList();
      case 'GOOD':
        return _findings
            .where((f) => f.condition == FindingCondition.good)
            .toList();
      default:
        return _findings;
    }
  }

  void _navigateToEstimate() {
    if (widget.onCreateEstimate != null) {
      widget.onCreateEstimate!();
      return;
    }

    final orderId = _telemetry?.orderId ?? widget.serviceOrderId ?? '';
    final inspId = _inspection?.id ?? '';

    // If estimate builder route exists or show confirmation
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.calculate_outlined, color: AppColors.accentRed, size: 28),
            const SizedBox(width: 8),
            Text(
              'CREATE ESTIMATE',
              style: AppTypography.headlineSmall(),
            ),
          ],
        ),
        content: Text(
          'Diagnostic findings from Inspection $inspId will be imported into Estimate Builder for Service Order $orderId.\n\n• $_criticalCount Critical items requiring immediate authorization\n• $_fairCount Fair items recommended for maintenance',
          style: AppTypography.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: AppTypography.labelLarge(color: AppColors.textSecondaryLight),
            ),
          ),
          ElevatedButton(
            key: const Key('confirm-create-estimate-button'),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Estimate draft initialized from inspection findings.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'PROCEED TO ESTIMATE',
              style: AppTypography.labelLarge(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final secondaryTextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'ADMIN DIAGNOSTIC REVIEW',
          style: AppTypography.headlineSmall(
            color: isDark ? AppColors.textPrimaryDark : AppColors.racingRed,
          ),
        ),
        actions: [
          if (_inspection != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: StatusBadge(
                  label: _inspection!.status.displayName.toUpperCase(),
                  type: _inspection!.status.isCompleted
                      ? StatusBadgeType.success
                      : StatusBadgeType.inProgress,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Vehicle and Order Telemetry Header
                      _buildHeaderCard(isDark, textColor, secondaryTextColor),
                      const SizedBox(height: 16),

                      // 2. Metric Summary Counters
                      _buildSummaryCounters(isDark, textColor),
                      const SizedBox(height: 16),

                      // 3. Master Technician Summary
                      if (_inspection?.summary != null) ...[
                        _buildMasterSummaryCard(isDark, textColor, secondaryTextColor),
                        const SizedBox(height: 16),
                      ],

                      // 4. Diagnostic Filter Tabs
                      _buildFilterRow(isDark),
                      const SizedBox(height: 12),

                      // 5. Findings List
                      _buildFindingsList(isDark, textColor, secondaryTextColor),
                      const SizedBox(height: 24),

                      // 6. Action Button: Create Estimate from Findings
                      _buildActionButton(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard(
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final telemetry = _telemetry!;

    return PitCard(
      accentBorderLeft: AppColors.accentRed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.plateBackground,
                  borderRadius: AppSpacing.roundedSmall,
                  border: Border.all(
                    color: AppColors.borderStrongLight,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  telemetry.licensePlate,
                  style: AppTypography.telemetryMedium(
                    color: AppColors.plateText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              StatusBadge(
                label: telemetry.orderNumber,
                type: StatusBadgeType.neutral,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            telemetry.vehicleDisplayName,
            style: AppTypography.headlineMedium(
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.speed, size: 16, color: secondaryTextColor),
              const SizedBox(width: 4),
              Text(
                telemetry.formattedOdometer,
                style: AppTypography.telemetrySmall(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.person_outline, size: 16, color: secondaryTextColor),
              const SizedBox(width: 4),
              Text(
                telemetry.customerName,
                style: AppTypography.bodySmall(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Text(
            'INTAKE COMPLAINT: ${telemetry.customerComplaint}',
            style: AppTypography.bodySmall(
              color: secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCounters(bool isDark, Color textColor) {
    return Row(
      children: [
        _buildCounterCard(
          label: 'TOTAL CHECKED',
          count: _findings.length,
          color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _buildCounterCard(
          label: 'CRITICAL ITEMS',
          count: _criticalCount,
          color: AppColors.danger,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _buildCounterCard(
          label: 'FAIR ITEMS',
          count: _fairCount,
          color: AppColors.warning,
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        _buildCounterCard(
          label: 'GOOD ITEMS',
          count: _goodCount,
          color: AppColors.success,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildCounterCard({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: AppSpacing.roundedSmall,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: AppTypography.telemetryLarge(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterSummaryCard(
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return PitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined,
                  size: 20, color: AppColors.accentRed),
              const SizedBox(width: 8),
              Text(
                'TECHNICIAN MASTER SUMMARY',
                style: AppTypography.labelLarge(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _inspection!.summary!,
            style: AppTypography.bodyMedium(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(bool isDark) {
    const filters = ['ALL', 'CRITICAL', 'FAIR', 'GOOD'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              key: Key('filter-tab-$filter'),
              onTap: () => setState(() => _activeFilter = filter),
              borderRadius: AppSpacing.roundedSmall,
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? AppColors.surfaceElevatedDark
                          : AppColors.graphitePrimary)
                      : (isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight),
                  borderRadius: AppSpacing.roundedSmall,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentRed
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                  ),
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: AppTypography.labelSmall(
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.graphitePrimary),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFindingsList(
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final findings = _filteredFindings;

    if (findings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24.0),
        alignment: Alignment.center,
        child: Text(
          'No findings found matching filter "$_activeFilter".',
          style: AppTypography.bodyMedium(color: secondaryTextColor),
        ),
      );
    }

    return Column(
      children: findings.map((finding) {
        Color conditionColor;
        switch (finding.condition) {
          case FindingCondition.good:
            conditionColor = AppColors.success;
          case FindingCondition.fair:
            conditionColor = AppColors.warning;
          case FindingCondition.critical:
            conditionColor = AppColors.danger;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: PitCard(
            accentBorderLeft: conditionColor,
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
                            finding.category.toUpperCase(),
                            style: AppTypography.labelSmall(
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            finding.itemName,
                            style: AppTypography.bodyLarge(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        StatusBadge(
                          label: finding.condition.displayName.toUpperCase(),
                          color: conditionColor,
                        ),
                        if (finding.condition != FindingCondition.good) ...[
                          const SizedBox(width: 6),
                          StatusBadge(
                            label: '${finding.severity.displayName.toUpperCase()} PRIORITY',
                            type: finding.severity == SeverityLevel.urgent
                                ? StatusBadgeType.danger
                                : StatusBadgeType.warning,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (finding.notes != null && finding.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Notes: ${finding.notes}',
                    style: AppTypography.bodySmall(color: textColor),
                  ),
                ],
                if (finding.recommendedAction != null &&
                    finding.recommendedAction!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceContainerDark
                          : AppColors.surfaceContainerLight,
                      borderRadius: AppSpacing.roundedSmall,
                      border: Border.all(
                        color: finding.condition == FindingCondition.critical
                            ? AppColors.danger.withValues(alpha: 0.4)
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.build_circle_outlined,
                          size: 16,
                          color: AppColors.accentRed,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Action: ${finding.recommendedAction}',
                            style: AppTypography.bodySmall(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        key: const Key('create-estimate-button'),
        onPressed: _navigateToEstimate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedSmall,
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calculate_outlined, size: 22),
            const SizedBox(width: 8),
            Text(
              'CREATE ESTIMATE FROM FINDINGS',
              style: AppTypography.labelLarge(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
