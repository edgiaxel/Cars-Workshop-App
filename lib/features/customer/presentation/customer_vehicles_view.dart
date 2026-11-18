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
import '../../../shared/widgets/secondary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import 'customer_shell.dart';

/// Customer vehicles garage view connected to real Supabase records.
class CustomerVehiclesPage extends ConsumerWidget {
  const CustomerVehiclesPage({super.key});

  void _showVehicleDialog(
    BuildContext context,
    WidgetRef ref, [
    Vehicle? vehicle,
  ]) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _CustomerVehicleFormDialog(
        vehicle: vehicle,
        onSaved: () {
          ref.invalidate(customerVehiclesProvider(null));
          ref.invalidate(vehiclesProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(customerVehiclesProvider(null));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final borderSubtle = isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;

    return CustomerShell(
      currentRoute: RoutePaths.customerVehicles,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(customerVehiclesProvider(null).future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: 'MY GARAGE FLEET',
                subtitle:
                    'Your registered machines and service profile telemetry',
                action: PrimaryButton(
                  text: 'Add Vehicle',
                  icon: Icons.add,
                  width: 150,
                  onPressed: () => _showVehicleDialog(context, ref),
                ),
              ),
              const SizedBox(height: AppSpacing.compact),
              vehiclesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.section),
                    child: LoadingState(
                      message: 'Retrieving your garage telemetry...',
                    ),
                  ),
                ),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.refresh(customerVehiclesProvider(null)),
                ),
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return const EmptyState(
                      title: 'No Registered Vehicles',
                      message: 'You have no registered vehicles in your garage fleet yet.',
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
                      final v = vehicles[index];

                      return PitCard(
                        technicalLabel:
                            'VEHICLE • ${(v.id.length >= 8 ? v.id.substring(0, 8) : v.id).toUpperCase()}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.directions_car,
                                  color: AppColors.primaryAccent,
                                  size: 24,
                                ),
                                const SizedBox(width: AppSpacing.compact),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v.displayName,
                                        style: AppTypography.sectionTitle(
                                          color: textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      StatusBadge(
                                        label: v.identifierLabel,
                                        color: AppColors.primaryAccent,
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _showVehicleDialog(context, ref, v),
                                  icon: const Icon(Icons.edit, size: 14),
                                  label: const Text('Edit'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textPrimary,
                                    side: BorderSide(
                                      color: borderSubtle,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                            if (v.notes != null && v.notes!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.compact),
                              Text(
                                v.notes!,
                                style: AppTypography.bodySmall(
                                  color: textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.standard),
                            Divider(
                              color: borderSubtle,
                              height: 1,
                            ),
                            const SizedBox(height: AppSpacing.compact),
                            Wrap(
                              spacing: AppSpacing.section,
                              runSpacing: AppSpacing.compact,
                              children: [
                                if (v.modelYear != null)
                                  _buildInfoChip(
                                    context,
                                    Icons.calendar_today_outlined,
                                    'Year: ${v.modelYear}',
                                  ),
                                _buildInfoChip(
                                  context,
                                  Icons.speed_outlined,
                                  '${v.mileageKm.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} KM',
                                ),
                                if (v.color != null && v.color!.isNotEmpty)
                                  _buildInfoChip(
                                    context,
                                    Icons.palette_outlined,
                                    v.color!,
                                  ),
                                if (v.vin != null && v.vin!.isNotEmpty)
                                  _buildInfoChip(
                                    context,
                                    Icons.confirmation_number_outlined,
                                    'VIN: ${v.vin!}',
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

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.technical(color: textSecondary),
        ),
      ],
    );
  }
}

class _CustomerVehicleFormDialog extends ConsumerStatefulWidget {
  const _CustomerVehicleFormDialog({this.vehicle, required this.onSaved});

  final Vehicle? vehicle;
  final VoidCallback onSaved;

  @override
  ConsumerState<_CustomerVehicleFormDialog> createState() =>
      _CustomerVehicleFormDialogState();
}

class _CustomerVehicleFormDialogState
    extends ConsumerState<_CustomerVehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _variantController;
  late final TextEditingController _yearController;
  late final TextEditingController _plateController;
  late final TextEditingController _numberController;
  late final TextEditingController _vinController;
  late final TextEditingController _mileageController;
  late final TextEditingController _colorController;
  late final TextEditingController _notesController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _makeController = TextEditingController(text: v?.make ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _variantController = TextEditingController(text: v?.variant ?? '');
    _yearController = TextEditingController(
      text: v?.modelYear?.toString() ?? DateTime.now().year.toString(),
    );
    _plateController = TextEditingController(text: v?.licensePlate ?? '');
    _numberController = TextEditingController(text: v?.vehicleNumber ?? '');
    _vinController = TextEditingController(text: v?.vin ?? '');
    _mileageController = TextEditingController(
      text: v?.mileageKm.toString() ?? '0',
    );
    _colorController = TextEditingController(text: v?.color ?? '');
    _notesController = TextEditingController(text: v?.notes ?? '');
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _numberController.dispose();
    _vinController.dispose();
    _mileageController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final isEditing = widget.vehicle != null;
      final year = int.tryParse(_yearController.text.trim());
      final mileage = int.tryParse(_mileageController.text.trim()) ?? 0;

      if (isEditing) {
        await ref.read(vehiclesProvider.notifier).updateVehicle(
          id: widget.vehicle!.id,
          make: _makeController.text.trim(),
          model: _modelController.text.trim(),
          variant: _variantController.text.trim().isEmpty
              ? null
              : _variantController.text.trim(),
          modelYear: year,
          licensePlate: _plateController.text.trim().isEmpty
              ? null
              : _plateController.text.trim(),
          vehicleNumber: _numberController.text.trim().isEmpty
              ? null
              : _numberController.text.trim(),
          vin: _vinController.text.trim().isEmpty
              ? null
              : _vinController.text.trim(),
          mileageKm: mileage,
          color: _colorController.text.trim().isEmpty
              ? null
              : _colorController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      } else {
        final currentCustomer = await ref.read(currentCustomerProvider.future);
        if (currentCustomer == null) {
          throw Exception('Could not resolve your customer account.');
        }

        await ref.read(vehiclesProvider.notifier).createVehicle(
          customerId: currentCustomer.id,
          make: _makeController.text.trim(),
          model: _modelController.text.trim(),
          variant: _variantController.text.trim().isEmpty
              ? null
              : _variantController.text.trim(),
          modelYear: year,
          licensePlate: _plateController.text.trim().isEmpty
              ? null
              : _plateController.text.trim(),
          vehicleNumber: _numberController.text.trim().isEmpty
              ? null
              : _numberController.text.trim(),
          vin: _vinController.text.trim().isEmpty
              ? null
              : _vinController.text.trim(),
          mileageKm: mileage,
          color: _colorController.text.trim().isEmpty
              ? null
              : _colorController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      }

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Vehicle telemetry updated in your garage.'
                  : 'New vehicle registered to your garage fleet.',
            ),
            backgroundColor: AppColors.statusCompleted,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehicle != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.surfaceCard : AppColors.lightSurfaceCard;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'EDIT VEHICLE' : 'REGISTER NEW VEHICLE',
                    style: AppTypography.sectionTitle(color: textPrimary),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textMuted),
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
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
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _makeController,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Make / Brand *',
                            hintText: 'e.g. BMW, Porsche, Honda',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Make is required'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        TextFormField(
                          controller: _modelController,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Model *',
                            hintText: 'e.g. M3 Touring, 911 GT3',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Model is required'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        TextFormField(
                          controller: _variantController,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Variant / Trim',
                            hintText: 'e.g. Competition G81, xDrive',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        TextFormField(
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Model Year',
                            hintText: 'e.g. 2024',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        TextFormField(
                          controller: _plateController,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'License Plate *',
                            hintText: 'e.g. D 1999 AZ',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'License plate is required'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        TextFormField(
                          controller: _numberController,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Car / Fleet Number',
                            hintText: 'e.g. #15',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        TextFormField(
                          controller: _mileageController,
                          keyboardType: TextInputType.number,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Current Mileage (KM) *',
                            hintText: 'e.g. 12500',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Mileage is required';
                            }
                            final num = int.tryParse(v.trim());
                            if (num == null || num < 0) return 'Invalid KM';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        TextFormField(
                          controller: _colorController,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Color / Livery',
                            hintText: 'e.g. Isle of Man Green',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        TextFormField(
                          controller: _vinController,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'VIN / Chassis Number',
                            hintText: '17-digit VIN',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          style: AppTypography.bodyMedium(color: textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Vehicle Specification & Notes',
                            hintText:
                                'Modifications, tire sizes, maintenance notes...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.standard),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: 'Cancel',
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.standard),
                  Expanded(
                    child: PrimaryButton(
                      text: isEditing ? 'Save Changes' : 'Register Vehicle',
                      isLoading: _isSaving,
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
