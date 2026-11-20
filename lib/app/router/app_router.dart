import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_paths.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../config/app_config.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.initial,
  routes: [
    GoRoute(
      path: RoutePaths.initial,
      builder: (context, state) => const _M0LandingPage(),
    ),
    GoRoute(
      path: RoutePaths.login,
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Login Screen (M1 Foundation)')),
      ),
    ),
  ],
);

class _M0LandingPage extends StatelessWidget {
  const _M0LandingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConfig.appName, style: AppTypography.headingSmall()),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.speed,
                size: 64,
                color: AppColors.racingRed,
              ),
              const SizedBox(height: 16),
              Text(
                'PitMate Automotive Workshop OS',
                style: AppTypography.headingMedium(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Version ${AppConfig.appVersion} — M0 Foundation Ready',
                style: AppTypography.bodyMedium(color: AppColors.neutral),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Technical Foundation Status:',
                        style: AppTypography.label(),
                      ),
                      const SizedBox(height: 8),
                      const _StatusRow(
                        label: 'Flutter & Dart Toolchain',
                        isOk: true,
                      ),
                      const _StatusRow(
                        label: 'Android & Web Compatibility',
                        isOk: true,
                      ),
                      const _StatusRow(
                        label: 'Architecture & Canonical Docs',
                        isOk: true,
                      ),
                      _StatusRow(
                        label: 'Supabase Integration',
                        isOk: AppConfig.isSupabaseConfigured,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool isOk;

  const _StatusRow({required this.label, required this.isOk});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.info_outline,
            size: 16,
            color: isOk ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Text(label, style: AppTypography.bodySmall()),
        ],
      ),
    );
  }
}
