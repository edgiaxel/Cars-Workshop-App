import 'package:flutter/material.dart';
import '../../app/router/route_paths.dart';
import '../models/user_profile.dart';
import 'responsive_scaffold.dart';

/// Customer role shell providing vehicle owner self-service navigation items.
class CustomerShell extends StatelessWidget {
  final Widget body;
  final String currentPath;
  final UserProfile? userProfile;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final ValueChanged<String>? onNavigate;

  const CustomerShell({
    super.key,
    required this.body,
    required this.currentPath,
    this.userProfile,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.onNavigate,
  });

  static const List<NavigationItem> customerNavigationItems = [
    NavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      route: RoutePaths.customer,
    ),
    NavigationItem(
      label: 'Garage',
      icon: Icons.garage_outlined,
      selectedIcon: Icons.garage,
      route: RoutePaths.customerGarage,
    ),
    NavigationItem(
      label: 'Bookings',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      route: RoutePaths.customerBookings,
    ),
    NavigationItem(
      label: 'Invoices',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      route: RoutePaths.customerInvoices,
    ),
    NavigationItem(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      route: RoutePaths.customerProfile,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: title ?? 'Customer Portal',
      navigationItems: customerNavigationItems,
      currentPath: currentPath,
      userProfile: userProfile,
      body: body,
      actions: actions,
      floatingActionButton: floatingActionButton,
      onNavigate: onNavigate,
    );
  }
}
