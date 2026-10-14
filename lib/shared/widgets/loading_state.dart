import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Loading state view adhering to ARCHITECTURE.md section 15 & DESIGN.md.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message = 'LOADING TELEMETRY...'});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.standard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryAccent,
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.standard),
              Text(
                message!.toUpperCase(),
                style: AppTypography.technical(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
