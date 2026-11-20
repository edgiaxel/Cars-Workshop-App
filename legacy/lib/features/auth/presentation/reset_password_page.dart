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

/// Password reset execution screen for /reset-password route.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _success = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authSessionProvider.notifier)
          .updatePassword(_passwordController.text);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _success = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Update Password',
      showBackButton: false,
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingSection,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      'Establish New Password',
                      style: AppTypography.pageTitle(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.compact),
                  Center(
                    child: Text(
                      'Configure your updated credentials to regain telemetry access',
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: AppSpacing.paddingStandard,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.error),
                        borderRadius: AppRadius.cardRadius,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.compact),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodySmall(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.standard),
                  ],

                  if (_success) ...[
                    PitCard(
                      technicalLabel: 'CREDENTIALS UPDATED',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.success,
                            size: 48,
                          ),
                          const SizedBox(height: AppSpacing.standard),
                          Text(
                            'Your password has been successfully updated.',
                            style: AppTypography.bodyMedium(
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.section),
                          PrimaryButton(
                            text: 'Continue to Portal',
                            icon: Icons.login,
                            onPressed: () {
                              final authState = ref.read(authSessionProvider);
                              if (authState.isAuthenticated) {
                                context.go(
                                  RoutePaths.dashboardForUserRole(
                                    authState.role,
                                  ),
                                );
                              } else {
                                context.go(RoutePaths.login);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    PitCard(
                      technicalLabel: 'NEW CREDENTIALS',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: Icon(Icons.lock_outline, size: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.standard),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icon(
                                Icons.lock_reset_outlined,
                                size: 20,
                              ),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.section),
                          PrimaryButton(
                            text: 'Save New Password',
                            icon: Icons.check,
                            isLoading: _isLoading,
                            onPressed: _handleUpdate,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
