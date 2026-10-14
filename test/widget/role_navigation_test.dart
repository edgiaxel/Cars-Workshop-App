import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/data/models/user_profile.dart';
import 'package:pitmate/data/models/user_role.dart';
import 'package:pitmate/features/admin/presentation/admin_customers_view.dart';
import 'package:pitmate/features/admin/presentation/admin_inventory_view.dart';
import 'package:pitmate/features/admin/presentation/admin_shell_page.dart';
import 'package:pitmate/features/auth/domain/auth_session_state.dart';
import 'package:pitmate/features/customer/presentation/customer_vehicles_view.dart';
import 'package:pitmate/features/mechanic/presentation/mechanic_tasks_view.dart';
import 'package:pitmate/shared/providers/auth_provider.dart';
import 'package:pitmate/shared/providers/customer_provider.dart';
import 'package:pitmate/shared/providers/spare_part_provider.dart';
import 'package:pitmate/shared/providers/task_provider.dart';
import 'package:pitmate/shared/providers/vehicle_provider.dart';
import 'package:pitmate/shared/widgets/empty_state.dart';

import '../helpers/fake_repositories.dart';

class _FakeAuthNotifier extends AuthSessionNotifier {
  _FakeAuthNotifier(this._state);
  final AuthSessionState _state;

  @override
  AuthSessionState build() => _state;
}

void main() {
  group('Role Navigation & Representative Views Test', () {
    final adminProfile = const UserProfile(
      id: 'admin-1',
      role: UserRole.admin,
      fullName: 'Christian Horner',
    );

    final mechanicProfile = const UserProfile(
      id: 'mech-1',
      role: UserRole.mechanic,
      fullName: 'Max Verstappen',
    );

    final customerProfile = const UserProfile(
      id: 'cust-1',
      role: UserRole.customer,
      fullName: 'Axel Zeed',
    );

    testWidgets(
      'Admin drawer renders all 8 navigation destinations on mobile',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authSessionProvider.overrideWith(
                () => _FakeAuthNotifier(
                  AuthSessionState.authenticated(
                    userId: 'admin-1',
                    email: 'admin@pitmate.co',
                    profile: adminProfile,
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: AdminShellPage()),
          ),
        );
        await tester.pumpAndSettle();

        // Open drawer via hamburger menu
        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Customers'), findsOneWidget);
        expect(find.text('Mechanics'), findsOneWidget);
        expect(find.text('Vehicles'), findsOneWidget);
        expect(find.text('Bookings'), findsOneWidget);
        expect(find.text('Services'), findsOneWidget);
        expect(find.text('Inventory'), findsOneWidget);
        expect(find.text('Reports'), findsOneWidget);
      },
    );

    testWidgets(
      'Admin desktop layout renders persistent sidebar without drawer',
      (WidgetTester tester) async {
        // Desktop size >= 840
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authSessionProvider.overrideWith(
                () => _FakeAuthNotifier(
                  AuthSessionState.authenticated(
                    userId: 'admin-1',
                    email: 'admin@pitmate.co',
                    profile: adminProfile,
                  ),
                ),
              ),
            ],
            child: const MaterialApp(home: AdminShellPage()),
          ),
        );
        await tester.pumpAndSettle();

        // On desktop, PITMATE brand in sidebar is rendered and Drawer is not used
        expect(find.text('PITMATE'), findsOneWidget);
        expect(find.byType(Drawer), findsNothing);
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Inventory'), findsOneWidget);
      },
    );

    testWidgets('Admin Customers page renders directory and reacts to search', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              () => _FakeAuthNotifier(
                AuthSessionState.authenticated(
                  userId: 'admin-1',
                  email: 'admin@pitmate.co',
                  profile: adminProfile,
                ),
              ),
            ),
            customerRepositoryProvider.overrideWithValue(
              FakeCustomerRepository(),
            ),
          ],
          child: const MaterialApp(home: AdminCustomersPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CUSTOMER DIRECTORY'), findsOneWidget);
      expect(find.text('BMW M Motorsport'), findsOneWidget);
      expect(find.text('Aston Martin'), findsOneWidget);

      // Search for non-existent customer to trigger empty state
      await tester.enterText(find.byType(TextField), 'NonExistentClientXYZ');
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No Customers Found'), findsOneWidget);
    });

    testWidgets('Admin Inventory page renders spare parts and stock status', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              () => _FakeAuthNotifier(
                AuthSessionState.authenticated(
                  userId: 'admin-1',
                  email: 'admin@pitmate.co',
                  profile: adminProfile,
                ),
              ),
            ),
            sparePartRepositoryProvider.overrideWithValue(
              FakeSparePartRepository(),
            ),
          ],
          child: const MaterialApp(home: AdminInventoryPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SPARE PARTS INVENTORY'), findsOneWidget);
      expect(find.text('5W-40 Full Synthetic Engine Oil'), findsOneWidget);
      expect(find.text('LOW STOCK'), findsWidgets);
    });

    testWidgets('Mechanic Tasks page renders diagnostic checklists', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              () => _FakeAuthNotifier(
                AuthSessionState.authenticated(
                  userId: 'mech-1',
                  email: 'verstappen@pitmate.co',
                  profile: mechanicProfile,
                ),
              ),
            ),
            taskRepositoryProvider.overrideWithValue(FakeTaskRepository()),
          ],
          child: const MaterialApp(home: MechanicTasksPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DIAGNOSTIC & CHECKLIST TASKS'), findsOneWidget);
      expect(find.text('Engine Diagnostic Inspection'), findsOneWidget);
      expect(find.text('High Voltage System Inspection'), findsOneWidget);
    });

    testWidgets('Customer Vehicles page renders garage fleet cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              () => _FakeAuthNotifier(
                AuthSessionState.authenticated(
                  userId: 'cust-1',
                  email: 'lexazeed@gmail.com',
                  profile: customerProfile,
                ),
              ),
            ),
            vehicleRepositoryProvider.overrideWithValue(
              FakeVehicleRepository(),
            ),
          ],
          child: const MaterialApp(home: CustomerVehiclesPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MY GARAGE FLEET'), findsOneWidget);
      expect(find.text('BMW M3 Touring Competition G81'), findsOneWidget);
      expect(find.text('D 1999 AZ'), findsOneWidget);
      expect(find.text('Toyota Innova Zenix Hybrid'), findsOneWidget);
    });
  });
}
