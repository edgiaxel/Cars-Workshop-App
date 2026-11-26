import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workshop_bay_model.dart';

class WorkshopBayRepository {
  WorkshopBayRepository({this.client});

  final SupabaseClient? client;
  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  Future<List<WorkshopBayModel>> fetchBays() async {
    final response = await _supabase
        .from('workshop_bays')
        .select('*, service_orders(order_number, status, customers(full_name), vehicles(license_plate, model))')
        .order('bay_number', ascending: true);

    return (response as List)
        .map((row) => WorkshopBayModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Upserts the canonical 5 workshop bays into `public.workshop_bays`.
  Future<List<WorkshopBayModel>> initializeDefaultBays() async {
    const defaultBays = [
      {'bay_number': 1, 'name': 'Bay 01 - Quick Service', 'status': 'available'},
      {'bay_number': 2, 'name': 'Bay 02 - Diagnostic & Performance', 'status': 'available'},
      {'bay_number': 3, 'name': 'Bay 03 - Heavy Repair', 'status': 'available'},
      {'bay_number': 4, 'name': 'Bay 04 - Electrical & Electronics', 'status': 'available'},
      {'bay_number': 5, 'name': 'Bay 05 - Suspension & Brakes', 'status': 'available'},
    ];

    await _supabase
        .from('workshop_bays')
        .upsert(defaultBays, onConflict: 'bay_number');

    return fetchBays();
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
