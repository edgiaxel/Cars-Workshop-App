import 'package:flutter/material.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/role_shell_scaffold.dart';
import '../../../shared/widgets/status_badge.dart';

/// Navigation destinations available to workshop mechanics.
const List<RoleShellDestination> mechanicDestinations = [
  RoleShellDestination(
    label: 'Dashboard',
    route: RoutePaths.mechanic,
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  RoleShellDestination(
    label: 'Assigned Services',
    route: RoutePaths.mechanicServices,
    icon: Icons.car_repair_outlined,
    selectedIcon: Icons.car_repair,
  ),
  RoleShellDestination(
    label: 'Tasks & Checklist',
    route: RoutePaths.mechanicTasks,
    icon: Icons.checklist_outlined,
    selectedIcon: Icons.checklist,
  ),
  RoleShellDestination(
    label: 'Service History',
    route: RoutePaths.mechanicHistory,
    icon: Icons.history_outlined,
    selectedIcon: Icons.history,
  ),
  RoleShellDestination(
    label: 'Earnings',
    route: RoutePaths.mechanicEarnings,
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments,
  ),
];

/// Shared scaffold wrapper for all mechanic destinations.
class MechanicShell extends StatelessWidget {
  const MechanicShell({
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
      roleTitle: 'Mechanic Workbench',
      roleBadge: const StatusBadge(
        label: 'ROLE: MECHANIC',
        color: AppColors.primaryAccent,
      ),
      destinations: mechanicDestinations,
      actions: actions,
      body: child,
    );
  }
}
