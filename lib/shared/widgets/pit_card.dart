import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Motorsport-styled card container with 1px precision border,
/// customizable padding, optional accent stripes (left/top), and subtle surface tone.
class PitCard extends StatelessWidget {
  const PitCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.p16,
    this.margin,
    this.color,
    this.borderColor,
    this.borderRadius,
    this.elevation = 0,
    this.onTap,
    this.accentBorderLeft,
    this.accentBorderTop,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final double elevation;
  final VoidCallback? onTap;
  final Color? accentBorderLeft;
  final Color? accentBorderTop;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBg = color ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final effectiveBorder = borderColor ?? (isDark ? AppColors.borderDark : AppColors.borderLight);
    final effectiveRadius = borderRadius ?? AppSpacing.roundedCard;

    Widget cardBody;

    if (accentBorderTop != null) {
      cardBody = ClipRRect(
        borderRadius: effectiveRadius,
        child: Container(
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: effectiveRadius,
            border: Border.all(color: effectiveBorder, width: 1.0),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 4.0,
                child: Container(color: accentBorderTop),
              ),
              Padding(
                padding: padding ?? AppSpacing.p16,
                child: child,
              ),
            ],
          ),
        ),
      );
    } else if (accentBorderLeft != null) {
      cardBody = ClipRRect(
        borderRadius: effectiveRadius,
        child: Container(
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: effectiveRadius,
            border: Border.all(color: effectiveBorder, width: 1.0),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                width: 3.5,
                child: Container(color: accentBorderLeft),
              ),
              Padding(
                padding: padding ?? AppSpacing.p16,
                child: child,
              ),
            ],
          ),
        ),
      );
    } else {
      cardBody = Container(
        padding: padding,
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: effectiveRadius,
          border: Border.all(color: effectiveBorder, width: 1.0),
        ),
        child: child,
      );
    }

    if (onTap != null) {
      return Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          borderRadius: effectiveRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: effectiveRadius,
            child: cardBody,
          ),
        ),
      );
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: cardBody,
    );
  }
}
