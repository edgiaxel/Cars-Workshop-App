import 'package:flutter/material.dart';
import '../../app/router/route_paths.dart';
import '../models/user_profile.dart';
import 'responsive_scaffold.dart';

/// Mechanic role shell providing technician workspace navigation items.
class MechanicShell extends StatelessWidget {
  final Widget body;
  final String currentPath;
  final UserProfile? userProfile;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final ValueChanged<String>? onNavigate;

  const MechanicShell({
    super.key,
    required this.body,
    required this.currentPath,
    this.userProfile,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.onNavigate,
  });

  static const List<NavigationItem> mechanicNavigationItems = [
    NavigationItem(
      label: 'My Work',
      icon: Icons.home_repair_service_outlined,
      selectedIcon: Icons.home_repair_service,
      route: RoutePaths.mechanic,
    ),
    NavigationItem(
      label: 'Tasks',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      route: RoutePaths.mechanicTasks,
    ),
    NavigationItem(
      label: 'Inspections',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
      route: RoutePaths.mechanicInspections,
    ),
    NavigationItem(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      route: RoutePaths.mechanicProfile,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: title ?? 'Mechanic Workspace',
      navigationItems: mechanicNavigationItems,
      currentPath: currentPath,
      userProfile: userProfile,
      body: body,
      actions: actions,
      floatingActionButton: floatingActionButton,
      onNavigate: onNavigate,
    );
  }
}
