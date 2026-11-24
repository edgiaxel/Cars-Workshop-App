import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';

/// Admin Reports & Analytics Screen (VS-23)
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveRoleScaffold(
      roleTitle: 'Workshop Reports & Analytics',
      userName: 'Toto Wolf',
      userSubtitle: 'Workshop Director',
      currentIndex: 11,
      navItems: RoleNavigation.adminNavItems,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
