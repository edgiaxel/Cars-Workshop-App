import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/task_remote_datasource.dart';
import '../../data/models/service_task.dart';
import '../../data/repositories/task_repository.dart';
import 'mechanic_provider.dart';
import 'supabase_provider.dart';

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseTaskRemoteDataSource(client);
});

final taskRepositoryProvider = Provider<TaskRepository?>((ref) {
  final dataSource = ref.watch(taskRemoteDataSourceProvider);
  if (dataSource == null) return null;
  return SupabaseTaskRepository(dataSource);
});

class TasksNotifier extends AsyncNotifier<List<ServiceTask>> {
  @override
  Future<List<ServiceTask>> build() async {
    final repository = ref.watch(taskRepositoryProvider);
    if (repository == null) return const [];
    return repository.getTasks();
  }

  Future<void> updateStatus(String id, String status) async {
    final repository = ref.read(taskRepositoryProvider);
    if (repository != null) {
      await repository.updateTaskStatus(id, status);
      ref.invalidateSelf();
    }
  }
}

final tasksProvider = AsyncNotifierProvider<TasksNotifier, List<ServiceTask>>(
  TasksNotifier.new,
);

class MechanicTasksNotifier extends AsyncNotifier<List<ServiceTask>> {
  @override
  Future<List<ServiceTask>> build() async {
    final repository = ref.watch(taskRepositoryProvider);
    if (repository == null) return const [];
    String? mechId;
    try {
      final currentMech = await ref.watch(currentMechanicProvider.future);
      mechId = currentMech?.id;
    } catch (_) {}
    return repository.getTasks(mechanicId: mechId);
  }

  Future<void> updateStatus(String id, String status) async {
    final repository = ref.read(taskRepositoryProvider);
    if (repository != null) {
      await repository.updateTaskStatus(id, status);
      ref.invalidateSelf();
    }
  }
}

final mechanicTasksProvider =
    AsyncNotifierProvider<MechanicTasksNotifier, List<ServiceTask>>(
      MechanicTasksNotifier.new,
    );
