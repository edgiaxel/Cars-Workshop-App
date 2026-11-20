import 'package:flutter/material.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/widgets/role_shell_scaffold.dart';

/// Navigation destinations available to workshop customers.
const List<RoleShellDestination> customerDestinations = [
  RoleShellDestination(
    label: 'Dashboard',
    route: RoutePaths.customer,
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  RoleShellDestination(
    label: 'Profile',
    route: RoutePaths.customerProfile,
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
  RoleShellDestination(
    label: 'Vehicles',
    route: RoutePaths.customerVehicles,
    icon: Icons.directions_car_outlined,
    selectedIcon: Icons.directions_car,
  ),
  RoleShellDestination(
    label: 'Bookings',
    route: RoutePaths.customerBookings,
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today,
  ),
  RoleShellDestination(
    label: 'Service History',
    route: RoutePaths.customerHistory,
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
  ),
  RoleShellDestination(
    label: 'Notifications',
    route: RoutePaths.customerNotifications,
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
  ),
  RoleShellDestination(
    label: 'Reminders',
    route: RoutePaths.customerReminders,
    icon: Icons.alarm_outlined,
    selectedIcon: Icons.alarm,
  ),
];

/// Shared scaffold wrapper for all customer destinations.
class CustomerShell extends StatelessWidget {
  const CustomerShell({
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
      roleTitle: 'Customer Portal',
      destinations: customerDestinations,
      actions: actions,
      body: child,
    );
  }
}
