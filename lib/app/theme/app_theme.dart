import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Material 3 Themes for PitMate (Light & Dark).
class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.racingRed,
      onPrimary: Colors.white,
      primaryContainer: AppColors.accentRed,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.graphitePrimary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.surfaceElevatedLight,
      onSecondaryContainer: AppColors.textPrimaryLight,
      tertiary: AppColors.graphiteSecondary,
      onTertiary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF93000A),
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.borderStrongLight,
      shadow: Colors.black.withValues(alpha: 0.05),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      cardColor: AppColors.surfaceLight,
      dividerColor: AppColors.borderLight,
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge(color: AppColors.textPrimaryLight),
        displayMedium: AppTypography.displayMedium(color: AppColors.textPrimaryLight),
        headlineLarge: AppTypography.headlineLarge(color: AppColors.textPrimaryLight),
        headlineMedium: AppTypography.headlineMedium(color: AppColors.textPrimaryLight),
        headlineSmall: AppTypography.headlineSmall(color: AppColors.textPrimaryLight),
        titleLarge: AppTypography.headlineSmall(color: AppColors.textPrimaryLight),
        titleMedium: AppTypography.labelLarge(color: AppColors.textPrimaryLight),
        titleSmall: AppTypography.labelMedium(color: AppColors.textPrimaryLight),
        bodyLarge: AppTypography.bodyLarge(color: AppColors.textPrimaryLight),
        bodyMedium: AppTypography.bodyMedium(color: AppColors.textPrimaryLight),
        bodySmall: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
        labelLarge: AppTypography.labelLarge(color: AppColors.textPrimaryLight),
        labelMedium: AppTypography.labelMedium(color: AppColors.textSecondaryLight),
        labelSmall: AppTypography.labelSmall(color: AppColors.textMutedLight),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.graphitePrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.headlineSmall(color: AppColors.graphitePrimary),
        iconTheme: const IconThemeData(color: AppColors.graphitePrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedCard,
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentRed,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space12),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMedium),
          textStyle: GoogleFonts.barlowCondensed(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.graphitePrimary,
          side: const BorderSide(color: AppColors.borderLight, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space12),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMedium),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentRed,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12, vertical: AppSpacing.space8),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevatedLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space12),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMedium,
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMedium,
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMedium,
          borderSide: const BorderSide(color: AppColors.accentRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMedium,
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        hintStyle: AppTypography.bodyMedium(color: AppColors.textMutedLight),
        labelStyle: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.accentRed,
        unselectedItemColor: AppColors.textSecondaryLight,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.accentRed,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF5C0004),
      onPrimaryContainer: const Color(0xFFFFDAD6),
      secondary: const Color(0xFFBFC7D1),
      onSecondary: const Color(0xFF293138),
      secondaryContainer: AppColors.surfaceElevatedDark,
      onSecondaryContainer: AppColors.textPrimaryDark,
      tertiary: const Color(0xFF77DAA8),
      onTertiary: const Color(0xFF003823),
      error: AppColors.dangerDark,
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      outline: AppColors.borderDark,
      outlineVariant: AppColors.borderStrongDark,
      shadow: Colors.black.withValues(alpha: 0.3),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      cardColor: AppColors.surfaceDark,
      dividerColor: AppColors.borderDark,
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge(color: AppColors.textPrimaryDark),
        displayMedium: AppTypography.displayMedium(color: AppColors.textPrimaryDark),
        headlineLarge: AppTypography.headlineLarge(color: AppColors.textPrimaryDark),
        headlineMedium: AppTypography.headlineMedium(color: AppColors.textPrimaryDark),
        headlineSmall: AppTypography.headlineSmall(color: AppColors.textPrimaryDark),
        titleLarge: AppTypography.headlineSmall(color: AppColors.textPrimaryDark),
        titleMedium: AppTypography.labelLarge(color: AppColors.textPrimaryDark),
        titleSmall: AppTypography.labelMedium(color: AppColors.textPrimaryDark),
        bodyLarge: AppTypography.bodyLarge(color: AppColors.textPrimaryDark),
        bodyMedium: AppTypography.bodyMedium(color: AppColors.textPrimaryDark),
        bodySmall: AppTypography.bodySmall(color: AppColors.textSecondaryDark),
        labelLarge: AppTypography.labelLarge(color: AppColors.textPrimaryDark),
        labelMedium: AppTypography.labelMedium(color: AppColors.textSecondaryDark),
        labelSmall: AppTypography.labelSmall(color: AppColors.textMutedDark),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.headlineSmall(color: AppColors.textPrimaryDark),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedCard,
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentRed,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space12),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMedium),
          textStyle: GoogleFonts.barlowCondensed(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          side: const BorderSide(color: AppColors.borderDark, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space12),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMedium),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentRed,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12, vertical: AppSpacing.space8),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevatedDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space12),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMedium,
          borderSide: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMedium,
          borderSide: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMedium,
          borderSide: const BorderSide(color: AppColors.accentRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMedium,
          borderSide: const BorderSide(color: AppColors.dangerDark, width: 1),
        ),
        hintStyle: AppTypography.bodyMedium(color: AppColors.textMutedDark),
        labelStyle: AppTypography.bodyMedium(color: AppColors.textSecondaryDark),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.accentRed,
        unselectedItemColor: AppColors.textSecondaryDark,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
