import 'package:flutter/material.dart';

/// Centralized color tokens for PitMate v2.0 (Motorsport-inspired).
class AppColors {
  const AppColors._();

  // Primary Accent (Racing Red)
  static const Color racingRed = Color(0xFFDC2626);
  static const Color racingRedDark = Color(0xFFB91C1C);
  static const Color racingRedLight = Color(0xFFEF4444);

  // Dark Theme Surfaces
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B);    // Slate 800
  static const Color darkCard = Color(0xFF334155);       // Slate 700
  static const Color darkBorder = Color(0xFF475569);     // Slate 600

  // Light Theme Surfaces
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF1F5F9);       // Slate 100
  static const Color lightBorder = Color(0xFFCBD5E1);     // Slate 300

  // Semantic Status Colors
  static const Color success = Color(0xFF16A34A); // Green 600
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFDC2626);   // Red 600
  static const Color info = Color(0xFF0284C7);    // Light Blue 600
  static const Color neutral = Color(0xFF64748B); // Slate 500
}
