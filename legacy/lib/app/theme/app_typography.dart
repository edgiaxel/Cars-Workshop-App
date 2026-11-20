import 'package:flutter/material.dart';

import '../customization/pitmate_typography.dart';

/// Typography configuration adhering to DESIGN.md section 6 and CUSTOMIZATION.md.
///
/// Uses Inter for primary UI text and Space Grotesk for display/technical metrics.
/// Bridges directly to canonical [PitmateTypography].
abstract class AppTypography {
  // Display typography (Space Grotesk) - headings, large numbers, technical metrics
  static TextStyle displayLarge({Color? color}) =>
      PitmateTypography.displayLarge(color: color);

  static TextStyle pageTitle({Color? color}) =>
      PitmateTypography.pageTitle(color: color);

  static TextStyle sectionTitle({Color? color}) =>
      PitmateTypography.sectionTitle(color: color);

  // Primary UI typography (Inter) - body, forms, labels, buttons
  static TextStyle bodyLarge({Color? color}) =>
      PitmateTypography.bodyLarge(color: color);

  static TextStyle bodyMedium({Color? color}) =>
      PitmateTypography.bodyMedium(color: color);

  static TextStyle bodySmall({Color? color}) =>
      PitmateTypography.bodySmall(color: color);

  static TextStyle label({Color? color}) =>
      PitmateTypography.label(color: color);

  static TextStyle technical({Color? color}) =>
      PitmateTypography.technical(color: color);

  static TextStyle metricValue({
    double fontSize = 28,
    Color? color,
  }) =>
      PitmateTypography.metricValue(fontSize: fontSize, color: color);

  /// Full TextTheme configured for MaterialApp dark theme.
  static TextTheme get textTheme => PitmateTypography.darkTextTheme;

  /// Full TextTheme configured for MaterialApp light theme.
  static TextTheme get lightTextTheme => PitmateTypography.lightTextTheme;
}

