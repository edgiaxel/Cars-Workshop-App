import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Vector emblem and brand typography lockup for PitMate.
class PitMateLogo extends StatelessWidget {
  const PitMateLogo({
    super.key,
    this.compact = false,
    this.size = 28.0,
    this.textColor,
  });

  final bool compact;
  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveTextColor = textColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary);

    Widget emblem = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.racingRed,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: AppColors.racingRed.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.speed,
          color: Colors.white,
          size: size * 0.65,
        ),
      ),
    );

    if (compact) return emblem;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        emblem,
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PITMATE',
              style: AppTypography.headlineSmall(
                color: effectiveTextColor,
              ).copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                height: 1.0,
              ),
            ),
            Text(
              'WORKSHOP OS',
              style: AppTypography.telemetrySmall(
                color: isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight,
              ).copyWith(fontSize: 8.5, letterSpacing: 0.8),
            ),
          ],
        ),
      ],
    );
  }
}
