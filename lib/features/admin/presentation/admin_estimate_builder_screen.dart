import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/estimates/data/models/estimate_item_model.dart';
import 'package:pitmate/features/estimates/data/models/estimate_model.dart';
import 'package:pitmate/features/estimates/data/repositories/estimate_repository.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

/// Admin Estimate Builder Screen (UI-A09).
/// Features:
/// - Service order and vehicle telemetry
/// - Diagnostic findings review & conversion into line items
/// - Itemized editor (Part, Labor, Package) with live line totals
/// - Live financial calculations (Subtotal, 11% PPN, Discount, Grand Total)
/// - Revision tracking and status badge
/// - Direct save draft & publish actions
class AdminEstimateBuilderScreen extends ConsumerStatefulWidget {
  const AdminEstimateBuilderScreen({
    super.key,
    this.serviceOrderId,
    this.initialEstimate,
    this.initialItems,
  });

  final String? serviceOrderId;
  final EstimateModel? initialEstimate;
  final List<EstimateItemModel>? initialItems;

  @override
  ConsumerState<AdminEstimateBuilderScreen> createState() =>
      _AdminEstimateBuilderScreenState();
}

class _AdminEstimateBuilderScreenState
    extends ConsumerState<AdminEstimateBuilderScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Header info
  String _orderNumber = 'SO-202611-0001';
  String _customerName = 'Alex Pratama';
  String _customerPhone = '+62 812-3456-7890';
  String _vehicleDisplay = 'Honda Civic Type R (FL5)';
  String _licensePlate = 'B 5678 CIV';
  String _complaint = 'Grinding noise from front axle during high-speed deceleration';
  String _assignedBay = 'Bay 02';
  int _odometerKm = 8200;

  // Diagnostic findings from inspection
  final List<Map<String, dynamic>> _findings = [
    {
      'item_name': 'Front Brake Pads (Brembo 4-pot)',
      'condition': 'critical',
      'severity': 'urgent',
      'notes': 'Pad material worn to 1.8mm. Rotor showing minor thermal discoloration.',
      'recommended_action': 'Replace front brake pad set immediately and bed-in.',
      'suggested_type': EstimateItemType.part,
      'suggested_price_cents': 220000000,
    },
    {
      'item_name': 'Brake Fluid Flush & Bleed',
      'condition': 'fair',
      'severity': 'medium',
      'notes': 'Moisture level 2.8%, boiling point reduced.',
      'recommended_action': 'Flush and replace with Motul RBF 660 synthetic fluid.',
      'suggested_type': EstimateItemType.part,
      'suggested_price_cents': 45000000,
    },
    {
      'item_name': 'Brake Overhaul Labor',
      'condition': 'good',
      'severity': 'low',
      'notes': 'Caliper guide pins require cleaning and high-temp synthetic grease.',
      'recommended_action': 'Perform caliper overhaul service.',
      'suggested_type': EstimateItemType.labor,
      'suggested_price_cents': 50000000,
    },
  ];

  late EstimateModel _estimate;
  late List<EstimateItemModel> _items;
  late TextEditingController _notesController;
  late TextEditingController _discountController;

  @override
  void initState() {
    super.initState();
    _initEstimate();
    _notesController = TextEditingController(text: _estimate.notes ?? '');
    final discountIdr = EstimateModel.centsToIdr(_estimate.discountCents);
    _discountController = TextEditingController(
      text: discountIdr > 0 ? discountIdr.toString() : '0',
    );
    _loadLiveOrderAndEstimate();
  }

  void _initEstimate() {
    if (widget.initialEstimate != null) {
      _estimate = widget.initialEstimate!;
      _items = widget.initialItems != null
          ? List.from(widget.initialItems!)
          : [];
    } else {
      _estimate = EstimateModel(
        id: '',
        serviceOrderId: widget.serviceOrderId ?? 'mock-order-id',
        revisionNumber: 1,
        status: EstimateStatus.draft,
        subtotalCents: 315000000,
        taxCents: 34650000,
        discountCents: 0,
        totalCents: 349650000,
        notes: 'All parts OEM specification. Includes professional brake caliper service and track bleed.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _items = [
        EstimateItemModel.create(
          id: 'item-1',
          estimateId: _estimate.id,
          itemType: EstimateItemType.part,
          description: 'Honda OEM Brembo Front Brake Pad Set (FL5)',
          quantity: 1,
          unitPriceCents: 220000000,
          isOptional: false,
        ),
        EstimateItemModel.create(
          id: 'item-2',
          estimateId: _estimate.id,
          itemType: EstimateItemType.part,
          description: 'Motul RBF 660 High-Temp Racing Brake Fluid (500ml)',
          quantity: 2,
          unitPriceCents: 22500000,
          isOptional: false,
        ),
        EstimateItemModel.create(
          id: 'item-3',
          estimateId: _estimate.id,
          itemType: EstimateItemType.labor,
          description: 'Front Brake Overhaul & Precision Bleeding Service',
          quantity: 1,
          unitPriceCents: 50000000,
          isOptional: false,
        ),
      ];
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadLiveOrderAndEstimate() async {
    final orderId = widget.serviceOrderId;
    if (orderId == null || orderId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(estimateRepositoryProvider);

      // Load Service Order summary
      final orderResult = await repo.fetchServiceOrderSummary(orderId);
      orderResult.when(
        success: (orderData) {
          if (orderData != null && mounted) {
            final cust = orderData['customers'] as Map<String, dynamic>?;
            final veh = orderData['vehicles'] as Map<String, dynamic>?;
            setState(() {
              _orderNumber = (orderData['order_number'] as String?) ?? _orderNumber;
              _customerName = (cust?['full_name'] as String?) ?? _customerName;
              _customerPhone = (cust?['phone_number'] as String?) ?? _customerPhone;
              if (veh != null) {
                _vehicleDisplay = '${veh['make'] ?? ''} ${veh['model'] ?? ''}';
                _licensePlate = (veh['license_plate'] as String?) ?? _licensePlate;
              }
              _complaint = (orderData['customer_complaint'] as String?) ?? _complaint;
              _assignedBay = (orderData['assigned_bay'] as String?) ?? _assignedBay;
              _odometerKm = (orderData['odometer'] as int?) ?? _odometerKm;
            });
          }
        },
        failure: (_) {},
      );

      // Load Estimate for order
      final estResult = await repo.fetchEstimateByOrderId(orderId);
      await estResult.when(
        success: (existingEst) async {
          if (existingEst != null && mounted) {
            final itemsResult = await repo.fetchEstimateItems(existingEst.id);
            itemsResult.when(
              success: (loadedItems) {
                if (mounted) {
                  setState(() {
                    _estimate = existingEst;
                    _items = loadedItems;
                    _notesController.text = existingEst.notes ?? '';
                    final dIdr = EstimateModel.centsToIdr(existingEst.discountCents);
                    _discountController.text = dIdr > 0 ? dIdr.toString() : '0';
                  });
                }
              },
              failure: (_) {},
            );
          }
        },
        failure: (_) {},
      );
    } catch (e) {
      debugPrint('Fallback loading estimate: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _recalculateTotals() {
    final subtotal = EstimateModel.calculateSubtotalFromItems(_items);
    final tax = EstimateModel.calculateTax(subtotal);
    final discountIdr = int.tryParse(_discountController.text.trim()) ?? 0;
    final discountCents = EstimateModel.idrToCents(discountIdr);
    final total = EstimateModel.calculateGrandTotal(subtotal, tax, discountCents);

    setState(() {
      _estimate = _estimate.copyWith(
        subtotalCents: subtotal,
        taxCents: tax,
        discountCents: discountCents,
        totalCents: total,
        notes: _notesController.text.trim(),
      );
    });
  }

  void _addItem(EstimateItemType type, [String? desc, int? priceCents]) {
    final newItem = EstimateItemModel.create(
      id: 'temp-${DateTime.now().microsecondsSinceEpoch}',
      estimateId: _estimate.id,
      itemType: type,
      description: desc ?? 'New ${type.displayName}',
      quantity: 1,
      unitPriceCents: priceCents ?? EstimateModel.idrToCents(100000),
      isOptional: false,
    );

    setState(() {
      _items.add(newItem);
    });
    _recalculateTotals();
  }

  void _removeItem(int index) {
    if (index < 0 || index >= _items.length) return;
    setState(() {
      _items.removeAt(index);
    });
    _recalculateTotals();
  }

  void _updateItemQuantity(int index, int delta) {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    final nextQty = item.quantity + delta;
    if (nextQty <= 0) return;

    setState(() {
      _items[index] = item.copyWith(
        quantity: nextQty,
        totalPriceCents: nextQty * item.unitPriceCents,
      );
    });
    _recalculateTotals();
  }

  void _updateItemDescription(int index, String desc) {
    if (index < 0 || index >= _items.length) return;
    setState(() {
      _items[index] = _items[index].copyWith(description: desc);
    });
  }

  void _updateItemUnitPrice(int index, int unitPriceIdr) {
    if (index < 0 || index >= _items.length) return;
    final cents = EstimateModel.idrToCents(unitPriceIdr);
    setState(() {
      _items[index] = _items[index].copyWith(
        unitPriceCents: cents,
        totalPriceCents: _items[index].quantity * cents,
      );
    });
    _recalculateTotals();
  }

  void _toggleItemOptional(int index, bool val) {
    if (index < 0 || index >= _items.length) return;
    setState(() {
      _items[index] = _items[index].copyWith(isOptional: val);
    });
    _recalculateTotals();
  }

  Future<void> _saveDraft() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    _recalculateTotals();

    try {
      final repo = ref.read(estimateRepositoryProvider);
      final result = await repo.createEstimateDraft(_estimate, _items);

      result.when(
        success: (saved) {
          if (mounted) {
            setState(() {
              _estimate = saved;
              _successMessage = 'Estimate draft saved successfully.';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Draft saved (${saved.revisionLabel})'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        failure: (err) {
          if (mounted) {
            setState(() {
              _errorMessage = err.message;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save draft: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _publishEstimate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    _recalculateTotals();

    try {
      final repo = ref.read(estimateRepositoryProvider);
      // First ensure draft is persisted
      final draftResult = await repo.createEstimateDraft(_estimate, _items);

      await draftResult.when(
        success: (saved) async {
          final publishResult = await repo.publishEstimate(saved.id);
          publishResult.when(
            success: (published) {
              if (mounted) {
                setState(() {
                  _estimate = published;
                  _successMessage = 'Estimate published to customer.';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Estimate published to customer.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            failure: (err) {
              if (mounted) {
                setState(() => _errorMessage = err.message);
              }
            },
          );
        },
        failure: (err) {
          if (mounted) {
            setState(() => _errorMessage = err.message);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to publish: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
    final mutedColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return ResponsiveRoleScaffold(
      roleTitle: 'Estimate Builder',
      userName: 'Toto Wolf',
      userSubtitle: 'Workshop Director',
      showBackButton: true,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RoutePaths.admin);
        }
      },
      navItems: RoleNavigation.adminNavItems,
      currentIndex: 3,
      onNavIndexChanged: (index) => RoleNavigation.navigate(context, RoleNavigation.adminNavItems, index, currentIndex: 3),
      telemetryNotice: 'BAY: $_assignedBay • ${_items.length} ITEMS',
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                key: Key('estimate_builder_loading'),
                color: AppColors.racingRed,
              ),
            )
          : SingleChildScrollView(
              padding: AppSpacing.p24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Banner: Status, Revision, Actions
                  _buildHeaderBanner(context, isDark, textColor, mutedColor),
                  const SizedBox(height: 16),

                  if (_errorMessage != null) ...[
                    Container(
                      key: const Key('estimate_builder_error_banner'),
                      padding: AppSpacing.p12,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: AppSpacing.roundedSmall,
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodyMedium(color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_successMessage != null) ...[
                    Container(
                      key: const Key('estimate_builder_success_banner'),
                      padding: AppSpacing.p12,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: AppSpacing.roundedSmall,
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: AppTypography.bodyMedium(color: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Section 1: Order & Vehicle Telemetry
                  _buildOrderTelemetryCard(context, isDark, textColor, mutedColor, borderColor),
                  const SizedBox(height: 16),

                  // Section 2: Inspection Findings Summary
                  _buildFindingsCard(context, isDark, textColor, mutedColor, borderColor),
                  const SizedBox(height: 16),

                  // Section 3: Itemized Lines Editor
                  _buildItemizedLinesCard(context, isDark, textColor, mutedColor, borderColor),
                  const SizedBox(height: 16),

                  // Section 4: Workshop Notes & Financial Summary
                  _buildFinancialSummarySection(context, isDark, textColor, mutedColor, borderColor),
                  const SizedBox(height: 32),

                  // Bottom Action Buttons (for high visibility)
                  _buildBottomActionButtons(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderBanner(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    return PitCard(
      padding: AppSpacing.p16,
      accentBorderLeft: AppColors.racingRed,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'ESTIMATE BUILDER',
                style: AppTypography.headlineMedium(color: textColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.racingRed.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.roundedSmall,
                  border: Border.all(color: AppColors.racingRed.withValues(alpha: 0.35)),
                ),
                child: Text(
                  _estimate.revisionLabel.toUpperCase(),
                  style: AppTypography.telemetrySmall(
                    color: AppColors.racingRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              StatusBadge(
                label: _estimate.status.displayName,
                type: _getStatusBadgeType(_estimate.status),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('btn_save_draft'),
                onPressed: _isLoading ? null : _saveDraft,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save Draft'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, 48),
                ),
              ),
              ElevatedButton.icon(
                key: const Key('btn_publish_estimate'),
                onPressed: _isLoading ? null : _publishEstimate,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Publish to Customer'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(180, 48),
                  backgroundColor: AppColors.racingRed,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  StatusBadgeType _getStatusBadgeType(EstimateStatus status) {
    switch (status) {
      case EstimateStatus.draft:
        return StatusBadgeType.neutral;
      case EstimateStatus.sent:
        return StatusBadgeType.warning;
      case EstimateStatus.approved:
        return StatusBadgeType.success;
      case EstimateStatus.partiallyApproved:
        return StatusBadgeType.info;
      case EstimateStatus.rejected:
        return StatusBadgeType.danger;
      case EstimateStatus.superseded:
        return StatusBadgeType.neutral;
    }
  }

  Widget _buildOrderTelemetryCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    return PitCard(
      padding: AppSpacing.p16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed, size: 18, color: AppColors.racingRed),
                  const SizedBox(width: 8),
                  Text(
                    'SERVICE ORDER TELEMETRY',
                    style: AppTypography.labelLarge(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                  borderRadius: AppSpacing.roundedSmall,
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  _orderNumber,
                  style: AppTypography.telemetryMedium(
                    color: AppColors.racingRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _buildTelemetryField('CUSTOMER', _customerName, Icons.person_outline, mutedColor, textColor),
              _buildTelemetryField('PHONE', _customerPhone, Icons.phone_outlined, mutedColor, textColor),
              _buildTelemetryField('VEHICLE', _vehicleDisplay, Icons.directions_car_outlined, mutedColor, textColor),
              _buildTelemetryField('PLATE', _licensePlate, Icons.badge_outlined, mutedColor, textColor, isMono: true),
              _buildTelemetryField('ODOMETER', '$_odometerKm KM', Icons.timeline, mutedColor, textColor, isMono: true),
              _buildTelemetryField('BAY', _assignedBay, Icons.warehouse_outlined, mutedColor, textColor),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: AppSpacing.p12,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
              borderRadius: AppSpacing.roundedSmall,
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.report_problem_outlined, size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'Customer Complaint: ',
                      style: AppTypography.bodySmall(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(
                          text: _complaint,
                          style: AppTypography.bodySmall(color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryField(
    String label,
    String value,
    IconData icon,
    Color mutedColor,
    Color textColor, {
    bool isMono = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: mutedColor),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.labelSmall(color: mutedColor)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: isMono
              ? AppTypography.telemetryMedium(color: textColor, fontWeight: FontWeight.w600)
              : AppTypography.bodyMedium(color: textColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildFindingsCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    return PitCard(
      padding: AppSpacing.p16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.health_and_safety_outlined, size: 18, color: AppColors.info),
                  const SizedBox(width: 8),
                  Text(
                    'DIAGNOSTIC FINDINGS & INSPECTION SUMMARY',
                    style: AppTypography.labelLarge(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                '${_findings.length} FINDINGS DETECTED',
                style: AppTypography.telemetrySmall(color: mutedColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _findings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final finding = _findings[index];
              final severity = finding['severity'] as String? ?? 'low';
              final badgeType = severity == 'urgent'
                  ? StatusBadgeType.danger
                  : (severity == 'medium' ? StatusBadgeType.warning : StatusBadgeType.info);

              return Container(
                padding: AppSpacing.p12,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                  borderRadius: AppSpacing.roundedSmall,
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(label: severity.toUpperCase(), type: badgeType),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            finding['item_name'] as String,
                            style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            finding['notes'] as String,
                            style: AppTypography.bodySmall(color: mutedColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Action: ${finding['recommended_action']}',
                            style: AppTypography.bodySmall(
                              color: AppColors.racingRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(110, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Line'),
                      onPressed: () {
                        _addItem(
                          finding['suggested_type'] as EstimateItemType,
                          finding['item_name'] as String,
                          finding['suggested_price_cents'] as int?,
                        );
                      },
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

  Widget _buildItemizedLinesCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    return PitCard(
      padding: AppSpacing.p16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.list_alt, size: 18, color: AppColors.racingRed),
                  const SizedBox(width: 8),
                  Text(
                    'ITEMIZED LINES EDITOR',
                    style: AppTypography.labelLarge(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  OutlinedButton.icon(
                    key: const Key('btn_add_part'),
                    onPressed: () => _addItem(EstimateItemType.part),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+ Part'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(88, 48)),
                  ),
                  OutlinedButton.icon(
                    key: const Key('btn_add_labor'),
                    onPressed: () => _addItem(EstimateItemType.labor),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+ Labor'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(88, 48)),
                  ),
                  OutlinedButton.icon(
                    key: const Key('btn_add_package'),
                    onPressed: () => _addItem(EstimateItemType.package),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+ Package'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(88, 48)),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No line items added yet. Click "+ Part" or "+ Labor" to create estimate lines.',
                  style: AppTypography.bodyMedium(color: mutedColor),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildLineItemRow(context, index, isDark, textColor, mutedColor, borderColor);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLineItemRow(
    BuildContext context,
    int index,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    final item = _items[index];

    return Container(
      key: Key('estimate_item_row_$index'),
      padding: AppSpacing.p12,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
        borderRadius: AppSpacing.roundedSmall,
        border: Border.all(
          color: item.isOptional
              ? AppColors.warning.withValues(alpha: 0.5)
              : borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Item Type Selector
              DropdownButton<EstimateItemType>(
                key: Key('item_type_dropdown_$index'),
                value: item.itemType,
                underline: const SizedBox(),
                items: EstimateItemType.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(
                      t.displayName.toUpperCase(),
                      style: AppTypography.labelMedium(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newType) {
                  if (newType != null) {
                    setState(() {
                      _items[index] = item.copyWith(itemType: newType);
                    });
                  }
                },
              ),
              const SizedBox(width: 8),

              // Description input
              Expanded(
                child: TextFormField(
                  key: Key('item_desc_field_$index'),
                  initialValue: item.description,
                  decoration: InputDecoration(
                    hintText: 'Item description or part SKU',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: AppSpacing.roundedSmall),
                  ),
                  style: AppTypography.bodyMedium(color: textColor),
                  onChanged: (val) => _updateItemDescription(index, val),
                ),
              ),
              const SizedBox(width: 8),

              // Delete button (min 48px touch target)
              IconButton(
                key: Key('btn_delete_item_$index'),
                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                tooltip: 'Delete Line',
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              // Quantity stepper
              Container(
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.roundedSmall,
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: Key('btn_decrement_qty_$index'),
                      icon: const Icon(Icons.remove, size: 16),
                      tooltip: 'Decrease Quantity',
                      onPressed: () => _updateItemQuantity(index, -1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        key: Key('item_qty_text_$index'),
                        style: AppTypography.telemetryMedium(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      key: Key('btn_increment_qty_$index'),
                      icon: const Icon(Icons.add, size: 16),
                      tooltip: 'Increase Quantity',
                      onPressed: () => _updateItemQuantity(index, 1),
                    ),
                  ],
                ),
              ),

              // Unit price input in IDR
              SizedBox(
                width: 170,
                child: TextFormField(
                  key: Key('item_unit_price_field_$index'),
                  initialValue: EstimateModel.centsToIdr(item.unitPriceCents).toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    labelText: 'Unit Price (IDR)',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: AppSpacing.roundedSmall),
                  ),
                  style: AppTypography.telemetryMedium(color: textColor),
                  onChanged: (val) {
                    final price = int.tryParse(val) ?? 0;
                    _updateItemUnitPrice(index, price);
                  },
                ),
              ),

              // Line total display
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('LINE TOTAL', style: AppTypography.labelSmall(color: mutedColor)),
                  Text(
                    item.formattedTotalPrice,
                    key: Key('item_total_price_text_$index'),
                    style: AppTypography.telemetryMedium(
                      color: AppColors.racingRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              // Optional toggle
              Tooltip(
                message: 'Mark as optional customer recommendation',
                child: FilterChip(
                  key: Key('item_optional_chip_$index'),
                  label: const Text('OPTIONAL'),
                  selected: item.isOptional,
                  onSelected: (val) => _toggleItemOptional(index, val),
                  selectedColor: AppColors.warning.withValues(alpha: 0.25),
                  checkmarkColor: AppColors.warning,
                  labelStyle: AppTypography.telemetrySmall(
                    color: item.isOptional ? AppColors.warning : mutedColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummarySection(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PitCard(
          padding: AppSpacing.p16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WORKSHOP NOTES FOR CUSTOMER',
                style: AppTypography.labelLarge(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('field_estimate_notes'),
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Include warranties, turnaround timeframe, or technician recommendations...',
                  border: OutlineInputBorder(borderRadius: AppSpacing.roundedSmall),
                ),
                style: AppTypography.bodyMedium(color: textColor),
                onChanged: (val) {
                  setState(() {
                    _estimate = _estimate.copyWith(notes: val.trim());
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PitCard(
          padding: AppSpacing.p16,
          accentBorderLeft: AppColors.racingRed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FINANCIAL SUMMARY',
                style: AppTypography.labelLarge(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(height: 20),
              _buildSummaryRow('SUBTOTAL (EXCL. TAX)', _estimate.formattedSubtotal, textColor, isMono: true),
              const SizedBox(height: 8),
              _buildSummaryRow(
                'PPN (11% TAX)',
                _estimate.formattedTax,
                isDark ? AppColors.infoDark : AppColors.info,
                isMono: true,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('DISCOUNT (IDR)', style: AppTypography.bodyMedium(color: mutedColor)),
                  SizedBox(
                    width: 140,
                    child: TextFormField(
                      key: const Key('field_discount_input'),
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: AppSpacing.roundedSmall),
                      ),
                      style: AppTypography.telemetryMedium(color: textColor),
                      onChanged: (val) => _recalculateTotals(),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GRAND TOTAL',
                    style: AppTypography.headlineSmall(
                      color: textColor,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _estimate.formattedTotal,
                    key: const Key('text_grand_total'),
                    style: AppTypography.telemetryLarge(
                      color: AppColors.racingRed,
                      fontWeight: FontWeight.w700,
                    ).copyWith(fontSize: 22),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, {bool isMono = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium(color: color)),
        Text(
          value,
          style: isMono
              ? AppTypography.telemetryMedium(color: color, fontWeight: FontWeight.w600)
              : AppTypography.bodyMedium(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildBottomActionButtons() {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 16,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          key: const Key('btn_bottom_save_draft'),
          onPressed: _isLoading ? null : _saveDraft,
          icon: const Icon(Icons.save_outlined, size: 20),
          label: const Text('Save Draft'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(140, 52),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          key: const Key('btn_bottom_publish'),
          onPressed: _isLoading ? null : _publishEstimate,
          icon: const Icon(Icons.send_rounded, size: 20),
          label: const Text('Publish Estimate to Customer'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(240, 52),
            backgroundColor: AppColors.racingRed,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
