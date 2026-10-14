import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/vehicle_remote_datasource.dart';
import '../../data/models/vehicle.dart';
import '../../data/repositories/vehicle_repository.dart';
import 'supabase_provider.dart';

/// Provider for [VehicleRemoteDataSource].
final vehicleRemoteDataSourceProvider = Provider<VehicleRemoteDataSource?>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseVehicleRemoteDataSource(client);
});

/// Provider for [VehicleRepository].
final vehicleRepositoryProvider = Provider<VehicleRepository?>((ref) {
  final dataSource = ref.watch(vehicleRemoteDataSourceProvider);
  if (dataSource == null) return null;
  return SupabaseVehicleRepository(dataSource);
});

/// AsyncNotifier managing the Vehicle fleet list for Admin.
class VehiclesNotifier extends AsyncNotifier<List<Vehicle>> {
  String _searchQuery = '';
  String _filterMake = 'All';

  String get searchQuery => _searchQuery;
  String get filterMake => _filterMake;

  @override
  Future<List<Vehicle>> build() async {
    final repository = ref.watch(vehicleRepositoryProvider);
    if (repository == null) {
      return const [];
    }
    return repository.getVehicles(
      searchQuery: _searchQuery,
      filterMake: _filterMake,
    );
  }

  Future<void> setFilter({String? query, String? make}) async {
    if (query != null) _searchQuery = query;
    if (make != null) _filterMake = make;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(vehicleRepositoryProvider);
      if (repository == null) return const [];
      return repository.getVehicles(
        searchQuery: _searchQuery,
        filterMake: _filterMake,
      );
    });
  }

  Future<Vehicle> createVehicle({
    required String customerId,
    required String make,
    required String model,
    String? variant,
    int? modelYear,
    String? licensePlate,
    String? vin,
    String? vehicleNumber,
    int mileageKm = 0,
    String? color,
    String? notes,
  }) async {
    final repository = ref.read(vehicleRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase vehicle repository is unconfigured.');
    }

    final created = await repository.createVehicle(
      customerId: customerId,
      make: make,
      model: model,
      variant: variant,
      modelYear: modelYear,
      licensePlate: licensePlate,
      vin: vin,
      vehicleNumber: vehicleNumber,
      mileageKm: mileageKm,
      color: color,
      notes: notes,
    );

    ref.invalidateSelf();
    return created;
  }

  Future<Vehicle> updateVehicle({
    required String id,
    String? customerId,
    String? make,
    String? model,
    String? variant,
    int? modelYear,
    String? licensePlate,
    String? vin,
    String? vehicleNumber,
    int? mileageKm,
    String? color,
    String? notes,
  }) async {
    final repository = ref.read(vehicleRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase vehicle repository is unconfigured.');
    }

    final updated = await repository.updateVehicle(
      id: id,
      customerId: customerId,
      make: make,
      model: model,
      variant: variant,
      modelYear: modelYear,
      licensePlate: licensePlate,
      vin: vin,
      vehicleNumber: vehicleNumber,
      mileageKm: mileageKm,
      color: color,
      notes: notes,
    );

    ref.invalidateSelf();
    return updated;
  }

  Future<void> deleteVehicle(String id) async {
    final repository = ref.read(vehicleRepositoryProvider);
    if (repository == null) {
      throw Exception('Supabase vehicle repository is unconfigured.');
    }

    await repository.deleteVehicle(id);
    ref.invalidateSelf();
  }
}

/// Provider exposing reactive vehicle fleet.
final vehiclesProvider = AsyncNotifierProvider<VehiclesNotifier, List<Vehicle>>(
  VehiclesNotifier.new,
);

/// Provider fetching vehicles for the currently logged in customer (or given customerId).
final customerVehiclesProvider = FutureProvider.family<List<Vehicle>, String?>((
  ref,
  customerId,
) async {
  final repository = ref.watch(vehicleRepositoryProvider);
  if (repository == null) return const [];
  return repository.getVehicles(customerId: customerId);
});
