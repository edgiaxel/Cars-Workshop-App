import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../app/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/vehicle.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> getVehicles({String? customerId, String? query});
  Future<Vehicle?> getVehicleById(String id);
  Future<Vehicle> registerVehicle({
    required String customerId,
    required String licensePlate,
    required String make,
    required String model,
    required int year,
    String? vin,
    String? color,
    String? transmission,
    int currentMileage = 0,
    String? notes,
  });
  Future<Vehicle> updateVehicle(Vehicle vehicle);
  Future<bool> isPlateRegistered(String licensePlate);
}

class SupabaseVehicleRepository implements VehicleRepository {
  supa.SupabaseClient get _client => supa.Supabase.instance.client;

  @override
  Future<List<Vehicle>> getVehicles({String? customerId, String? query}) async {
    if (!AppConfig.isSupabaseConfigured) return [];

    try {
      var queryBuilder = _client.from('vehicles').select();

      if (customerId != null) {
        queryBuilder = queryBuilder.eq('customer_id', customerId);
      }

      if (query != null && query.trim().isNotEmpty) {
        queryBuilder = queryBuilder.or(
          'license_plate.ilike.%${query.trim()}%,make.ilike.%${query.trim()}%,model.ilike.%${query.trim()}%',
        );
      }

      final data = await queryBuilder.order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch vehicles: $e');
    }
  }

  @override
  Future<Vehicle?> getVehicleById(String id) async {
    if (!AppConfig.isSupabaseConfigured) return null;

    try {
      final data = await _client
          .from('vehicles')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return Vehicle.fromJson(data);
    } catch (e) {
      throw DatabaseException('Failed to fetch vehicle: $e');
    }
  }

  @override
  Future<bool> isPlateRegistered(String licensePlate) async {
    if (!AppConfig.isSupabaseConfigured) return false;

    try {
      final data = await _client
          .from('vehicles')
          .select('id')
          .ilike('license_plate', licensePlate.trim())
          .maybeSingle();

      return data != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Vehicle> registerVehicle({
    required String customerId,
    required String licensePlate,
    required String make,
    required String model,
    required int year,
    String? vin,
    String? color,
    String? transmission,
    int currentMileage = 0,
    String? notes,
  }) async {
    if (!AppConfig.isSupabaseConfigured) {
      throw const DatabaseException('Supabase not configured');
    }

    final normalizedPlate = licensePlate.trim().toUpperCase();
    final isDuplicate = await isPlateRegistered(normalizedPlate);
    if (isDuplicate) {
      throw ValidationException('Vehicle plate $normalizedPlate is already registered');
    }

    try {
      final payload = {
        'customer_id': customerId,
        'license_plate': normalizedPlate,
        'make': make.trim(),
        'model': model.trim(),
        'year': year,
        'vin': vin?.trim().isEmpty == true ? null : vin?.trim().toUpperCase(),
        'color': color?.trim(),
        'transmission': transmission?.trim(),
        'current_mileage': currentMileage,
        'notes': notes?.trim(),
      };

      final data = await _client
          .from('vehicles')
          .insert(payload)
          .select()
          .single();

      return Vehicle.fromJson(data);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to register vehicle: $e');
    }
  }

  @override
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    if (!AppConfig.isSupabaseConfigured) {
      throw const DatabaseException('Supabase not configured');
    }

    try {
      final data = await _client
          .from('vehicles')
          .update(vehicle.toJson())
          .eq('id', vehicle.id)
          .select()
          .single();

      return Vehicle.fromJson(data);
    } catch (e) {
      throw DatabaseException('Failed to update vehicle: $e');
    }
  }
}
