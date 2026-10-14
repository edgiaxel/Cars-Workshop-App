import '../datasources/task_remote_datasource.dart';
import '../models/service_task.dart';

abstract class TaskRepository {
  Future<List<ServiceTask>> getTasks({
    String? mechanicId,
    String? serviceOrderId,
  });
  Future<void> updateTaskStatus(String id, String status);
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
}
