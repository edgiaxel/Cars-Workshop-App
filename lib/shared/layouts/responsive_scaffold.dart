import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/theme_provider.dart';
import '../models/user_profile.dart';
import '../widgets/status_badge.dart';

/// Data class representing an item in the navigation hierarchy.
class NavigationItem {
  final String label;
  final IconData icon;
  final String route;
  final IconData? selectedIcon;
  final String? badge;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
    this.selectedIcon,
    this.badge,
  });
}

/// Universal responsive scaffold adapting across Mobile, Tablet, and Desktop breakpoints.
/// - Desktop (width >= 1024): Permanent sidebar with branding, profile, navigation, and theme footer.
/// - Tablet (600 <= width < 1024): NavigationRail with icons and selected indicators.
/// - Mobile (width < 600): Top AppBar, body, and BottomNavigationBar.
class ResponsiveScaffold extends ConsumerWidget {
  final String title;
  final List<NavigationItem> navigationItems;
  final List<NavigationItem>? mobileNavigationItems;
  final String currentPath;
  final UserProfile? userProfile;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final ValueChanged<String>? onNavigate;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.navigationItems,
    this.mobileNavigationItems,
    required this.currentPath,
    this.userProfile,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.onNavigate,
  });

  static const double desktopBreakpoint = 1024.0;
  static const double tabletBreakpoint = 600.0;

  void _handleNavigation(BuildContext context, String route) {
    if (onNavigate != null) {
      onNavigate!(route);
    } else {
      context.go(route);
    }
  }

  int _findSelectedIndex(List<NavigationItem> items) {
    // Exact match first
    for (int i = 0; i < items.length; i++) {
      if (items[i].route == currentPath) return i;
    }
    // Prefix fallback for subpaths
    int bestIndex = -1;
    int bestLength = 0;
    for (int i = 0; i < items.length; i++) {
      final route = items[i].route;
      if (route == '/') continue;
      // Match if path is an exact subpath (e.g. '/admin/customers/create' matches '/admin/customers')
      if (currentPath.startsWith('$route/') || currentPath == route) {
        if (route.length > bestLength) {
          bestLength = route.length;
          bestIndex = i;
        }
      }
    }
    return bestIndex != -1 ? bestIndex : 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= desktopBreakpoint) {
          return _buildDesktopLayout(context, ref);
        } else if (constraints.maxWidth >= tabletBreakpoint) {
          return _buildTabletLayout(context, ref);
        } else {
          return _buildMobileLayout(context, ref);
        }
      },
    );
  }

  // ==========================================
  // DESKTOP LAYOUT (width >= 1024)
  // ==========================================
  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final selectedIndex = _findSelectedIndex(navigationItems);

    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                right: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Workshop Branding
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: AppSpacing.paddingXs,
                        decoration: BoxDecoration(
                          color: AppColors.racingRed,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Icon(
                          Icons.speed,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PitMate',
                              style: AppTypography.headingSmall(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'Automotive Workshop OS',
                              style: AppTypography.bodySmall(
                                color: AppColors.neutral,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // User Profile Header
                Padding(
                  padding: AppSpacing.paddingMd,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.racingRed.withValues(alpha: 0.15),
                        child: Text(
                          userProfile?.fullName.isNotEmpty == true
                              ? userProfile!.fullName.substring(0, 1).toUpperCase()
                              : 'P',
                          style: AppTypography.label(color: AppColors.racingRed),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProfile?.fullName ?? 'PitMate Staff',
                              style: AppTypography.bodyMedium(
                                color: isDark ? Colors.white : Colors.black87,
                              ).copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            StatusBadge(
                              label: userProfile?.role.label ?? 'Guest',
                              variant: userProfile?.role.isAdmin == true
                                  ? StatusBadgeVariant.error
                                  : (userProfile?.role.isMechanic == true
                                      ? StatusBadgeVariant.info
                                      : StatusBadgeVariant.success),
                              isSmall: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // Navigation Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: navigationItems.length,
                    itemBuilder: (context, index) {
                      final item = navigationItems[index];
                      final isSelected = index == selectedIndex;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Material(
                          color: isSelected
                              ? AppColors.racingRed.withValues(alpha: isDark ? 0.2 : 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            onTap: () => _handleNavigation(context, item.route),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm + 2,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? (item.selectedIcon ?? item.icon)
                                        : item.icon,
                                    size: 20,
                                    color: isSelected
                                        ? AppColors.racingRed
                                        : (isDark ? Colors.white70 : Colors.black54),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: AppTypography.bodyMedium(
                                        color: isSelected
                                            ? (isDark ? Colors.white : AppColors.racingRedDark)
                                            : (isDark ? Colors.white70 : Colors.black87),
                                      ).copyWith(
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (item.badge != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.racingRed,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        item.badge!,
                                        style: AppTypography.label(color: Colors.white).copyWith(
                                          fontSize: 10,
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

                const Divider(height: 1, thickness: 1),

                // Theme Switch Footer
                Padding(
                  padding: AppSpacing.paddingMd,
                  child: Row(
                    children: [
                      Icon(
                        themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                        size: 20,
                        color: AppColors.neutral,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          themeMode == ThemeMode.dark ? 'Dark Theme' : 'Light Theme',
                          style: AppTypography.bodySmall(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Toggle Theme Mode',
                        icon: const Icon(Icons.brightness_medium, size: 20),
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Desktop Content Area
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(title, style: AppTypography.headingSmall()),
                actions: actions,
                elevation: 0,
              ),
              body: body,
              floatingActionButton: floatingActionButton,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TABLET LAYOUT (600 <= width < 1024)
  // ==========================================
  Widget _buildTabletLayout(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = _findSelectedIndex(navigationItems);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              _handleNavigation(context, navigationItems[index].route);
            },
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            selectedIconTheme: const IconThemeData(color: AppColors.racingRed),
            selectedLabelTextStyle: AppTypography.label(color: AppColors.racingRed),
            unselectedIconTheme: IconThemeData(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            unselectedLabelTextStyle: AppTypography.label(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            labelType: NavigationRailLabelType.selected,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Container(
                padding: AppSpacing.paddingXs,
                decoration: BoxDecoration(
                  color: AppColors.racingRed,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.speed, color: Colors.white, size: 24),
              ),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: IconButton(
                tooltip: 'Toggle Theme',
                icon: const Icon(Icons.brightness_medium),
                onPressed: () {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              ),
            ),
            destinations: navigationItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon ?? item.icon),
                label: Text(item.label),
              );
            }).toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(title, style: AppTypography.headingSmall()),
                actions: actions,
                elevation: 0,
              ),
              body: body,
              floatingActionButton: floatingActionButton,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MOBILE LAYOUT (width < 600)
  // ==========================================
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    final activeMobileItems = mobileNavigationItems ??
        (navigationItems.length > 5 ? navigationItems.sublist(0, 5) : navigationItems);

    final selectedIndex = _findSelectedIndex(activeMobileItems);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppTypography.headingSmall()),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: const Icon(Icons.brightness_medium, size: 20),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          ...?actions,
        ],
        elevation: 0,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          _handleNavigation(context, activeMobileItems[index].route);
        },
        destinations: activeMobileItems.map((item) {
          return NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon ?? item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}
