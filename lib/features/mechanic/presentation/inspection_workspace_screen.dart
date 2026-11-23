import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../inspections/data/models/inspection_finding_model.dart';
import '../../inspections/data/models/service_order_telemetry.dart';
import '../../inspections/data/repositories/inspection_repository.dart';

/// Predefined standard inspection items per engineering category.
const Map<String, List<String>> kStandardInspectionCategories = {
  'Powertrain': ['Engine Oil', 'Transmission', 'Coolant', 'Spark Plugs'],
  'Brakes & Suspension': [
    'Front Brake Pads',
    'Rear Brake Pads',
    'Rotors',
    'Brake Fluid',
  ],
  'Electrical & Battery': ['Battery Health', 'Alternator', 'Headlights'],
  'Fluids & Filters': ['Air Filter', 'Cabin Filter', 'Steering Fluid'],
  'Tires & Chassis': ['Tire Tread Depth', 'Wheel Alignment', 'Exhaust'],
};

/// Mutable in-memory evaluation state for an inspection checklist item.
class _ItemDiagnosticState {
  _ItemDiagnosticState({
    required this.category,
    required this.itemName,
    this.condition = FindingCondition.good,
    this.severity = SeverityLevel.low,
  });

  final String category;
  final String itemName;
  FindingCondition condition;
  SeverityLevel severity;
  String notes = '';
  String recommendedAction = '';
  bool isEvaluated = false;
  String? existingFindingId;
}

/// Mechanic Inspection Workspace Screen (UI-M03).
/// Allows technicians to execute multi-point vehicle diagnostics,
/// record conditions, severities, notes, and submit to estimate pending state.
class InspectionWorkspaceScreen extends ConsumerStatefulWidget {
  const InspectionWorkspaceScreen({
    super.key,
    this.serviceOrderId,
    this.inspectionId,
    this.initialTelemetry,
    this.repository,
  });

  final String? serviceOrderId;
  final String? inspectionId;
  final ServiceOrderTelemetry? initialTelemetry;
  final IInspectionRepository? repository;

  @override
  ConsumerState<InspectionWorkspaceScreen> createState() =>
      _InspectionWorkspaceScreenState();
}

