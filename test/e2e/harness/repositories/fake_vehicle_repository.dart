import 'package:pitmate/core/errors/app_exception.dart';
import '../models/e2e_vehicle.dart';
import '../fixtures/seed_fixtures.dart';

/// Test fake for VehicleRepository matching PROJECT.md interface contract.
class FakeVehicleRepository {
  final List<Vehicle> _vehicles = [];

  FakeVehicleRepository({List<Vehicle>? initialVehicles}) {
    if (initialVehicles != null) {
      _vehicles.addAll(initialVehicles);
    } else {
      _vehicles.addAll([
        SeedFixtures.vehicle1,
        SeedFixtures.vehicle2,
        SeedFixtures.guestVehicle,
      ]);
    }
  }

  List<Vehicle> get snapshot => List.unmodifiable(_vehicles);

  Future<List<Vehicle>> getVehiclesByCustomerId(String customerId) async {
    return _vehicles.where((v) => v.customerId == customerId).toList();
  }

  Future<List<Vehicle>> getAllVehicles({String? search}) async {
    if (search == null || search.trim().isEmpty) {
      return List.unmodifiable(_vehicles);
    }
    final query = search.trim().toLowerCase();
    return _vehicles.where((v) {
      final matchesPlate = v.licensePlate.toLowerCase().contains(query);
      final matchesMake = v.make.toLowerCase().contains(query);
      final matchesModel = v.model.toLowerCase().contains(query);
      final matchesVin = (v.vin ?? '').toLowerCase().contains(query);
      return matchesPlate || matchesMake || matchesModel || matchesVin;
    }).toList();
  }

  Future<bool> checkLicensePlateExists(String licensePlate) async {
    final normalized = Vehicle.normalizePlate(licensePlate);
    return _vehicles.any((v) => v.licensePlate == normalized);
  }

  Future<Vehicle> registerVehicle(Vehicle vehicle) async {
    final normalizedPlate = Vehicle.normalizePlate(vehicle.licensePlate);
    if (normalizedPlate.isEmpty) {
      throw const ValidationException('License plate cannot be empty.');
    }

    // Duplicate check
    final exists = await checkLicensePlateExists(normalizedPlate);
    if (exists) {
      throw ValidationException('Duplicate license plate: $normalizedPlate already exists.');
    }

    // Year validation (1900..2100 per database schema check)
    if (vehicle.year < 1900 || vehicle.year > 2100) {
      throw ValidationException(
        'Vehicle year must be between 1900 and 2100. Received: ${vehicle.year}',
      );
    }

    // Mileage validation (>= 0)
    if (vehicle.currentMileage < 0) {
      throw ValidationException(
        'Odometer mileage cannot be negative. Received: ${vehicle.currentMileage}',
      );
    }

    if (vehicle.make.trim().isEmpty) {
      throw const ValidationException('Vehicle make cannot be empty.');
    }
    if (vehicle.model.trim().isEmpty) {
      throw const ValidationException('Vehicle model cannot be empty.');
    }

    final newVehicle = vehicle.copyWith(
      id: vehicle.id.isEmpty
          ? 'veh-${DateTime.now().millisecondsSinceEpoch}'
          : vehicle.id,
      licensePlate: normalizedPlate,
      make: vehicle.make.trim(),
      model: vehicle.model.trim(),
    );

    _vehicles.add(newVehicle);
    return newVehicle;
  }
}
