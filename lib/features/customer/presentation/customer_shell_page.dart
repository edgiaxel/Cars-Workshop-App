import 'package:flutter/material.dart';

import '../../../app/router/route_paths.dart';
import 'customer_dashboard_view.dart';
import 'customer_shell.dart';

/// Entry page for /customer route adhering to ARCHITECTURE.md.
class CustomerShellPage extends StatelessWidget {
  const CustomerShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomerShell(
      currentRoute: RoutePaths.customer,
      child: CustomerDashboardView(),
    );
  }
}
