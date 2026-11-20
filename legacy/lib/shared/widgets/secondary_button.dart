import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Secondary action button adhering to DESIGN.md section 11.2.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.width,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final bg = isDark ? AppColors.surfaceSecondary : AppColors.lightSurfaceSecondary;
    final border = isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;
    final iconColor = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    final button = SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          backgroundColor: bg,
          side: BorderSide(color: border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: AppSpacing.compact),
            ],
            Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );

    if (width != null) {
      return SizedBox(
        width: width,
        child: button,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.hasBoundedWidth) {
          return SizedBox(
            width: double.infinity,
            child: button,
          );
        }
        return button;
      },
    );
  }
}
