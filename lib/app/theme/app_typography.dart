import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography configuration adhering to DESIGN.md section 6.
///
/// Uses Inter for primary UI text and Space Grotesk for display/technical metrics.
/// Provides safe fallback styling for offline scenarios.
abstract class AppTypography {
  // Display typography (Space Grotesk) - headings, large numbers, technical metrics
  static TextStyle displayLarge({Color color = AppColors.textPrimary}) {
    try {
      return GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: -0.5,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: -0.5,
      );
    }
  }

  static TextStyle pageTitle({Color color = AppColors.textPrimary}) {
    try {
      return GoogleFonts.spaceGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: -0.3,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: -0.3,
      );
    }
  }

  static TextStyle sectionTitle({Color color = AppColors.textPrimary}) {
    try {
      return GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.2,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.2,
      );
    }
  }

  // Primary UI typography (Inter) - body, forms, labels, buttons
  static TextStyle bodyLarge({Color color = AppColors.textPrimary}) {
    try {
      return GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: color,
        height: 1.5,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: color,
        height: 1.5,
      );
    }
  }

  static TextStyle bodyMedium({Color color = AppColors.textPrimary}) {
    try {
      return GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: color,
        height: 1.4,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: color,
        height: 1.4,
      );
    }
  }

  static TextStyle bodySmall({Color color = AppColors.textSecondary}) {
    try {
      return GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: color,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: color,
      );
    }
  }

  static TextStyle label({Color color = AppColors.textPrimary}) {
    try {
      return GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      );
    }
  }

  static TextStyle technical({Color color = AppColors.textMuted}) {
    try {
      return GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.8,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.8,
      );
    }
  }

  static TextStyle metricValue({
    double fontSize = 28,
    Color color = AppColors.textPrimary,
  }) {
    try {
      return GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
      );
    }
  }

  /// Full TextTheme configured for MaterialApp dark theme.
  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: displayLarge(),
      headlineMedium: pageTitle(),
      titleLarge: sectionTitle(),
      titleMedium: label(),
      bodyLarge: bodyLarge(),
      bodyMedium: bodyMedium(),
      bodySmall: bodySmall(),
      labelLarge: label(),
      labelSmall: technical(),
    );
  }
}
