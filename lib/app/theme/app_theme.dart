import 'package:flutter/material.dart';

import '../customization/pitmate_theme.dart';

/// MaterialApp theme configuration adhering strictly to DESIGN.md and CUSTOMIZATION.md.
///
/// Implements PitMate's visual system, delegating to canonical [PitmateTheme].
abstract class AppTheme {
  static ThemeData get darkTheme => PitmateTheme.darkTheme;
  static ThemeData get lightTheme => PitmateTheme.lightTheme;
  static ThemeData get customerLightTheme => PitmateTheme.lightTheme;
}

