import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/pit_card.dart';

/// Public about page for /about route.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'About PitMate',
      body: SingleChildScrollView(
        padding: AppSpacing.paddingSection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('PitMate Workshop OS', style: AppTypography.pageTitle()),
            const SizedBox(height: AppSpacing.compact),
            Text(
              'A modern mobile car workshop management application built with Flutter and Supabase, designed for precision single-workshop management with endurance-racing telemetry aesthetics.',
              style: AppTypography.bodyMedium(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.section),
            PitCard(
              technicalLabel: 'ARCHITECTURE SPECS',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSpecRow('Frontend', 'Flutter 3.47 / Dart 3.13'),
                  _buildSpecRow('Backend', 'Supabase PostgreSQL + Auth + RLS'),
                  _buildSpecRow('State Management', 'Riverpod 3.4'),
                  _buildSpecRow('Routing', 'GoRouter 18'),
                  _buildSpecRow('Typography', 'Inter + Space Grotesk'),
                  _buildSpecRow('Aesthetic', 'Motorsport Dark Terminal'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.standard),
            PitCard(
              technicalLabel: 'APPLICATION ROLES',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSpecRow('Admin', 'Christian Horner (Workshop Manager)'),
                  _buildSpecRow('Mechanic', 'Max Verstappen, Sergio Perez'),
                  _buildSpecRow('Customer', 'BMW M Motorsport, Aston Martin'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.technical(color: AppColors.textMuted),
          ),
          Text(
            value,
            style: AppTypography.bodySmall(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
