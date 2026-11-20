/// Route path definitions for PitMate v2.0.
class RoutePaths {
  const RoutePaths._();

  static const String initial = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Admin Workspace Routes
  static const String admin = '/admin';
  static const String adminFloor = '/admin/floor';
  static const String adminCustomers = '/admin/customers';
  static const String adminVehicles = '/admin/vehicles';
  static const String adminMechanics = '/admin/mechanics';
  static const String adminInventory = '/admin/inventory';
  static const String adminFinance = '/admin/finance';
  static const String adminSettings = '/admin/settings';

  // Mechanic Workspace Routes
  static const String mechanic = '/mechanic';
  static const String mechanicTasks = '/mechanic/tasks';
  static const String mechanicInspections = '/mechanic/inspections';
  static const String mechanicProfile = '/mechanic/profile';

  // Customer Workspace Routes
  static const String customer = '/customer';
  static const String customerGarage = '/customer/garage';
  static const String customerBookings = '/customer/bookings';
  static const String customerInvoices = '/customer/invoices';
  static const String customerProfile = '/customer/profile';
}
