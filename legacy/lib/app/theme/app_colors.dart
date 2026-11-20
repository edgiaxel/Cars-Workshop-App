import 'package:flutter/material.dart';

import '../customization/pitmate_palette.dart';

/// PitMate color tokens adhering strictly to DESIGN.md section 4 and CUSTOMIZATION.md.
///
/// Features a dark, motorsport-inspired visual foundation:
/// Dark backgrounds, elevated slate surfaces, and a controlled red accent.
/// Bridges directly to the canonical [PitmatePalette].
abstract class AppColors {
  // 4.1 Base Colors (Dark)
  static const Color backgroundPrimary = PitmatePalette.darkBackgroundPrimary;
  static const Color backgroundLight = PitmatePalette.lightBackgroundPrimary;
  static const Color backgroundSecondary = PitmatePalette.darkBackgroundSecondary;
  static const Color surfacePrimary = PitmatePalette.darkSurfacePrimary;
  static const Color surfaceSecondary = PitmatePalette.darkSurfaceSecondary;
  static const Color surfaceElevated = PitmatePalette.darkSurfaceElevated;
  static const Color surfaceCard = PitmatePalette.darkSurfaceSecondary;
  static const Color surfaceBackground = PitmatePalette.darkBackgroundPrimary;

  static const Color borderSubtle = PitmatePalette.darkBorderSubtle;

  static const Color textPrimary = PitmatePalette.darkTextPrimary;
  static const Color textSecondary = PitmatePalette.darkTextSecondary;
  static const Color textMuted = PitmatePalette.darkTextMuted;

  // 4.4 Motorsport Light Base Colors (DESIGN.md Addendum 1)
  static const Color lightBackgroundPrimary = PitmatePalette.lightBackgroundPrimary;
  static const Color lightBackgroundSecondary = PitmatePalette.lightBackgroundSecondary;
  static const Color lightSurfacePrimary = PitmatePalette.lightSurfacePrimary;
  static const Color lightSurfaceSecondary = PitmatePalette.lightSurfaceSecondary;
  static const Color lightSurfaceElevated = PitmatePalette.lightSurfaceElevated;
  static const Color lightSurfaceCard = PitmatePalette.lightSurfaceSecondary;
  static const Color lightSurfaceBackground = PitmatePalette.lightBackgroundPrimary;
  static const Color lightBorderSubtle = PitmatePalette.lightBorderSubtle;
  static const Color lightTextPrimary = PitmatePalette.lightTextPrimary;
  static const Color lightTextSecondary = PitmatePalette.lightTextSecondary;
  static const Color lightTextMuted = PitmatePalette.lightTextMuted;

  // 4.2 Brand / Accent Colors
  static const Color primaryAccent = PitmatePalette.primaryAccent; // Motorsport Red
  static const Color primaryAccentLight = PitmatePalette.primaryAccentLight;
  static const Color primaryAccentDark = PitmatePalette.primaryAccentDark;

  // 4.3 Semantic Colors
  static const Color success = PitmatePalette.success;
  static const Color warning = PitmatePalette.warning;
  static const Color error = PitmatePalette.error;
  static const Color info = PitmatePalette.info;
  static const Color neutral = PitmatePalette.neutral;

  // Status Color Mapping (DESIGN.md section 5)
  static const Color statusRequested = PitmatePalette.statusRequested;
  static const Color statusApproved = PitmatePalette.statusApproved;
  static const Color statusScheduled = PitmatePalette.statusScheduled;
  static const Color statusInspection = PitmatePalette.statusInspection;
  static const Color statusDiagnosis = PitmatePalette.statusDiagnosis;
  static const Color statusWaitingApproval = PitmatePalette.statusWaitingApproval;
  static const Color statusWaitingParts = PitmatePalette.statusWaitingParts;
  static const Color statusInProgress = PitmatePalette.statusInProgress;
  static const Color statusCompletionReview = PitmatePalette.statusCompletionReview;
  static const Color statusCompleted = PitmatePalette.statusCompleted;
  static const Color statusPayment = PitmatePalette.statusPayment;
  static const Color statusClosed = PitmatePalette.statusClosed;
  static const Color statusCancelled = PitmatePalette.statusCancelled;

  // Task Status Colors
  static const Color taskPending = PitmatePalette.taskPending;
  static const Color taskInProgress = PitmatePalette.taskInProgress;
  static const Color taskCompleted = PitmatePalette.taskCompleted;
  static const Color taskBlocked = PitmatePalette.taskBlocked;
  static const Color taskCancelled = PitmatePalette.taskCancelled;

  // Context-aware dynamic resolvers
  static bool isDark(BuildContext context) => PitmatePalette.isDark(context);
  static Color surface(BuildContext context) => PitmatePalette.surface(context);
  static Color text(BuildContext context) => PitmatePalette.textPrimary(context);
  static Color textSubtle(BuildContext context) => PitmatePalette.textSecondary(context);
}

