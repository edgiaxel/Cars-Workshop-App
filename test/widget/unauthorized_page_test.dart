import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/data/models/user_profile.dart';
import 'package:pitmate/data/models/user_role.dart';
import 'package:pitmate/features/auth/domain/auth_session_state.dart';
import 'package:pitmate/features/auth/presentation/unauthorized_page.dart';
import 'package:pitmate/shared/providers/auth_provider.dart';

void main() {
  testWidgets(
    'UnauthorizedPage displays access restriction and recovery actions',
    (WidgetTester tester) async {
      final customerProfile = const UserProfile(
        id: 'cust-123',
        role: UserRole.customer,
        fullName: 'Axel Zeed',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              () => _FakeAuthSessionNotifier(
                AuthSessionState.authenticated(
                  userId: 'cust-123',
                  email: 'lexazeed@gmail.com',
                  profile: customerProfile,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: UnauthorizedPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.text('TELEMETRY SECURITY AUDIT'), findsOneWidget);
      expect(find.text('lexazeed@gmail.com'), findsOneWidget);
      expect(find.text('Customer'), findsOneWidget);
      expect(find.text('RETURN TO DASHBOARD'), findsOneWidget);
      expect(find.text('Sign Out Session'), findsOneWidget);
    },
  );
}

class _FakeAuthSessionNotifier extends AuthSessionNotifier {
  _FakeAuthSessionNotifier(this._initial);
  final AuthSessionState _initial;

  @override
  AuthSessionState build() => _initial;
}
