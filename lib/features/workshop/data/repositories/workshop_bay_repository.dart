import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workshop_bay_model.dart';

class WorkshopBayRepository {
  WorkshopBayRepository({this.client});

  final SupabaseClient? client;
  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  Future<List<WorkshopBayModel>> fetchBays() async {
    final response = await _supabase
        .from('workshop_bays')
        .select('*, service_orders(order_number, customers(full_name), vehicles(license_plate, model))')
        .order('bay_number', ascending: true);

    return (response as List)
        .map((row) => WorkshopBayModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<WorkshopBayModel> assignBay({
    required String serviceOrderId,
    required int bayNumber,
  }) async {
    final response = await _supabase.rpc(
      'assign_vehicle_bay',
      params: {
        'p_service_order_id': serviceOrderId,
        'p_bay_number': bayNumber,
      },
    );

    return WorkshopBayModel.fromJson(response as Map<String, dynamic>);
  }
}
