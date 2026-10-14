import 'package:flutter/material.dart';

/// PitMate color tokens adhering strictly to DESIGN.md section 4.
///
/// Features a dark, motorsport-inspired visual foundation:
/// Dark backgrounds, elevated slate surfaces, and a controlled red accent.
abstract class AppColors {
  // 4.1 Base Colors
  static const Color backgroundPrimary = Color(0xFF0B0D10);
  static const Color backgroundSecondary = Color(0xFF11151A);
  static const Color surfacePrimary = Color(0xFF171C22);
  static const Color surfaceSecondary = Color(0xFF1E252D);
  static const Color surfaceElevated = Color(0xFF252D36);

  static const Color borderSubtle = Color(0xFF2D3742);

  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFFAAB4C0);
  static const Color textMuted = Color(0xFF707B88);

  // 4.2 Brand / Accent Colors
  static const Color primaryAccent = Color(0xFFE10600); // Motorsport Red
  static const Color primaryAccentLight = Color(0xFFFF3B30);
  static const Color primaryAccentDark = Color(0xFFA80000);

  // 4.3 Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color neutral = Color(0xFF64748B);

  // Status Color Mapping (DESIGN.md section 5)
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

  // Task Status Colors
  static const Color taskPending = neutral;
  static const Color taskInProgress = primaryAccent;
  static const Color taskCompleted = success;
  static const Color taskBlocked = warning;
  static const Color taskCancelled = error;
}
