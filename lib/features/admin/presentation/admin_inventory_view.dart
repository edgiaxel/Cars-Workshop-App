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
          }
        },
      ),
    );
  }

  void _confirmDeletePart(SparePart part) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
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
                          technicalLabel: 'SKU • ${part.sku}',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      part.name,
                                      style: AppTypography.sectionTitle(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      StatusBadge(
                                        label: isLowStock
                                            ? 'LOW STOCK'
                                            : 'IN STOCK',
                                        color: isLowStock
                                            ? AppColors.error
                                            : AppColors.statusCompleted,
                                      ),
                                      const SizedBox(width: AppSpacing.compact),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: AppColors.textMuted,
                                          size: 18,
                                        ),
                                        tooltip: 'Edit part',
                                        onPressed: () => _openPartDialog(part),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.error,
                                          size: 18,
                                        ),
                                        tooltip: 'Delete part',
                                        onPressed: () =>
                                            _confirmDeletePart(part),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.compact),
                              Text(
                                'Brand: ${part.brand ?? 'Generic'} • Category: ${part.category} • Unit: ${part.unit}',
                                style: AppTypography.bodySmall(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (part.description != null &&
                                  part.description!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.micro),
                                Text(
                                  part.description!,
                                  style: AppTypography.bodySmall(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.standard),
                              const Divider(
                                color: AppColors.borderSubtle,
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
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      Text(
                                        '${part.stock} ${part.unit}',
                                        style: AppTypography.label(
                                          color: isLowStock
                                              ? AppColors.error
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: AppSpacing.standard,
                                      ),
                                      Text(
                                        'Min: ',
                                        style: AppTypography.technical(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      Text(
                                        '${part.minimumStock} ${part.unit}',
                                        style: AppTypography.label(
                                          color: AppColors.textSecondary,
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
  late final TextEditingController _descriptionController;

  String _selectedCategory = 'Fluids';
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

    return Dialog(
      backgroundColor: AppColors.surfacePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: SingleChildScrollView(
          padding: AppSpacing.paddingSection,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Spare Part' : 'Add New Spare Part',
                      style: AppTypography.sectionTitle(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
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
                const SizedBox(height: AppSpacing.standard),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _skuController,
                        style: AppTypography.bodyMedium(),
                        decoration: const InputDecoration(
                          labelText: 'SKU *',
                          hintText: 'e.g. OIL-5W40-001',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'SKU is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.compact),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        dropdownColor: AppColors.surfacePrimary,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                        ),
                        items: _availableCategories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.compact),
                TextFormField(
                  controller: _nameController,
                  style: AppTypography.bodyMedium(),
                  decoration: const InputDecoration(
                    labelText: 'Part Name *',
                    hintText: 'e.g. Castrol EDGE 5W-40 Synthetic Oil',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: AppSpacing.compact),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _brandController,
                        style: AppTypography.bodyMedium(),
                        decoration: const InputDecoration(
                          labelText: 'Brand',
                          hintText: 'e.g. Castrol, Brembo',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.compact),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        style: AppTypography.bodyMedium(),
                        decoration: const InputDecoration(
                          labelText: 'Unit *',
                          hintText: 'pcs, liter, set',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Unit is required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.compact),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _unitCostController,
                        keyboardType: TextInputKeyData.number,
                        style: AppTypography.bodyMedium(),
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
                    ),
                    const SizedBox(width: AppSpacing.compact),
                    Expanded(
                      child: TextFormField(
                        controller: _sellingPriceController,
                        keyboardType: TextInputKeyData.number,
                        style: AppTypography.bodyMedium(),
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
                    ),
                    const SizedBox(width: AppSpacing.compact),
                    Expanded(
                      child: TextFormField(
                        controller: _minimumStockController,
                        keyboardType: TextInputKeyData.number,
                        style: AppTypography.bodyMedium(),
                        decoration: const InputDecoration(
                          labelText: 'Min Stock *',
                          hintText: 'Threshold',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final num = int.tryParse(v.trim());
                          if (num == null || num < 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.compact),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  style: AppTypography.bodyMedium(),
                  decoration: const InputDecoration(
                    labelText: 'Description / Notes',
                    hintText:
                        'Specifications, application vehicle models, etc.',
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: AppTypography.label(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.compact),
                    PrimaryButton(
                      text: isEditing ? 'Save Changes' : 'Create Part',
                      isLoading: _isLoading,
                      onPressed: _submit,
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
}

extension TextInputKeyData on TextInputType {
  static const TextInputType number = TextInputType.number;
}
