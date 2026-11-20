import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';

/// Access restriction screen for /unauthorized route adhering to ARCHITECTURE.md & DESIGN.md.
class UnauthorizedPage extends ConsumerWidget {
  const UnauthorizedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionProvider);
    final userRole = authState.role?.displayName ?? 'Unauthenticated';

    return AppScaffold(
      title: 'Security Alert',
      showBackButton: false,
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingSection,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.error, width: 2),
                    ),
                    child: const Icon(
                      Icons.gpp_bad_outlined,
                      color: AppColors.error,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.standard),
                Center(
                  child: Text(
                    'Access Restricted',
                    style: AppTypography.pageTitle(),
                  ),
                ),
                const SizedBox(height: AppSpacing.compact),
                Center(
                  child: Text(
                    'Your active session lacks clearance for this operational terminal.',
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.section),

                PitCard(
                  technicalLabel: 'TELEMETRY SECURITY AUDIT',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAuditRow(
                        'Authenticated Identity',
                        authState.email ?? 'Unknown',
                      ),
                      _buildAuditRow('Assigned Clearance', userRole),
                      _buildAuditRow(
                        'Security Policy',
                        'Role-Based Access Control (RBAC)',
                      ),
                      const SizedBox(height: AppSpacing.standard),
                      Text(
                        'This sector is restricted to designated personnel. If you believe this clearance is in error, contact the workshop administrator.',
                        style: AppTypography.bodySmall(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.section),
                PrimaryButton(
                  text: 'Return to Dashboard',
                  icon: Icons.dashboard_outlined,
                  onPressed: () {
                    if (authState.isAuthenticated) {
                      context.go(
                        RoutePaths.dashboardForUserRole(authState.role),
                      );
                    } else {
                      context.go(RoutePaths.login);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.standard),
                SecondaryButton(
                  text: 'Sign Out Session',
                  icon: Icons.logout,
                  onPressed: () async {
                    await ref.read(authSessionProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go(RoutePaths.login);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuditRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AppTypography.technical(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: AppSpacing.compact),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.bodySmall(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
