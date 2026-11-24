import 'package:pitmate/features/reminders/models/maintenance_reminder.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for maintenance reminder persistence and RPC triggers.
class ReminderRepository {
  ReminderRepository({this.client});

  final SupabaseClient? client;
  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  /// Fetch reminders for specific customer profile.
  Future<List<MaintenanceReminder>> fetchCustomerReminders(String customerId) async {
    try {
      final res = await _supabase
          .from('maintenance_reminders')
          .select('*, vehicles(make, model, license_plate, mileage)')
          .eq('customer_id', customerId)
          .neq('status', 'dismissed')
          .order('due_date', ascending: true);

      final rows = res as List<dynamic>;
      return rows.map((e) => MaintenanceReminder.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch all reminders for workshop administration.
  Future<List<MaintenanceReminder>> fetchAdminReminders({String? status}) async {
    try {
      var query = _supabase
          .from('maintenance_reminders')
          .select('*, vehicles(make, model, license_plate, mileage), customers(full_name)');

      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }

      final res = await query.order('created_at', ascending: false).limit(100);
      final rows = res as List<dynamic>;
      return rows.map((e) => MaintenanceReminder.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Dismiss reminder via RPC.
  Future<bool> dismissReminder(String reminderId) async {
    try {
      final res = await _supabase.rpc(
        'dismiss_maintenance_reminder',
        params: {'p_reminder_id': reminderId},
      );
      return res == true;
    } catch (_) {
      try {
        await _supabase
            .from('maintenance_reminders')
            .update({'status': 'dismissed', 'dismissed_at': DateTime.now().toIso8601String()})
            .eq('id', reminderId);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  /// Trigger batch notification generation for all due reminders via RPC.
  Future<int> processDueReminders() async {
    try {
      final res = await _supabase.rpc('process_due_reminders');
      return (res as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Lookup customer ID for authenticated profile.
  Future<String?> getCurrentCustomerId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final res = await _supabase
          .from('customers')
          .select('id')
          .eq('profile_id', user.id)
          .maybeSingle();

      return res?['id'] as String?;
    } catch (_) {
      return null;
    }
  }
}