class _InspectionWorkspaceScreenState
    extends ConsumerState<InspectionWorkspaceScreen> {
  late final IInspectionRepository _repository;
  bool _isLoading = true;
  bool _isSubmitting = false;

  String? _inspectionId;
  ServiceOrderTelemetry? _telemetry;
  final TextEditingController _summaryController = TextEditingController();

  // Category item checklist state
  final Map<String, _ItemDiagnosticState> _itemsState = {};
  String _selectedCategory = 'Powertrain';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ref.read(inspectionRepositoryProvider);
    _initializeChecklist();
    _loadInspectionData();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  void _initializeChecklist() {
    for (final entry in kStandardInspectionCategories.entries) {
      final category = entry.key;
      for (final item in entry.value) {
        final key = '$category::$item';
        _itemsState[key] = _ItemDiagnosticState(
          category: category,
          itemName: item,
          condition: FindingCondition.good,
          severity: SeverityLevel.low,
        );
      }
    }
  }

  Future<void> _loadInspectionData() async {
    setState(() {
      _isLoading = true;
    });

    final orderId = widget.serviceOrderId ?? 'SO-2026-0143';

    // 1. Fetch telemetry
    if (widget.initialTelemetry != null) {
      _telemetry = widget.initialTelemetry;
    } else {
      final telemetryResult = await _repository.fetchOrderTelemetry(orderId);
      if (telemetryResult.isSuccess && telemetryResult.dataOrNull != null) {
        _telemetry = telemetryResult.dataOrNull;
      } else {
        // Fallback default telemetry for demo/test mode
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
          status: 'inspection_pending',
        );
      }
    }

    // 2. Fetch or create inspection session
    if (widget.inspectionId != null) {
      _inspectionId = widget.inspectionId;
    } else {
      String? currentUserId;
      try {
        currentUserId = Supabase.instance.client.auth.currentUser?.id;
      } catch (_) {}

      final sessionResult = await _repository.createOrGetInspection(
        orderId,
        mechanicId: currentUserId,
      );

      if (sessionResult.isSuccess && sessionResult.dataOrNull != null) {
        final session = sessionResult.dataOrNull!;
        _inspectionId = session.id;
        if (session.summary != null && session.summary!.isNotEmpty) {
          _summaryController.text = session.summary!;
        }
      } else {
        _inspectionId = 'insp-${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    // 3. Load existing findings if session exists
    if (_inspectionId != null) {
      final findingsResult = await _repository.fetchInspectionFindings(
        _inspectionId!,
      );
      if (findingsResult.isSuccess && findingsResult.dataOrNull != null) {
        for (final finding in findingsResult.dataOrNull!) {
          final key = '${finding.category}::${finding.itemName}';
          if (_itemsState.containsKey(key)) {
            final state = _itemsState[key]!;
            state.condition = finding.condition;
            state.severity = finding.severity;
            state.notes = finding.notes ?? '';
            state.recommendedAction = finding.recommendedAction ?? '';
            state.isEvaluated = true;
            state.existingFindingId = finding.id;
          }
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Completeness check calculations
  int get _totalItems => _itemsState.length;
  int get _evaluatedItemsCount =>
      _itemsState.values.where((item) => item.isEvaluated).length;

  Set<String> get _touchedCategories {
    final set = <String>{};
    for (final item in _itemsState.values) {
      if (item.isEvaluated) {
        set.add(item.category);
      }
    }
    return set;
  }

  bool get _isChecklistComplete {
    if (_evaluatedItemsCount == 0) return false;
    for (final category in kStandardInspectionCategories.keys) {
      if (!_touchedCategories.contains(category)) {
        return false;
      }
    }
    return true;
  }

  void _markAllGoodInCategory(String category) {
    setState(() {
      for (final entry in _itemsState.entries) {
        if (entry.value.category == category) {
          entry.value.isEvaluated = true;
          entry.value.condition = FindingCondition.good;
          entry.value.severity = SeverityLevel.low;
        }
      }
    });
  }

  Future<void> _submitInspection() async {
    if (!_isChecklistComplete) {
      final missing = kStandardInspectionCategories.keys
          .where((cat) => !_touchedCategories.contains(cat))
          .join(', ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot submit: Untouched categories ($missing). All 5 categories must be evaluated.',
            style: AppTypography.bodySmall(color: Colors.white),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final inspId =
          _inspectionId ?? 'insp-${DateTime.now().millisecondsSinceEpoch}';

      // 1. Save all evaluated findings
      for (final item in _itemsState.values) {
        if (!item.isEvaluated) continue;

        final finding = InspectionFinding(
          id: item.existingFindingId ?? '',
          inspectionId: inspId,
          category: item.category,
          itemName: item.itemName,
          condition: item.condition,
          severity: item.severity,
          notes: item.notes.trim().isNotEmpty ? item.notes.trim() : null,
          recommendedAction: item.recommendedAction.trim().isNotEmpty
              ? item.recommendedAction.trim()
              : null,
          createdAt: DateTime.now(),
        );

        await _repository.saveFinding(finding);
      }

      // 2. Submit inspection RPC
      String? currentUserId;
      try {
        currentUserId = Supabase.instance.client.auth.currentUser?.id;
      } catch (_) {}

      final summary = _summaryController.text.trim().isNotEmpty
          ? _summaryController.text.trim()
          : 'Standard multi-point vehicle inspection completed. Diagnostic findings recorded.';

      final result = await _repository.submitInspection(
        inspId,
        summary,
        mechanicId: currentUserId,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'INSPECTION SUBMITTED',
                    style: AppTypography.headlineSmall(),
                  ),
                ),
              ],
            ),
            content: Text(
              'Inspection diagnostics successfully submitted. Service order transitioned to ESTIMATE PENDING.',
              style: AppTypography.bodyMedium(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/mechanic');
                  }
                },
                child: Text(
                  'RETURN TO WORKSPACE',
                  style: AppTypography.labelLarge(
                    color: AppColors.accentRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.exceptionOrNull?.message ?? 'Failed to submit inspection.',
              style: AppTypography.bodySmall(color: Colors.white),
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.graphitePrimary;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return ResponsiveRoleScaffold(
      roleTitle: 'Inspection Diagnostics',
      userName: 'Max Verstappen',
      userSubtitle: 'Lead Performance Tech',
      currentIndex: 2,
      navItems: RoleNavigation.mechanicNavItems,
      onNavIndexChanged: (i) => RoleNavigation.navigate(
        context,
        RoleNavigation.mechanicNavItems,
        i,
        currentIndex: 2,
      ),
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RoutePaths.mechanic);
        }
      },
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      telemetryNotice: '$_evaluatedItemsCount/$_totalItems CHECKED',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Center(
            child: StatusBadge(
              label: '$_evaluatedItemsCount/$_totalItems CHECKED',
              type: _isChecklistComplete
                  ? StatusBadgeType.success
                  : StatusBadgeType.warning,
            ),
          ),
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Vehicle Telemetry Header
                      _buildVehicleTelemetryHeader(
                        isDark,
                        textColor,
                        secondaryTextColor,
                      ),
                      const SizedBox(height: 16),

                      // 2. Category Navigation Tabs
                      _buildCategorySelector(isDark),
                      const SizedBox(height: 16),

                      // 3. Category Checklist Items
                      _buildCategoryChecklist(
                        isDark,
                        textColor,
                        secondaryTextColor,
                      ),
                      const SizedBox(height: 24),

                      // 4. Overall Master Summary Input
                      _buildSummarySection(
                        isDark,
                        textColor,
                        secondaryTextColor,
                      ),
                      const SizedBox(height: 24),

                      // 5. Submit Section & Completeness Validator
                      _buildSubmitBar(isDark),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildVehicleTelemetryHeader(
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
              // License Plate Display Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
                label: telemetry.assignedBay ?? 'BAY 02',
                type: StatusBadgeType.info,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            telemetry.vehicleDisplayName,
            style: AppTypography.headlineMedium(color: textColor),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
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
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: secondaryTextColor,
                  ),
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
            ],
          ),
          const Divider(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.report_problem_outlined,
                size: 18,
                color: AppColors.accentRed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CUSTOMER COMPLAINT / INTAKE NOTE',
                      style: AppTypography.labelSmall(
                        color: AppColors.accentRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      telemetry.customerComplaint,
                      style: AppTypography.bodyMedium(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kStandardInspectionCategories.keys.map((category) {
          final isSelected = _selectedCategory == category;
          final isTouched = _touchedCategories.contains(category);

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              key: Key('category-tab-$category'),
              onTap: () => setState(() => _selectedCategory = category),
              borderRadius: AppSpacing.roundedSmall,
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 10.0,
                ),
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
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTouched
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: isTouched
                          ? AppColors.success
                          : (isSelected
                                ? Colors.white70
                                : AppColors.textSecondaryLight),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.toUpperCase(),
                      style: AppTypography.labelMedium(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.graphitePrimary),
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryChecklist(
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final items = kStandardInspectionCategories[_selectedCategory] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              '${_selectedCategory.toUpperCase()} DIAGNOSTICS',
              style: AppTypography.labelLarge(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            // Quick action: Mark category as all good
            TextButton.icon(
              key: Key('mark-all-good-$_selectedCategory'),
              onPressed: () => _markAllGoodInCategory(_selectedCategory),
              icon: const Icon(
                Icons.done_all,
                size: 18,
                color: AppColors.success,
              ),
              label: Text(
                'MARK ALL AS GOOD',
                style: AppTypography.labelSmall(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((itemName) {
          final key = '$_selectedCategory::$itemName';
          final itemState = _itemsState[key]!;
          return _buildChecklistItemCard(
            itemState,
            isDark,
            textColor,
            secondaryTextColor,
          );
        }),
      ],
    );
  }

  Widget _buildChecklistItemCard(
    _ItemDiagnosticState itemState,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    Color conditionColor;
    switch (itemState.condition) {
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
        accentBorderLeft: itemState.isEvaluated ? conditionColor : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    itemState.itemName,
                    style: AppTypography.bodyLarge(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (itemState.isEvaluated)
                  StatusBadge(
                    label: itemState.condition.displayName.toUpperCase(),
                    color: conditionColor,
                  )
                else
                  Text(
                    'NOT EVALUATED',
                    style: AppTypography.telemetrySmall(
                      color: secondaryTextColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 1. Condition Toggles (Good, Fair, Critical)
            Text(
              'COMPONENT CONDITION',
              style: AppTypography.labelSmall(
                color: secondaryTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildConditionButton(
                  itemState: itemState,
                  targetCondition: FindingCondition.good,
                  label: 'Good',
                  color: AppColors.success,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildConditionButton(
                  itemState: itemState,
                  targetCondition: FindingCondition.fair,
                  label: 'Fair',
                  color: AppColors.warning,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildConditionButton(
                  itemState: itemState,
                  targetCondition: FindingCondition.critical,
                  label: 'Critical',
                  color: AppColors.danger,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Severity Level (Low, Medium, Urgent)
            if (itemState.condition != FindingCondition.good) ...[
              Text(
                'DIAGNOSTIC SEVERITY LEVEL',
                style: AppTypography.labelSmall(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildSeverityButton(
                    itemState: itemState,
                    targetSeverity: SeverityLevel.low,
                    label: 'Low Priority',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildSeverityButton(
                    itemState: itemState,
                    targetSeverity: SeverityLevel.medium,
                    label: 'Medium',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildSeverityButton(
                    itemState: itemState,
                    targetSeverity: SeverityLevel.urgent,
                    label: 'Urgent',
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // 3. Mechanic observation notes textfield
            Text(
              'OBSERVATION / DIAGNOSTIC NOTES',
              style: AppTypography.labelSmall(
                color: secondaryTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              key: Key('notes-input-${itemState.itemName}'),
              initialValue: itemState.notes,
              onChanged: (val) {
                itemState.notes = val;
                if (!itemState.isEvaluated && val.trim().isNotEmpty) {
                  setState(() => itemState.isEvaluated = true);
                }
              },
              decoration: InputDecoration(
                hintText: 'e.g. Pad thickness measured at 2.8mm, uneven wear on inner edge',
                filled: true,
                fillColor: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerLight,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.roundedSmall,
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
              ),
              style: AppTypography.bodySmall(color: textColor),
            ),
            const SizedBox(height: 10),

            // 4. Recommended repair action textfield
            Text(
              'RECOMMENDED REPAIR / PART ACTION',
              style: AppTypography.labelSmall(
                color: secondaryTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              key: Key('action-input-${itemState.itemName}'),
              initialValue: itemState.recommendedAction,
              onChanged: (val) {
                itemState.recommendedAction = val;
                if (!itemState.isEvaluated && val.trim().isNotEmpty) {
                  setState(() => itemState.isEvaluated = true);
                }
              },
              decoration: InputDecoration(
                hintText:
                    'e.g. Replace front brake pad set & skim/machine rotors',
                filled: true,
                fillColor: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerLight,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.roundedSmall,
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
              ),
              style: AppTypography.bodySmall(color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionButton({
    required _ItemDiagnosticState itemState,
    required FindingCondition targetCondition,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    final isSelected =
        itemState.isEvaluated && itemState.condition == targetCondition;

    return Expanded(
      child: InkWell(
        key: Key('condition-${itemState.itemName}-$label'),
        onTap: () {
          setState(() {
            itemState.condition = targetCondition;
            itemState.isEvaluated = true;
          });
        },
        borderRadius: AppSpacing.roundedSmall,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.18)
                : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: AppSpacing.roundedSmall,
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: AppTypography.labelSmall(
              color: isSelected
                  ? color
                  : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textSecondaryLight),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityButton({
    required _ItemDiagnosticState itemState,
    required SeverityLevel targetSeverity,
    required String label,
    required bool isDark,
  }) {
    final isSelected = itemState.severity == targetSeverity;
    final color = targetSeverity == SeverityLevel.urgent
        ? AppColors.danger
        : (targetSeverity == SeverityLevel.medium
              ? AppColors.warning
              : AppColors.info);

    return Expanded(
      child: InkWell(
        key: Key('severity-${itemState.itemName}-$label'),
        onTap: () => setState(() => itemState.severity = targetSeverity),
        borderRadius: AppSpacing.roundedSmall,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.16)
                : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: AppSpacing.roundedSmall,
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: AppTypography.labelSmall(
              color: isSelected
                  ? color
                  : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textSecondaryLight),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(
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
                Icons.rate_review_outlined,
                size: 20,
                color: AppColors.accentRed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'MASTER INSPECTION SUMMARY & RECOMMENDATIONS',
                  style: AppTypography.labelLarge(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Provide overall diagnostic findings that will appear on the customer estimate package.',
            style: AppTypography.bodySmall(color: secondaryTextColor),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('inspection-summary-input'),
            controller: _summaryController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'e.g. Powertrain and battery are in healthy condition. Front brake rotors have heat glazing and need resurfacing. Air filter replacement recommended.',
              filled: true,
              fillColor: isDark
                  ? AppColors.surfaceContainerDark
                  : AppColors.surfaceContainerLight,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.roundedSmall,
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            style: AppTypography.bodyMedium(color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBar(bool isDark) {
    final complete = _isChecklistComplete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!complete)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: AppSpacing.roundedSmall,
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Completeness requirement: Evaluate at least 1 item in each of the 5 categories (${_touchedCategories.length}/5 touched) before submission.',
                    style: AppTypography.bodySmall(
                      color: isDark
                          ? AppColors.warningDark
                          : AppColors.graphitePrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            key: const Key('submit-inspection-button'),
            onPressed: _isSubmitting ? null : _submitInspection,
            style: ElevatedButton.styleFrom(
              backgroundColor: complete
                  ? AppColors.accentRed
                  : AppColors.graphiteSecondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.roundedSmall,
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_turned_in_outlined, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'SUBMIT INSPECTION TO ESTIMATE PENDING',
                          style: AppTypography.labelLarge(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
