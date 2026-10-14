import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import 'pit_card.dart';

/// Telemetry metric card adhering to DESIGN.md sections 9 & 15.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.technicalCode,
    this.subtitle,
    this.icon,
    this.badgeText,
    this.badgeColor,
    this.accentColor = AppColors.primaryAccent,
    this.onTap,
  });

  final String title;
  final String value;
  final String? technicalCode;
  final String? subtitle;
  final IconData? icon;
  final String? badgeText;
  final Color? badgeColor;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PitCard(
      technicalLabel: technicalCode,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: AppTypography.technical(color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: AppSpacing.compact),
                Icon(icon, size: 18, color: accentColor),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.compact,
            runSpacing: 4,
            children: [
              Text(
                value,
                style: AppTypography.metricValue(
                  fontSize: 24,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? accentColor).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    border: Border.all(
                      color: (badgeColor ?? accentColor).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    badgeText!,
                    style: AppTypography.technical(
                      color: badgeColor ?? accentColor,
                    ).copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.micro),
            Text(
              subtitle!,
              style: AppTypography.bodySmall(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
