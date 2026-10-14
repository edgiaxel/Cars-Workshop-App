import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';

/// Public landing screen for / and /landing adhering to ARCHITECTURE.md section 12.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBackButton: false,
      body: SingleChildScrollView(
        padding: AppSpacing.paddingSection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.medium),
            // Header badge & title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Text(
                    'PITMATE',
                    style: AppTypography.technical(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                ),
                const SizedBox(width: AppSpacing.compact),
                Text(
                  'MOTORSPORT GARAGE OS',
                  style: AppTypography.technical(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.standard),
            Text(
              'Precision Workshop Management',
              style: AppTypography.displayLarge(),
            ),
            const SizedBox(height: AppSpacing.compact),
            Text(
              'A high-performance car workshop management application built with Flutter and Supabase for road vehicles, GT3 racecars, and hypercars.',
              style: AppTypography.bodyMedium(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.section),

            // Primary Call to Actions
            PrimaryButton(
              text: 'Access Portal',
              icon: Icons.login,
              onPressed: () => context.push(RoutePaths.login),
            ),
            const SizedBox(height: AppSpacing.standard),
            SecondaryButton(
              text: 'Register Account',
              icon: Icons.person_add_outlined,
              onPressed: () => context.push(RoutePaths.register),
            ),
            const SizedBox(height: AppSpacing.standard),
            SecondaryButton(
              text: 'About PitMate',
              icon: Icons.info_outline,
              onPressed: () => context.push(RoutePaths.about),
            ),

            const SizedBox(height: AppSpacing.large),

            // Role Area Preview Cards (proves routing foundation works)
            Text(
              'OPERATIONAL TERMINALS',
              style: AppTypography.technical(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.compact),
            PitCard(
              technicalLabel: 'ADMINISTRATION',
              onTap: () => context.push(RoutePaths.admin),
              child: Row(
                children: [
                  const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: AppColors.primaryAccent,
                  ),
                  const SizedBox(width: AppSpacing.standard),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Terminal', style: AppTypography.label()),
                        Text(
                          'Workshop management, mechanics, inventory & reports',
                          style: AppTypography.bodySmall(),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            PitCard(
              technicalLabel: 'WORKBENCH',
              onTap: () => context.push(RoutePaths.mechanic),
              child: Row(
                children: [
                  const Icon(
                    Icons.build_circle_outlined,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.standard),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mechanic Terminal', style: AppTypography.label()),
                        Text(
                          'Assigned services, tasks, checklists & parts requests',
                          style: AppTypography.bodySmall(),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            PitCard(
              technicalLabel: 'CUSTOMER PORTAL',
              onTap: () => context.push(RoutePaths.customer),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_car_outlined,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: AppSpacing.standard),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer Portal', style: AppTypography.label()),
                        Text(
                          'Registered vehicles, service tracking & bookings',
                          style: AppTypography.bodySmall(),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
