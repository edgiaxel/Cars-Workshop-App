import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/otp_verification_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/customers/presentation/admin_customers_page.dart';
import '../../features/vehicles/presentation/admin_vehicles_page.dart';
import '../../features/vehicles/presentation/customer_garage_page.dart';
import '../../shared/layouts/admin_shell.dart';
import '../../shared/layouts/customer_shell.dart';
import '../../shared/layouts/mechanic_shell.dart';
import '../../shared/widgets/pit_card.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'route_paths.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.initial,
  routes: [
    GoRoute(
      path: RoutePaths.initial,
      builder: (context, state) => const _M0LandingPage(),
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
      path: '/otp-verify',
      builder: (context, state) => OtpVerificationPage(
        email: state.uri.queryParameters['email'],
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),

    // ==========================================
    // ADMIN WORKSPACE SHELL & SUBROUTES
    // ==========================================
    ShellRoute(
      builder: (context, state, child) {
        return AdminShell(body: child, currentPath: state.matchedLocation);
      },
      routes: [
        GoRoute(
          path: RoutePaths.admin,
          builder: (context, state) => const _PlaceholderView(
            title: 'Admin Overview',
            description: 'Workshop status metrics, active vehicle intake, and bay workload.',
          ),
        ),
        GoRoute(
          path: RoutePaths.adminFloor,
          builder: (context, state) => const _PlaceholderView(
            title: 'Workshop Floor',
            description:
                'Active bay monitoring, vehicle lifters, and service dispatch.',
          ),
        ),
        GoRoute(
          path: RoutePaths.adminCustomers,
          builder: (context, state) => const AdminCustomersPage(),
        ),
        GoRoute(
          path: RoutePaths.adminVehicles,
          builder: (context, state) => const AdminVehiclesPage(),
        ),
        GoRoute(
          path: RoutePaths.adminMechanics,
          builder: (context, state) => const _PlaceholderView(
            title: 'Mechanic Roster',
            description:
                'Technician schedules, skill levels, and bay assignments.',
          ),
        ),
        GoRoute(
          path: RoutePaths.adminInventory,
          builder: (context, state) => const _PlaceholderView(
            title: 'Inventory Stock',
            description:
                'Parts inventory, stock levels, and procurement alerts.',
          ),
        ),
        GoRoute(
          path: RoutePaths.adminFinance,
          builder: (context, state) => const _PlaceholderView(
            title: 'Finance & Invoices',
            description:
                'Settled revenue, outstanding balances, and cash accounting.',
          ),
        ),
        GoRoute(
          path: RoutePaths.adminSettings,
          builder: (context, state) => const _PlaceholderView(
            title: 'Workshop Settings',
            description:
                'Workshop operating parameters and system configuration.',
          ),
        ),
      ],
    ),

    // ==========================================
    // MECHANIC WORKSPACE SHELL & SUBROUTES
    // ==========================================
    ShellRoute(
      builder: (context, state, child) {
        return MechanicShell(body: child, currentPath: state.matchedLocation);
      },
      routes: [
        GoRoute(
          path: RoutePaths.mechanic,
          builder: (context, state) => const _PlaceholderView(
            title: 'My Assigned Work',
            description: 'Vehicles and repair operations assigned to your bay.',
          ),
        ),
        GoRoute(
          path: RoutePaths.mechanicTasks,
          builder: (context, state) => const _PlaceholderView(
            title: 'Active Operations & Tasks',
            description:
                'Task checklists, parts requests, and repair progress logs.',
          ),
        ),
        GoRoute(
          path: RoutePaths.mechanicInspections,
          builder: (context, state) => const _PlaceholderView(
            title: 'Inspection Checklists',
            description:
                'Multi-point vehicle diagnostic checklists and defect logs.',
          ),
        ),
        GoRoute(
          path: RoutePaths.mechanicProfile,
          builder: (context, state) => const _PlaceholderView(
            title: 'Mechanic Profile',
            description:
                'Technician profile, certifications, and shift records.',
          ),
        ),
      ],
    ),

    // ==========================================
    // CUSTOMER WORKSPACE SHELL & SUBROUTES
    // ==========================================
    ShellRoute(
      builder: (context, state, child) {
        return CustomerShell(body: child, currentPath: state.matchedLocation);
      },
      routes: [
        GoRoute(
          path: RoutePaths.customer,
          builder: (context, state) => const CustomerGaragePage(),
        ),
        GoRoute(
          path: RoutePaths.customerGarage,
          builder: (context, state) => const CustomerGaragePage(),
        ),
        GoRoute(
          path: RoutePaths.customerBookings,
          builder: (context, state) => const _PlaceholderView(
            title: 'Service Bookings',
            description:
                'Upcoming scheduled workshop appointments and check-in status.',
          ),
        ),
        GoRoute(
          path: RoutePaths.customerInvoices,
          builder: (context, state) => const _PlaceholderView(
            title: 'Service Invoices',
            description: 'Invoices, repair cost breakdowns, and receipts.',
          ),
        ),
        GoRoute(
          path: RoutePaths.customerProfile,
          builder: (context, state) => const _PlaceholderView(
            title: 'Customer Profile',
            description:
                'Account settings, notification preferences, and contact info.',
          ),
        ),
      ],
    ),
  ],
);

/// Placeholder content card displaying view title and description.
class _PlaceholderView extends StatelessWidget {
  final String title;
  final String description;

  const _PlaceholderView({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: PitCard(
          title: title,
          child: Text(
            description,
            style: AppTypography.bodyMedium(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _M0LandingPage extends StatelessWidget {
  const _M0LandingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.appName, style: AppTypography.headingSmall()),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.speed, size: 64, color: AppColors.racingRed),
              const SizedBox(height: 16),
              Text(
                'PitMate Automotive Workshop OS',
                style: AppTypography.headingMedium(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Version ${AppConfig.appVersion} — M0 Foundation Ready',
                style: AppTypography.bodyMedium(color: AppColors.neutral),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Technical Foundation Status:',
                        style: AppTypography.label(),
                      ),
                      const SizedBox(height: 8),
                      const _StatusRow(
                        label: 'Flutter & Dart Toolchain',
                        isOk: true,
                      ),
                      const _StatusRow(
                        label: 'Android & Web Compatibility',
                        isOk: true,
                      ),
                      const _StatusRow(
                        label: 'Architecture & Canonical Docs',
                        isOk: true,
                      ),
                      _StatusRow(
                        label: 'Supabase Integration',
                        isOk: AppConfig.isSupabaseConfigured,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool isOk;

  const _StatusRow({required this.label, required this.isOk});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.info_outline,
            size: 16,
            color: isOk ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Text(label, style: AppTypography.bodySmall()),
        ],
      ),
    );
  }
}
