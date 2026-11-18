import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/service_task.dart';

abstract class TaskRemoteDataSource {
  Future<List<ServiceTask>> getTasks({
    String? mechanicId,
    String? serviceOrderId,
  });
  Future<void> updateTaskStatus(String id, String status);
  Future<ServiceTask> createTask({
    required String serviceOrderId,
    String? assignedMechanicId,
    required String title,
    String? description,
    String? notes,
    String status = 'pending',
  });
  Future<ServiceTask> updateTask({
    required String id,
    String? status,
    String? notes,
    int? actualMinutes,
  });
  Future<void> deleteTask(String id);
}

class SupabaseTaskRemoteDataSource implements TaskRemoteDataSource {
  SupabaseTaskRemoteDataSource(this._client);
  final SupabaseClient? _client;

  @override
  Future<List<ServiceTask>> getTasks({
    String? mechanicId,
    String? serviceOrderId,
  }) async {
    final client = _client;
    if (client == null) return [];

    var query = client
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
    final client = _client;
    if (client == null) return;
    await client.from('service_tasks').update({'status': status}).eq('id', id);
  }

  @override
  Future<ServiceTask> createTask({
    required String serviceOrderId,
    String? assignedMechanicId,
    required String title,
    String? description,
    String? notes,
    String status = 'pending',
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase client is unavailable');
    }
    final payload = <String, dynamic>{
      'service_order_id': serviceOrderId,
      'title': title,
      'status': status,
      'assigned_mechanic_id': ?assignedMechanicId,
      if (description != null && description.isNotEmpty) 'description': description,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final data = await client
        .from('service_tasks')
        .insert(payload)
        .select(
          '*, mechanics(*, profiles(*)), service_orders(*, vehicles(*), customers(*, profiles(*)))',
        )
        .single();

    return ServiceTask.fromJson(data);
  }

  @override
  Future<ServiceTask> updateTask({
    required String id,
    String? status,
    String? notes,
    int? actualMinutes,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase client is unavailable');
    }
    final payload = <String, dynamic>{
      'status': ?status,
      'notes': ?notes,
      'actual_minutes': ?actualMinutes,
      if (status == 'completed') 'completed_at': DateTime.now().toIso8601String(),
      if (status == 'in_progress') 'started_at': DateTime.now().toIso8601String(),
    };

    final data = await client
        .from('service_tasks')
        .update(payload)
        .eq('id', id)
        .select(
          '*, mechanics(*, profiles(*)), service_orders(*, vehicles(*), customers(*, profiles(*)))',
        )
        .single();

    return ServiceTask.fromJson(data);
  }

  @override
  Future<void> deleteTask(String id) async {
    final client = _client;
    if (client == null) return;
    await client.from('service_tasks').delete().eq('id', id);
  }
}
