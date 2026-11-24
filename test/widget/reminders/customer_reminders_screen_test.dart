import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/auth/domain/user_profile.dart';
import 'package:pitmate/features/auth/domain/user_role.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/reminders/data/reminder_repository.dart';
import 'package:pitmate/features/reminders/models/maintenance_reminder.dart';
import 'package:pitmate/features/reminders/presentation/customer_reminders_screen.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

class FakeReminderRepository extends ReminderRepository {
  FakeReminderRepository({required this.reminders});

  final List<MaintenanceReminder> reminders;

  @override
  Future<String?> getCurrentCustomerId() async => 'cust-101';

  @override
  Future<List<MaintenanceReminder>> fetchCustomerReminders(String customerId) async {
    return reminders;
  }

  @override
  Future<bool> dismissReminder(String reminderId) async => true;
}

void main() {
  const testProfile = UserProfile(
    id: 'user-1',
    role: UserRole.customer,
    fullName: 'Axel Zeed',
  );

  final sampleReminders = [
    MaintenanceReminder(
      id: 'rem-1',
      customerId: 'cust-101',
      vehicleId: 'veh-1',
      reminderType: 'scheduled_date',
      title: '6-Month Routine Health Check',
      description: 'Check coolant and brake fluid levels',
      dueDate: DateTime.now().add(const Duration(days: 45)),
      vehicleMake: 'Toyota',
      vehicleModel: 'GR Yaris',
      licensePlate: 'B 1234 TOY',
      status: 'pending',
    ),
    MaintenanceReminder(
      id: 'rem-2',
      customerId: 'cust-101',
      vehicleId: 'veh-1',
      reminderType: 'mileage_odometer',
      title: 'Periodic 15,000 KM Engine & Filter Service',
      dueOdometerKm: 15000,
      currentMileageKm: 10450,
      vehicleMake: 'Toyota',
      vehicleModel: 'GR Yaris',
      licensePlate: 'B 1234 TOY',
      status: 'notified',
    ),
  ];

  testWidgets('CustomerRemindersScreen renders empty state when no reminders',
      (tester) async {
    final fakeRepo = FakeReminderRepository(reminders: const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthAuthenticated(testProfile)),
          ),
          reminderRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: CustomerRemindersScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('All Vehicles Fully Serviced'), findsOneWidget);
  });

  testWidgets('CustomerRemindersScreen renders reminder cards with interval details and action buttons',
      (tester) async {
    final fakeRepo = FakeReminderRepository(reminders: sampleReminders);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthAuthenticated(testProfile)),
          ),
          reminderRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: CustomerRemindersScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('6-Month Routine Health Check'), findsOneWidget);
    expect(find.text('Periodic 15,000 KM Engine & Filter Service'), findsOneWidget);
    expect(find.text('Toyota GR Yaris • B 1234 TOY'), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Book Service'), findsNWidgets(2));
    expect(find.text('Dismiss'), findsNWidgets(2));
  });
}
