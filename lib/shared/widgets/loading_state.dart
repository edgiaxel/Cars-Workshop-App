import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Motorsport-inspired loading state indicator using PitMate racing red.
class LoadingState extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingState({
    super.key,
    this.message,
    this.size = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.racingRed),
              ),
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                style: AppTypography.bodyMedium(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
