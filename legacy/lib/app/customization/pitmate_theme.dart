import 'package:flutter/material.dart';

import 'pitmate_layout.dart';
import 'pitmate_palette.dart';
import 'pitmate_typography.dart';

/// PitMate Canonical Theme Builder adhering strictly to DESIGN.md and CUSTOMIZATION.md.
///
/// Builds complete ThemeData for both Dark and Light modes.
abstract class PitmateTheme {
  /// Dark Theme (Default motorsport-inspired dark UI)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PitmatePalette.darkBackgroundPrimary,
      cardColor: PitmatePalette.darkSurfacePrimary,
      colorScheme: const ColorScheme.dark(
        primary: PitmatePalette.primaryAccent,
        primaryContainer: PitmatePalette.primaryAccentDark,
        secondary: PitmatePalette.darkSurfaceElevated,
        surface: PitmatePalette.darkSurfacePrimary,
        error: PitmatePalette.error,
        onPrimary: Colors.white,
        onSecondary: PitmatePalette.darkTextPrimary,
        onSurface: PitmatePalette.darkTextPrimary,
        onError: Colors.white,
        outline: PitmatePalette.darkBorderSubtle,
      ),
      textTheme: PitmateTypography.darkTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: PitmatePalette.darkSurfacePrimary,
        foregroundColor: PitmatePalette.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: PitmateTypography.sectionTitle(
          color: PitmatePalette.darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: PitmatePalette.darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: PitmatePalette.darkSurfacePrimary,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PitmateLayout.radiusCard),
          side: const BorderSide(
            color: PitmatePalette.darkBorderSubtle,
            width: 1,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: PitmatePalette.darkSurfacePrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PitmateLayout.radiusModal),
          side: const BorderSide(
            color: PitmatePalette.darkBorderSubtle,
            width: 1,
          ),
        ),
        titleTextStyle: PitmateTypography.sectionTitle(
          color: PitmatePalette.darkTextPrimary,
        ),
        contentTextStyle: PitmateTypography.bodyMedium(
          color: PitmatePalette.darkTextSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PitmatePalette.primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, PitmateLayout.defaultControlHeight),
          padding: PitmateLayout.paddingButton,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PitmateLayout.radiusControl),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PitmatePalette.darkTextPrimary,
          minimumSize: const Size(0, PitmateLayout.defaultControlHeight),
          padding: PitmateLayout.paddingButton,
          side: const BorderSide(
            color: PitmatePalette.darkBorderSubtle,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PitmateLayout.radiusControl),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PitmatePalette.darkSurfacePrimary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PitmateLayout.radiusInput),
          borderSide: const BorderSide(
            color: PitmatePalette.darkBorderSubtle,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PitmateLayout.radiusInput),
          borderSide: const BorderSide(
            color: PitmatePalette.darkBorderSubtle,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PitmateLayout.radiusInput),
          borderSide: const BorderSide(
            color: PitmatePalette.primaryAccent,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PitmateLayout.radiusInput),
          borderSide: const BorderSide(color: PitmatePalette.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PitmateLayout.radiusInput),
          borderSide: const BorderSide(color: PitmatePalette.error, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: PitmatePalette.darkTextSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: PitmatePalette.darkTextMuted,
          fontSize: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: PitmatePalette.darkBorderSubtle,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: PitmatePalette.darkSurfacePrimary,
        selectedItemColor: PitmatePalette.primaryAccent,
        unselectedItemColor: PitmatePalette.darkTextMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  /// Light Theme (Motorsport-clean technical light UI)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: PitmatePalette.lightBackgroundPrimary,
      cardColor: PitmatePalette.lightSurfacePrimary,
      colorScheme: const ColorScheme.light(
        primary: PitmatePalette.primaryAccent,
        primaryContainer: PitmatePalette.primaryAccentLight,
        secondary: PitmatePalette.lightSurfaceSecondary,
        surface: PitmatePalette.lightSurfacePrimary,
        error: PitmatePalette.error,
        onPrimary: Colors.white,
        onSecondary: PitmatePalette.lightTextPrimary,
        onSurface: PitmatePalette.lightTextPrimary,
        onError: Colors.white,
        outline: PitmatePalette.lightBorderSubtle,
      ),
      textTheme: PitmateTypography.lightTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: PitmatePalette.lightSurfacePrimary,
        foregroundColor: PitmatePalette.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: PitmatePalette.lightTextPrimary,
        ),
        iconTheme: IconThemeData(color: PitmatePalette.lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: PitmatePalette.lightSurfacePrimary,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PitmateLayout.radiusCard),
          side: const BorderSide(
            color: PitmatePalette.lightBorderSubtle,
            width: 1,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: PitmatePalette.lightSurfacePrimary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PitmateLayout.radiusModal),
          side: const BorderSide(
            color: PitmatePalette.lightBorderSubtle,
            width: 1,
          ),
        ),
        titleTextStyle: PitmateTypography.sectionTitle(
          color: PitmatePalette.lightTextPrimary,
        ),
        contentTextStyle: PitmateTypography.bodyMedium(
          color: PitmatePalette.lightTextSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PitmatePalette.primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, PitmateLayout.defaultControlHeight),
          padding: PitmateLayout.paddingButton,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PitmateLayout.radiusControl),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PitmatePalette.lightTextPrimary,
          minimumSize: const Size(0, PitmateLayout.defaultControlHeight),
          padding: PitmateLayout.paddingButton,
          side: const BorderSide(
            color: PitmatePalette.lightBorderSubtle,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PitmateLayout.radiusControl),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PitmatePalette.lightSurfacePrimary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PitmateLayout.radiusInput),
          borderSide: const BorderSide(
            color: PitmatePalette.lightBorderSubtle,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PitmateLayout.radiusInput),
          borderSide: const BorderSide(
            color: PitmatePalette.lightBorderSubtle,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PitmateLayout.radiusInput),
          borderSide: const BorderSide(
            color: PitmatePalette.primaryAccent,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PitmateLayout.radiusInput),
          borderSide: const BorderSide(color: PitmatePalette.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PitmateLayout.radiusInput),
          borderSide: const BorderSide(color: PitmatePalette.error, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: PitmatePalette.lightTextSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: PitmatePalette.lightTextMuted,
          fontSize: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: PitmatePalette.lightBorderSubtle,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: PitmatePalette.lightSurfacePrimary,
        selectedItemColor: PitmatePalette.primaryAccent,
        unselectedItemColor: PitmatePalette.lightTextMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),
    );
  }

  static ThemeData get customerLightTheme => lightTheme;
}
