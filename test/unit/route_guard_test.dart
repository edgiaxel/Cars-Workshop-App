import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/router/app_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/data/models/user_profile.dart';
import 'package:pitmate/data/models/user_role.dart';
import 'package:pitmate/features/auth/domain/auth_session_state.dart';

void main() {
  group('GoRouter Role & Auth Redirect Guards', () {
    final adminProfile = UserProfile(
      id: 'admin-1',
      role: UserRole.admin,
      fullName: 'Christian Horner',
    );

    final mechanicProfile = UserProfile(
      id: 'mech-1',
      role: UserRole.mechanic,
      fullName: 'Max Verstappen',
    );

    final customerProfile = UserProfile(
      id: 'cust-1',
      role: UserRole.customer,
      fullName: 'Axel Zeed',
    );

    test('Initial loading state does not trigger premature redirects', () {
      final state = AuthSessionState.initial();

      expect(
        evaluateAuthRedirect(location: RoutePaths.landing, authState: state),
        isNull,
      );
      expect(
        evaluateAuthRedirect(location: RoutePaths.admin, authState: state),
        isNull,
      );
    });

    test('Unauthenticated user is allowed on public routes', () {
      final state = AuthSessionState.unauthenticated();

      expect(
        evaluateAuthRedirect(location: RoutePaths.landing, authState: state),
        isNull,
      );
      expect(
        evaluateAuthRedirect(location: RoutePaths.about, authState: state),
        isNull,
      );
      expect(
        evaluateAuthRedirect(location: RoutePaths.login, authState: state),
        isNull,
      );
      expect(
        evaluateAuthRedirect(location: RoutePaths.register, authState: state),
        isNull,
      );
      expect(
        evaluateAuthRedirect(
          location: RoutePaths.forgotPassword,
          authState: state,
        ),
        isNull,
      );
    });

    test('Unauthenticated user on protected route redirects to login', () {
      final state = AuthSessionState.unauthenticated();

      expect(
        evaluateAuthRedirect(location: RoutePaths.admin, authState: state),
        RoutePaths.login,
      );
      expect(
        evaluateAuthRedirect(location: RoutePaths.mechanic, authState: state),
        RoutePaths.login,
      );
      expect(
        evaluateAuthRedirect(location: RoutePaths.customer, authState: state),
        RoutePaths.login,
      );
      expect(
        evaluateAuthRedirect(
          location: RoutePaths.unauthorized,
          authState: state,
        ),
        RoutePaths.login,
      );
    });

    test('Authenticated admin is allowed on /admin', () {
      final state = AuthSessionState.authenticated(
        userId: 'admin-1',
        email: 'admin@pitmate.co',
        profile: adminProfile,
      );

      expect(
        evaluateAuthRedirect(location: RoutePaths.admin, authState: state),
        isNull,
      );
    });

    test('Authenticated mechanic is allowed on /mechanic', () {
      final state = AuthSessionState.authenticated(
        userId: 'mech-1',
        email: 'verstappen@pitmate.co',
        profile: mechanicProfile,
      );

      expect(
        evaluateAuthRedirect(location: RoutePaths.mechanic, authState: state),
        isNull,
      );
    });

    test('Authenticated customer is allowed on /customer', () {
      final state = AuthSessionState.authenticated(
        userId: 'cust-1',
        email: 'lexazeed@gmail.com',
        profile: customerProfile,
      );

      expect(
        evaluateAuthRedirect(location: RoutePaths.customer, authState: state),
        isNull,
      );
    });

    test('Wrong role access redirects to /unauthorized', () {
      final customerState = AuthSessionState.authenticated(
        userId: 'cust-1',
        email: 'lexazeed@gmail.com',
        profile: customerProfile,
      );

      // Customer trying to access admin
      expect(
        evaluateAuthRedirect(
          location: RoutePaths.admin,
          authState: customerState,
        ),
        RoutePaths.unauthorized,
      );

      // Customer trying to access mechanic
      expect(
        evaluateAuthRedirect(
          location: RoutePaths.mechanic,
          authState: customerState,
        ),
        RoutePaths.unauthorized,
      );

      final mechanicState = AuthSessionState.authenticated(
        userId: 'mech-1',
        email: 'verstappen@pitmate.co',
        profile: mechanicProfile,
      );

      // Mechanic trying to access admin
      expect(
        evaluateAuthRedirect(
          location: RoutePaths.admin,
          authState: mechanicState,
        ),
        RoutePaths.unauthorized,
      );

      // Mechanic trying to access customer
      expect(
        evaluateAuthRedirect(
          location: RoutePaths.customer,
          authState: mechanicState,
        ),
        RoutePaths.unauthorized,
      );

      final adminState = AuthSessionState.authenticated(
        userId: 'admin-1',
        email: 'admin@pitmate.co',
        profile: adminProfile,
      );

      // Admin trying to access mechanic
      expect(
        evaluateAuthRedirect(
          location: RoutePaths.mechanic,
          authState: adminState,
        ),
        RoutePaths.unauthorized,
      );
    });

    test(
      'Authenticated users on auth forms are redirected to their dashboard',
      () {
        final adminState = AuthSessionState.authenticated(
          userId: 'admin-1',
          email: 'admin@pitmate.co',
          profile: adminProfile,
        );

        expect(
          evaluateAuthRedirect(
            location: RoutePaths.login,
            authState: adminState,
          ),
          RoutePaths.admin,
        );
        expect(
          evaluateAuthRedirect(
            location: RoutePaths.register,
            authState: adminState,
          ),
          RoutePaths.admin,
        );
        expect(
          evaluateAuthRedirect(
            location: RoutePaths.forgotPassword,
            authState: adminState,
          ),
          RoutePaths.admin,
        );

        final mechanicState = AuthSessionState.authenticated(
          userId: 'mech-1',
          email: 'verstappen@pitmate.co',
          profile: mechanicProfile,
        );

        expect(
          evaluateAuthRedirect(
            location: RoutePaths.login,
            authState: mechanicState,
          ),
          RoutePaths.mechanic,
        );

        final customerState = AuthSessionState.authenticated(
          userId: 'cust-1',
          email: 'lexazeed@gmail.com',
          profile: customerProfile,
        );

        expect(
          evaluateAuthRedirect(
            location: RoutePaths.login,
            authState: customerState,
          ),
          RoutePaths.customer,
        );
      },
    );

    test('Authenticated user is permitted to view /unauthorized screen', () {
      final customerState = AuthSessionState.authenticated(
        userId: 'cust-1',
        email: 'lexazeed@gmail.com',
        profile: customerProfile,
      );

      expect(
        evaluateAuthRedirect(
          location: RoutePaths.unauthorized,
          authState: customerState,
        ),
        isNull,
      );
    });

    group('Milestone 4 — All 20 Destinations Role Guard Matrix', () {
      const adminRoutes = [
        RoutePaths.admin,
        RoutePaths.adminCustomers,
        RoutePaths.adminMechanics,
        RoutePaths.adminVehicles,
        RoutePaths.adminBookings,
        RoutePaths.adminServices,
        RoutePaths.adminInventory,
        RoutePaths.adminReports,
      ];

      const mechanicRoutes = [
        RoutePaths.mechanic,
        RoutePaths.mechanicServices,
        RoutePaths.mechanicTasks,
        RoutePaths.mechanicHistory,
        RoutePaths.mechanicEarnings,
      ];

      const customerRoutes = [
        RoutePaths.customer,
        RoutePaths.customerProfile,
        RoutePaths.customerVehicles,
        RoutePaths.customerBookings,
        RoutePaths.customerHistory,
        RoutePaths.customerNotifications,
        RoutePaths.customerReminders,
      ];

      final adminState = AuthSessionState.authenticated(
        userId: 'admin-1',
        email: 'admin@pitmate.co',
        profile: adminProfile,
      );

      final mechanicState = AuthSessionState.authenticated(
        userId: 'mech-1',
        email: 'verstappen@pitmate.co',
        profile: mechanicProfile,
      );

      final customerState = AuthSessionState.authenticated(
        userId: 'cust-1',
        email: 'lexazeed@gmail.com',
        profile: customerProfile,
      );

      final unauthState = AuthSessionState.unauthenticated();

      test('Unauthenticated user is blocked from all 20 destinations', () {
        for (final route in [
          ...adminRoutes,
          ...mechanicRoutes,
          ...customerRoutes,
        ]) {
          expect(
            evaluateAuthRedirect(location: route, authState: unauthState),
            RoutePaths.login,
            reason:
                'Route $route should redirect unauthenticated user to login',
          );
        }
      });

      test('Admin is granted access to all 8 admin destinations', () {
        for (final route in adminRoutes) {
          expect(
            evaluateAuthRedirect(location: route, authState: adminState),
            isNull,
            reason: 'Admin should have access to $route',
          );
        }
      });

      test('Admin is blocked from all mechanic and customer destinations', () {
        for (final route in [...mechanicRoutes, ...customerRoutes]) {
          expect(
            evaluateAuthRedirect(location: route, authState: adminState),
            RoutePaths.unauthorized,
            reason: 'Admin should not have access to $route',
          );
        }
      });

      test('Mechanic is granted access to all 5 mechanic destinations', () {
        for (final route in mechanicRoutes) {
          expect(
            evaluateAuthRedirect(location: route, authState: mechanicState),
            isNull,
            reason: 'Mechanic should have access to $route',
          );
        }
      });

      test('Mechanic is blocked from all admin and customer destinations', () {
        for (final route in [...adminRoutes, ...customerRoutes]) {
          expect(
            evaluateAuthRedirect(location: route, authState: mechanicState),
            RoutePaths.unauthorized,
            reason: 'Mechanic should not have access to $route',
          );
        }
      });

      test('Customer is granted access to all 7 customer destinations', () {
        for (final route in customerRoutes) {
          expect(
            evaluateAuthRedirect(location: route, authState: customerState),
            isNull,
            reason: 'Customer should have access to $route',
          );
        }
      });

      test('Customer is blocked from all admin and mechanic destinations', () {
        for (final route in [...adminRoutes, ...mechanicRoutes]) {
          expect(
            evaluateAuthRedirect(location: route, authState: customerState),
            RoutePaths.unauthorized,
            reason: 'Customer should not have access to $route',
          );
        }
      });
    });
  });
}
