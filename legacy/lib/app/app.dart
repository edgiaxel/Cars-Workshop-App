import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/providers/theme_provider.dart';
import 'config/app_config.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root application widget connecting Theme, Router, and Configuration.
///
/// Adheres to ARCHITECTURE.md section 5 and CUSTOMIZATION.md.
class PitMateApp extends ConsumerWidget {
  const PitMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

