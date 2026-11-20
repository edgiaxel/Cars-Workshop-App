import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../customers/domain/customer.dart';
import '../../customers/presentation/providers/customer_provider.dart';
import '../domain/vehicle.dart';
import 'admin_vehicles_page.dart';
import 'providers/vehicle_provider.dart';

class CustomerGaragePage extends ConsumerWidget {
  const CustomerGaragePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your garage')),
      );
    }

    final AsyncValue<Customer?> customerAsync =
        ref.watch(currentCustomerProfileProvider(user.id));

    return customerAsync.when(
      loading: () => const Scaffold(body: LoadingState(message: 'Loading profile...')),
      error: (err, _) => Scaffold(
        body: ErrorState(
          title: 'Failed to Load Profile',
          message: err.toString(),
        ),
      ),
      data: (Customer? customer) {
        if (customer == null) {
          return const Scaffold(
            body: EmptyState(
              title: 'Customer Profile Not Linked',
              description:
                  'Your authenticated account is not yet linked to a workshop customer record.',
            ),
          );
        }

        final AsyncValue<List<Vehicle>> vehiclesAsync =
            ref.watch(customerVehiclesProvider(customer.id));

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Garage'),
            actions: [
              IconButton(
                tooltip: 'Add Vehicle',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        AddVehicleDialog(fixedCustomerId: customer.id),
                  ).then((_) => ref.refresh(customerVehiclesProvider(customer.id)));
                },
              ),
            ],
          ),
          body: vehiclesAsync.when(
            loading: () => const LoadingState(message: 'Loading vehicles...'),
            error: (err, _) => ErrorState(
              title: 'Failed to Load Vehicles',
              message: err.toString(),
              onRetry: () => ref.refresh(customerVehiclesProvider(customer.id)),
            ),
            data: (List<Vehicle> vehicles) {
              if (vehicles.isEmpty) {
                return EmptyState(
                  title: 'Your Garage is Empty',
                  description:
                      'Register your vehicle to schedule service appointments and track repairs.',
                  actionLabel: 'Add Your First Vehicle',
                  onAction: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          AddVehicleDialog(fixedCustomerId: customer.id),
                    ).then((_) => ref.refresh(customerVehiclesProvider(customer.id)));
                  },
                );
              }

              return ListView.separated(
                padding: AppSpacing.paddingMd,
                itemCount: vehicles.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  return PitCard(
                    padding: AppSpacing.paddingMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${vehicle.make} ${vehicle.model}',
                              style: AppTypography.headingSmall(),
                            ),
                            StatusBadge(
                              label: vehicle.licensePlate,
                              variant: StatusBadgeVariant.error,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Year: ${vehicle.year} • Mileage: ${vehicle.currentMileage} km',
                          style: AppTypography.bodySmall(color: AppColors.neutral),
                        ),
                        if (vehicle.transmission != null || vehicle.color != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${vehicle.transmission ?? ''} ${vehicle.color != null ? '• ${vehicle.color}' : ''}',
                            style: AppTypography.bodySmall(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('add_garage_vehicle_button'),
            icon: const Icon(Icons.add),
            label: const Text('Add Vehicle'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) =>
                    AddVehicleDialog(fixedCustomerId: customer.id),
              ).then((_) => ref.refresh(customerVehiclesProvider(customer.id)));
            },
          ),
        );
      },
    );
  }
}
