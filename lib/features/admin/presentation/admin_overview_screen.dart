import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

/// Admin Workshop Overview Screen matching screens/admin_home_overview prototype.
class AdminOverviewScreen extends ConsumerStatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  ConsumerState<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends ConsumerState<AdminOverviewScreen> {
  int _navIndex = 0;

  static const List<RoleNavItem> _adminNavItems = [
    RoleNavItem(label: 'Workshop Overview', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
    RoleNavItem(label: 'Customers & Fleet', icon: Icons.people_outline, selectedIcon: Icons.people),
    RoleNavItem(label: 'Service Orders', icon: Icons.assignment_outlined, selectedIcon: Icons.assignment, badge: '4'),
    RoleNavItem(label: 'Bay Schedule', icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month),
    RoleNavItem(label: 'Inventory', icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2),
  ];

  void _onNavChanged(int index) {
    if (index == 1) {
      context.go(RoutePaths.adminCustomers);
      return;
    }
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    return ResponsiveRoleScaffold(
      roleTitle: 'Workshop Dispatch',
      userName: 'Toto Wolf',
      userSubtitle: 'Workshop Director',
      currentIndex: _navIndex,
      onNavIndexChanged: _onNavChanged,
      navItems: _adminNavItems,
      telemetryNotice: '4/5 BAYS ACTIVE (80%)',
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.people_alt_outlined, size: 20),
          onPressed: () => context.go(RoutePaths.adminCustomers),
          tooltip: 'Manage Customers',
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quick Navigation Banner to Customers
                PitCard(
                  accentBorderLeft: AppColors.accentRed,
                  onTap: () => context.go(RoutePaths.adminCustomers),
                  child: Row(
                    children: [
                      const Icon(Icons.group_add_outlined, color: AppColors.accentRed, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CUSTOMER REGISTRY & WALK-IN INTAKE',
                              style: AppTypography.labelLarge(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Register new walk-in guest vehicles or inspect existing customer accounts.',
                              style: AppTypography.bodySmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.accentRed),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Live Workshop KPI Row
                Row(
                  children: [
                    Expanded(
                      child: PitCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACTIVE ORDERS',
                              style: AppTypography.labelSmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('4', style: AppTypography.headlineLarge(color: textColor)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PitCard(
                        padding: const EdgeInsets.all(12),
                        accentBorderLeft: AppColors.accentRed,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'IN WORKSHOP',
                              style: AppTypography.labelSmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('3', style: AppTypography.headlineLarge(color: AppColors.accentRed)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PitCard(
                        padding: const EdgeInsets.all(12),
                        accentBorderLeft: AppColors.warning,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AWAITING AUTH',
                              style: AppTypography.labelSmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('1', style: AppTypography.headlineLarge(color: AppColors.warning)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PitCard(
                        padding: const EdgeInsets.all(12),
                        accentBorderLeft: AppColors.success,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QC READY',
                              style: AppTypography.labelSmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('1', style: AppTypography.headlineLarge(color: AppColors.success)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Active Workshop Bay Status
                Text(
                  'ACTIVE SHOP BAYS',
                  style: AppTypography.headlineSmall(color: textColor),
                ),
                const SizedBox(height: 10),

                // Bay 02 Card (Matching Prototype)
                PitCard(
                  accentBorderLeft: AppColors.accentRed,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'BAY 02 — HOIST B',
                                style: AppTypography.headlineSmall(color: textColor),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge.inProgress('IN PROGRESS', icon: Icons.play_arrow),
                            ],
                          ),
                          Text(
                            'Tech: Dian S.',
                            style: AppTypography.bodySmall(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Honda Civic Type R (FL5) [B 9912 SPO]',
                        style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'SO-2026-0143: Brake Rotor & Pad Bedding + High-Temp Fluid Flush',
                        style: AppTypography.bodySmall(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Bay 04 Card
                PitCard(
                  accentBorderLeft: AppColors.warning,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'BAY 04 — DIAGNOSTIC',
                                style: AppTypography.headlineSmall(color: textColor),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge.warning('WAITING CLIENT AUTH', icon: Icons.pending),
                            ],
                          ),
                          Text(
                            'Tech: Reza P.',
                            style: AppTypography.bodySmall(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'BMW 320i F30 LCI [B 3021 RFS]',
                        style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'SO-2026-0144: Ignition Coil #3 Replacement (Client Quote Sent)',
                        style: AppTypography.bodySmall(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
