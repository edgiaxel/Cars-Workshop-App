import '../../data/models/user_role.dart';

/// Authoritative route path constants for PitMate adhering to ARCHITECTURE.md.
abstract class RoutePaths {
  // Public Routes
  static const String root = '/';
  static const String landing = '/landing';
  static const String about = '/about';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Admin Destinations (8 routes)
  static const String admin = '/admin';
  static const String adminCustomers = '/admin/customers';
  static const String adminMechanics = '/admin/mechanics';
  static const String adminVehicles = '/admin/vehicles';
  static const String adminBookings = '/admin/bookings';
  static const String adminServices = '/admin/services';
  static const String adminInventory = '/admin/inventory';
  static const String adminReports = '/admin/reports';

  // Mechanic Destinations (5 routes)
  static const String mechanic = '/mechanic';
  static const String mechanicServices = '/mechanic/services';
  static const String mechanicTasks = '/mechanic/tasks';
  static const String mechanicHistory = '/mechanic/history';
  static const String mechanicEarnings = '/mechanic/earnings';

  // Customer Destinations (7 routes)
  static const String customer = '/customer';
  static const String customerProfile = '/customer/profile';
  static const String customerVehicles = '/customer/vehicles';
  static const String customerBookings = '/customer/bookings';
  static const String customerHistory = '/customer/history';
  static const String customerNotifications = '/customer/notifications';
  static const String customerReminders = '/customer/reminders';

  // Access Control Alert Route
  static const String unauthorized = '/unauthorized';

  /// Helper to get the dashboard route for a given role name string.
  static String dashboardForRole(String role) {
    switch (role.trim().toLowerCase()) {
      case 'admin':
        return admin;
      case 'mechanic':
        return mechanic;
      case 'customer':
        return customer;
      default:
        return landing;
    }
  }

  /// Helper to get the dashboard route for a typed [UserRole].
  static String dashboardForUserRole(UserRole? role) {
    if (role == null) return login;
    switch (role) {
      case UserRole.admin:
        return admin;
      case UserRole.mechanic:
        return mechanic;
      case UserRole.customer:
        return customer;
    }
  }
}
