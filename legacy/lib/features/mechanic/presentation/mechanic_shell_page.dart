import 'package:flutter/material.dart';

import '../../../app/router/route_paths.dart';
import 'mechanic_dashboard_view.dart';
import 'mechanic_shell.dart';

/// Entry page for /mechanic route adhering to ARCHITECTURE.md.
class MechanicShellPage extends StatelessWidget {
  const MechanicShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MechanicShell(
      currentRoute: RoutePaths.mechanic,
      child: MechanicDashboardView(),
    );
  }
}
