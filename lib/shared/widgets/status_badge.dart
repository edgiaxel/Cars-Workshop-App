import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Semantic variants supported by [StatusBadge].
enum StatusBadgeVariant {
  success,
  warning,
  error,
  info,
  neutral;

  Color get color {
    return switch (this) {
      StatusBadgeVariant.success => AppColors.success,
      StatusBadgeVariant.warning => AppColors.warning,
      StatusBadgeVariant.error => AppColors.error,
      StatusBadgeVariant.info => AppColors.info,
      StatusBadgeVariant.neutral => AppColors.neutral,
    };
  }

  IconData get defaultIcon {
    return switch (this) {
      StatusBadgeVariant.success => Icons.check_circle_outline,
      StatusBadgeVariant.warning => Icons.warning_amber_rounded,
      StatusBadgeVariant.error => Icons.error_outline,
      StatusBadgeVariant.info => Icons.info_outline,
      StatusBadgeVariant.neutral => Icons.remove_circle_outline,
    };
  }
}

/// Compact semantic status badge displaying colored chips with icons/dots.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeVariant variant;
  final IconData? icon;
  final bool showDot;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = StatusBadgeVariant.neutral,
    this.icon,
    this.showDot = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = variant.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = color.withValues(alpha: isDark ? 0.18 : 0.12);
    final borderColor = color.withValues(alpha: isDark ? 0.4 : 0.3);

    final resolvedIcon = icon ?? (showDot ? null : variant.defaultIcon);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSpacing.xs + 2 : AppSpacing.sm,
        vertical: isSmall ? 2.0 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: isSmall ? 6 : 8,
              height: isSmall ? 6 : 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: isSmall ? 4 : AppSpacing.xs),
          ] else if (resolvedIcon != null) ...[
            Icon(resolvedIcon, size: isSmall ? 12 : 14, color: color),
            SizedBox(width: isSmall ? 4 : AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTypography.label(color: color).copyWith(
                fontSize: isSmall ? 10 : 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
