import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';

void main() {
  group('Design Tokens verification against DESIGN.md', () {
    test('Motorsport dark base palette colors', () {
      expect(AppColors.backgroundPrimary, const Color(0xFF0B0D10));
      expect(AppColors.backgroundSecondary, const Color(0xFF11151A));
      expect(AppColors.surfacePrimary, const Color(0xFF171C22));
      expect(AppColors.surfaceSecondary, const Color(0xFF1E252D));
      expect(AppColors.surfaceElevated, const Color(0xFF252D36));
      expect(AppColors.primaryAccent, const Color(0xFFE10600));
    });

    test('Status color tokens', () {
      expect(AppColors.warning, const Color(0xFFF59E0B));
      expect(AppColors.statusWaitingApproval, AppColors.warning);
      expect(AppColors.statusInProgress, AppColors.primaryAccent);
      expect(AppColors.statusCompleted, AppColors.success);
      expect(AppColors.error, const Color(0xFFEF4444));
    });

    test('Spacing tokens match DESIGN.md 4px scale', () {
      expect(AppSpacing.micro, 4.0);
      expect(AppSpacing.compact, 8.0);
      expect(AppSpacing.small, 12.0);
      expect(AppSpacing.standard, 16.0);
      expect(AppSpacing.medium, 20.0);
      expect(AppSpacing.section, 24.0);
      expect(AppSpacing.large, 32.0);
      expect(AppSpacing.major, 40.0);
      expect(AppSpacing.page, 48.0);
    });

    test('Radius tokens match DESIGN.md section 8', () {
      expect(AppRadius.control, 8.0);
      expect(AppRadius.input, 10.0);
      expect(AppRadius.card, 12.0);
      expect(AppRadius.cardLarge, 16.0);
      expect(AppRadius.pill, 24.0);
    });
  });
}
