import 'package:flutter/material.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'pitmate_logo.dart';

/// Navigation destination item for role scaffolds.
class RoleNavItem {
  const RoleNavItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.path,
    this.badge,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String? path;
  final String? badge;
}

/// Adaptive layout scaffold for PitMate roles.
/// - Desktop/Tablet (width >= 900px): Persistent sidebar navigation + top status bar + content area.
/// - Mobile (width < 900px): Top header with PitMate vector emblem & user avatar + bottom nav + content.
class ResponsiveRoleScaffold extends StatelessWidget {
  const ResponsiveRoleScaffold({
    super.key,
    required this.roleTitle,
    required this.body,
    required this.navItems,
    this.currentIndex = 0,
    this.onNavIndexChanged,
    this.userName = 'Marcus T.',
    this.userSubtitle = 'Workshop Admin',
    this.actions,
    this.floatingActionButton,
    this.telemetryNotice,
    this.onBack,
    this.showBackButton,
    this.onLogout,
  });

  final String roleTitle;
  final Widget body;
  final List<RoleNavItem> navItems;
  final int currentIndex;
  final ValueChanged<int>? onNavIndexChanged;
  final String userName;
  final String userSubtitle;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final String? telemetryNotice;
  final VoidCallback? onBack;
  final bool? showBackButton;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppSpacing.mobileBreakpoint;
        if (isDesktop) {
          return _buildDesktopLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          // Persistent Sidebar
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(right: BorderSide(color: borderColor, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PitMateLogo(),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed.withValues(alpha: 0.12),
                          borderRadius: AppSpacing.roundedSmall,
                          border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          roleTitle.toUpperCase(),
                          style: AppTypography.telemetrySmall(
                            color: AppColors.accentRed,
                            fontWeight: FontWeight.w700,
                          ).copyWith(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 12),

                // Nav Items
                Expanded(
                  child: ListView.builder(
                    itemCount: navItems.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final item = navItems[index];
                      final isSelected = index == currentIndex;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: isSelected
                              ? (isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight)
                              : Colors.transparent,
                          borderRadius: AppSpacing.roundedMedium,
                          child: InkWell(
                            borderRadius: AppSpacing.roundedMedium,
                            onTap: () => onNavIndexChanged?.call(index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(
                                borderRadius: AppSpacing.roundedMedium,
                                border: isSelected
                                    ? const Border(
                                        left: BorderSide(color: AppColors.accentRed, width: 3),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
                                    size: 20,
                                    color: isSelected
                                        ? AppColors.accentRed
                                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: AppTypography.labelLarge(
                                        color: isSelected
                                            ? textColor
                                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (item.badge != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.accentRed,
                                        borderRadius: AppSpacing.roundedFull,
                                      ),
                                      child: Text(
                                        item.badge!,
                                        style: AppTypography.telemetrySmall(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ).copyWith(fontSize: 10),
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

                // User profile card in sidebar bottom
                const Divider(height: 1, thickness: 1),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.accentRed,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userName,
                              style: AppTypography.labelLarge(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              userSubtitle,
                              style: AppTypography.bodySmall(
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (onLogout != null)
                        IconButton(
                          key: const Key('scaffold_logout_button'),
                          icon: const Icon(Icons.logout, size: 18),
                          tooltip: 'Sign Out',
                          onPressed: onLogout,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content View with Top Telemetry Status Bar
          Expanded(
            child: Column(
              children: [
                // Top Status Bar
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                  ),
                  child: Row(
                    children: [
                      if (showBackButton == true || (showBackButton == null && onBack != null)) ...[
                        IconButton(
                          key: const Key('scaffold_back_button'),
                          icon: const Icon(Icons.arrow_back, size: 20),
                          tooltip: 'Back',
                          onPressed: onBack,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        roleTitle,
                        style: AppTypography.headlineMedium(color: textColor),
                      ),
                      if (telemetryNotice != null) ...[
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
                            borderRadius: AppSpacing.roundedSmall,
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                telemetryNotice!,
                                style: AppTypography.telemetrySmall(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      ...?actions,
                    ],
                  ),
                ),

                // Content
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    return Scaffold(
      floatingActionButton: floatingActionButton,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  if (showBackButton == true || (showBackButton == null && onBack != null)) ...[
                    IconButton(
                      key: const Key('mobile_scaffold_back_button'),
                      icon: const Icon(Icons.arrow_back, size: 20),
                      tooltip: 'Back',
                      onPressed: onBack,
                    ),
                    const SizedBox(width: 4),
                  ] else ...[
                    const PitMateLogo(compact: true),
                    const SizedBox(width: 10),
                    Container(
                      height: 16,
                      width: 1,
                      color: borderColor,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      roleTitle.toUpperCase(),
                      style: AppTypography.headlineSmall(color: textColor).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...?actions,
                  if (onLogout != null) ...[
                    IconButton(
                      key: const Key('mobile_scaffold_logout_button'),
                      icon: const Icon(Icons.logout, size: 20),
                      tooltip: 'Sign Out',
                      onPressed: onLogout,
                    ),
                  ],
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: AppColors.racingRed,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: body,
      bottomNavigationBar: navItems.isEmpty
          ? null
          : Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(top: BorderSide(color: borderColor, width: 1.0)),
              ),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: onNavIndexChanged,
                items: navItems.map((item) {
                  return BottomNavigationBarItem(
                    icon: item.badge != null
                        ? Badge(
                            label: Text(item.badge!),
                            backgroundColor: AppColors.accentRed,
                            child: Icon(item.icon),
                          )
                        : Icon(item.icon),
                    activeIcon: Icon(item.selectedIcon ?? item.icon),
                    label: item.label,
                  );
                }).toList(),
              ),
            ),
    );
  }
}
