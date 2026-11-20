import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/app_config.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/pit_primary_button.dart';
import 'providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    try {
      await ref.read(authControllerProvider.notifier).signIn(
            _emailController.text,
            _passwordController.text,
          );
      final UserProfile? user = ref.read(authControllerProvider).user;
      if (mounted && user != null) {
        final destination = switch (user.role) {
          UserRole.admin => RoutePaths.admin,
          UserRole.mechanic => RoutePaths.mechanic,
          UserRole.customer => RoutePaths.customer,
        };
        context.go(destination);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: AppColors.racingRed.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.speed,
                        size: 48,
                        color: AppColors.racingRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppConfig.appName,
                    style: AppTypography.headingLarge(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Automotive Workshop Management',
                    style: AppTypography.bodySmall(color: AppColors.neutral),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  PitCard(
                    padding: AppSpacing.paddingLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Sign In', style: AppTypography.headingSmall()),
                        const SizedBox(height: AppSpacing.md),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: AppSpacing.paddingSm,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTypography.bodySmall(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        TextFormField(
                          key: const Key('login_email_input'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        TextFormField(
                          key: const Key('login_password_input'),
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: Text(
                              'Forgot password?',
                              style: AppTypography.bodySmall(color: AppColors.racingRed),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        PitPrimaryButton(
                          key: const Key('login_submit_button'),
                          text: 'Sign In',
                          isLoading: authState.isLoading,
                          onPressed: _handleLogin,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?", style: AppTypography.bodyMedium()),
                      TextButton(
                        onPressed: () => context.push(RoutePaths.register),
                        child: Text(
                          'Register as Customer',
                          style: AppTypography.label(color: AppColors.racingRed),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
