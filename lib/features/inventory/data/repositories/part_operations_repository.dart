import 'package:pitmate/features/inventory/data/models/part_request_model.dart';
import 'package:pitmate/features/inventory/data/models/service_task_part_consumption_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository managing mechanic part requests, admin fulfillment, and operation consumption.
class PartOperationsRepository {
  final SupabaseClient? _client;

  PartOperationsRepository([SupabaseClient? client]) : _client = client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Submits a new floor part request for a task.
  Future<PartRequestModel> requestPart({
    required String taskId,
    required String partId,
    required int quantity,
    String? notes,
  }) async {
    final response = await _supabase.rpc(
      'request_part_for_task',
      params: {
        'p_task_id': taskId,
        'p_part_id': partId,
        'p_quantity': quantity,
        'p_notes': notes,
      },
    );

    return PartRequestModel.fromJson(response as Map<String, dynamic>);
  }

  /// Admin fulfills a pending part request (whole or partial).
  Future<PartRequestModel> fulfillRequest({
    required String requestId,
    required int quantityToFulfill,
  }) async {
    final response = await _supabase.rpc(
      'fulfill_part_request',
      params: {
        'p_request_id': requestId,
        'p_quantity_to_fulfill': quantityToFulfill,
      },
    );

    return PartRequestModel.fromJson(response as Map<String, dynamic>);
  }

  /// Admin rejects or cancels a part request, releasing any reserved stock.
  Future<PartRequestModel> rejectRequest({
    required String requestId,
    String? reason,
  }) async {
    final response = await _supabase.rpc(
      'reject_part_request',
      params: {
        'p_request_id': requestId,
        'p_reason': reason,
      },
    );

    return PartRequestModel.fromJson(response as Map<String, dynamic>);
  }

  /// Fetches pending or recent part requests for workshop floor.
  Future<List<PartRequestModel>> fetchRequests({String? serviceOrderId, String? status}) async {
    var query = _supabase.from('part_requests').select('*, parts(sku, name, unit_of_measurement), profiles(full_name)');

    if (serviceOrderId != null && serviceOrderId.isNotEmpty) {
      query = query.eq('service_order_id', serviceOrderId);
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      query = query.eq('status', status);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((row) => PartRequestModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Records actual part consumption and returns unused units for a task.
  Future<Map<String, dynamic>> consumeAndReturnParts({
    required String taskId,
    required String partId,
    required int consumedQty,
    required int returnedQty,
  }) async {
    final response = await _supabase.rpc(
      'consume_and_return_parts',
      params: {
        'p_task_id': taskId,
        'p_part_id': partId,
        'p_consumed_qty': consumedQty,
        'p_returned_qty': returnedQty,
      },
    );

    return (response as Map<String, dynamic>?) ?? {};
  }

  /// Fetches consumed parts recorded on an operation.
  Future<List<ServiceTaskPartConsumptionModel>> fetchTaskConsumptions(String taskId) async {
    final response = await _supabase
        .from('service_task_part_consumptions')
        .select('*, parts(sku, name, unit_of_measurement)')
        .eq('task_id', taskId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => ServiceTaskPartConsumptionModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Fetches list of catalog parts with available stock for mechanic request dialog.
  Future<List<Map<String, dynamic>>> fetchCatalogForRequest() async {
    final response = await _supabase
        .from('parts')
        .select('id, sku, name, unit_of_measurement, inventory_balances(quantity_available)')
        .order('name', ascending: true);

    return (response as List).cast<Map<String, dynamic>>();
  }
}
