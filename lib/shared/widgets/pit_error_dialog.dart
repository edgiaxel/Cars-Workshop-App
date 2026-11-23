import 'package:flutter/material.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_typography.dart';

/// In-app error and validation dialog providing clear, human-legible feedback
/// instead of raw database exception text.
Future<void> showPitErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? hint,
  String primaryButtonText = 'UNDERSTOOD',
  VoidCallback? onPrimaryPressed,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;
  final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.steelMuted;
  final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.accentRed.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.accentRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: AppTypography.headingSmall(
                color: AppColors.accentRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A1515) : const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(8),
                border: BorderSide(color: AppColors.accentRed.withValues(alpha: 0.3)),
              ),
              child: Text(
                message,
                style: AppTypography.bodyMedium(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (hint != null && hint.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.accentBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hint,
                      style: AppTypography.bodySmall(
                        color: subtextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: () {
            Navigator.pop(ctx);
            if (onPrimaryPressed != null) onPrimaryPressed();
          },
          child: Text(
            primaryButtonText,
            style: AppTypography.labelLarge(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

/// In-form validation banner for clear visual error status.
class PitValidationBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const PitValidationBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: BorderSide(color: AppColors.accentRed.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 20, color: AppColors.accentRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall(
                color: AppColors.accentRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, size: 16, color: AppColors.accentRed),
            ),
        ],
      ),
    );
  }
}
