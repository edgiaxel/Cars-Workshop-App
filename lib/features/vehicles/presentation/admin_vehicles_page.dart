import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/pit_primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../customers/presentation/providers/customer_provider.dart';
import 'providers/vehicle_provider.dart';

class AdminVehiclesPage extends ConsumerStatefulWidget {
  const AdminVehiclesPage({super.key});

  @override
  ConsumerState<AdminVehiclesPage> createState() => _AdminVehiclesPageState();
}

class _AdminVehiclesPageState extends ConsumerState<AdminVehiclesPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddVehicleDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddVehicleDialog(),
    ).then((_) => ref.refresh(allVehiclesProvider));
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(allVehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Registry'),
        actions: [
          IconButton(
            tooltip: 'Register Vehicle',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddVehicleDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.paddingMd,
            child: TextField(
              key: const Key('vehicle_search_input'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by plate, make, model...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: vehiclesAsync.when(
              loading: () => const LoadingState(message: 'Loading vehicles...'),
              error: (err, stack) => ErrorState(
                title: 'Failed to Load Vehicles',
                message: err.toString(),
                onRetry: () => ref.refresh(allVehiclesProvider),
              ),
              data: (vehicles) {
                final filtered = vehicles.where((v) {
                  if (_searchQuery.isEmpty) return true;
                  return v.licensePlate.toLowerCase().contains(_searchQuery) ||
                      v.make.toLowerCase().contains(_searchQuery) ||
                      v.model.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: 'No Vehicles Registered',
                    description: _searchQuery.isEmpty
                        ? 'No vehicles in the workshop database yet.'
                        : 'No vehicles match your search criteria.',
                    actionLabel: 'Register Vehicle',
                    onAction: _showAddVehicleDialog,
                  );
                }

                return ListView.separated(
                  padding: AppSpacing.paddingMd,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final vehicle = filtered[index];
                    return PitCard(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.racingRed.withValues(alpha: 0.1),
                          child: const Icon(Icons.directions_car, color: AppColors.racingRed),
                        ),
                        title: Row(
                          children: [
                            Text(
                              vehicle.licensePlate,
                              style: AppTypography.headingSmall(),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            StatusBadge(
                              label: '${vehicle.year}',
                              variant: StatusBadgeVariant.neutral,
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${vehicle.make} ${vehicle.model} • ${vehicle.currentMileage} km',
                              style: AppTypography.bodySmall(),
                            ),
                            if (vehicle.vin != null)
                              Text('VIN: ${vehicle.vin}', style: AppTypography.bodySmall(color: AppColors.neutral)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_vehicle_fab'),
        onPressed: _showAddVehicleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddVehicleDialog extends ConsumerStatefulWidget {
  final String? fixedCustomerId;

  const AddVehicleDialog({super.key, this.fixedCustomerId});

  @override
  ConsumerState<AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends ConsumerState<AddVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCustomerId;
  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController(text: DateTime.now().year.toString());
  final _mileageController = TextEditingController(text: '0');
  final _vinController = TextEditingController();
  final _colorController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.fixedCustomerId;
  }

  @override
  void dispose() {
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _vinController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      setState(() => _errorMessage = 'Please select a customer');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(vehicleRepositoryProvider).registerVehicle(
            customerId: _selectedCustomerId!,
            licensePlate: _plateController.text,
            make: _makeController.text,
            model: _modelController.text,
            year: int.parse(_yearController.text),
            currentMileage: int.tryParse(_mileageController.text) ?? 0,
            vin: _vinController.text.isNotEmpty ? _vinController.text : null,
            color: _colorController.text.isNotEmpty ? _colorController.text : null,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);

    return AlertDialog(
      title: const Text('Register New Vehicle'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(_errorMessage!, style: AppTypography.bodySmall(color: AppColors.error)),
                  ),
                if (widget.fixedCustomerId == null)
                  customersAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (err, _) => Text('Error loading customers: $err'),
                    data: (customers) {
                      return DropdownButtonFormField<String>(
                        key: const Key('add_vehicle_customer_select'),
                        decoration: const InputDecoration(labelText: 'Customer Owner *', border: OutlineInputBorder()),
                        initialValue: _selectedCustomerId,
                        items: customers.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.name} (${c.phone})', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCustomerId = val),
                        validator: (val) => val == null ? 'Customer is required' : null,
                      );
                    },
                  ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const Key('add_vehicle_plate_input'),
                  controller: _plateController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'License Plate * (e.g. B 1234 PIT)', border: OutlineInputBorder()),
                  validator: (val) => val == null || val.trim().isEmpty ? 'License plate is required' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('add_vehicle_make_input'),
                        controller: _makeController,
                        decoration: const InputDecoration(labelText: 'Make * (e.g. BMW)', border: OutlineInputBorder()),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Make is required' : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        key: const Key('add_vehicle_model_input'),
                        controller: _modelController,
                        decoration: const InputDecoration(labelText: 'Model * (e.g. M3)', border: OutlineInputBorder()),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Model is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('add_vehicle_year_input'),
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Year *', border: OutlineInputBorder()),
                        validator: (val) {
                          final yr = int.tryParse(val ?? '');
                          if (yr == null || yr < 1900 || yr > 2100) return 'Invalid year';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        key: const Key('add_vehicle_mileage_input'),
                        controller: _mileageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Mileage (km)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const Key('add_vehicle_vin_input'),
                  controller: _vinController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'VIN (Optional, 17 characters)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        PitPrimaryButton(
          key: const Key('save_vehicle_button'),
          text: 'Register Vehicle',
          isLoading: _isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
