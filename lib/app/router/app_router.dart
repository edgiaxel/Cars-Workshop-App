import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user_role.dart';
import '../../features/admin/presentation/admin_bookings_view.dart';
import '../../features/admin/presentation/admin_customers_view.dart';
import '../../features/admin/presentation/admin_inventory_view.dart';
import '../../features/admin/presentation/admin_mechanics_view.dart';
import '../../features/admin/presentation/admin_reports_view.dart';
import '../../features/admin/presentation/admin_services_view.dart';
import '../../features/admin/presentation/admin_shell_page.dart';
import '../../features/admin/presentation/admin_vehicles_view.dart';
import '../../features/auth/domain/auth_session_state.dart';
import '../../features/auth/presentation/about_page.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/landing_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/auth/presentation/unauthorized_page.dart';
import '../../features/customer/presentation/customer_bookings_view.dart';
import '../../features/customer/presentation/customer_history_view.dart';
import '../../features/customer/presentation/customer_notifications_view.dart';
import '../../features/customer/presentation/customer_profile_view.dart';
import '../../features/customer/presentation/customer_reminders_view.dart';
import '../../features/customer/presentation/customer_shell_page.dart';
import '../../features/customer/presentation/customer_vehicles_view.dart';
import '../../features/mechanic/presentation/mechanic_earnings_view.dart';
import '../../features/mechanic/presentation/mechanic_history_view.dart';
import '../../features/mechanic/presentation/mechanic_services_view.dart';
import '../../features/mechanic/presentation/mechanic_shell_page.dart';
import '../../features/mechanic/presentation/mechanic_tasks_view.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/error_state.dart';
import 'route_paths.dart';

/// Listenable adapter that triggers GoRouter redirects whenever AuthSessionState changes.
class AuthRouterListenable extends ChangeNotifier {
  AuthRouterListenable(Ref ref) {
    ref.listen<AuthSessionState>(authSessionProvider, (previous, next) {
      notifyListeners();
    });
  }
}

/// Provider for [AuthRouterListenable].
final authRouterListenableProvider = Provider<AuthRouterListenable>((ref) {
  return AuthRouterListenable(ref);
});

/// Pure redirect logic separated for testability and clarity.
String? evaluateAuthRedirect({
  required String location,
  required AuthSessionState authState,
}) {
  // 1. While the session is checking on initial app launch, avoid premature routing
  if (authState.isInitial) {
    return null;
  }

  final isAuthenticated = authState.isAuthenticated;
  final role = authState.role;

  final isPublicAuthRoute =
      location == RoutePaths.login ||
      location == RoutePaths.register ||
      location == RoutePaths.forgotPassword;

  final isProtectedAdmin = location.startsWith(RoutePaths.admin);
  final isProtectedMechanic = location.startsWith(RoutePaths.mechanic);
  final isProtectedCustomer = location.startsWith(RoutePaths.customer);
  final isProtectedRoute =
      isProtectedAdmin || isProtectedMechanic || isProtectedCustomer;

  // 2. Unauthenticated user attempting to access protected routes
  if (!isAuthenticated) {
    if (isProtectedRoute || location == RoutePaths.unauthorized) {
      return RoutePaths.login;
    }
    return null;
  }

  // 3. Authenticated user visiting login/register/forgot-password or landing/root
  final isLandingOrRoot =
      location == RoutePaths.root || location == RoutePaths.landing;
  if (isPublicAuthRoute || isLandingOrRoot) {
    return RoutePaths.dashboardForUserRole(role);
  }

  // 4. Role-based clearance checks
  if (isProtectedAdmin && role != UserRole.admin) {
    return RoutePaths.unauthorized;
  }

  if (isProtectedMechanic && role != UserRole.mechanic) {
    return RoutePaths.unauthorized;
  }

  if (isProtectedCustomer && role != UserRole.customer) {
    return RoutePaths.unauthorized;
  }

  return null;
}

