import 'package:flutter/material.dart';

import '../../../app/router/route_paths.dart';
import 'admin_dashboard_view.dart';
import 'admin_shell.dart';

/// Entry page for /admin route adhering to ARCHITECTURE.md.
class AdminShellPage extends StatelessWidget {
  const AdminShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      currentRoute: RoutePaths.admin,
      child: AdminDashboardView(),
    );
  }
}
