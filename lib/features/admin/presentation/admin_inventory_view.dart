import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/spare_part.dart';
import '../../../shared/providers/spare_part_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/search_filter_bar.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import 'admin_shell.dart';

/// Spare parts inventory management view for Admin role backed by live Supabase data.
class AdminInventoryPage extends ConsumerStatefulWidget {
  const AdminInventoryPage({super.key});

  @override
  ConsumerState<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends ConsumerState<AdminInventoryPage> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Fluids',
    'Filters',
    'Brakes',
    'Tires',
    'Electrical',
    'Suspension',
    'Engine',
  ];

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    ref
        .read(sparePartsProvider.notifier)
        .setFilter(query: query, category: _selectedCategory);
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    ref
        .read(sparePartsProvider.notifier)
        .setFilter(query: _searchQuery, category: category);
  }

  void _openPartDialog([SparePart? part]) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _PartFormDialog(
        part: part,
        onSave: (payload) async {
          if (part == null) {
            await ref
                .read(sparePartsProvider.notifier)
                .createSparePart(
                  sku: payload['sku'] as String,
                  name: payload['name'] as String,
                  category: payload['category'] as String,
                  brand: payload['brand'] as String?,
                  description: payload['description'] as String?,
                  unit: payload['unit'] as String? ?? 'pcs',
                  unitCost: payload['unit_cost'] as double,
                  sellingPrice: payload['selling_price'] as double,
                  minimumStock: payload['minimum_stock'] as int? ?? 0,
                  initialStock: payload['initial_stock'] as int? ?? 0,
                );
          } else {
            await ref
                .read(sparePartsProvider.notifier)
                .updateSparePart(
                  id: part.id,
                  sku: payload['sku'] as String?,
                  name: payload['name'] as String?,
                  category: payload['category'] as String?,
                  brand: payload['brand'] as String?,
                  description: payload['description'] as String?,
                  unit: payload['unit'] as String?,
                  unitCost: payload['unit_cost'] as double?,
                  sellingPrice: payload['selling_price'] as double?,
                  minimumStock: payload['minimum_stock'] as int?,
                );

            final adjustQty = payload['adjust_quantity'] as int?;
            if (adjustQty != null && adjustQty != 0) {
              await ref
                  .read(sparePartsProvider.notifier)
                  .adjustStock(
                    id: part.id,
                    quantity: adjustQty,
                    transactionType:
                        payload['adjust_type'] as String? ?? 'adjustment',
                    notes: payload['adjust_notes'] as String?,
                  );
            }
          }
        },
      ),
    );
  }

  void _confirmDeletePart(SparePart part) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Delete Spare Part', style: AppTypography.sectionTitle()),
        content: Text(
          'Are you sure you want to delete ${part.name} (${part.sku}) from the catalog?',
          style: AppTypography.bodyMedium(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: AppTypography.label(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ref
                    .read(sparePartsProvider.notifier)
                    .deleteSparePart(part.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Part ${part.name} removed from catalog.'),
                      backgroundColor: AppColors.statusCompleted,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete part: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partsAsync = ref.watch(sparePartsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final borderSubtle =
        isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;

    return AdminShell(
      currentRoute: RoutePaths.adminInventory,
      child: SingleChildScrollView(
        padding: AppSpacing.paddingSection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: 'SPARE PARTS INVENTORY',
              subtitle: 'Warehouse stock levels, minimum reorder thresholds, and catalog',
              action: PrimaryButton(
                text: 'Add Part',
                icon: Icons.add,
                width: 140,
                onPressed: () => _openPartDialog(),
              ),
            ),
            const SizedBox(height: AppSpacing.compact),
            SearchFilterBar(
              searchHint: 'Search parts by name, SKU, or brand...',
              onSearchChanged: _onSearchChanged,
              filterOptions: _categories,
              selectedFilter: _selectedCategory,
              onFilterSelected: _onCategorySelected,
            ),
            const SizedBox(height: AppSpacing.section),
            partsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.section),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => ErrorState(
                title: 'Failed to load inventory',
                message: err.toString(),
                onRetry: () => ref.refresh(sparePartsProvider),
              ),
              data: (parts) {
                if (parts.isEmpty) {
                  return EmptyState(
                    title: 'No Spare Parts Found',
                    message:
                        _searchQuery.isNotEmpty || _selectedCategory != 'All'
                        ? 'No inventory parts match your query or category filter.'
                        : 'No spare parts have been added to the catalog yet.',
                    icon: Icons.inventory_2_outlined,
                  );
                }

                return Column(
                  children: [
                    for (int index = 0; index < parts.length; index++) ...[
                      if (index > 0)
                        const SizedBox(height: AppSpacing.standard),
                      () {
                        final part = parts[index];
                        final isLowStock = part.isLowStock;

                        return PitCard(
                          technicalLabel: 'SKU \u2022 ${part.sku}',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      part.name,
                                      style: AppTypography.sectionTitle(
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.compact),
                                  StatusBadge(
                                    label: isLowStock
                                        ? 'LOW STOCK'
                                        : 'IN STOCK',
                                    color: isLowStock
                                        ? AppColors.error
                                        : AppColors.statusCompleted,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.compact),
                              Text(
                                'Brand: ${part.brand ?? 'Generic'} \u2022 Category: ${part.category} \u2022 Unit: ${part.unit}',
                                style: AppTypography.bodySmall(
                                  color: textSecondary,
                                ),
                              ),
                              if (part.description != null &&
                                  part.description!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.micro),
                                Text(
                                  part.description!,
                                  style: AppTypography.bodySmall(
                                    color: textMuted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.standard),
                              Divider(
                                color: borderSubtle,
                                height: 1,
                              ),
                              const SizedBox(height: AppSpacing.compact),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Stock: ',
                                        style: AppTypography.technical(
                                          color: textMuted,
                                        ),
                                      ),
                                      Text(
                                        '${part.stock} ${part.unit}',
                                        style: AppTypography.label(
                                          color: isLowStock
                                              ? AppColors.error
                                              : textPrimary,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: AppSpacing.standard,
                                      ),
                                      Text(
                                        'Min: ',
                                        style: AppTypography.technical(
                                          color: textMuted,
                                        ),
                                      ),
                                      Text(
                                        '${part.minimumStock} ${part.unit}',
                                        style: AppTypography.label(
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'IDR ${part.sellingPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                    style: AppTypography.label(
                                      color: AppColors.primaryAccent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.compact),
                              Divider(
                                color: borderSubtle,
                                height: 1,
                              ),
                              const SizedBox(height: AppSpacing.compact),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 14,
                                    ),
                                    label: const Text('Edit'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: textPrimary,
                                      side: BorderSide(
                                        color: borderSubtle,
                                      ),
                                    ),
                                    onPressed: () => _openPartDialog(part),
                                  ),
                                  const SizedBox(width: AppSpacing.compact),
                                  OutlinedButton.icon(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 14,
                                    ),
                                    label: const Text('Delete'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(
                                        color: AppColors.error,
                                      ),
                                    ),
                                    onPressed: () =>
                                        _confirmDeletePart(part),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }(),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PartFormDialog extends StatefulWidget {
  const _PartFormDialog({this.part, required this.onSave});

  final SparePart? part;
  final Future<void> Function(Map<String, dynamic> payload) onSave;

  @override
  State<_PartFormDialog> createState() => _PartFormDialogState();
}

class _PartFormDialogState extends State<_PartFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _skuController;
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _unitController;
  late final TextEditingController _unitCostController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _minimumStockController;
  late final TextEditingController _initialStockController;
  late final TextEditingController _adjustQuantityController;
  late final TextEditingController _adjustNotesController;
  late final TextEditingController _descriptionController;

  String _selectedCategory = 'Fluids';
  bool _enableStockAdjustment = false;
  String _selectedAdjustType = 'purchase';
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _availableCategories = [
    'Fluids',
    'Filters',
    'Brakes',
    'Tires',
    'Electrical',
    'Suspension',
    'Engine',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.part;
    _skuController = TextEditingController(text: p?.sku ?? '');
    _nameController = TextEditingController(text: p?.name ?? '');
    _brandController = TextEditingController(text: p?.brand ?? '');
    _unitController = TextEditingController(text: p?.unit ?? 'pcs');
    _unitCostController = TextEditingController(
      text: p != null ? p.unitCost.toStringAsFixed(0) : '0',
    );
    _sellingPriceController = TextEditingController(
      text: p != null ? p.sellingPrice.toStringAsFixed(0) : '0',
    );
    _minimumStockController = TextEditingController(
      text: p != null ? p.minimumStock.toString() : '5',
    );
    _initialStockController = TextEditingController(text: '10');
    _adjustQuantityController = TextEditingController(text: '10');
    _adjustNotesController = TextEditingController();
    _descriptionController = TextEditingController(text: p?.description ?? '');

    if (p != null && _availableCategories.contains(p.category)) {
      _selectedCategory = p.category;
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _unitController.dispose();
    _unitCostController.dispose();
    _sellingPriceController.dispose();
    _minimumStockController.dispose();
    _initialStockController.dispose();
    _adjustQuantityController.dispose();
    _adjustNotesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final unitCost = double.tryParse(_unitCostController.text.trim()) ?? 0.0;
      final sellingPrice =
          double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
      final minimumStock =
          int.tryParse(_minimumStockController.text.trim()) ?? 0;
      final initialStock =
          int.tryParse(_initialStockController.text.trim()) ?? 0;

      int? adjustQty;
      if (widget.part != null && _enableStockAdjustment) {
        adjustQty = int.tryParse(_adjustQuantityController.text.trim());
      }

      final payload = <String, dynamic>{
        'sku': _skuController.text.trim(),
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'brand': _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'unit': _unitController.text.trim().isEmpty
            ? 'pcs'
            : _unitController.text.trim(),
        'unit_cost': unitCost,
        'selling_price': sellingPrice,
        'minimum_stock': minimumStock,
        'initial_stock': initialStock,
        'adjust_quantity': adjustQty,
        'adjust_type': _selectedAdjustType,
        'adjust_notes': _adjustNotesController.text.trim().isEmpty
            ? null
            : _adjustNotesController.text.trim(),
      };

      await widget.onSave(payload);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.part != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.surfaceCard : AppColors.lightSurfaceCard;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;
    final borderSubtle =
        isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: dialogBg,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.standard),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'EDIT SPARE PART' : 'ADD NEW SPARE PART',
                    style: AppTypography.sectionTitle(color: textPrimary),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textMuted),
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.compact),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.compact),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall(color: AppColors.error),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.compact),

              // Scrollable Form in a single vertical column
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _skuController,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'SKU *',
                            hintText: 'e.g. OIL-5W40-001',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'SKU is required'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.standard),

                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                          ),
                          items: _availableCategories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.standard),

                        TextFormField(
                          controller: _nameController,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Part Name *',
                            hintText: 'e.g. Castrol EDGE 5W-40 Synthetic Oil',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.standard),

                        TextFormField(
                          controller: _brandController,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Brand',
                            hintText: 'e.g. Castrol, Brembo',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.standard),

                        TextFormField(
                          controller: _unitController,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Unit *',
                            hintText: 'pcs, liter, set',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Unit is required'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.standard),

                        TextFormField(
                          controller: _unitCostController,
                          keyboardType: TextInputKeyData.number,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Unit Cost (IDR) *',
                            hintText: 'Cost price',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Cost is required';
                            }
                            final num = double.tryParse(v.trim());
                            if (num == null || num < 0) {
                              return 'Invalid amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.standard),

                        TextFormField(
                          controller: _sellingPriceController,
                          keyboardType: TextInputKeyData.number,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Selling Price (IDR) *',
                            hintText: 'Selling price',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Price is required';
                            }
                            final num = double.tryParse(v.trim());
                            if (num == null || num < 0) {
                              return 'Invalid amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.standard),

                        TextFormField(
                          controller: _minimumStockController,
                          keyboardType: TextInputKeyData.number,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Minimum Safety Stock *',
                            hintText: 'Threshold for alerts',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final num = int.tryParse(v.trim());
                            if (num == null || num < 0) return 'Invalid';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.standard),

                        // Initial stock for new parts
                        if (!isEditing) ...[
                          TextFormField(
                            controller: _initialStockController,
                            keyboardType: TextInputKeyData.number,
                            style: AppTypography.bodyMedium(color: textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Initial Inventory Stock (Quantity)',
                              hintText: 'e.g. 20',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final num = int.tryParse(v.trim());
                              if (num == null || num < 0) return 'Invalid quantity';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.standard),
                        ],

                        // Stock adjustment for existing parts
                        if (isEditing) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.compact),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceBackground
                                  : AppColors.lightSurfaceBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'CURRENT STOCK',
                                      style: AppTypography.technical(
                                        color: textMuted,
                                      ),
                                    ),
                                    Text(
                                      '${widget.part!.stock} ${widget.part!.unit}',
                                      style: AppTypography.label(
                                        color: widget.part!.isLowStock
                                            ? AppColors.error
                                            : AppColors.statusCompleted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.compact),
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Adjust / Add Stock',
                                    style: AppTypography.bodyMedium(
                                      color: textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Restock inventory or adjust manual counts',
                                    style: AppTypography.bodySmall(
                                      color: textSecondary,
                                    ),
                                  ),
                                  value: _enableStockAdjustment,
                                  onChanged: (val) {
                                    setState(() =>
                                        _enableStockAdjustment = val ?? false);
                                  },
                                ),
                                if (_enableStockAdjustment) ...[
                                  const SizedBox(height: AppSpacing.compact),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedAdjustType,
                                    decoration: const InputDecoration(
                                      labelText: 'Transaction Type',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'purchase',
                                        child: Text('Purchase / Restock (+)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'adjustment',
                                        child: Text('Inventory Adjustment'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'damaged',
                                        child: Text('Damaged / Write-off (-)'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(
                                            () => _selectedAdjustType = val);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.compact),
                                  TextFormField(
                                    controller: _adjustQuantityController,
                                    keyboardType: TextInputKeyData.number,
                                    style: AppTypography.bodyMedium(
                                      color: textPrimary,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Quantity to Add / Adjust *',
                                      hintText: 'e.g. 20 (or -5 if write-off)',
                                    ),
                                    validator: (v) {
                                      if (!_enableStockAdjustment) return null;
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Quantity is required';
                                      }
                                      final num = int.tryParse(v.trim());
                                      if (num == null || num == 0) {
                                        return 'Enter non-zero quantity';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.compact),
                                  TextFormField(
                                    controller: _adjustNotesController,
                                    style: AppTypography.bodyMedium(
                                      color: textPrimary,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Adjustment Reason / Notes',
                                      hintText:
                                          'e.g. Supplier delivery PO-2026-11',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.standard),
                        ],

                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Description / Notes',
                            hintText:
                                'Specifications, compatible vehicle models, etc.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.standard),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: 'Cancel',
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.standard),
                  Expanded(
                    child: PrimaryButton(
                      text: isEditing ? 'Save Changes' : 'Create Part',
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension TextInputKeyData on TextInputType {
  static const TextInputType number = TextInputType.number;
}
