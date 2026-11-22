import 'package:flutter/material.dart';

/// Spacing and dimensional design tokens for PitMate.
class AppSpacing {
  const AppSpacing._();

  // Spacing scales (4, 8, 12, 16, 24, 32, 48)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // EdgeInsets helpers
  static const EdgeInsets p4 = EdgeInsets.all(space4);
  static const EdgeInsets p8 = EdgeInsets.all(space8);
  static const EdgeInsets p12 = EdgeInsets.all(space12);
  static const EdgeInsets p16 = EdgeInsets.all(space16);
  static const EdgeInsets p24 = EdgeInsets.all(space24);
  static const EdgeInsets p32 = EdgeInsets.all(space32);

  static const EdgeInsets h8 = EdgeInsets.symmetric(horizontal: space8);
  static const EdgeInsets h16 = EdgeInsets.symmetric(horizontal: space16);
  static const EdgeInsets h24 = EdgeInsets.symmetric(horizontal: space24);

  static const EdgeInsets v8 = EdgeInsets.symmetric(vertical: space8);
  static const EdgeInsets v12 = EdgeInsets.symmetric(vertical: space12);
  static const EdgeInsets v16 = EdgeInsets.symmetric(vertical: space16);

  // Border radius tokens
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusCard = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusFull = 9999.0;

  static const BorderRadius roundedSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius roundedMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius roundedCard = BorderRadius.all(Radius.circular(radiusCard));
  static const BorderRadius roundedLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // Breakpoints
  static const double mobileBreakpoint = 900.0;
}
