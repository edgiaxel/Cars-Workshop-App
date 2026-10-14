import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/reminder_remote_datasource.dart';
import '../../data/models/service_reminder.dart';
import '../../data/repositories/reminder_repository.dart';
import 'customer_provider.dart';
import 'supabase_provider.dart';

final reminderRemoteDataSourceProvider = Provider<ReminderRemoteDataSource?>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return SupabaseReminderRemoteDataSource(client);
});

final reminderRepositoryProvider = Provider<ReminderRepository?>((ref) {
  final dataSource = ref.watch(reminderRemoteDataSourceProvider);
  if (dataSource == null) return null;
  return SupabaseReminderRepository(dataSource);
});

class RemindersNotifier extends AsyncNotifier<List<ServiceReminder>> {
  @override
  Future<List<ServiceReminder>> build() async {
    final repository = ref.watch(reminderRepositoryProvider);
    if (repository == null) return const [];
    return repository.getReminders();
  }

  Future<void> updateStatus(String id, String status) async {
    final repository = ref.read(reminderRepositoryProvider);
    if (repository != null) {
      await repository.updateReminderStatus(id, status);
      ref.invalidateSelf();
    }
  }
}

final remindersProvider =
    AsyncNotifierProvider<RemindersNotifier, List<ServiceReminder>>(
      RemindersNotifier.new,
    );

class CustomerRemindersNotifier extends AsyncNotifier<List<ServiceReminder>> {
  @override
  Future<List<ServiceReminder>> build() async {
    final repository = ref.watch(reminderRepositoryProvider);
    final customer = ref.watch(currentCustomerProvider).asData?.value;
    if (repository == null) return const [];
    return repository.getReminders(customerId: customer?.id);
  }

  Future<void> updateStatus(String id, String status) async {
    final repository = ref.read(reminderRepositoryProvider);
    if (repository != null) {
      await repository.updateReminderStatus(id, status);
      ref.invalidateSelf();
    }
  }
}

final customerServiceRemindersProvider =
    AsyncNotifierProvider<CustomerRemindersNotifier, List<ServiceReminder>>(
      CustomerRemindersNotifier.new,
    );
