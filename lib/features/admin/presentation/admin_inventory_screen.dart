import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:pitmate/features/inventory/data/models/inventory_transaction_model.dart';
import 'package:pitmate/features/inventory/data/models/part_model.dart';
import 'package:pitmate/features/inventory/data/repositories/inventory_repository.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/pit_error_dialog.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

/// Admin Inventory & Stock Management Screen (UI-A11 & UI-A12).
class AdminInventoryScreen extends ConsumerStatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  ConsumerState<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends ConsumerState<AdminInventoryScreen> {
  final InventoryRepository _repo = InventoryRepository();
  bool _isLoading = true;
  List<PartModel> _parts = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  Future<void> _loadParts() async {
    setState(() => _isLoading = true);
    try {
      final parts = await _repo.fetchParts(
        categorySearch: _selectedCategory,
        query: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _parts = parts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _parts = [];
          _isLoading = false;
        });
      }
    }
  }

  void _onNavChanged(int index) {
    RoleNavigation.navigate(context, RoleNavigation.adminNavItems, index, currentIndex: 5);
  }

  String _formatRupiah(int cents) {
    final value = cents ~/ 100;
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // --- Modals ---

  Future<void> _openCreateOrEditPartDialog([PartModel? existing]) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skuController = TextEditingController(text: existing?.sku ?? '');
    final nameController = TextEditingController(text: existing?.name ?? '');
    final catController = TextEditingController(text: existing?.category ?? 'lubricants');
    final uomController = TextEditingController(text: existing?.unitOfMeasurement ?? 'pcs');
    final costController = TextEditingController(
        text: existing != null ? (existing.purchaseCostCents ~/ 100).toString() : '0');
    final priceController = TextEditingController(
        text: existing != null ? (existing.sellingPriceCents ~/ 100).toString() : '0');
    final minStockController = TextEditingController(
        text: existing != null ? existing.minimumStock.toString() : '5');

    String? validationError;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          title: Text(
            existing == null ? 'NEW CATALOG PART' : 'EDIT PART: ${existing.sku}',
            style: AppTypography.headlineSmall(
              color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (validationError != null)
                    PitValidationBanner(
                      message: validationError!,
                      onDismiss: () => setDialogState(() => validationError = null),
                    ),
                  TextField(
                    controller: skuController,
                    enabled: existing == null,
                    decoration: const InputDecoration(
                      labelText: 'SKU / Part Code *',
                      hintText: 'e.g. OIL-5W30-SYN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Part Name *',
                      hintText: 'e.g. Synthetic Engine Oil 5W-30',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: catController,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            hintText: 'lubricants, brakes, filters',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: uomController,
                          decoration: const InputDecoration(
                            labelText: 'Unit of Measure',
                            hintText: 'pcs, liter, set',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: costController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Purchase Cost (Rp)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Selling Price (Rp) *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: minStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minimum Safety Stock',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
              onPressed: () async {
                if (skuController.text.trim().isEmpty ||
                    nameController.text.trim().isEmpty ||
                    priceController.text.trim().isEmpty) {
                  setDialogState(() {
                    validationError = 'SKU, Name, and Selling Price are required.';
                  });
                  return;
                }

                final costCents = (int.tryParse(costController.text.trim()) ?? 0) * 100;
                final priceCents = (int.tryParse(priceController.text.trim()) ?? 0) * 100;
                final minStock = int.tryParse(minStockController.text.trim()) ?? 0;

                try {
                  if (existing == null) {
                    await _repo.createPart(
                      sku: skuController.text.trim(),
                      name: nameController.text.trim(),
                      category: catController.text.trim(),
                      unitOfMeasurement: uomController.text.trim(),
                      purchaseCostCents: costCents,
                      sellingPriceCents: priceCents,
                      minimumStock: minStock,
                    );
                  } else {
                    await _repo.updatePart(
                      id: existing.id,
                      sku: skuController.text.trim(),
                      name: nameController.text.trim(),
                      category: catController.text.trim(),
                      unitOfMeasurement: uomController.text.trim(),
                      sellingPriceCents: priceCents,
                      minimumStock: minStock,
                    );
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadParts();
                } catch (e) {
                  setDialogState(() {
                    validationError = e.toString().replaceAll('Exception: ', '');
                  });
                }
              },
              child: Text(existing == null ? 'SAVE PART' : 'UPDATE PART'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReceiveStockDialog(PartModel part) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qtyController = TextEditingController(text: '10');
    final costController = TextEditingController(text: (part.purchaseCostCents ~/ 100).toString());
    final refController = TextEditingController(text: 'PO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final notesController = TextEditingController(text: 'Supplier intake');

    int previewNewAvgCents = part.purchaseCostCents;
    String? validationError;

    void updatePreview(void Function(void Function()) setDialogState) {
      final qty = int.tryParse(qtyController.text.trim()) ?? 0;
      final unitCost = (int.tryParse(costController.text.trim()) ?? 0) * 100;
      if (qty > 0) {
        final totalUnits = part.quantityOnHand + qty;
        final totalVal = (part.quantityOnHand * part.purchaseCostCents) + (qty * unitCost);
        setDialogState(() {
          previewNewAvgCents = (totalVal / totalUnits).round();
        });
      }
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          title: Text(
            'RECEIVE STOCK: ${part.sku}',
            style: AppTypography.headlineSmall(
              color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (validationError != null)
                    PitValidationBanner(
                      message: validationError!,
                      onDismiss: () => setDialogState(() => validationError = null),
                    ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: (isDark ? AppColors.borderDark : AppColors.borderLight)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(part.name, style: AppTypography.labelLarge().copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          'Current On-Hand: ${part.quantityOnHand} ${part.unitOfMeasurement}  |  Current Cost: ${_formatRupiah(part.purchaseCostCents)}',
                          style: AppTypography.bodySmall(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Quantity (${part.unitOfMeasurement}) *',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => updatePreview(setDialogState),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: costController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Unit Cost (Rp) *',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => updatePreview(setDialogState),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Real-time Weighted-Average Calculation Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Projected New Avg Cost:', style: AppTypography.bodySmall().copyWith(fontWeight: FontWeight.w600)),
                        Text(
                          _formatRupiah(previewNewAvgCents),
                          style: AppTypography.labelLarge(
                            color: AppColors.info,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: refController,
                    decoration: const InputDecoration(
                      labelText: 'Supplier PO Reference',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Intake Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () async {
                final qty = int.tryParse(qtyController.text.trim()) ?? 0;
                final unitCost = (int.tryParse(costController.text.trim()) ?? 0) * 100;

                if (qty <= 0) {
                  setDialogState(() => validationError = 'Quantity must be greater than zero.');
                  return;
                }

                try {
                  await _repo.receiveStock(
                    partId: part.id,
                    quantity: qty,
                    unitCostCents: unitCost,
                    supplierRef: refController.text.trim(),
                    notes: notesController.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadParts();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Received $qty units of ${part.sku}. Weighted-average cost updated.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  setDialogState(() {
                    validationError = e.toString().replaceAll('Exception: ', '');
                  });
                }
              },
              child: const Text('RECEIVE STOCK'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAdjustStockDialog(PartModel part) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qtyController = TextEditingController();
    final reasonController = TextEditingController();
    String? validationError;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          title: Text(
            'ADJUST STOCK: ${part.sku}',
            style: AppTypography.headlineSmall(
              color: isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (validationError != null)
                    PitValidationBanner(
                      message: validationError!,
                      onDismiss: () => setDialogState(() => validationError = null),
                    ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: (isDark ? AppColors.borderDark : AppColors.borderLight)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(part.name, style: AppTypography.labelLarge().copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          'On-Hand: ${part.quantityOnHand} | Reserved: ${part.quantityReserved} | Available: ${part.quantityAvailable}',
                          style: AppTypography.bodySmall(
                            color: part.quantityAvailable <= 0 ? AppColors.accentRed : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: qtyController,
                    keyboardType: const TextInputType.numberWithOptions(signed: true),
                    decoration: InputDecoration(
                      labelText: 'Quantity Change (+ or -) *',
                      hintText: 'e.g. -2 for damage or 5 for found stock',
                      border: const OutlineInputBorder(),
                      suffixText: part.unitOfMeasurement,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Mandatory Audit Reason *',
                      hintText: 'e.g. Handling damage in Bay 02 or quarterly count correction',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
              onPressed: () async {
                final change = int.tryParse(qtyController.text.trim()) ?? 0;
                final reason = reasonController.text.trim();

                if (change == 0) {
                  setDialogState(() => validationError = 'Quantity change cannot be zero.');
                  return;
                }
                if (reason.isEmpty) {
                  setDialogState(() => validationError = 'Audit reason is mandatory for all manual adjustments.');
                  return;
                }

                // Check negative available stock invariant before sending
                if (part.quantityOnHand + change < part.quantityReserved) {
                  setDialogState(() {
                    validationError = 'Adjustment of $change would result in negative available stock (${part.quantityReserved} reserved).';
                  });
                  return;
                }

                try {
                  await _repo.adjustStock(
                    partId: part.id,
                    quantityChange: change,
                    reason: reason,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadParts();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Stock adjusted for ${part.sku}. Ledger recorded.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (!mounted) return;
                  showPitErrorDialog(
                    context,
                    title: 'STOCK ADJUSTMENT REJECTED',
                    message: e.toString().replaceAll('Exception: ', ''),
                    hint: 'Ensure that adjusted on-hand inventory never falls below reserved job quantities.',
                  );
                }
              },
              child: const Text('CONFIRM ADJUSTMENT'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openHistoryDialog(PartModel part) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: Text(
          'LEDGER HISTORY: ${part.sku}',
          style: AppTypography.headlineSmall().copyWith(fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: 600,
          height: 400,
          child: FutureBuilder<List<InventoryTransactionModel>>(
            future: _repo.fetchTransactionHistory(part.id),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final txs = snapshot.data ?? [];
              if (txs.isEmpty) {
                return Center(
                  child: Text('No ledger history recorded for this part yet.', style: AppTypography.bodyMedium()),
                );
              }
              return ListView.separated(
                itemCount: txs.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (ctx, idx) {
                  final tx = txs[idx];
                  final isPositive = tx.quantityChange > 0;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: isPositive
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.accentRed.withValues(alpha: 0.15),
                      child: Icon(
                        isPositive ? Icons.add : Icons.remove,
                        color: isPositive ? AppColors.success : AppColors.accentRed,
                        size: 18,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tx.typeLabel, style: AppTypography.labelLarge().copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          '${isPositive ? '+' : ''}${tx.quantityChange} ${part.unitOfMeasurement}',
                          style: AppTypography.labelLarge(
                            color: isPositive ? AppColors.success : AppColors.accentRed,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tx.reason != null)
                          Text('Reason: ${tx.reason!}', style: AppTypography.bodySmall()),
                        Text(
                          'Balance after: ${tx.balanceAfterOnHand} | Unit Cost: ${_formatRupiah(tx.unitCostCents)} | ${tx.createdAt.toLocal().toString().substring(0, 16)}',
                          style: AppTypography.bodySmall(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  // --- Screen Build ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    final totalParts = _parts.length;
    final lowStockCount = _parts.where((p) => p.isLowStock).length;
    final outOfStockCount = _parts.where((p) => p.isOutOfStock).length;
    final totalValuation = _parts.fold<int>(0, (sum, p) => sum + p.totalValuationCents);
    final auth = ref.watch(authNotifierProvider);
    final userName =
        auth is AuthAuthenticated ? auth.userProfile.fullName : 'User';

    return ResponsiveRoleScaffold(
      roleTitle: 'Inventory & Stock Management',
      userName: userName,
      userSubtitle: 'Workshop Director',
      currentIndex: 5,
      onNavIndexChanged: _onNavChanged,
      navItems: RoleNavigation.adminNavItems,
      telemetryNotice: 'INVENTORY VALUATION: ${_formatRupiah(totalValuation)}',
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      actions: [
        const NotificationBellButton(),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Inventory',
          onPressed: _loadParts,
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Metric Telemetry Cards
                    _buildMetricCards(totalParts, lowStockCount, outOfStockCount, totalValuation, isNarrow, textColor),
                    const SizedBox(height: 18),

                    // 2. Search & Filter Bar + Add Part Action
                    _buildFilterBar(isDark, isNarrow),
                    const SizedBox(height: 16),

                    // 3. Catalog Inventory List (Mobile Cards vs Desktop Table)
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_parts.isEmpty)
                      PitCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 48, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                const SizedBox(height: 12),
                                Text('No parts match the selected filter.', style: AppTypography.headlineSmall()),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      isNarrow
                          ? _buildMobilePartsList(isDark)
                          : _buildDesktopPartsTable(isDark, textColor),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCards(int total, int lowStock, int outOfStock, int totalValuation, bool isNarrow, Color textColor) {
    final cards = [
      _buildSingleMetric('TOTAL PARTS', '$total', Icons.category_outlined, AppColors.info),
      _buildSingleMetric('LOW STOCK', '$lowStock', Icons.warning_amber_outlined, AppColors.warning),
      _buildSingleMetric('OUT OF STOCK', '$outOfStock', Icons.error_outline, AppColors.accentRed),
      _buildSingleMetric('TOTAL VALUATION', _formatRupiah(totalValuation), Icons.account_balance_wallet_outlined, AppColors.success),
    ];

    if (isNarrow) {
      return Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: c)).toList(),
      );
    }

    return Row(
      children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: c))).toList(),
    );
  }

  Widget _buildSingleMetric(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PitCard(
      accentBorderLeft: color,
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodySmall(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(value, style: AppTypography.headlineMedium().copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark, bool isNarrow) {
    final categories = ['all', 'lubricants', 'filters', 'brakes', 'fluids', 'ignition'];

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search SKU or part name...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val);
              _loadParts();
            },
          ),
        ),
        const SizedBox(width: 10),
        DropdownButton<String>(
          value: _selectedCategory,
          items: categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase(), style: AppTypography.labelLarge())))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedCategory = val);
              _loadParts();
            }
          },
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: Text(isNarrow ? 'NEW' : 'NEW PART'),
          onPressed: () => _openCreateOrEditPartDialog(),
        ),
      ],
    );
  }

  Widget _buildDesktopPartsTable(bool isDark, Color textColor) {
    return PitCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('SKU / PART')),
            DataColumn(label: Text('CATEGORY')),
            DataColumn(label: Text('ON HAND')),
            DataColumn(label: Text('RESERVED')),
            DataColumn(label: Text('AVAILABLE')),
            DataColumn(label: Text('UNIT COST')),
            DataColumn(label: Text('RETAIL PRICE')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: _parts.map((p) {
            return DataRow(
              cells: [
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(p.sku, style: AppTypography.labelLarge(color: AppColors.accentRed).copyWith(fontWeight: FontWeight.w700)),
                      Text(p.name, style: AppTypography.bodySmall(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
                DataCell(Text(p.category.toUpperCase(), style: AppTypography.bodySmall())),
                DataCell(Text('${p.quantityOnHand} ${p.unitOfMeasurement}', style: AppTypography.bodyMedium().copyWith(fontWeight: FontWeight.w600))),
                DataCell(Text('${p.quantityReserved} ${p.unitOfMeasurement}', style: AppTypography.bodyMedium(color: AppColors.warning))),
                DataCell(
                  Text(
                    '${p.quantityAvailable} ${p.unitOfMeasurement}',
                    style: AppTypography.bodyMedium(
                      color: p.quantityAvailable <= 0 ? AppColors.accentRed : AppColors.success,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                DataCell(Text(_formatRupiah(p.purchaseCostCents), style: AppTypography.bodySmall())),
                DataCell(Text(_formatRupiah(p.sellingPriceCents), style: AppTypography.bodySmall().copyWith(fontWeight: FontWeight.w600))),
                DataCell(
                  p.isOutOfStock
                      ? const StatusBadge(label: 'OUT OF STOCK', color: AppColors.accentRed)
                      : p.isLowStock
                          ? const StatusBadge(label: 'LOW STOCK', color: AppColors.warning)
                          : const StatusBadge(label: 'HEALTHY', color: AppColors.success),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, size: 18, color: AppColors.success),
                        tooltip: 'Receive Stock',
                        onPressed: () => _openReceiveStockDialog(p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune, size: 18, color: AppColors.warning),
                        tooltip: 'Adjust Stock',
                        onPressed: () => _openAdjustStockDialog(p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.history, size: 18, color: AppColors.info),
                        tooltip: 'Ledger History',
                        onPressed: () => _openHistoryDialog(p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        tooltip: 'Edit Part',
                        onPressed: () => _openCreateOrEditPartDialog(p),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobilePartsList(bool isDark) {
    return Column(
      children: _parts.map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: PitCard(
            accentBorderLeft: p.isOutOfStock
                ? AppColors.accentRed
                : p.isLowStock
                    ? AppColors.warning
                    : AppColors.success,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.sku, style: AppTypography.labelLarge(color: AppColors.accentRed).copyWith(fontWeight: FontWeight.w700)),
                    if (p.isOutOfStock)
                      const StatusBadge(label: 'OUT OF STOCK', color: AppColors.accentRed)
                    else if (p.isLowStock)
                      const StatusBadge(label: 'LOW STOCK', color: AppColors.warning)
                    else
                      const StatusBadge(label: 'HEALTHY', color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 4),
                Text(p.name, style: AppTypography.bodyMedium().copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('On Hand: ${p.quantityOnHand}', style: AppTypography.bodySmall()),
                    Text('Reserved: ${p.quantityReserved}', style: AppTypography.bodySmall(color: AppColors.warning)),
                    Text(
                      'Available: ${p.quantityAvailable}',
                      style: AppTypography.bodySmall(
                        color: p.quantityAvailable <= 0 ? AppColors.accentRed : AppColors.success,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Avg Cost: ${_formatRupiah(p.purchaseCostCents)}', style: AppTypography.bodySmall(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    Text('Retail: ${_formatRupiah(p.sellingPriceCents)}', style: AppTypography.bodySmall().copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.add_shopping_cart, size: 16, color: AppColors.success),
                      label: const Text('RECEIVE', style: TextStyle(color: AppColors.success)),
                      onPressed: () => _openReceiveStockDialog(p),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.tune, size: 16, color: AppColors.warning),
                      label: const Text('ADJUST', style: TextStyle(color: AppColors.warning)),
                      onPressed: () => _openAdjustStockDialog(p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.history, size: 18),
                      tooltip: 'History',
                      onPressed: () => _openHistoryDialog(p),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
