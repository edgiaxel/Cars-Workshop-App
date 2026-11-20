/// Route path definitions for PitMate v2.0.
class RoutePaths {
  const RoutePaths._();

  static const String initial = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Role Shells
  static const String admin = '/admin';
  static const String mechanic = '/mechanic';
  static const String customer = '/customer';

  // Sub-routes
  static const String workshopQueue = '/admin/queue';
  static const String mechanicTasks = '/mechanic/tasks';
  static const String customerGarage = '/customer/garage';
}
