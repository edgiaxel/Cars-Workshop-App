import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Application scaffold establishing PitMate's visual identity.
///
/// Features the motorsport dark surface, red accent line, and structured hierarchy.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.showBackButton = true,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: title != null
          ? AppBar(
              title: Text(
                title!,
                style: AppTypography.pageTitle(color: AppColors.textPrimary),
              ),
              automaticallyImplyLeading: showBackButton,
              actions: actions,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: Container(
                  height: 2,
                  color: AppColors.primaryAccent.withValues(alpha: 0.8),
                ),
              ),
            )
          : null,
      body: SafeArea(child: body),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
