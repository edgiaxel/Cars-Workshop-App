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
  static const String adminBookings = '/admin/bookings';
  static const String adminInspectionReview = '/admin/inspection-review';
  static const String adminEstimateBuilder = '/admin/estimates';
  static const String adminWorkshopFloor = '/admin/floor';
  static const String adminInventory = '/admin/inventory';
  static const String adminPartRequests = '/admin/part-requests';
  static const String adminCompensation = '/admin/compensation';
  static const String adminQualityControl = '/admin/quality-control';
  static const String adminInvoices = '/admin/invoices';
  static const String adminHandover = '/admin/handover';

  // Mechanic subsystem paths
  static const String mechanic = '/mechanic';
  static const String mechanicInspection = '/mechanic/inspection';
  static const String mechanicOperation = '/mechanic/operation';
  static const String mechanicEarnings = '/mechanic/earnings';

  // Customer subsystem paths
  static const String customer = '/customer';
  static const String customerGarage = '/customer/garage';
  static const String bookService = '/customer/book-service';
  static const String customerAppointments = '/customer/appointments';
  static const String customerEstimateApproval = '/customer/estimates';
  static const String customerInvoices = '/customer/invoices';
}
