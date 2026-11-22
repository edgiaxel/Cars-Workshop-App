/// Centralized route paths for PitMate application.
class RoutePaths {
  const RoutePaths._();

  // Root & Auth paths
  static const String root = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String forgotPassword = '/forgot-password';

  // Admin subsystem paths
  static const String admin = '/admin';
  static const String adminCustomers = '/admin/customers';
  static const String adminInspectionReview = '/admin/inspection-review';

  // Mechanic subsystem paths
  static const String mechanic = '/mechanic';
  static const String mechanicInspection = '/mechanic/inspection';

  // Customer subsystem paths
  static const String customer = '/customer';
  static const String customerGarage = '/customer/garage';
}
