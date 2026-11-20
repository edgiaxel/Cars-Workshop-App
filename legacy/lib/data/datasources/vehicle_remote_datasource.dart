import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vehicle.dart';

/// Contract for Vehicle remote data operations.
abstract class VehicleRemoteDataSource {
  Future<List<Vehicle>> fetchVehicles({
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

/// Supabase implementation for [VehicleRemoteDataSource].
class SupabaseVehicleRemoteDataSource implements VehicleRemoteDataSource {
  const SupabaseVehicleRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Vehicle>> fetchVehicles({
    String? customerId,
    String? searchQuery,
    String? filterMake,
  }) async {
    var query = _client.from('vehicles').select('*, customers(*, profiles(*))');

    if (customerId != null && customerId.isNotEmpty) {
      query = query.eq('customer_id', customerId);
    }

    if (filterMake != null &&
        filterMake.isNotEmpty &&
        filterMake.toLowerCase() != 'all') {
      query = query.ilike('make', '%$filterMake%');
    }

    final data = await query.order('created_at', ascending: false);
    final vehicles = (data as List)
        .map((json) => Vehicle.fromJson(json as Map<String, dynamic>))
        .toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      return vehicles.where((v) {
        final makeModelMatch = v.displayName.toLowerCase().contains(q);
        final plateMatch = v.licensePlate?.toLowerCase().contains(q) ?? false;
        final numMatch = v.vehicleNumber?.toLowerCase().contains(q) ?? false;
        final ownerMatch =
            v.customer?.displayName.toLowerCase().contains(q) ?? false;
        return makeModelMatch || plateMatch || numMatch || ownerMatch;
      }).toList();
    }

    return vehicles;
  }

  @override
  Future<Vehicle> getVehicleById(String id) async {
    final data = await _client
        .from('vehicles')
        .select('*, customers(*, profiles(*))')
        .eq('id', id)
        .single();
    return Vehicle.fromJson(data);
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
  }) async {
    final payload = <String, dynamic>{
      'customer_id': customerId,
      'make': make.trim(),
      'model': model.trim(),
      'mileage_km': mileageKm,
    };
    if (variant != null && variant.trim().isNotEmpty) {
      payload['variant'] = variant.trim();
    }
    if (modelYear != null) {
      payload['model_year'] = modelYear;
    }
    if (licensePlate != null && licensePlate.trim().isNotEmpty) {
      payload['license_plate'] = licensePlate.trim().toUpperCase();
    }
    if (vin != null && vin.trim().isNotEmpty) {
      payload['vin'] = vin.trim().toUpperCase();
    }
    if (vehicleNumber != null && vehicleNumber.trim().isNotEmpty) {
      payload['vehicle_number'] = vehicleNumber.trim();
    }
    if (color != null && color.trim().isNotEmpty) {
      payload['color'] = color.trim();
    }
    if (notes != null && notes.trim().isNotEmpty) {
      payload['notes'] = notes.trim();
    }

    final data = await _client
        .from('vehicles')
        .insert(payload)
        .select('*, customers(*, profiles(*))')
        .single();

    return Vehicle.fromJson(data);
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
  }) async {
    final updatePayload = <String, dynamic>{};
    if (customerId != null) updatePayload['customer_id'] = customerId;
    if (make != null) updatePayload['make'] = make.trim();
    if (model != null) updatePayload['model'] = model.trim();
    if (variant != null) updatePayload['variant'] = variant.trim();
    if (modelYear != null) updatePayload['model_year'] = modelYear;
    if (licensePlate != null) {
      updatePayload['license_plate'] = licensePlate.trim().toUpperCase();
    }
    if (vin != null) updatePayload['vin'] = vin.trim().toUpperCase();
    if (vehicleNumber != null) {
      updatePayload['vehicle_number'] = vehicleNumber.trim();
    }
    if (mileageKm != null) updatePayload['mileage_km'] = mileageKm;
    if (color != null) updatePayload['color'] = color.trim();
    if (notes != null) updatePayload['notes'] = notes.trim();

    final data = await _client
        .from('vehicles')
        .update(updatePayload)
        .eq('id', id)
        .select('*, customers(*, profiles(*))')
        .single();

    return Vehicle.fromJson(data);
  }

  @override
  Future<void> deleteVehicle(String id) async {
    await _client.from('vehicles').delete().eq('id', id);
  }
}
