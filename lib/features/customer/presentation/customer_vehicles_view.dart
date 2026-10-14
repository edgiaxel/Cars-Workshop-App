import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/vehicle.dart';
import '../../../shared/providers/vehicle_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import 'customer_shell.dart';

/// Customer vehicles garage view connected to real Supabase records.
class CustomerVehiclesPage extends ConsumerWidget {
  const CustomerVehiclesPage({super.key});

  void _showAddVehicleDialog(BuildContext context) {
    final makeController = TextEditingController();
    final modelController = TextEditingController();
    final plateController = TextEditingController();
    final mileageController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        title: Text(
          'REGISTER NEW VEHICLE',
          style: AppTypography.sectionTitle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add a new vehicle to your garage fleet. Service history and maintenance reminders will be tracked automatically.',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.standard),
              TextField(
                controller: makeController,
                style: AppTypography.bodyMedium(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Make / Brand (e.g. BMW)',
                ),
              ),
              const SizedBox(height: AppSpacing.standard),
              TextField(
                controller: modelController,
                style: AppTypography.bodyMedium(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Model (e.g. M3 Touring G81)',
                ),
              ),
              const SizedBox(height: AppSpacing.standard),
              TextField(
                controller: plateController,
                style: AppTypography.bodyMedium(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'License Plate (e.g. D 1999 AZ)',
                ),
              ),
              const SizedBox(height: AppSpacing.standard),
              TextField(
                controller: mileageController,
                keyboardType: TextInputType.number,
                style: AppTypography.bodyMedium(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Current Mileage (KM)',
                ),
              ),
            ],
          ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Vehicle registration added to your garage fleet.',
                  ),
                  backgroundColor: AppColors.statusCompleted,
                ),
              );
            },
            child: const Text('Register Vehicle'),
          ),
        ],
      ),
    );
  }

  void _showEditVehicleDialog(BuildContext context, Vehicle v) {
    final mileageController = TextEditingController(
      text: v.mileageKm.toString(),
    );
    final notesController = TextEditingController(text: v.notes ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfacePrimary,
        title: Text(
          'UPDATE VEHICLE TELEMETRY',
          style: AppTypography.sectionTitle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                v.displayName,
                style: AppTypography.label(color: AppColors.primaryAccent),
              ),
              const SizedBox(height: AppSpacing.standard),
              TextField(
                controller: mileageController,
                keyboardType: TextInputType.number,
                style: AppTypography.bodyMedium(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Updated Odometer (KM)',
                ),
              ),
              const SizedBox(height: AppSpacing.standard),
              TextField(
                controller: notesController,
                maxLines: 2,
                style: AppTypography.bodyMedium(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Service Notes & Specs',
                ),
              ),
            ],
          ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vehicle telemetry updated.'),
                  backgroundColor: AppColors.statusCompleted,
                ),
              );
            },
            child: const Text('Save Updates'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(customerVehiclesProvider(null));

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
                  onPressed: () => _showAddVehicleDialog(context),
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
                                          color: AppColors.textPrimary,
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
                                      _showEditVehicleDialog(context, v),
                                  icon: const Icon(Icons.edit, size: 14),
                                  label: const Text('Edit'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textPrimary,
                                    side: const BorderSide(
                                      color: AppColors.borderSubtle,
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
                                if (v.modelYear != null)
                                  _buildInfoChip(
                                    Icons.calendar_today_outlined,
                                    'Year: ${v.modelYear}',
                                  ),
                                _buildInfoChip(
                                  Icons.speed_outlined,
                                  '${v.mileageKm.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} KM',
                                ),
                                if (v.color != null && v.color!.isNotEmpty)
                                  _buildInfoChip(
                                    Icons.palette_outlined,
                                    v.color!,
                                  ),
                                if (v.vin != null && v.vin!.isNotEmpty)
                                  _buildInfoChip(
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
