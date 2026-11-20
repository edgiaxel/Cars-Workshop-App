import '../datasources/task_remote_datasource.dart';
import '../models/service_task.dart';

abstract class TaskRepository {
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

class SupabaseTaskRepository implements TaskRepository {
  SupabaseTaskRepository(this._dataSource);
  final TaskRemoteDataSource _dataSource;

  @override
  Future<List<ServiceTask>> getTasks({
    String? mechanicId,
    String? serviceOrderId,
  }) {
    return _dataSource.getTasks(
      mechanicId: mechanicId,
      serviceOrderId: serviceOrderId,
    );
  }

  @override
  Future<void> updateTaskStatus(String id, String status) {
    return _dataSource.updateTaskStatus(id, status);
  }

  @override
  Future<ServiceTask> createTask({
    required String serviceOrderId,
    String? assignedMechanicId,
    required String title,
    String? description,
    String? notes,
    String status = 'pending',
  }) {
    return _dataSource.createTask(
      serviceOrderId: serviceOrderId,
      assignedMechanicId: assignedMechanicId,
      title: title,
      description: description,
      notes: notes,
      status: status,
    );
  }

  @override
  Future<ServiceTask> updateTask({
    required String id,
    String? status,
    String? notes,
    int? actualMinutes,
  }) {
    return _dataSource.updateTask(
      id: id,
      status: status,
      notes: notes,
      actualMinutes: actualMinutes,
    );
  }

  @override
  Future<void> deleteTask(String id) {
    return _dataSource.deleteTask(id);
  }
}
