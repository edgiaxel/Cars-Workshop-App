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

/// Password recovery request screen for /forgot-password route.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authSessionProvider.notifier)
          .sendPasswordReset(_emailController.text.trim());

      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
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
      title: 'Password Recovery',
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent,
                        borderRadius: BorderRadius.circular(AppRadius.control),
                      ),
                      child: Text(
                        'TELEMETRY RECOVERY',
                        style: AppTypography.technical(color: Colors.white)
                            .copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.standard),
                  Center(
                    child: Text(
                      'Reset Your Password',
                      style: AppTypography.pageTitle(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.compact),
                  Center(
                    child: Text(
                      'Enter your registered email address to receive recovery instructions',
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

                  if (_emailSent) ...[
                    PitCard(
                      technicalLabel: 'DISPATCH CONFIRMED',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.mark_email_read_outlined,
                            color: AppColors.success,
                            size: 48,
                          ),
                          const SizedBox(height: AppSpacing.standard),
                          Text(
                            'Password reset instructions have been dispatched to ${_emailController.text.trim()}.',
                            style: AppTypography.bodyMedium(
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.compact),
                          Text(
                            'Please check your inbox and follow the link to establish a new password.',
                            style: AppTypography.bodySmall(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.section),
                          PrimaryButton(
                            text: 'Back to Sign In',
                            icon: Icons.arrow_back,
                            onPressed: () => context.go(RoutePaths.login),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    PitCard(
                      technicalLabel: 'RECOVERY PORTAL',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email address is required';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.section),
                          PrimaryButton(
                            text: 'Send Reset Link',
                            icon: Icons.send_outlined,
                            isLoading: _isLoading,
                            onPressed: _handleSubmit,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(RoutePaths.login),
                        child: Text(
                          'Remembered credentials? Sign in',
                          style: AppTypography.bodySmall(
                            color: AppColors.primaryAccentLight,
                          ),
                        ),
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