/// Centralized application router adhering to ARCHITECTURE.md section 12.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(authRouterListenableProvider);

  return GoRouter(
    initialLocation: RoutePaths.landing,
    debugLogDiagnostics: false,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authSessionProvider);
      return evaluateAuthRedirect(
        location: state.uri.path,
        authState: authState,
      );
    },
    routes: [
      GoRoute(
        path: RoutePaths.root,
        redirect: (context, state) => RoutePaths.landing,
      ),
      GoRoute(
        path: RoutePaths.landing,
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: RoutePaths.about,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        builder: (context, state) => const ResetPasswordPage(),
      ),

      // Admin Destinations (8 destinations)
      GoRoute(
        path: RoutePaths.admin,
        builder: (context, state) => const AdminShellPage(),
      ),
      GoRoute(
        path: RoutePaths.adminCustomers,
        builder: (context, state) => const AdminCustomersPage(),
      ),
      GoRoute(
        path: RoutePaths.adminMechanics,
        builder: (context, state) => const AdminMechanicsPage(),
      ),
      GoRoute(
        path: RoutePaths.adminVehicles,
        builder: (context, state) => const AdminVehiclesPage(),
      ),
      GoRoute(
        path: RoutePaths.adminBookings,
        builder: (context, state) => const AdminBookingsPage(),
      ),
      GoRoute(
        path: RoutePaths.adminServices,
        builder: (context, state) => const AdminServicesPage(),
      ),
      GoRoute(
        path: RoutePaths.adminInventory,
        builder: (context, state) => const AdminInventoryPage(),
      ),
      GoRoute(
        path: RoutePaths.adminReports,
        builder: (context, state) => const AdminReportsPage(),
      ),

      // Mechanic Destinations (5 destinations)
      GoRoute(
        path: RoutePaths.mechanic,
        builder: (context, state) => const MechanicShellPage(),
      ),
      GoRoute(
        path: RoutePaths.mechanicServices,
        builder: (context, state) => const MechanicServicesPage(),
      ),
      GoRoute(
        path: RoutePaths.mechanicTasks,
        builder: (context, state) => const MechanicTasksPage(),
      ),
      GoRoute(
        path: RoutePaths.mechanicHistory,
        builder: (context, state) => const MechanicHistoryPage(),
      ),
      GoRoute(
        path: RoutePaths.mechanicEarnings,
        builder: (context, state) => const MechanicEarningsPage(),
      ),

      // Customer Destinations (7 destinations)
      GoRoute(
        path: RoutePaths.customer,
        builder: (context, state) => const CustomerShellPage(),
      ),
      GoRoute(
        path: RoutePaths.customerProfile,
        builder: (context, state) => const CustomerProfilePage(),
      ),
      GoRoute(
        path: RoutePaths.customerVehicles,
        builder: (context, state) => const CustomerVehiclesPage(),
      ),
      GoRoute(
        path: RoutePaths.customerBookings,
        builder: (context, state) => const CustomerBookingsPage(),
      ),
      GoRoute(
        path: RoutePaths.customerHistory,
        builder: (context, state) => const CustomerHistoryPage(),
      ),
      GoRoute(
        path: RoutePaths.customerNotifications,
        builder: (context, state) => const CustomerNotificationsPage(),
      ),
      GoRoute(
        path: RoutePaths.customerReminders,
        builder: (context, state) => const CustomerRemindersPage(),
      ),

      // Access Control
      GoRoute(
        path: RoutePaths.unauthorized,
        builder: (context, state) => const UnauthorizedPage(),
      ),
    ],
    errorBuilder: (context, state) => AppScaffold(
      title: 'Navigation Alert',
      body: ErrorState(
        title: 'Route Not Found',
        message: 'The requested route "${state.uri}" does not exist.',
        onRetry: () => context.go(RoutePaths.landing),
        retryLabel: 'RETURN TO PIT',
      ),
    ),
  );
});
