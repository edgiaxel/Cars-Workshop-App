import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_paths.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../providers/auth_provider.dart';

/// Navigation item description for role-based shells.
class RoleShellDestination {
  const RoleShellDestination({
    required this.label,
    required this.route,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final String route;
  final IconData icon;
  final IconData? selectedIcon;
}

/// Unified responsive application shell supporting desktop sidebar and mobile drawer.
class RoleShellScaffold extends ConsumerWidget {
  const RoleShellScaffold({
    super.key,
    required this.currentRoute,
    required this.roleTitle,
    required this.roleBadge,
    required this.destinations,
    required this.body,
    this.actions,
  });

  final String currentRoute;
  final String roleTitle;
  final Widget roleBadge;
  final List<RoleShellDestination> destinations;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionProvider);
    final userProfile = authState.profile;
    final isDesktop = MediaQuery.of(context).size.width >= 840;

    final dashboardRoute = destinations.isNotEmpty
        ? destinations.first.route
        : RoutePaths.landing;
    final isDashboard = currentRoute == dashboardRoute;

    final scaffold = isDesktop
        ? Scaffold(
            backgroundColor: AppColors.backgroundPrimary,
            body: Row(
              children: [
                // Desktop Persistent Navigation Sidebar
                _buildDesktopSidebar(context, ref, authState, userProfile),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.borderSubtle,
                ),
                // Main Content Area
                Expanded(
                  child: Column(
                    children: [
                      _buildDesktopTopBar(context, ref, userProfile),
                      Expanded(child: body),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Scaffold(
            backgroundColor: AppColors.backgroundPrimary,
            appBar: AppBar(
              leading: isDashboard
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                      tooltip: 'Back to Dashboard',
                      onPressed: () => context.go(dashboardRoute),
                    ),
              title: Text(
                roleTitle,
                style: AppTypography.sectionTitle(color: AppColors.textPrimary),
              ),
              actions: [
                roleBadge,
                const SizedBox(width: AppSpacing.compact),
                ...?actions,
                IconButton(
                  icon: const Icon(
                    Icons.logout,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Sign Out',
                  onPressed: () async {
                    await ref.read(authSessionProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go(RoutePaths.landing);
                    }
                  },
                ),
                const SizedBox(width: AppSpacing.compact),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: Container(
                  height: 2,
                  color: AppColors.primaryAccent.withValues(alpha: 0.8),
                ),
              ),
            ),
            drawer: _buildMobileDrawer(context, ref, authState, userProfile),
            body: SafeArea(child: body),
          );

    return PopScope(
      canPop: isDashboard,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go(dashboardRoute);
        }
      },
      child: scaffold,
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    WidgetRef ref,
    dynamic authState,
    dynamic userProfile,
  ) {
    return Container(
      width: 260,
      color: AppColors.backgroundSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo & Branding
          Padding(
            padding: const EdgeInsets.all(AppSpacing.standard),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Text(
                    'PITMATE',
                    style: AppTypography.technical(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(width: AppSpacing.compact),
                Expanded(
                  child: Text(
                    roleTitle,
                    style: AppTypography.technical(color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),

          // Destinations List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.compact),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final item = destinations[index];
                final isSelected =
                    currentRoute == item.route ||
                    (item.route != '/' &&
                        item.route.split('/').length > 2 &&
                        currentRoute.startsWith(item.route));

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.compact,
                    vertical: 2,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      onTap: () => context.go(item.route),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.standard,
                          vertical: AppSpacing.compact + 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryAccent.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppRadius.control,
                          ),
                          border: isSelected
                              ? const Border(
                                  left: BorderSide(
                                    color: AppColors.primaryAccent,
                                    width: 3,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? (item.selectedIcon ?? item.icon)
                                  : item.icon,
                              size: 20,
                              color: isSelected
                                  ? AppColors.primaryAccent
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.standard),
                            Expanded(
                              child: Text(
                                item.label,
                                style: isSelected
                                    ? AppTypography.label(
                                        color: AppColors.textPrimary,
                                      )
                                    : AppTypography.bodySmall(
                                        color: AppColors.textSecondary,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: AppColors.borderSubtle),
          // User & Session Footer
          Padding(
            padding: const EdgeInsets.all(AppSpacing.standard),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceSecondary,
                  child: Text(
                    (userProfile?.fullName as String? ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.compact),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProfile?.fullName ?? 'User',
                        style: AppTypography.label(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        authState.email ?? '',
                        style: AppTypography.bodySmall(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.logout,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  tooltip: 'Sign Out',
                  onPressed: () async {
                    Navigator.pop(context);
                    await ref.read(authSessionProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go(RoutePaths.landing);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTopBar(
    BuildContext context,
    WidgetRef ref,
    dynamic userProfile,
  ) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.section),
      decoration: const BoxDecoration(
        color: AppColors.surfacePrimary,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                roleTitle,
                style: AppTypography.technical(color: AppColors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.standard),
              roleBadge,
            ],
          ),
          Row(
            children: [
              ...?actions,
              const SizedBox(width: AppSpacing.standard),
              Text(
                userProfile?.fullName ?? '',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(
    BuildContext context,
    WidgetRef ref,
    dynamic authState,
    dynamic userProfile,
  ) {
    return Drawer(
      backgroundColor: AppColors.backgroundSecondary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.standard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent,
                          borderRadius: BorderRadius.circular(
                            AppRadius.control,
                          ),
                        ),
                        child: Text(
                          'PITMATE',
                          style: AppTypography.technical(color: Colors.white)
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ),
                      roleBadge,
                    ],
                  ),
                  const SizedBox(height: AppSpacing.standard),
                  Text(
                    userProfile?.fullName ?? 'Authenticated User',
                    style: AppTypography.sectionTitle(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    authState.email ?? '',
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.compact,
                ),
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final item = destinations[index];
                  final isSelected = currentRoute == item.route;

                  return ListTile(
                    leading: Icon(
                      isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
                      color: isSelected
                          ? AppColors.primaryAccent
                          : AppColors.textSecondary,
                    ),
                    title: Text(
                      item.label,
                      style: isSelected
                          ? AppTypography.label(color: AppColors.primaryAccent)
                          : AppTypography.bodyMedium(
                              color: AppColors.textPrimary,
                            ),
                    ),
                    selected: isSelected,
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      context.go(item.route);
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                'Sign Out Session',
                style: AppTypography.bodyMedium(color: AppColors.error),
              ),
              onTap: () async {
                await ref.read(authSessionProvider.notifier).signOut();
                if (context.mounted) {
                  context.go(RoutePaths.landing);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
