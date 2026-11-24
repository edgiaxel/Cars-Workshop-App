import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/auth/domain/user_profile.dart';
import 'package:pitmate/features/auth/domain/user_role.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/reminders/data/reminder_repository.dart';
import 'package:pitmate/features/reminders/models/maintenance_reminder.dart';
import 'package:pitmate/features/reminders/presentation/admin_reminders_screen.dart';
import 'package:pitmate/features/reminders/presentation/customer_reminders_screen.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

class FakeAdminReminderRepository extends ReminderRepository {
  FakeAdminReminderRepository({required this.reminders});

  final List<MaintenanceReminder> reminders;

  @override
  Future<List<MaintenanceReminder>> fetchAdminReminders({String? status}) async {
    if (status == null || status == 'all') return reminders;
    return reminders.where((r) => r.status == status).toList();
  }

  @override
  Future<int> processDueReminders() async => 2;
}

void main() {
  const adminProfile = UserProfile(
    id: 'admin-1',
    role: UserRole.admin,
    fullName: 'Toto Wolf',
  );

  final sampleReminders = [
    MaintenanceReminder(
      id: 'rem-1',
      customerId: 'cust-1',
      vehicleId: 'veh-1',
      reminderType: 'scheduled_date',
      title: '6-Month Routine Health Check',
      dueDate: DateTime.now().add(const Duration(days: 30)),
      vehicleMake: 'Toyota',
      vehicleModel: 'GR Yaris',
      licensePlate: 'B 1234 TOY',
      customerName: 'Axel Zeed',
      status: 'pending',
    ),
    MaintenanceReminder(
      id: 'rem-2',
      customerId: 'cust-2',
      vehicleId: 'veh-2',
      reminderType: 'mileage_odometer',
      title: 'Periodic 15,000 KM Service',
      dueOdometerKm: 15000,
      vehicleMake: 'Honda',
      vehicleModel: 'Civic Type R',
      licensePlate: 'B 5678 CIV',
      customerName: 'Aston Martin',
      status: 'notified',
    ),
  ];

  testWidgets('AdminRemindersScreen renders queue, filter chips, and triggers process due action',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeRepo = FakeAdminReminderRepository(reminders: sampleReminders);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthAuthenticated(adminProfile)),
          ),
          reminderRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: AdminRemindersScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Service Reminders Queue'), findsOneWidget);
    expect(find.text('2 QUEUED REMINDERS'), findsOneWidget);
    expect(find.text('Process Due'), findsOneWidget);
    expect(find.text('6-Month Routine Health Check'), findsOneWidget);
    expect(find.text('Periodic 15,000 KM Service'), findsOneWidget);

    // Tap Pending chip filter
    await tester.tap(find.byKey(const Key('chip_pending')));
    await tester.pumpAndSettle();

    expect(find.text('6-Month Routine Health Check'), findsOneWidget);
    expect(find.text('Periodic 15,000 KM Service'), findsNothing);

    // Tap Process Due button
    await tester.tap(find.byKey(const Key('process_due_reminders_button')));
    await tester.pumpAndSettle();

    expect(find.text('Processed due reminders: 2 customer notifications emitted'), findsOneWidget);
  });
}
