import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'route_paths.dart';

/// Navigation guard evaluating user session and role authorization.
class RouteGuards {
  const RouteGuards._();

  static String? handleAuthRedirect(
    BuildContext context,
    GoRouterState state, {
    required bool isAuthenticated,
    String? userRole,
  }) {
    final isLoggingIn = state.matchedLocation == RoutePaths.login ||
        state.matchedLocation == RoutePaths.register;

    if (!isAuthenticated) {
      return isLoggingIn ? null : RoutePaths.login;
    }

    if (isLoggingIn || state.matchedLocation == RoutePaths.initial) {
      return switch (userRole) {
        'admin' => RoutePaths.admin,
        'mechanic' => RoutePaths.mechanic,
        _ => RoutePaths.customer,
      };
    }

    return null;
  }
}
