import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pitmate_palette.dart';

/// PitMate Canonical Typography configuration adhering strictly to DESIGN.md section 6 and CUSTOMIZATION.md.
///
/// Uses Inter for primary UI text and Space Grotesk for display/technical metrics.
/// When [color] is omitted, text style inherits the ambient theme text color,
/// ensuring high-contrast rendering across both light and dark modes.
abstract class PitmateTypography {
  // --- Space Grotesk (Display / Technical / Headings) ---
  static TextStyle displayLarge({Color? color}) {
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

  static TextStyle pageTitle({Color? color}) {
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

  static TextStyle sectionTitle({Color? color}) {
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

  static TextStyle metricValue({
    double fontSize = 28,
    Color? color,
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

  // --- Inter (Primary UI / Body / Labels / Form controls) ---
  static TextStyle bodyLarge({Color? color}) {
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

  static TextStyle bodyMedium({Color? color}) {
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

  static TextStyle bodySmall({Color? color}) {
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

  static TextStyle label({Color? color}) {
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

  static TextStyle technical({Color? color}) {
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

  /// Full TextTheme configured for Dark mode.
  static TextTheme get darkTextTheme {
    return TextTheme(
      displayLarge: displayLarge(color: PitmatePalette.darkTextPrimary),
      headlineMedium: pageTitle(color: PitmatePalette.darkTextPrimary),
      titleLarge: sectionTitle(color: PitmatePalette.darkTextPrimary),
      titleMedium: label(color: PitmatePalette.darkTextPrimary),
      bodyLarge: bodyLarge(color: PitmatePalette.darkTextPrimary),
      bodyMedium: bodyMedium(color: PitmatePalette.darkTextPrimary),
      bodySmall: bodySmall(color: PitmatePalette.darkTextSecondary),
      labelLarge: label(color: PitmatePalette.darkTextPrimary),
      labelSmall: technical(color: PitmatePalette.darkTextMuted),
    );
  }

  /// Full TextTheme configured for Light mode.
  static TextTheme get lightTextTheme {
    return TextTheme(
      displayLarge: displayLarge(color: PitmatePalette.lightTextPrimary),
      headlineMedium: pageTitle(color: PitmatePalette.lightTextPrimary),
      titleLarge: sectionTitle(color: PitmatePalette.lightTextPrimary),
      titleMedium: label(color: PitmatePalette.lightTextPrimary),
      bodyLarge: bodyLarge(color: PitmatePalette.lightTextPrimary),
      bodyMedium: bodyMedium(color: PitmatePalette.lightTextPrimary),
      bodySmall: bodySmall(color: PitmatePalette.lightTextSecondary),
      labelLarge: label(color: PitmatePalette.lightTextPrimary),
      labelSmall: technical(color: PitmatePalette.lightTextMuted),
    );
  }
}
