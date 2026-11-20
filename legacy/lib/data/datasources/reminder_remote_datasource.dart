import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/service_reminder.dart';

abstract class ReminderRemoteDataSource {
  Future<List<ServiceReminder>> getReminders({String? customerId});
  Future<ServiceReminder> createReminder(Map<String, dynamic> payload);
  Future<void> updateReminderStatus(String id, String status);
}

class SupabaseReminderRemoteDataSource implements ReminderRemoteDataSource {
  SupabaseReminderRemoteDataSource(this._client);
  final SupabaseClient? _client;

  @override
  Future<List<ServiceReminder>> getReminders({String? customerId}) async {
    if (_client == null) return [];

    var query = _client.from('service_reminders').select('*, vehicles(*)');
    if (customerId != null) {
      query = query.eq('customer_id', customerId);
    }

    final data = await query.order('due_date', ascending: true);
    return (data as List)
        .map((json) => ServiceReminder.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ServiceReminder> createReminder(Map<String, dynamic> payload) async {
    if (_client == null) {
      throw Exception('Supabase client is null.');
    }
    final data = await _client
        .from('service_reminders')
        .insert(payload)
        .select('*, vehicles(*)')
        .single();
    return ServiceReminder.fromJson(data);
  }

  @override
  Future<void> updateReminderStatus(String id, String status) async {
    if (_client == null) return;
    await _client
        .from('service_reminders')
        .update({'status': status})
        .eq('id', id);
  }
}
