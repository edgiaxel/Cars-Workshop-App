import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography definitions for PitMate:
/// - Headers: Barlow Condensed or Space Grotesk
/// - Body: Inter
/// - Telemetry/Monospace: JetBrains Mono
class AppTypography {
  const AppTypography._();

  // Headers (Barlow Condensed / Space Grotesk)
  static TextStyle displayLarge({Color? color}) => GoogleFonts.barlowCondensed(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: 0.5,
        color: color,
      );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.barlowCondensed(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: 0.25,
        color: color,
      );

  static TextStyle headlineLarge({Color? color}) => GoogleFonts.barlowCondensed(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.15,
        letterSpacing: 0.25,
        color: color,
      );

  static TextStyle headlineMedium({Color? color}) => GoogleFonts.barlowCondensed(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.2,
        color: color,
      );

  static TextStyle headlineSmall({Color? color}) => GoogleFonts.barlowCondensed(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.15,
        color: color,
      );

  // Alternative header: Space Grotesk
  static TextStyle spaceGroteskHeader({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  // Body text (Inter)
  static TextStyle bodyLarge({Color? color, FontWeight fontWeight = FontWeight.w400}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: fontWeight,
        height: 1.5,
        color: color,
      );

  static TextStyle bodyMedium({Color? color, FontWeight fontWeight = FontWeight.w400}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: fontWeight,
        height: 1.4,
        color: color,
      );

  static TextStyle bodySmall({Color? color, FontWeight fontWeight = FontWeight.w400}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: fontWeight,
        height: 1.35,
        color: color,
      );

  // Labels & UI controls (Inter)
  static TextStyle labelLarge({Color? color, FontWeight fontWeight = FontWeight.w600}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: fontWeight,
        letterSpacing: 0.2,
        color: color,
      );

  static TextStyle labelMedium({Color? color, FontWeight fontWeight = FontWeight.w600}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: fontWeight,
        letterSpacing: 0.3,
        color: color,
      );

  static TextStyle labelSmall({Color? color, FontWeight fontWeight = FontWeight.w600}) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: fontWeight,
        letterSpacing: 0.4,
        color: color,
      );

  // Telemetry & Diagnostic strings (JetBrains Mono)
  static TextStyle telemetryLarge({Color? color, FontWeight fontWeight = FontWeight.w600}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 16,
        fontWeight: fontWeight,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle telemetryMedium({Color? color, FontWeight fontWeight = FontWeight.w500}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: fontWeight,
        letterSpacing: -0.1,
        color: color,
      );

  static TextStyle telemetrySmall({Color? color, FontWeight fontWeight = FontWeight.w500}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: fontWeight,
        letterSpacing: 0.0,
        color: color,
      );
}
