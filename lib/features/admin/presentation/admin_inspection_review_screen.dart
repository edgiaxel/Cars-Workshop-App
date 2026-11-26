import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/inspections/data/models/inspection_finding_model.dart';
import 'package:pitmate/features/inspections/data/models/inspection_model.dart';
import 'package:pitmate/features/inspections/data/models/service_order_telemetry.dart';
import 'package:pitmate/features/inspections/data/repositories/inspection_repository.dart';
import 'package:pitmate/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin Inspection & Diagnostic Review Screen (UI-A08).
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
  String? _errorMessage;

  List<Map<String, dynamic>> _availableInspections = [];
  String? _selectedInspectionId;
  String? _selectedOrderId;

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

  bool get _hasSupabaseOrInjectedRepo {
    if (widget.repository != null) return true;
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadReviewData({
    String? overrideOrderId,
    String? overrideInspectionId,
  }) async {
    if (!_hasSupabaseOrInjectedRepo) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? targetOrderId = overrideOrderId ?? widget.serviceOrderId;
      String? targetInspectionId = overrideInspectionId ?? widget.inspectionId;

      if (targetOrderId == null && targetInspectionId == null) {
        final listRes = await _repository.fetchInspectionsList();
        if (listRes.isFailure) {
          if (mounted) {
            setState(() {
              _errorMessage = listRes.exceptionOrNull?.message ??
                  'Failed to load inspections.';
              _isLoading = false;
            });
          }
          return;
        }

        final list = listRes.dataOrNull ?? [];
        _availableInspections = list;
        if (list.isEmpty) {
          if (mounted) {
            setState(() {
              _telemetry = null;
              _inspection = null;
              _findings = [];
              _selectedInspectionId = null;
              _selectedOrderId = null;
              _isLoading = false;
            });
          }
          return;
        }

        final preferred = list.firstWhere(
          (row) => row['status'] == 'completed',
          orElse: () => list.first,
        );
        targetInspectionId = preferred['id'] as String?;
        targetOrderId = preferred['service_order_id'] as String?;
      } else if (_availableInspections.isEmpty) {
        final listRes = await _repository.fetchInspectionsList();
        if (listRes.isSuccess) {
          _availableInspections = listRes.dataOrNull ?? [];
        }
      }

      _selectedInspectionId = targetInspectionId;
      _selectedOrderId = targetOrderId;

      if (targetOrderId == null || targetOrderId.isEmpty) {
        if (mounted) {
          setState(() {
            _telemetry = null;
            _inspection = null;
            _findings = [];
            _isLoading = false;
          });
        }
        return;
      }

      final telemetryResult =
          await _repository.fetchOrderTelemetry(targetOrderId);
      if (telemetryResult.isFailure) {
        if (mounted) {
          setState(() {
            _errorMessage = telemetryResult.exceptionOrNull?.message ??
                'Failed to load service order telemetry.';
            _isLoading = false;
          });
        }
        return;
      }
      _telemetry = telemetryResult.dataOrNull;

      if (targetInspectionId != null && targetInspectionId.isNotEmpty) {
        final inspRes =
            await _repository.fetchInspectionById(targetInspectionId);
        if (inspRes.isFailure) {
          if (mounted) {
            setState(() {
              _errorMessage = inspRes.exceptionOrNull?.message ??
                  'Failed to load inspection record.';
              _isLoading = false;
            });
          }
          return;
        }
        _inspection = inspRes.dataOrNull;
      } else {
        final inspRes =
            await _repository.fetchInspectionByOrderId(targetOrderId);
        if (inspRes.isFailure) {
          if (mounted) {
            setState(() {
              _errorMessage = inspRes.exceptionOrNull?.message ??
                  'Failed to load inspection for order.';
              _isLoading = false;
            });
          }
          return;
        }
        _inspection = inspRes.dataOrNull;
      }

      if (_inspection != null) {
        _selectedInspectionId = _inspection!.id;
        final findingsRes =
            await _repository.fetchInspectionFindings(_inspection!.id);
        if (findingsRes.isSuccess) {
          _findings = findingsRes.dataOrNull ?? [];
        } else {
          _findings = [];
          _errorMessage = findingsRes.exceptionOrNull?.message;
        }
      } else {
        _findings = [];
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load inspection review: $e';
          _isLoading = false;
        });
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

    final orderId =
        _telemetry?.orderId ?? _selectedOrderId ?? widget.serviceOrderId ?? '';
    final orderNum = _telemetry?.orderNumber ?? orderId;
    final inspId = _inspection?.id ?? '';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.calculate_outlined,
              color: AppColors.accentRed,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text('CREATE ESTIMATE', style: AppTypography.headlineSmall()),
          ],
        ),
        content: Text(
          'Diagnostic findings from inspection ${inspId.isNotEmpty ? inspId : orderNum} will be loaded into Estimate Builder for Service Order $orderNum.\n\n• $_criticalCount Critical items requiring immediate authorization\n• $_fairCount Fair items recommended for maintenance',
          style: AppTypography.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: AppTypography.labelLarge(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          ElevatedButton(
            key: const Key('confirm-create-estimate-button'),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('${RoutePaths.adminEstimateBuilder}?orderId=$orderId');
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
    final auth = ref.watch(authNotifierProvider);
    final userName =
        auth is AuthAuthenticated ? auth.userProfile.fullName : 'User';

    return ResponsiveRoleScaffold(
      roleTitle: 'Diagnostic Review',
      userName: userName,
      userSubtitle: 'Workshop Director',
      currentIndex: 4,
      onNavIndexChanged: (i) => RoleNavigation.navigate(
        context,
        RoleNavigation.adminNavItems,
        i,
        currentIndex: 4,
      ),
      navItems: RoleNavigation.adminNavItems,
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RoutePaths.adminWorkshopFloor);
        }
      },
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      telemetryNotice: _inspection != null
          ? 'STATUS: ${_inspection!.status.displayName.toUpperCase()}'
          : 'NO ACTIVE INSPECTION',
      actions: [
        const NotificationBellButton(),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh Inspections',
          onPressed: () => _loadReviewData(),
        ),
        if (_inspection != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBodyContent(isDark, textColor, secondaryTextColor),
    );
  }

  Widget _buildBodyContent(
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    if (_errorMessage != null && _telemetry == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: PitCard(
              accentBorderLeft: AppColors.danger,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.danger,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unable to Load Inspection Review',
                    style: AppTypography.headlineSmall(color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall(color: secondaryTextColor),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _loadReviewData(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('RETRY'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_telemetry == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: PitCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    size: 48,
                    color: AppColors.textMutedDark,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No vehicle inspections recorded yet',
                    style: AppTypography.headlineSmall(color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check in a vehicle on the Workshop Floor and complete a mechanic inspection to review diagnostic findings here.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium(color: secondaryTextColor),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _loadReviewData(),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('REFRESH'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentRed,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            context.go(RoutePaths.adminWorkshopFloor),
                        icon: const Icon(Icons.warehouse_outlined, size: 18),
                        label: const Text('OPEN WORKSHOP FLOOR'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                PitCard(
                  accentBorderLeft: AppColors.danger,
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall(color: AppColors.danger),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_availableInspections.isNotEmpty) ...[
                _buildInspectionSelector(isDark, textColor, secondaryTextColor),
                const SizedBox(height: 16),
              ],
              _buildHeaderCard(isDark, textColor, secondaryTextColor),
              const SizedBox(height: 16),
              _buildSummaryCounters(isDark, textColor),
              const SizedBox(height: 16),
              if (_inspection?.summary != null &&
                  _inspection!.summary!.isNotEmpty) ...[
                _buildMasterSummaryCard(isDark, textColor, secondaryTextColor),
                const SizedBox(height: 16),
              ],
              _buildFilterRow(isDark),
              const SizedBox(height: 12),
              _buildFindingsList(isDark, textColor, secondaryTextColor),
              const SizedBox(height: 24),
              _buildActionButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInspectionSelector(
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final currentValue = _availableInspections.any(
            (row) => row['id'] == _selectedInspectionId)
        ? _selectedInspectionId
        : null;

    return PitCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.directions_car, size: 18, color: secondaryTextColor),
          const SizedBox(width: 10),
          Text(
            'INSPECTION RECORD',
            style: AppTypography.labelSmall(
              color: secondaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('dropdown_inspection_selector'),
                value: currentValue,
                isExpanded: true,
                items: _availableInspections.map((row) {
                  final id = row['id'] as String? ?? '';
                  final so = row['service_orders'] as Map<String, dynamic>?;
                  final veh = so?['vehicles'] as Map<String, dynamic>?;
                  final orderNum =
                      so?['order_number'] as String? ?? 'Service Order';
                  final plate = veh?['license_plate'] as String? ?? '';
                  final model = veh?['model'] as String? ?? '';
                  final status =
                      (row['status'] as String? ?? '').toUpperCase();
                  final label = [
                    orderNum,
                    if (plate.isNotEmpty) plate,
                    if (model.isNotEmpty) model,
                    if (status.isNotEmpty) '[$status]',
                  ].join(' • ');

                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(
                      label,
                      style: AppTypography.bodyMedium(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (nextId) {
                  if (nextId == null) return;
                  final row = _availableInspections.firstWhere(
                    (r) => r['id'] == nextId,
                    orElse: () => <String, dynamic>{},
                  );
                  final orderId = row['service_order_id'] as String?;
                  if (orderId != null) {
                    _loadReviewData(
                      overrideOrderId: orderId,
                      overrideInspectionId: nextId,
                    );
                  }
                },
              ),
            ),
          ),
        ],
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
            style: AppTypography.headlineMedium(color: textColor),
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
          color:
              isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
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
              const Icon(
                Icons.assignment_outlined,
                size: 20,
                color: AppColors.accentRed,
              ),
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
    if (_findings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24.0),
        alignment: Alignment.center,
        child: Text(
          'No diagnostic findings recorded for this inspection yet.',
          style: AppTypography.bodyMedium(color: secondaryTextColor),
        ),
      );
    }

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
                            label:
                                '${finding.severity.displayName.toUpperCase()} PRIORITY',
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
        onPressed: _telemetry == null ? null : _navigateToEstimate,
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
