import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Primary call-to-action button adhering to PitMate racing red design specs.
class PitPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final double height;

  const PitPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    Widget child;
    if (isLoading) {
      child = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              text,
              style: AppTypography.label(color: Colors.white),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    } else {
      child = Text(
        text,
        style: AppTypography.label(color: Colors.white),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }

    Widget button = ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.racingRed,
        disabledBackgroundColor: AppColors.racingRed.withValues(alpha: 0.4),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white70,
        minimumSize: Size(fullWidth ? double.infinity : 88.0, height),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        elevation: isEnabled ? 2 : 0,
      ),
      child: child,
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, height: height, child: button);
    }

    return SizedBox(height: height, child: button);
  }
}
