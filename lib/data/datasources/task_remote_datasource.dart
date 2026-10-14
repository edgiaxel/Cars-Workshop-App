import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/service_task.dart';

abstract class TaskRemoteDataSource {
  Future<List<ServiceTask>> getTasks({
    String? mechanicId,
    String? serviceOrderId,
  });
  Future<void> updateTaskStatus(String id, String status);
}

class SupabaseTaskRemoteDataSource implements TaskRemoteDataSource {
  SupabaseTaskRemoteDataSource(this._client);
  final SupabaseClient? _client;

  @override
  Future<List<ServiceTask>> getTasks({
    String? mechanicId,
    String? serviceOrderId,
  }) async {
    if (_client == null) return [];

    var query = _client
        .from('service_tasks')
        .select(
          '*, mechanics(*, profiles(*)), service_orders(*, vehicles(*), customers(*, profiles(*)))',
        );

    if (mechanicId != null) {
      query = query.eq('assigned_mechanic_id', mechanicId);
    }
    if (serviceOrderId != null) {
      query = query.eq('service_order_id', serviceOrderId);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List)
        .map((json) => ServiceTask.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateTaskStatus(String id, String status) async {
    if (_client == null) return;
    await _client.from('service_tasks').update({'status': status}).eq('id', id);
  }
}
