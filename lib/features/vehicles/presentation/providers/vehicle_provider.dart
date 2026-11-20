import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/features/vehicles/data/vehicle_repository.dart';
import 'package:pitmate/features/vehicles/domain/vehicle.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return SupabaseVehicleRepository();
});

final customerVehiclesProvider = FutureProvider.autoDispose.family<List<Vehicle>, String>((ref, customerId) async {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.getVehicles(customerId: customerId);
});

final allVehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) async {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.getVehicles();
});
