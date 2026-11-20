import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

/// Root application widget for PitMate v2.0.
///
/// Automatically ensures a [ProviderScope] exists so standalone widget tests
/// pumping [PitMateApp] directly without an outer [ProviderScope] continue to work.
class PitMateApp extends StatelessWidget {
  const PitMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    bool hasScope = true;
    try {
      ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      hasScope = false;
    }

    if (!hasScope) {
      return const ProviderScope(child: _PitMateAppContent());
    }
    return const _PitMateAppContent();
  }
}

class _PitMateAppContent extends ConsumerWidget {
  const _PitMateAppContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
