import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Modular card panel adhering to DESIGN.md sections 8, 9, and 10.
class PitCard extends StatelessWidget {
  const PitCard({
    super.key,
    required this.child,
    this.technicalLabel,
    this.padding = AppSpacing.paddingStandard,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final String? technicalLabel;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBg = backgroundColor ??
        (isDark ? AppColors.surfacePrimary : AppColors.lightSurfacePrimary);
    final effectiveBorder = borderColor ??
        (isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle);
    final technicalColor =
        isDark ? AppColors.textMuted : AppColors.lightTextSecondary;

    Widget cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: effectiveBorder, width: 1),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (technicalLabel != null) ...[
              Text(
                technicalLabel!.toUpperCase(),
                style: AppTypography.technical(color: technicalColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.compact),
            ],
            child,
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: cardContent,
      );
    }

    return cardContent;
  }
}
