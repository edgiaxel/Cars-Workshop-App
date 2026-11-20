import 'package:flutter/material.dart';

/// Spacing and border-radius design tokens adhering to DESIGN.md sections 7 & 8.
abstract class AppSpacing {
  // Base 4px spacing scale
  static const double micro = 4.0;
  static const double compact = 8.0;
  static const double small = 12.0;
  static const double standard = 16.0;
  static const double medium = 20.0;
  static const double section = 24.0;
  static const double large = 32.0;
  static const double major = 40.0;
  static const double page = 48.0;

  // EdgeInsets helpers
  static const EdgeInsets paddingCompact = EdgeInsets.all(compact);
  static const EdgeInsets paddingStandard = EdgeInsets.all(standard);
  static const EdgeInsets paddingSection = EdgeInsets.all(section);
  static const EdgeInsets paddingHorizontalStandard = EdgeInsets.symmetric(
    horizontal: standard,
  );
  static const EdgeInsets paddingVerticalStandard = EdgeInsets.symmetric(
    vertical: standard,
  );
}

/// Border-radius tokens adhering to DESIGN.md section 8.
abstract class AppRadius {
  static const double control = 8.0;
  static const double input = 10.0;
  static const double card = 12.0;
  static const double cardLarge = 16.0;
  static const double dialog = 16.0;
  static const double container = 20.0;
  static const double pill = 24.0;

  // BorderRadius helpers
  static final BorderRadius controlRadius = BorderRadius.circular(control);
  static final BorderRadius inputRadius = BorderRadius.circular(input);
  static final BorderRadius cardRadius = BorderRadius.circular(card);
  static final BorderRadius cardLargeRadius = BorderRadius.circular(cardLarge);
  static final BorderRadius dialogRadius = BorderRadius.circular(dialog);
  static final BorderRadius pillRadius = BorderRadius.circular(pill);
}
