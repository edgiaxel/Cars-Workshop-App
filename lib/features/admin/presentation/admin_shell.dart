import 'package:flutter/material.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/role_shell_scaffold.dart';
import '../../../shared/widgets/status_badge.dart';

/// Navigation destinations available to workshop administrators.
const List<RoleShellDestination> adminDestinations = [
  RoleShellDestination(
    label: 'Dashboard',
    route: RoutePaths.admin,
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  RoleShellDestination(
    label: 'Customers',
    route: RoutePaths.adminCustomers,
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
  ),
  RoleShellDestination(
    label: 'Mechanics',
    route: RoutePaths.adminMechanics,
    icon: Icons.engineering_outlined,
    selectedIcon: Icons.engineering,
  ),
  RoleShellDestination(
    label: 'Vehicles',
    route: RoutePaths.adminVehicles,
    icon: Icons.directions_car_outlined,
    selectedIcon: Icons.directions_car,
  ),
  RoleShellDestination(
    label: 'Bookings',
    route: RoutePaths.adminBookings,
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
  ),
  RoleShellDestination(
    label: 'Services',
    route: RoutePaths.adminServices,
    icon: Icons.build_outlined,
    selectedIcon: Icons.build,
  ),
  RoleShellDestination(
    label: 'Inventory',
    route: RoutePaths.adminInventory,
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
  ),
  RoleShellDestination(
    label: 'Reports',
    route: RoutePaths.adminReports,
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
  ),
];

/// Shared scaffold wrapper for all admin destinations.
class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.currentRoute,
    required this.child,
    this.actions,
  });

  final String currentRoute;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return RoleShellScaffold(
      currentRoute: currentRoute,
      roleTitle: 'Admin Terminal',
      roleBadge: const StatusBadge(
        label: 'ROLE: ADMIN',
        color: AppColors.primaryAccent,
      ),
      destinations: adminDestinations,
      actions: actions,
      body: child,
    );
  }
}
