import 'package:flutter/material.dart';
import '../../app/router/route_paths.dart';
import '../models/user_profile.dart';
import 'responsive_scaffold.dart';

/// Admin role shell providing full workshop management navigation items.
class AdminShell extends StatelessWidget {
  final Widget body;
  final String currentPath;
  final UserProfile? userProfile;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final ValueChanged<String>? onNavigate;

  const AdminShell({
    super.key,
    required this.body,
    required this.currentPath,
    this.userProfile,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.onNavigate,
  });

  static const List<NavigationItem> adminNavigationItems = [
    NavigationItem(
      label: 'Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: RoutePaths.admin,
    ),
    NavigationItem(
      label: 'Workshop Floor',
      icon: Icons.precision_manufacturing_outlined,
      selectedIcon: Icons.precision_manufacturing,
      route: RoutePaths.adminFloor,
    ),
    NavigationItem(
      label: 'Customers',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      route: RoutePaths.adminCustomers,
    ),
    NavigationItem(
      label: 'Vehicles',
      icon: Icons.directions_car_outlined,
      selectedIcon: Icons.directions_car,
      route: RoutePaths.adminVehicles,
    ),
    NavigationItem(
      label: 'Mechanics',
      icon: Icons.engineering_outlined,
      selectedIcon: Icons.engineering,
      route: RoutePaths.adminMechanics,
    ),
    NavigationItem(
      label: 'Inventory',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      route: RoutePaths.adminInventory,
    ),
    NavigationItem(
      label: 'Finance',
      icon: Icons.attach_money,
      selectedIcon: Icons.monetization_on,
      route: RoutePaths.adminFinance,
    ),
    NavigationItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      route: RoutePaths.adminSettings,
    ),
  ];

  static const List<NavigationItem> adminMobileItems = [
    NavigationItem(
      label: 'Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: RoutePaths.admin,
    ),
    NavigationItem(
      label: 'Workshop',
      icon: Icons.precision_manufacturing_outlined,
      selectedIcon: Icons.precision_manufacturing,
      route: RoutePaths.adminFloor,
    ),
    NavigationItem(
      label: 'Customers',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      route: RoutePaths.adminCustomers,
    ),
    NavigationItem(
      label: 'Inventory',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      route: RoutePaths.adminInventory,
    ),
    NavigationItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      route: RoutePaths.adminSettings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: title ?? 'Workshop Admin',
      navigationItems: adminNavigationItems,
      mobileNavigationItems: adminMobileItems,
      currentPath: currentPath,
      userProfile: userProfile,
      body: body,
      actions: actions,
      floatingActionButton: floatingActionButton,
      onNavigate: onNavigate,
    );
  }
}
