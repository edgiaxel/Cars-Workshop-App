import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/data/models/user_profile.dart';
import 'package:pitmate/data/models/user_role.dart';
import 'package:pitmate/features/admin/presentation/admin_shell_page.dart';
import 'package:pitmate/features/auth/domain/auth_session_state.dart';
import 'package:pitmate/features/customer/presentation/customer_shell_page.dart';
import 'package:pitmate/features/mechanic/presentation/mechanic_shell_page.dart';
import 'package:pitmate/shared/providers/auth_provider.dart';

class _FakeAuthNotifier extends AuthSessionNotifier {
  _FakeAuthNotifier(this._state);
  final AuthSessionState _state;

  @override
  AuthSessionState build() => _state;
}

void main() {
  group('Role Shell Presentation Tests', () {
    testWidgets('AdminShellPage displays admin identity, badge, and sign out', (
      WidgetTester tester,
    ) async {
      final adminProfile = const UserProfile(
        id: 'admin-1',
        role: UserRole.admin,
        fullName: 'Christian Horner',
      );

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

      expect(find.text('Admin Terminal'), findsOneWidget);
      expect(find.text('ROLE: ADMIN'), findsOneWidget);
      expect(find.text('Christian Horner'), findsOneWidget);
      expect(find.text('admin@pitmate.co'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsWidgets);
    });

    testWidgets(
      'MechanicShellPage displays technician identity, badge, and sign out',
      (WidgetTester tester) async {
        final mechanicProfile = const UserProfile(
          id: 'mech-1',
          role: UserRole.mechanic,
          fullName: 'Max Verstappen',
        );

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
            ],
            child: const MaterialApp(home: MechanicShellPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mechanic Workbench'), findsOneWidget);
        expect(find.text('ROLE: MECHANIC'), findsOneWidget);
        expect(find.text('Max Verstappen'), findsOneWidget);
        expect(find.text('verstappen@pitmate.co'), findsOneWidget);
        expect(find.byIcon(Icons.logout), findsWidgets);
      },
    );

    testWidgets(
      'CustomerShellPage displays customer identity, badge, and sign out',
      (WidgetTester tester) async {
        final customerProfile = const UserProfile(
          id: 'cust-1',
          role: UserRole.customer,
          fullName: 'Axel Zeed',
        );

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
            ],
            child: const MaterialApp(home: CustomerShellPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Customer Portal'), findsOneWidget);
        expect(find.text('ROLE: CUSTOMER'), findsOneWidget);
        expect(find.text('Axel Zeed'), findsOneWidget);
        expect(find.text('lexazeed@gmail.com'), findsOneWidget);
        expect(find.byIcon(Icons.logout), findsWidgets);
      },
    );
  });
}
