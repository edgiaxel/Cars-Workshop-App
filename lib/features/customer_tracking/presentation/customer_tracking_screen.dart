import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/shared/navigation/role_navigation.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';

/// Customer Service Tracking Screen (VS-21)
class CustomerTrackingScreen extends ConsumerStatefulWidget {
  const CustomerTrackingScreen({super.key});

  @override
  ConsumerState<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends ConsumerState<CustomerTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveRoleScaffold(
      roleTitle: 'Live Vehicle Tracking',
      userName: 'Axel Zeed',
      userSubtitle: 'Verified Customer',
      currentIndex: 5,
      navItems: RoleNavigation.customerNavItems,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
