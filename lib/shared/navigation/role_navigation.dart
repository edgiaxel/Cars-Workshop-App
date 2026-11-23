import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';

/// Centralized, canonical navigation configuration for all PitMate roles.
///
/// Ensures consistent sidebar and bottom navigation across all application screens,
/// preventing navigation drift, missing items, or mismatched indices.
class RoleNavigation {
  const RoleNavigation._();

  /// Canonical navigation items for Workshop Admin role (8 items).
  static const List<RoleNavItem> adminNavItems = [
    RoleNavItem(
      label: 'Workshop Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      path: RoutePaths.admin,
    ),
    RoleNavItem(
      label: 'Customers & Fleet',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      path: RoutePaths.adminCustomers,
    ),
    RoleNavItem(
      label: 'Workshop Floor',
      icon: Icons.garage_outlined,
      selectedIcon: Icons.garage,
      path: RoutePaths.adminWorkshopFloor,
    ),
    RoleNavItem(
      label: 'Bay Schedule & Bookings',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      path: RoutePaths.adminBookings,
    ),
    RoleNavItem(
      label: 'Inspection Review',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      path: RoutePaths.adminInspectionReview,
    ),
    RoleNavItem(
      label: 'Inventory & Stock',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      path: RoutePaths.adminInventory,
    ),
    RoleNavItem(
      label: 'Part Requests',
      icon: Icons.handyman_outlined,
      selectedIcon: Icons.handyman,
      path: RoutePaths.adminPartRequests,
    ),
    RoleNavItem(
      label: 'Compensation',
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments,
      path: RoutePaths.adminCompensation,
    ),
  ];

  /// Canonical navigation items for Mechanic role (4 items).
  static const List<RoleNavItem> mechanicNavItems = [
    RoleNavItem(
      label: 'My Work',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      path: RoutePaths.mechanic,
    ),
    RoleNavItem(
      label: 'Active Workspace',
      icon: Icons.precision_manufacturing_outlined,
      selectedIcon: Icons.precision_manufacturing,
      path: RoutePaths.mechanicOperation,
    ),
    RoleNavItem(
      label: 'Vehicle Inspection',
      icon: Icons.car_repair_outlined,
      selectedIcon: Icons.car_repair,
      path: RoutePaths.mechanicInspection,
    ),
    RoleNavItem(
      label: 'My Earnings',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      path: RoutePaths.mechanicEarnings,
    ),
  ];

  /// Canonical navigation items for Customer role (4 items).
  static const List<RoleNavItem> customerNavItems = [
    RoleNavItem(
      label: 'My Garage',
      icon: Icons.garage_outlined,
      selectedIcon: Icons.garage,
      path: RoutePaths.customerGarage,
    ),
    RoleNavItem(
      label: 'Book Service',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      path: RoutePaths.bookService,
    ),
    RoleNavItem(
      label: 'Appointments',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      path: RoutePaths.customerAppointments,
    ),
    RoleNavItem(
      label: 'Estimates & Approval',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      path: RoutePaths.customerEstimateApproval,
    ),
  ];

  /// Centralized router navigation handler.
  ///
  /// Navigates to [items[targetIndex].path] if valid and different from [currentIndex].
  static void navigate(
    BuildContext context,
    List<RoleNavItem> items,
    int targetIndex, {
    int? currentIndex,
  }) {
    if (targetIndex < 0 || targetIndex >= items.length) return;
    if (currentIndex != null && targetIndex == currentIndex) return;

    final item = items[targetIndex];
    if (item.path != null && item.path!.isNotEmpty) {
      context.go(item.path!);
    }
  }
}
