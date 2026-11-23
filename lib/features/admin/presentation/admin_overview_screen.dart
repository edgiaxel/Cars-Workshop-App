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
import 'package:pitmate/shared/navigation/role_navigation.dart';

class AdminOverviewScreen extends ConsumerStatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  ConsumerState<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends ConsumerState<AdminOverviewScreen> {


  void _onNavChanged(int index) {
    RoleNavigation.navigate(context, RoleNavigation.adminNavItems, index, currentIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    return ResponsiveRoleScaffold(
      roleTitle: 'Workshop Dispatch',
      userName: 'Toto Wolf',
      userSubtitle: 'Workshop Director',
      currentIndex: 0,
      onNavIndexChanged: _onNavChanged,
      navItems: RoleNavigation.adminNavItems,
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
                // Quick Navigation Banner to Workshop Floor
                PitCard(
                  accentBorderLeft: AppColors.accentRed,
                  onTap: () => context.go(RoutePaths.adminWorkshopFloor),
                  child: Row(
                    children: [
                      const Icon(Icons.garage_outlined, color: AppColors.accentRed, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WORKSHOP FLOOR & 5-BAY DISPATCH CONSOLE',
                              style: AppTypography.labelLarge(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Monitor 5 physical bays, detect occupancy conflicts, and dispatch approved operations.',
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
                const SizedBox(height: 12),

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
                const SizedBox(height: 12),

                // Quick Navigation Banner to Inventory & Catalog
                PitCard(
                  key: const Key('card_admin_nav_inventory'),
                  accentBorderLeft: AppColors.info,
                  onTap: () => context.go(RoutePaths.adminInventory),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, color: AppColors.info, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INVENTORY & SPARE PARTS CATALOG',
                              style: AppTypography.labelLarge(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Manage stock levels, receive shipments, audit movements, and record adjustments.',
                              style: AppTypography.bodySmall(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.info),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Navigation Banner to Part Requests & Compensation
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    final reqCard = PitCard(
                      key: const Key('card_admin_nav_requests'),
                      accentBorderLeft: AppColors.warning,
                      onTap: () => context.go(RoutePaths.adminPartRequests),
                      child: Row(
                        children: [
                          const Icon(Icons.handyman_outlined, color: AppColors.warning, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'FLOOR PART REQUESTS',
                              style: AppTypography.labelMedium(color: textColor).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.warning, size: 18),
                        ],
                      ),
                    );

                    final compCard = PitCard(
                      key: const Key('card_admin_nav_compensation'),
                      accentBorderLeft: AppColors.success,
                      onTap: () => context.go(RoutePaths.adminCompensation),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_outlined, color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'MECHANIC COMPENSATION',
                              style: AppTypography.labelMedium(color: textColor).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.success, size: 18),
                        ],
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          reqCard,
                          const SizedBox(height: 10),
                          compCard,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: reqCard),
                        const SizedBox(width: 12),
                        Expanded(child: compCard),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Live Workshop KPI Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    final kpi1 = PitCard(
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
                    );

                    final kpi2 = PitCard(
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
                    );

                    final kpi3 = PitCard(
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
                    );

                    final kpi4 = PitCard(
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
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: kpi1),
                              const SizedBox(width: 10),
                              Expanded(child: kpi2),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: kpi3),
                              const SizedBox(width: 10),
                              Expanded(child: kpi4),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: kpi1),
                        const SizedBox(width: 12),
                        Expanded(child: kpi2),
                        const SizedBox(width: 12),
                        Expanded(child: kpi3),
                        const SizedBox(width: 12),
                        Expanded(child: kpi4),
                      ],
                    );
                  },
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
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
