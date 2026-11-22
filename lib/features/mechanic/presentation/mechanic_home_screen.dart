import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/responsive_role_scaffold.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mechanic Home Screen matching screens/mechanic_home_my_work_2 prototype:
/// - Shift telemetry header (Bay indicator, shift hours)
/// - Compact workload metrics (Assigned, In Progress, On Hold, Passed QC)
/// - Current Active Job focal card (Honda Civic Type R FL5, K20C1, task checklist progress)
/// - Assigned jobs queue (BMW 320i F30 LCI, Subaru WRX STI)
class MechanicHomeScreen extends ConsumerStatefulWidget {
  const MechanicHomeScreen({super.key});

  @override
  ConsumerState<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

class _MechanicHomeScreenState extends ConsumerState<MechanicHomeScreen> {
  int _navIndex = 0;

  static const List<RoleNavItem> _mechanicNavItems = [
    RoleNavItem(
      label: 'My Work',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
    ),
    RoleNavItem(
      label: 'Tasks & Torques',
      icon: Icons.checklist_outlined,
      selectedIcon: Icons.checklist,
    ),
    RoleNavItem(
      label: 'Parts Reqs',
      icon: Icons.handyman_outlined,
      selectedIcon: Icons.handyman,
      badge: '1',
    ),
    RoleNavItem(
      label: 'Work History',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
    ),
    RoleNavItem(
      label: 'Profile',
      icon: Icons.account_circle_outlined,
      selectedIcon: Icons.account_circle,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.graphitePrimary;
    String mechanicName = 'Max Verstappen';
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final name = currentUser?.userMetadata?['full_name'] as String?;
      if (name != null && name.isNotEmpty) {
        mechanicName = name;
      }
    } catch (_) {}

    return ResponsiveRoleScaffold(
      roleTitle: 'Mechanic Telemetry',
      userName: mechanicName,
      userSubtitle: 'Lead Performance Tech',
      currentIndex: _navIndex,
      onNavIndexChanged: (i) => setState(() => _navIndex = i),
      navItems: _mechanicNavItems,
      telemetryNotice: 'BAY 02 TELEMETRY ONLINE',
      onLogout: () async {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (context.mounted) context.go(RoutePaths.login);
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, size: 22),
          onPressed: () {},
          tooltip: 'Notifications',
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Shift Telemetry Header
                _buildShiftTelemetryHeader(isDark, textColor),
                const SizedBox(height: 14),

                // 2. Workload Metrics (Assigned: 4, In Progress: 1, On Hold: 2, Passed QC: 1)
                _buildWorkloadMetrics(isDark, textColor),
                const SizedBox(height: 18),

                // 3. Current Active Job Focal Point Card
                _buildActiveJobCard(isDark, textColor),
                const SizedBox(height: 20),

                // 4. Assigned Jobs Queue
                _buildQueueSection(isDark, textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShiftTelemetryHeader(bool isDark, Color textColor) {
    return PitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GOOD MORNING, DIAN S.',
                style: AppTypography.headlineMedium(color: textColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceElevatedLight,
                  borderRadius: AppSpacing.roundedSmall,
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
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
                      'ACTIVE SHIFT',
                      style: AppTypography.telemetrySmall(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.precision_manufacturing,
                size: 16,
                color: AppColors.accentRed,
              ),
              const SizedBox(width: 4),
              Text(
                'Bay 02 • Hoist B',
                style: AppTypography.labelMedium(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '•',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Morning Shift (08:00 – 17:00)',
                style: AppTypography.bodySmall(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadMetrics(bool isDark, Color textColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 36) / 4;
        return Row(
          children: [
            _buildMetricCard(
              title: 'ASSIGNED',
              count: '4',
              subtext: 'TOTAL',
              color: textColor,
              width: cardWidth,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            _buildMetricCard(
              title: 'IN PROGRESS',
              count: '1',
              subtext: 'ACTIVE',
              color: AppColors.accentRed,
              accentLeft: AppColors.accentRed,
              width: cardWidth,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            _buildMetricCard(
              title: 'ON HOLD',
              count: '2',
              subtext: 'PARTS',
              color: AppColors.warning,
              width: cardWidth,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            _buildMetricCard(
              title: 'PASSED QC',
              count: '1',
              subtext: 'READY',
              color: AppColors.success,
              width: cardWidth,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required String subtext,
    required Color color,
    Color? accentLeft,
    required double width,
    required bool isDark,
  }) {
    return SizedBox(
      width: width,
      child: PitCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        accentBorderLeft: accentLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.telemetrySmall(
                color:
                    accentLeft ??
                    (isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight),
                fontWeight: FontWeight.w700,
              ).copyWith(fontSize: 9.5),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(count, style: AppTypography.headlineLarge(color: color)),
                Text(
                  subtext,
                  style: AppTypography.telemetrySmall(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ).copyWith(fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveJobCard(bool isDark, Color textColor) {
    return PitCard(
      accentBorderTop: AppColors.accentRed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  StatusBadge.inProgress('ACTIVE JOB', icon: Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(
                    'SO-2026-0143',
                    style: AppTypography.telemetryMedium(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceElevatedLight,
                  borderRadius: AppSpacing.roundedSmall,
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.accentRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Bay 02 • Hoist B',
                      style: AppTypography.telemetrySmall(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Vehicle Info Banner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceElevatedDark
                  : AppColors.surfaceElevatedLight,
              borderRadius: AppSpacing.roundedMedium,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_car,
                  color: AppColors.accentRed,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Honda Civic Type R (FL5)',
                        style: AppTypography.labelLarge(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.plateBackground,
                              borderRadius: AppSpacing.roundedSmall,
                              border: Border.all(
                                color: AppColors.borderStrongDark,
                              ),
                            ),
                            child: Text(
                              'B 9912 SPO',
                              style: AppTypography.telemetrySmall(
                                color: AppColors.plateText,
                                fontWeight: FontWeight.w700,
                              ).copyWith(fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '2.0L Turbo K20C1',
                            style: AppTypography.bodySmall(
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Procedure
          Text(
            'PROCEDURE',
            style: AppTypography.telemetrySmall(
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Brake Rotor & Pad Bedding + High-Temp Fluid Flush',
            style: AppTypography.bodyMedium(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // Driver Complaint Note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              borderRadius: AppSpacing.roundedSmall,
              border: const Border(
                left: BorderSide(color: AppColors.warning, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'DRIVER COMPLAINT',
                      style: AppTypography.telemetrySmall(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '“Customer reported slight pedal sponginess after 3 track laps at Sentul. Check caliper piston seals.”',
                  style: AppTypography.bodySmall(
                    color: textColor,
                    fontWeight: FontWeight.w400,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Verification Tasks Progress (3 of 5, 60%)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VERIFICATION TASKS',
                style: AppTypography.telemetrySmall(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '3 of 5 (60%)',
                style: AppTypography.telemetrySmall(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.60,
              minHeight: 6,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentRed),
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('OPEN ACTIVE JOB WORKSPACE'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.assignment_late, size: 16),
                  label: const Text('Report Finding'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.build_circle, size: 16),
                  label: const Text('Request Part'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueueSection(bool isDark, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ASSIGNED JOBS QUEUE',
              style: AppTypography.headlineSmall(color: textColor),
            ),
            Text(
              '3 Queued',
              style: AppTypography.telemetrySmall(
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Queued Job 1
        PitCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'SO-2026-0144',
                        style: AppTypography.telemetrySmall(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.plateBackground,
                          borderRadius: AppSpacing.roundedSmall,
                          border: Border.all(color: AppColors.borderStrongDark),
                        ),
                        child: Text(
                          'B 3021 RFS',
                          style: AppTypography.telemetrySmall(
                            color: AppColors.plateText,
                            fontWeight: FontWeight.w700,
                          ).copyWith(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  StatusBadge.warning('AWAITING AUTH', icon: Icons.pending),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'BMW 320i F30 LCI — Ignition Coil #3 Replacement',
                style: AppTypography.bodySmall(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Queued Job 2
        PitCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'SO-2026-0140',
                        style: AppTypography.telemetrySmall(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.plateBackground,
                          borderRadius: AppSpacing.roundedSmall,
                          border: Border.all(color: AppColors.borderStrongDark),
                        ),
                        child: Text(
                          'B 1555 ZT',
                          style: AppTypography.telemetrySmall(
                            color: AppColors.plateText,
                            fontWeight: FontWeight.w700,
                          ).copyWith(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  StatusBadge.success('QC READY', icon: Icons.check_circle),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Subaru WRX STI — Transmission Gear Oil Flush',
                style: AppTypography.bodySmall(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
