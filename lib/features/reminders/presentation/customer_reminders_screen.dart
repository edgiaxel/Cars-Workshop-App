import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';

/// Customer Maintenance Reminders Screen (VS-22)
class CustomerRemindersScreen extends ConsumerStatefulWidget {
  const CustomerRemindersScreen({super.key});

  @override
  ConsumerState<CustomerRemindersScreen> createState() => _CustomerRemindersScreenState();
}

class _CustomerRemindersScreenState extends ConsumerState<CustomerRemindersScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveRoleScaffold(
      roleTitle: 'Maintenance Reminders',
      userName: 'Axel Zeed',
      userSubtitle: 'Verified Customer',
      currentIndex: 6,
      navItems: RoleNavigation.customerNavItems,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
