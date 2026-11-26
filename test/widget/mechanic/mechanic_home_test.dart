import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/features/mechanic/presentation/mechanic_home_screen.dart';
import 'package:pitmate/features/service_operations/data/models/service_order_task_model.dart';

void main() {
  final sampleInspections = [
    {
      'id': 'insp-1',
      'service_order_id': 'so-1',
      'mechanic_id': null,
      'status': 'assigned',
      'service_orders': null,
    },
  ];

  final sampleTasks = [
    ServiceOrderTaskModel(
      id: 'task-1',
      serviceOrderId: 'so-1',
      title: 'Front Brake Pad Replacement',
      description: 'Install replacement pad set and torque bolts',
      estimatedDurationMinutes: 45,
      status: TaskStatus.inProgress,
      orderNumber: 'SO-202611-0001',
      vehiclePlate: 'B 9912 SPO',
      vehicleModel: 'Civic Type R',
      checklists: const [
        TaskChecklistModel(
          id: 'chk-1',
          taskId: 'task-1',
          itemDescription: 'Torque wheel lug nuts',
          isCompleted: true,
        ),
        TaskChecklistModel(
          id: 'chk-2',
          taskId: 'task-1',
          itemDescription: 'Verify brake fluid level',
          isCompleted: false,
        ),
      ],
      createdAt: DateTime(2026, 11, 20),
      updatedAt: DateTime(2026, 11, 20),
    ),
    ServiceOrderTaskModel(
      id: 'task-2',
      serviceOrderId: 'so-2',
      title: 'Oil & Filter Service',
      estimatedDurationMinutes: 30,
      status: TaskStatus.completed,
      orderNumber: 'SO-202611-0002',
      vehiclePlate: 'B 3021 RFS',
      createdAt: DateTime(2026, 11, 20),
      updatedAt: DateTime(2026, 11, 20),
    ),
  ];

  Widget buildMechanicScreen({
    List<Map<String, dynamic>>? inspections,
    List<ServiceOrderTaskModel>? tasks,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: MechanicHomeScreen(
          initialInspections: inspections,
          initialTasks: tasks,
        ),
      ),
    );
  }

  group('MechanicHomeScreen', () {
    testWidgets('renders honest empty states when queue is empty', (tester) async {
      await tester.pumpWidget(
        buildMechanicScreen(inspections: const [], tasks: const []),
      );
      await tester.pumpAndSettle();

      expect(find.text('PENDING INSPECTIONS'), findsOneWidget);
      expect(find.text('ASSIGNED TASKS'), findsOneWidget);
      expect(find.text('IN PROGRESS'), findsOneWidget);
      expect(find.text('COMPLETED TASKS'), findsOneWidget);
      expect(find.text('No pending vehicle inspections queued right now.'), findsOneWidget);
      expect(find.text('No repair operations assigned to your bay yet.'), findsOneWidget);
    });

    testWidgets('renders unassigned inspection claim card and assigned repair tasks', (tester) async {
      await tester.pumpWidget(
        buildMechanicScreen(
          inspections: sampleInspections,
          tasks: sampleTasks,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending Vehicle Inspection (Unassigned)'), findsOneWidget);
      expect(find.text('AWAITING CLAIM'), findsOneWidget);
      expect(find.text('CLAIM & INSPECT'), findsOneWidget);

      expect(find.text('Front Brake Pad Replacement'), findsOneWidget);
      expect(find.text('Oil & Filter Service'), findsOneWidget);
      expect(find.text('OPEN WORKSPACE'), findsOneWidget);
      expect(find.text('VIEW WORKSPACE'), findsOneWidget);
    });
  });
}
