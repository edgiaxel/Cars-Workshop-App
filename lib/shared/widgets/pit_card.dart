import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Styled surface container adhering to PitMate motorsport design guidelines.
class PitCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? header;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? width;
  final double? height;

  const PitCard({
    super.key,
    required this.child,
    this.title,
    this.header,
    this.padding = AppSpacing.paddingMd,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final border = borderColor ?? (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final radius = BorderRadius.circular(AppSpacing.radiusMd);

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null) ...[
          header!,
          const SizedBox(height: AppSpacing.sm),
        ] else if (title != null && title!.isNotEmpty) ...[
          Text(
            title!,
            style: AppTypography.headingSmall(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        child,
      ],
    );

    Widget cardWidget = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: content,
          ),
        ),
      ),
    );

    return cardWidget;
  }
}
