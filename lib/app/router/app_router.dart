import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/features/admin/presentation/admin_customers_screen.dart';
import 'package:pitmate/features/admin/presentation/admin_overview_screen.dart';
import 'package:pitmate/features/auth/presentation/auth_screens.dart';
import 'package:pitmate/features/customers/presentation/customer_garage_screen.dart';
import 'package:pitmate/features/mechanic/presentation/mechanic_home_screen.dart';

/// Application router for PitMate.
final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.root,
  routes: [
    GoRoute(
      path: RoutePaths.root,
      builder: (context, state) => const RoleHubScreen(),
    ),
    GoRoute(
      path: RoutePaths.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RoutePaths.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: RoutePaths.verifyOtp,
      builder: (context, state) => const VerifyOtpScreen(),
    ),
    GoRoute(
      path: RoutePaths.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: RoutePaths.admin,
      builder: (context, state) => const AdminOverviewScreen(),
    ),
    GoRoute(
      path: RoutePaths.adminCustomers,
      builder: (context, state) => const AdminCustomersScreen(),
    ),
    GoRoute(
      path: RoutePaths.mechanic,
      builder: (context, state) => const MechanicHomeScreen(),
    ),
    GoRoute(
      path: RoutePaths.customer,
      redirect: (context, state) => RoutePaths.customerGarage,
    ),
    GoRoute(
      path: RoutePaths.customerGarage,
      builder: (context, state) => const CustomerGarageScreen(),
    ),
  ],
);
