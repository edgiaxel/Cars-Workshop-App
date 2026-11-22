import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

enum StatusBadgeType {
  success,
  warning,
  inProgress,
  queued,
  danger,
  info,
  neutral,
}

/// Semantic motorsport status badge with 15% tint background and 1px crisp outline.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.neutral,
    this.icon,
    this.color,
    this.isMonospace = true,
  });

  final String label;
  final StatusBadgeType type;
  final IconData? icon;
  final Color? color;
  final bool isMonospace;

  factory StatusBadge.success(String label, {IconData? icon}) {
    return StatusBadge(label: label, type: StatusBadgeType.success, icon: icon);
  }

  factory StatusBadge.warning(String label, {IconData? icon}) {
    return StatusBadge(label: label, type: StatusBadgeType.warning, icon: icon);
  }

  factory StatusBadge.inProgress(String label, {IconData? icon}) {
    return StatusBadge(label: label, type: StatusBadgeType.inProgress, icon: icon);
  }

  factory StatusBadge.queued(String label, {IconData? icon}) {
    return StatusBadge(label: label, type: StatusBadgeType.queued, icon: icon);
  }

  factory StatusBadge.danger(String label, {IconData? icon}) {
    return StatusBadge(label: label, type: StatusBadgeType.danger, icon: icon);
  }

  factory StatusBadge.info(String label, {IconData? icon}) {
    return StatusBadge(label: label, type: StatusBadgeType.info, icon: icon);
  }

  Color _resolveColor(bool isDark) {
    if (color != null) return color!;
    switch (type) {
      case StatusBadgeType.success:
        return isDark ? AppColors.successDark : AppColors.success;
      case StatusBadgeType.warning:
        return isDark ? AppColors.warningDark : AppColors.warning;
      case StatusBadgeType.inProgress:
        return isDark ? AppColors.accentRed : AppColors.racingRed;
      case StatusBadgeType.queued:
      case StatusBadgeType.info:
        return isDark ? AppColors.infoDark : AppColors.info;
      case StatusBadgeType.danger:
        return isDark ? AppColors.dangerDark : AppColors.danger;
      case StatusBadgeType.neutral:
        return isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = _resolveColor(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.12),
        borderRadius: AppSpacing.roundedSmall,
        border: Border.all(color: baseColor.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.0, color: baseColor),
            const SizedBox(width: 4.0),
          ],
          Text(
            label.toUpperCase(),
            style: isMonospace
                ? AppTypography.telemetrySmall(color: baseColor, fontWeight: FontWeight.w700)
                : AppTypography.labelSmall(color: baseColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
