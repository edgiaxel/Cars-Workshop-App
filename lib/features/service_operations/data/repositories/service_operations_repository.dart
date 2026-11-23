import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_order_task_model.dart';

class ServiceOperationsRepository {
  ServiceOperationsRepository({this.client});

  final SupabaseClient? client;
  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  Future<List<ServiceOrderTaskModel>> fetchTasksForOrder(String serviceOrderId) async {
    final response = await _supabase
        .from('service_order_tasks')
        .select('*, task_checklists(*), assigned_mechanic:profiles!assigned_mechanic_id(full_name)')
        .eq('service_order_id', serviceOrderId)
        .order('sequence_order', ascending: true);

    return (response as List)
        .map((row) => ServiceOrderTaskModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<ServiceOrderTaskModel>> fetchTasksForMechanic(String mechanicId) async {
    final response = await _supabase
        .from('service_order_tasks')
        .select('*, task_checklists(*), service_orders(order_number, vehicles(license_plate, model)), assigned_mechanic:profiles!assigned_mechanic_id(full_name)')
        .eq('assigned_mechanic_id', mechanicId)
        .order('sequence_order', ascending: true);

    return (response as List)
        .map((row) => ServiceOrderTaskModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> dispatchOperations({
    required String serviceOrderId,
    required List<Map<String, dynamic>> tasks,
    String? leadMechanicId,
    int? bayNumber,
  }) async {
    await _supabase.rpc(
      'dispatch_order_operations',
      params: {
        'p_service_order_id': serviceOrderId,
        'p_tasks': tasks,
        'p_lead_mechanic_id': leadMechanicId,
        'p_bay_number': bayNumber,
      },
    );
  }

  Future<ServiceOrderTaskModel> startTask({
    required String taskId,
    String? mechanicId,
  }) async {
    final response = await _supabase.rpc(
      'start_task_operation',
      params: {
        'p_task_id': taskId,
        'p_mechanic_id': mechanicId,
      },
    );

    return ServiceOrderTaskModel.fromJson(response as Map<String, dynamic>);
  }

  Future<ServiceOrderTaskModel> pauseTask({
    required String taskId,
    required String reason,
  }) async {
    final response = await _supabase.rpc(
      'pause_task_operation',
      params: {
        'p_task_id': taskId,
        'p_reason': reason,
      },
    );

    return ServiceOrderTaskModel.fromJson(response as Map<String, dynamic>);
  }

  Future<ServiceOrderTaskModel> resumeTask(String taskId) async {
    final response = await _supabase.rpc(
      'resume_task_operation',
      params: {
        'p_task_id': taskId,
      },
    );

    return ServiceOrderTaskModel.fromJson(response as Map<String, dynamic>);
  }

  Future<ServiceOrderTaskModel> completeTask(String taskId) async {
    final response = await _supabase.rpc(
      'complete_task_operation',
      params: {
        'p_task_id': taskId,
      },
    );

    return ServiceOrderTaskModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> toggleChecklist({
    required String checklistId,
    required bool isCompleted,
    String? mechanicId,
  }) async {
    await _supabase
        .from('task_checklists')
        .update({
          'is_completed': isCompleted,
          'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
          'completed_by': isCompleted ? mechanicId : null,
        })
        .eq('id', checklistId);
  }

  Future<void> requestAssistance({
    required String taskId,
    required String reason,
    String? helperId,
  }) async {
    await _supabase.rpc(
      'request_task_assistance',
      params: {
        'p_task_id': taskId,
        'p_reason': reason,
        'p_helper_id': helperId,
      },
    );
  }

  Future<void> reportFinding({
    required String serviceOrderId,
    String? taskId,
    required String title,
    required String description,
    String severity = 'medium',
  }) async {
    await _supabase.rpc(
      'report_additional_finding',
      params: {
        'p_service_order_id': serviceOrderId,
        'p_task_id': taskId,
        'p_title': title,
        'p_description': description,
        'p_severity': severity,
      },
    );
  }
}
