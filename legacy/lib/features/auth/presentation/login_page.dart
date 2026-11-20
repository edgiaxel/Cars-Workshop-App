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

/// Public login page for /login route adhering to ARCHITECTURE.md section 12.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authSessionProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) {
        final authState = ref.read(authSessionProvider);
        if (authState.isAuthenticated) {
          context.go(RoutePaths.dashboardForUserRole(authState.role));
        }
      }
    } catch (e) {
      if (mounted) {
        final authState = ref.read(authSessionProvider);
        setState(() {
          _isLoading = false;
          _errorMessage =
              authState.errorMessage ??
              'Authentication failed. Please verify credentials.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Sign In',
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
                        'PITMATE TERMINAL',
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
                      'Access Workshop Portal',
                      style: AppTypography.pageTitle(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.compact),
                  Center(
                    child: Text(
                      'Sign in with your registered account credentials',
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondary,
                      ),
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

                  PitCard(
                    technicalLabel: 'CREDENTIALS',
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
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.standard),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.compact),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                context.push(RoutePaths.forgotPassword),
                            child: Text(
                              'Forgot Password?',
                              style: AppTypography.bodySmall(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.compact),
                        PrimaryButton(
                          text: 'Sign In',
                          icon: Icons.login,
                          isLoading: _isLoading,
                          onPressed: _handleSignIn,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.section),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push(RoutePaths.register),
                      child: Text(
                        'Do not have an account? Register',
                        style: AppTypography.bodySmall(
                          color: AppColors.primaryAccentLight,
                        ),
                      ),
                    ),
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
