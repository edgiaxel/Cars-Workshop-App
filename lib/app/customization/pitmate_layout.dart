import 'package:flutter/material.dart';

/// PitMate Canonical Layout & Spacing definitions adhering to DESIGN.md and CUSTOMIZATION.md.
///
/// Ensures consistent spatial rhythm, tap targets (>= 44px), and radii.
abstract class PitmateLayout {
  // Spacing Scale (8pt grid system)
  static const double micro = 4.0;
  static const double compact = 8.0;
  static const double standard = 16.0;
  static const double section = 24.0;
  static const double expansive = 32.0;
  static const double massive = 48.0;

  // Accessible Minimum Touch Target Dimensions (Anti-Slop / WCAG)
  static const double minTouchTarget = 44.0;
  static const double defaultControlHeight = 48.0;

  // Standard Edge Insets
  static const EdgeInsets paddingScreen = EdgeInsets.all(standard);
  static const EdgeInsets paddingSection = EdgeInsets.all(section);
  static const EdgeInsets paddingCard = EdgeInsets.all(standard);
  static const EdgeInsets paddingCompact = EdgeInsets.all(compact);
  static const EdgeInsets paddingButton = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 12.0,
  );

  // Border Radii
  static const double radiusControl = 4.0;
  static const double radiusCard = 6.0;
  static const double radiusInput = 4.0;
  static const double radiusBadge = 3.0;
  static const double radiusModal = 12.0;
}
