import '../datasources/reminder_remote_datasource.dart';
import '../models/service_reminder.dart';

abstract class ReminderRepository {
  Future<List<ServiceReminder>> getReminders({String? customerId});
  Future<ServiceReminder> createReminder(Map<String, dynamic> payload);
  Future<void> updateReminderStatus(String id, String status);
}

class SupabaseReminderRepository implements ReminderRepository {
  SupabaseReminderRepository(this._dataSource);
  final ReminderRemoteDataSource _dataSource;

  @override
  Future<List<ServiceReminder>> getReminders({String? customerId}) {
    return _dataSource.getReminders(customerId: customerId);
  }

  @override
  Future<ServiceReminder> createReminder(Map<String, dynamic> payload) {
    return _dataSource.createReminder(payload);
  }

  @override
  Future<void> updateReminderStatus(String id, String status) {
    return _dataSource.updateReminderStatus(id, status);
  }
}
