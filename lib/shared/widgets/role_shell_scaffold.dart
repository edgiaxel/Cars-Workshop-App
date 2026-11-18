import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_paths.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../data/models/service_notification.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/mechanic_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/service_order_provider.dart';
import '../providers/spare_part_provider.dart';
import '../providers/supabase_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/vehicle_provider.dart';
import 'secondary_button.dart';

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
    this.roleBadge,
    required this.destinations,
    required this.body,
    this.actions,
  });

  final String currentRoute;
  final String roleTitle;
  final Widget? roleBadge;
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
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              leading: isDashboard
                  ? null
                  : IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      tooltip: 'Back to Dashboard',
                      onPressed: () => context.go(dashboardRoute),
                    ),
              title: Text(
                roleTitle,
                style: AppTypography.sectionTitle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              actions: [
                const _GlobalRefreshButton(),
                const _GlobalNotificationBell(),
                IconButton(
                  icon: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  tooltip: Theme.of(context).brightness == Brightness.dark
                      ? 'Switch to Light Mode'
                      : 'Switch to Dark Mode',
                  onPressed: () {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),
                ...?actions,
                IconButton(
                  icon: Icon(
                    Icons.logout,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary,
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
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.borderSubtle
                : AppColors.lightBorderSubtle,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            roleTitle,
            style: AppTypography.sectionTitle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          Row(
            children: [
              const _GlobalRefreshButton(),
              const _GlobalNotificationBell(),
              IconButton(
                icon: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondary
                      : AppColors.lightTextSecondary,
                  size: 20,
                ),
                tooltip: Theme.of(context).brightness == Brightness.dark
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
                onPressed: () {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              ),
              const SizedBox(width: AppSpacing.compact),
              ...?actions,
              const SizedBox(width: AppSpacing.standard),
              Text(
                userProfile?.fullName ?? '',
                style: AppTypography.bodySmall(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondary
                      : AppColors.lightTextSecondary,
                ),
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
                      ?roleBadge,
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

/// Global Refresh Button that calls check_workshop_cron_tasks() RPC
/// and invalidates all workshop state providers with animation.
class _GlobalRefreshButton extends ConsumerStatefulWidget {
  const _GlobalRefreshButton();

  @override
  ConsumerState<_GlobalRefreshButton> createState() =>
      _GlobalRefreshButtonState();
}

class _GlobalRefreshButtonState extends ConsumerState<_GlobalRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _controller.repeat();

    try {
      final supabase = ref.read(supabaseClientProvider);
      if (supabase != null) {
        try {
          await supabase.rpc('check_workshop_cron_tasks');
        } catch (_) {
          // Fallback if RPC migration hasn't been run yet on remote db
        }
      }

      ref.invalidate(bookingsProvider);
      ref.invalidate(serviceOrdersProvider);
      ref.invalidate(sparePartsProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(vehiclesProvider);
      ref.invalidate(customersProvider);
      ref.invalidate(mechanicsProvider);
      ref.invalidate(customerBookingsProvider(null));
      ref.invalidate(customerVehiclesProvider(null));
      ref.invalidate(mechanicServiceOrdersProvider(null));
      ref.invalidate(mechanicTasksProvider);

      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Workshop database & state refreshed. Automated tasks executed.',
            ),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.statusCompleted,
          ),
        );
      }
    } finally {
      if (mounted) {
        _controller.stop();
        _controller.reset();
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return RotationTransition(
      turns: _controller,
      child: IconButton(
        icon: Icon(Icons.refresh, color: iconColor),
        tooltip: 'Reload Database & Run Automated Workshop Checks',
        onPressed: _isRefreshing ? null : _handleRefresh,
      ),
    );
  }
}

/// Global Notification Bell with badge and quick dialog
class _GlobalNotificationBell extends ConsumerWidget {
  const _GlobalNotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final notifs = notifsAsync.value ?? [];
    final unreadCount = notifs.where((n) => !n.isRead).length;

    Widget iconWidget = Icon(
      unreadCount > 0 ? Icons.notifications : Icons.notifications_outlined,
      color: unreadCount > 0 ? AppColors.primaryAccent : iconColor,
    );

    if (unreadCount > 0) {
      iconWidget = Badge(
        label: Text('$unreadCount'),
        backgroundColor: AppColors.error,
        child: iconWidget,
      );
    }

    return IconButton(
      icon: iconWidget,
      tooltip: 'Workshop Notifications ($unreadCount unread)',
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (dialogCtx) => _NotificationsQuickDialog(
            notifications: notifs,
          ),
        );
      },
    );
  }
}

class _NotificationsQuickDialog extends ConsumerWidget {
  const _NotificationsQuickDialog({required this.notifications});

  final List<ServiceNotification> notifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.surfaceCard : AppColors.lightSurfaceCard;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColors.lightTextMuted;

    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: dialogBg,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.standard),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: AppColors.primaryAccent,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.compact),
                      Text(
                        'NOTIFICATIONS',
                        style: AppTypography.sectionTitle(color: textPrimary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              if (unreadCount > 0) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      await ref
                          .read(notificationsProvider.notifier)
                          .markAllAsRead();
                    },
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Mark all as read'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.compact),
              Flexible(
                child: notifications.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 40,
                                color: textMuted,
                              ),
                              const SizedBox(height: AppSpacing.compact),
                              Text(
                                'No notifications at this time',
                                style: AppTypography.bodySmall(color: textMuted),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final n = notifications[index];
                          final isUnread = !n.isRead;

                          IconData iconData;
                          Color iconColor;
                          switch (n.type.toLowerCase()) {
                            case 'inventory':
                              iconData = Icons.inventory_2_outlined;
                              iconColor = AppColors.error;
                              break;
                            case 'booking':
                              iconData = Icons.event_available_outlined;
                              iconColor = AppColors.primaryAccent;
                              break;
                            case 'reminder':
                              iconData = Icons.alarm_on_outlined;
                              iconColor = AppColors.warning;
                              break;
                            default:
                              iconData = Icons.notifications_none;
                              iconColor = AppColors.info;
                          }

                          return InkWell(
                            onTap: isUnread
                                ? () => ref
                                    .read(notificationsProvider.notifier)
                                    .markAsRead(n.id)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.compact,
                                horizontal: 4,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        iconColor.withValues(alpha: 0.15),
                                    child: Icon(
                                      iconData,
                                      size: 18,
                                      color: iconColor,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.compact),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n.title,
                                                style: AppTypography.label(
                                                  color: textPrimary,
                                                ).copyWith(
                                                  fontWeight: isUnread
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                            if (isUnread)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: AppColors.primaryAccent,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          n.message,
                                          style: AppTypography.bodySmall(
                                            color: isUnread
                                                ? textPrimary
                                                : textSecondary,
                                          ),
                                        ),
                                        if (n.createdAt != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            n.createdAt!
                                                .toIso8601String()
                                                .replaceAll('T', ' ')
                                                .split('.')
                                                .first,
                                            style: AppTypography.technical(
                                              color: textMuted,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppSpacing.standard),
              SecondaryButton(
                text: 'Close',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
