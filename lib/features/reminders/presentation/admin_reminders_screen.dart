import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';

/// Admin Service Reminders Screen (VS-22)
class AdminRemindersScreen extends ConsumerStatefulWidget {
  const AdminRemindersScreen({super.key});

  @override
  ConsumerState<AdminRemindersScreen> createState() => _AdminRemindersScreenState();
}

class _AdminRemindersScreenState extends ConsumerState<AdminRemindersScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveRoleScaffold(
      roleTitle: 'Service Reminders Queue',
      userName: 'Toto Wolf',
      userSubtitle: 'Workshop Director',
      currentIndex: 12,
      navItems: RoleNavigation.adminNavItems,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
