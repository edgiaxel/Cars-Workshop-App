import 'package:flutter/material.dart';

/// PitMate Canonical Palette adhering strictly to DESIGN.md section 4 and CUSTOMIZATION.md.
///
/// Features a motorsport-inspired visual foundation supporting both:
/// - Dark mode: Obsidian backgrounds, elevated slate surfaces, and racing red accent.
/// - Light mode: Technical off-white backgrounds, crisp white surfaces, slate borders, and deep graphite text.
abstract class PitmatePalette {
  // --- Dark Base Palette (DESIGN.md 4.1) ---
  static const Color darkBackgroundPrimary = Color(0xFF0B0D10);
  static const Color darkBackgroundSecondary = Color(0xFF11151A);
  static const Color darkSurfacePrimary = Color(0xFF171C22);
  static const Color darkSurfaceSecondary = Color(0xFF1E252D);
  static const Color darkSurfaceElevated = Color(0xFF252D36);
  static const Color darkBorderSubtle = Color(0xFF2D3742);

  static const Color darkTextPrimary = Color(0xFFF5F7FA);
  static const Color darkTextSecondary = Color(0xFFAAB4C0);
  static const Color darkTextMuted = Color(0xFF707B88);

  // --- Light Base Palette (DESIGN.md 4.4 Addendum 1) ---
  static const Color lightBackgroundPrimary = Color(0xFFF7F9FC);
  static const Color lightBackgroundSecondary = Color(0xFFEEF2F6);
  static const Color lightSurfacePrimary = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF1F5F9);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightBorderSubtle = Color(0xFFD8E0E8);

  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF1E293B);
  static const Color lightTextMuted = Color(0xFF64748B);

  // --- Brand & Accent Colors (DESIGN.md 4.2) ---
  static const Color primaryAccent = Color(0xFFE10600); // Motorsport Red
  static const Color primaryAccentLight = Color(0xFFFF3B30);
  static const Color primaryAccentDark = Color(0xFFA80000);

  // --- Semantic State Colors (DESIGN.md 4.3) ---
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color neutral = Color(0xFF64748B);

  // --- Service Status Colors (DESIGN.md section 5) ---
  static const Color statusRequested = info;
  static const Color statusApproved = info;
  static const Color statusScheduled = info;
  static const Color statusInspection = warning;
  static const Color statusDiagnosis = warning;
  static const Color statusWaitingApproval = warning;
  static const Color statusWaitingParts = warning;
  static const Color statusInProgress = primaryAccent;
  static const Color statusCompletionReview = info;
  static const Color statusCompleted = success;
  static const Color statusPayment = success;
  static const Color statusClosed = neutral;
  static const Color statusCancelled = error;

  // --- Task Status Colors ---
  static const Color taskPending = neutral;
  static const Color taskInProgress = primaryAccent;
  static const Color taskCompleted = success;
  static const Color taskBlocked = warning;
  static const Color taskCancelled = error;

  // --- Context-Aware Resolvers for Theme Adaptability ---
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? darkBackgroundPrimary : lightBackgroundPrimary;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurfacePrimary : lightSurfacePrimary;

  static Color surfaceSecondary(BuildContext context) =>
      isDark(context) ? darkSurfaceSecondary : lightSurfaceSecondary;

  static Color surfaceElevated(BuildContext context) =>
      isDark(context) ? darkSurfaceElevated : lightSurfaceElevated;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorderSubtle : lightBorderSubtle;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? darkTextMuted : lightTextMuted;
}
