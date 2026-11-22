import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_order_model.dart';

class ServiceOrderRepository {
  ServiceOrderRepository({this.client});

  final SupabaseClient? client;

  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  Future<ServiceOrderModel> createIntake({
    required String customerId,
    required String vehicleId,
    required int odometer,
    required String customerComplaint,
    String intakeType = 'walk_in',
    String? bookingId,
    String? fuelLevel,
    String? initialNotes,
    String assignedBay = 'Bay 01',
  }) async {
    final response = await _supabase.rpc(
      'create_service_order_intake',
      params: {
        'p_customer_id': customerId,
        'p_vehicle_id': vehicleId,
        'p_odometer': odometer,
        'p_customer_complaint': customerComplaint,
        'p_intake_type': intakeType,
        'p_booking_id': bookingId,
        'p_fuel_level': fuelLevel,
        'p_initial_notes': initialNotes,
        'p_assigned_bay': assignedBay,
      },
    );

    return ServiceOrderModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<ServiceOrderModel>> fetchActiveOrders() async {
    final response = await _supabase
        .from('service_orders')
        .select('*, customers(full_name, phone_number), vehicles(license_plate, make, model)')
        .not('status', 'in', '("completed","closed","cancelled")')
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => ServiceOrderModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<ServiceOrderModel?> fetchOrderById(String orderId) async {
    final response = await _supabase
        .from('service_orders')
        .select('*, customers(full_name, phone_number), vehicles(license_plate, make, model)')
        .eq('id', orderId)
        .maybeSingle();

    if (response == null) return null;
    return ServiceOrderModel.fromJson(response);
  }
}
