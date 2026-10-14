import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/vehicle.dart';
import '../../../shared/providers/customer_provider.dart';
import '../../../shared/providers/vehicle_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/search_filter_bar.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import 'admin_shell.dart';

/// Vehicles fleet view for Admin role connected to live Supabase data.
class AdminVehiclesPage extends ConsumerStatefulWidget {
  const AdminVehiclesPage({super.key});

  @override
  ConsumerState<AdminVehiclesPage> createState() => _AdminVehiclesPageState();
}

class _AdminVehiclesPageState extends ConsumerState<AdminVehiclesPage> {
  String _selectedFilter = 'All';

  void _onSearchChanged(String query) {
    ref.read(vehiclesProvider.notifier).setFilter(query: query);
  }

  void _onFilterSelected(String filter) {
    setState(() => _selectedFilter = filter);
    ref.read(vehiclesProvider.notifier).setFilter(make: filter);
  }

  Future<void> _openVehicleDialog({Vehicle? vehicle}) async {
    final isEditing = vehicle != null;
    final formKey = GlobalKey<FormState>();

    final customersAsync = ref.read(customersProvider);
    final customers = customersAsync.value ?? [];

    String selectedCustomerId =
        vehicle?.customerId ?? (customers.isNotEmpty ? customers.first.id : '');
    final makeController = TextEditingController(text: vehicle?.make ?? '');
    final modelController = TextEditingController(text: vehicle?.model ?? '');
    final variantController = TextEditingController(
      text: vehicle?.variant ?? '',
    );
    final yearController = TextEditingController(
      text: vehicle?.modelYear?.toString() ?? DateTime.now().year.toString(),
    );
    final plateController = TextEditingController(
      text: vehicle?.licensePlate ?? '',
    );
    final numberController = TextEditingController(
      text: vehicle?.vehicleNumber ?? '',
    );
    final vinController = TextEditingController(text: vehicle?.vin ?? '');
    final mileageController = TextEditingController(
      text: vehicle?.mileageKm.toString() ?? '0',
    );
    final colorController = TextEditingController(text: vehicle?.color ?? '');
    final notesController = TextEditingController(text: vehicle?.notes ?? '');

    bool isSaving = false;
    String? errorMessage;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.standard,
                right: AppSpacing.standard,
                top: AppSpacing.section,
                bottom:
                    MediaQuery.of(sheetContext).viewInsets.bottom +
                    AppSpacing.section,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing
                                ? 'EDIT FLEET VEHICLE'
                                : 'REGISTER VEHICLE',
                            style: AppTypography.sectionTitle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.standard),
                      if (errorMessage != null) ...[
                        Text(
                          errorMessage!,
                          style: AppTypography.bodySmall(
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.compact),
                      ],
                      if (!isEditing) ...[
                        DropdownButtonFormField<String>(
                          initialValue: selectedCustomerId.isNotEmpty
                              ? selectedCustomerId
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Vehicle Owner / Client Account *',
                            prefixIcon: Icon(Icons.person_pin_outlined),
                          ),
                          items: customers.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.displayName),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedCustomerId = val);
                            }
                          },
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please select a customer account';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.standard),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: makeController,
                              decoration: const InputDecoration(
                                labelText: 'Make (e.g. BMW) *',
                                prefixIcon: Icon(Icons.directions_car_outlined),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.standard),
                          Expanded(
                            child: TextFormField(
                              controller: modelController,
                              decoration: const InputDecoration(
                                labelText: 'Model (e.g. M4 GT3) *',
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.standard),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: variantController,
                              decoration: const InputDecoration(
                                labelText: 'Variant (e.g. LMDh / Evo)',
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.standard),
                          Expanded(
                            child: TextFormField(
                              controller: yearController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Model Year',
                              ),
                              validator: (val) {
                                if (val != null && val.isNotEmpty) {
                                  final y = int.tryParse(val);
                                  if (y == null || y < 1900 || y > 2100) {
                                    return 'Invalid year';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.standard),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: plateController,
                              decoration: const InputDecoration(
                                labelText: 'License Plate (e.g. B 1234 CD)',
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.standard),
                          Expanded(
                            child: TextFormField(
                              controller: numberController,
                              decoration: const InputDecoration(
                                labelText: 'Car Number (e.g. #15)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.standard),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: mileageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Mileage (KM)',
                              ),
                              validator: (val) {
                                if (val != null && val.isNotEmpty) {
                                  final km = int.tryParse(val);
                                  if (km == null || km < 0) {
                                    return 'Invalid KM';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.standard),
                          Expanded(
                            child: TextFormField(
                              controller: colorController,
                              decoration: const InputDecoration(
                                labelText: 'Color / Livery',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.standard),
                      TextFormField(
                        controller: vinController,
                        decoration: const InputDecoration(
                          labelText: 'VIN / Chassis Number',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.standard),
                      TextFormField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Specification & Notes',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              text: 'Cancel',
                              onPressed: () => Navigator.of(sheetContext).pop(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.standard),
                          Expanded(
                            child: PrimaryButton(
                              text: isSaving ? 'Saving...' : 'Save Vehicle',
                              isLoading: isSaving,
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      setModalState(() {
                                        isSaving = true;
                                        errorMessage = null;
                                      });
                                      try {
                                        if (isEditing) {
                                          await ref
                                              .read(vehiclesProvider.notifier)
                                              .updateVehicle(
                                                id: vehicle.id,
                                                make: makeController.text
                                                    .trim(),
                                                model: modelController.text
                                                    .trim(),
                                                variant: variantController.text
                                                    .trim(),
                                                modelYear: int.tryParse(
                                                  yearController.text.trim(),
                                                ),
                                                licensePlate: plateController
                                                    .text
                                                    .trim(),
                                                vehicleNumber: numberController
                                                    .text
                                                    .trim(),
                                                vin: vinController.text.trim(),
                                                mileageKm:
                                                    int.tryParse(
                                                      mileageController.text
                                                          .trim(),
                                                    ) ??
                                                    0,
                                                color: colorController.text
                                                    .trim(),
                                                notes: notesController.text
                                                    .trim(),
                                              );
                                        } else {
                                          await ref
                                              .read(vehiclesProvider.notifier)
                                              .createVehicle(
                                                customerId: selectedCustomerId,
                                                make: makeController.text
                                                    .trim(),
                                                model: modelController.text
                                                    .trim(),
                                                variant: variantController.text
                                                    .trim(),
                                                modelYear: int.tryParse(
                                                  yearController.text.trim(),
                                                ),
                                                licensePlate: plateController
                                                    .text
                                                    .trim(),
                                                vehicleNumber: numberController
                                                    .text
                                                    .trim(),
                                                vin: vinController.text.trim(),
                                                mileageKm:
                                                    int.tryParse(
                                                      mileageController.text
                                                          .trim(),
                                                    ) ??
                                                    0,
                                                color: colorController.text
                                                    .trim(),
                                                notes: notesController.text
                                                    .trim(),
                                              );
                                        }

                                        if (context.mounted) {
                                          Navigator.of(sheetContext).pop();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    isEditing
                                                        ? 'Vehicle updated successfully.'
                                                        : 'Vehicle added to garage fleet.',
                                                  ),
                                                ),
                                              );
                                        }
                                      } catch (err) {
                                        setModalState(() {
                                          isSaving = false;
                                          errorMessage = err.toString();
                                        });
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteVehicle(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        title: Text(
          'Remove Vehicle',
          style: AppTypography.sectionTitle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove ${vehicle.displayName} (${vehicle.identifierLabel}) from the registry?',
          style: AppTypography.bodySmall(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(vehiclesProvider.notifier).deleteVehicle(vehicle.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehicle removed from fleet.')),
          );
        }
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text('Failed to delete: $err'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return AdminShell(
      currentRoute: RoutePaths.adminVehicles,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(vehiclesProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SectionHeader(
                      title: 'WORKSHOP FLEET REGISTRY',
                      subtitle: 'Track registered customer machinery, specifications, and telemetry',
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: PrimaryButton(
                      text: 'Add Car',
                      icon: Icons.add,
                      onPressed: () => _openVehicleDialog(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.compact),
              SearchFilterBar(
                searchHint:
                    'Search vehicles by make, model, chassis, or owner...',
                onSearchChanged: _onSearchChanged,
                filterOptions: const [
                  'All',
                  'BMW',
                  'Aston Martin',
                  'Toyota',
                  'Ford',
                ],
                selectedFilter: _selectedFilter,
                onFilterSelected: _onFilterSelected,
              ),
              const SizedBox(height: AppSpacing.section),
              vehiclesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.section),
                    child: LoadingState(
                      message: 'Accessing fleet registry database...',
                    ),
                  ),
                ),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.refresh(vehiclesProvider),
                ),
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return const EmptyState(
                      title: 'No Vehicles Found',
                      message: 'No vehicles match the specified criteria in the garage registry.',
                      icon: Icons.directions_car_outlined,
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: vehicles.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.standard),
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];

                      return PitCard(
                        technicalLabel:
                            'TELEMETRY-ID • ${(vehicle.id.length >= 8 ? vehicle.id.substring(0, 8) : vehicle.id).toUpperCase()}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.directions_car,
                                        color: AppColors.primaryAccent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: AppSpacing.compact),
                                      Expanded(
                                        child: Text(
                                          vehicle.displayName,
                                          style: AppTypography.sectionTitle(
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    StatusBadge(
                                      label: vehicle.identifierLabel,
                                      color: AppColors.primaryAccent,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: AppColors.textMuted,
                                      ),
                                      tooltip: 'Edit vehicle',
                                      onPressed: () =>
                                          _openVehicleDialog(vehicle: vehicle),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      tooltip: 'Remove vehicle',
                                      onPressed: () =>
                                          _confirmDeleteVehicle(vehicle),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (vehicle.customer != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_pin_outlined,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Owner: ${vehicle.customer!.displayName}',
                                    style: AppTypography.technical(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (vehicle.notes != null &&
                                vehicle.notes!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.compact),
                              Text(
                                vehicle.notes!,
                                style: AppTypography.bodySmall(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.standard),
                            const Divider(
                              color: AppColors.borderSubtle,
                              height: 1,
                            ),
                            const SizedBox(height: AppSpacing.compact),
                            Wrap(
                              spacing: AppSpacing.section,
                              runSpacing: AppSpacing.compact,
                              children: [
                                if (vehicle.modelYear != null)
                                  _buildInfoChip(
                                    Icons.calendar_today_outlined,
                                    'Year: ${vehicle.modelYear}',
                                  ),
                                _buildInfoChip(
                                  Icons.speed_outlined,
                                  '${vehicle.mileageKm.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} KM',
                                ),
                                if (vehicle.color != null &&
                                    vehicle.color!.isNotEmpty)
                                  _buildInfoChip(
                                    Icons.palette_outlined,
                                    vehicle.color!,
                                  ),
                                if (vehicle.vin != null &&
                                    vehicle.vin!.isNotEmpty)
                                  _buildInfoChip(
                                    Icons.confirmation_number_outlined,
                                    'VIN: ${vehicle.vin!}',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.technical(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
