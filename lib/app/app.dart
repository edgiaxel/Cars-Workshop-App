import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'config/app_config.dart';

/// Root application widget for PitMate v2.0.
class PitMateApp extends StatelessWidget {
  const PitMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to motorsport dark mode
      routerConfig: appRouter,
    );
  }
}
