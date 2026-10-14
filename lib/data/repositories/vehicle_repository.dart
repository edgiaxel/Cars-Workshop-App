import '../datasources/vehicle_remote_datasource.dart';
import '../models/vehicle.dart';

/// Repository contract for Vehicle operations.
abstract class VehicleRepository {
  Future<List<Vehicle>> getVehicles({
    String? customerId,
    String? searchQuery,
    String? filterMake,
  });
  Future<Vehicle> getVehicleById(String id);
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
  });
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
  });
  Future<void> deleteVehicle(String id);
}

/// Supabase implementation for [VehicleRepository].
class SupabaseVehicleRepository implements VehicleRepository {
  const SupabaseVehicleRepository(this._remoteDataSource);

  final VehicleRemoteDataSource _remoteDataSource;

  @override
  Future<List<Vehicle>> getVehicles({
    String? customerId,
    String? searchQuery,
    String? filterMake,
  }) {
    return _remoteDataSource.fetchVehicles(
      customerId: customerId,
      searchQuery: searchQuery,
      filterMake: filterMake,
    );
  }

  @override
  Future<Vehicle> getVehicleById(String id) {
    return _remoteDataSource.getVehicleById(id);
  }

  @override
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
  }) {
    return _remoteDataSource.createVehicle(
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
  }

  @override
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
  }) {
    return _remoteDataSource.updateVehicle(
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
  }

  @override
  Future<void> deleteVehicle(String id) {
    return _remoteDataSource.deleteVehicle(id);
  }
}
