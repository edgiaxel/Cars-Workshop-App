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

  Future<ServiceReminder?> createReminder({
    required String vehicleId,
    required String title,
    String reminderType = 'service',
    String? description,
    DateTime? dueDate,
    int? dueMileageKm,
  }) async {
    final repository = ref.read(reminderRepositoryProvider);
    final customer = ref.read(currentCustomerProvider).asData?.value;
    if (repository == null || customer == null) return null;

    final payload = {
      'customer_id': customer.id,
      'vehicle_id': vehicleId,
      'reminder_type': reminderType,
      'title': title.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (dueDate != null)
        'due_date': dueDate.toIso8601String().split('T').first,
      if (dueMileageKm != null && dueMileageKm > 0)
        'due_mileage_km': dueMileageKm,
      'status': 'pending',
    };

    final reminder = await repository.createReminder(payload);
    ref.invalidateSelf();
    return reminder;
  }

  /// Automatically generates follow-up service reminders from completed service orders.
  Future<int> syncFromServiceHistory() async {
    final client = ref.read(supabaseClientProvider);
    final customer = ref.read(currentCustomerProvider).asData?.value;
    if (client == null || customer == null) return 0;

    int generatedCount = 0;

    try {
      // Fetch completed or closed service orders for this customer
      final ordersData = await client
          .from('service_orders')
          .select('id, order_number, title, vehicle_id, odometer_km, updated_at, status')
          .eq('customer_id', customer.id)
          .inFilter('status', ['completed', 'closed'])
          .order('updated_at', ascending: false);

      final existingReminders = state.asData?.value ?? [];

      for (final order in ordersData as List) {
        final vehicleId = order['vehicle_id'] as String?;
        if (vehicleId == null) continue;

        // Check if there is already an active pending reminder for this vehicle
        final hasActive = existingReminders.any(
          (r) => r.vehicleId == vehicleId && r.status == 'pending',
        );

        if (!hasActive) {
          final completedAt = order['updated_at'] != null
              ? DateTime.tryParse(order['updated_at'] as String) ?? DateTime.now()
              : DateTime.now();
          final nextDueDate = completedAt.add(const Duration(days: 180));
          final odo = order['odometer_km'] as int?;
          final nextOdometer = (odo != null && odo > 0) ? odo + 10000 : null;
          final orderNum = order['order_number'] as String? ?? 'SO-HIST';

          await createReminder(
            vehicleId: vehicleId,
            title: 'Routine Service (${order['title'] ?? 'Scheduled Maintenance'})',
            reminderType: 'service',
            description:
                'Automated follow-up service reminder based on completed service order $orderNum.',
            dueDate: nextDueDate,
            dueMileageKm: nextOdometer,
          );
          generatedCount++;
        }
      }
    } catch (_) {
      // Ignore background sync errors
    }

    if (generatedCount > 0) {
      ref.invalidateSelf();
    }

    return generatedCount;
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

  Future<ServiceReminder?> createReminder({
    required String vehicleId,
    required String title,
    String reminderType = 'service',
    String? description,
    DateTime? dueDate,
    int? dueMileageKm,
  }) async {
    final repository = ref.read(reminderRepositoryProvider);
    final customer = ref.read(currentCustomerProvider).asData?.value;
    if (repository == null || customer == null) return null;

    final payload = {
      'customer_id': customer.id,
      'vehicle_id': vehicleId,
      'reminder_type': reminderType,
      'title': title.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (dueDate != null)
        'due_date': dueDate.toIso8601String().split('T').first,
      if (dueMileageKm != null && dueMileageKm > 0)
        'due_mileage_km': dueMileageKm,
      'status': 'pending',
    };

    final reminder = await repository.createReminder(payload);
    ref.invalidateSelf();
    return reminder;
  }

  /// Automatically generates follow-up service reminders from completed service orders.
  Future<int> syncFromServiceHistory() async {
    final client = ref.read(supabaseClientProvider);
    final customer = ref.read(currentCustomerProvider).asData?.value;
    if (client == null || customer == null) return 0;

    int generatedCount = 0;

    try {
      // Fetch completed or closed service orders for this customer
      final ordersData = await client
          .from('service_orders')
          .select('id, order_number, title, vehicle_id, odometer_km, updated_at, status')
          .eq('customer_id', customer.id)
          .inFilter('status', ['completed', 'closed'])
          .order('updated_at', ascending: false);

      final existingReminders = state.asData?.value ?? [];

      for (final order in ordersData as List) {
        final vehicleId = order['vehicle_id'] as String?;
        if (vehicleId == null) continue;

        // Check if there is already an active pending reminder for this vehicle
        final hasActive = existingReminders.any(
          (r) => r.vehicleId == vehicleId && r.status == 'pending',
        );

        if (!hasActive) {
          final completedAt = order['updated_at'] != null
              ? DateTime.tryParse(order['updated_at'] as String) ?? DateTime.now()
              : DateTime.now();
          final nextDueDate = completedAt.add(const Duration(days: 180));
          final odo = order['odometer_km'] as int?;
          final nextOdometer = (odo != null && odo > 0) ? odo + 10000 : null;
          final orderNum = order['order_number'] as String? ?? 'SO-HIST';

          await createReminder(
            vehicleId: vehicleId,
            title: 'Routine Service (${order['title'] ?? 'Scheduled Maintenance'})',
            reminderType: 'service',
            description:
                'Automated follow-up service reminder based on completed service order $orderNum.',
            dueDate: nextDueDate,
            dueMileageKm: nextOdometer,
          );
          generatedCount++;
        }
      }
    } catch (_) {
      // Ignore background sync errors
    }

    if (generatedCount > 0) {
      ref.invalidateSelf();
    }

    return generatedCount;
  }
}

final customerServiceRemindersProvider =
    AsyncNotifierProvider<CustomerRemindersNotifier, List<ServiceReminder>>(
      CustomerRemindersNotifier.new,
    );
