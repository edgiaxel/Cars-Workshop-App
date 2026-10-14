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

/// Public registration page for /register route adhering to ARCHITECTURE.md & SPEC.md.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _confirmationPending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ref
          .read(authSessionProvider.notifier)
          .signUpCustomer(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          );

      if (mounted) {
        if (response.session == null) {
          // Email confirmation is required by Supabase auth configuration
          setState(() {
            _isLoading = false;
            _confirmationPending = true;
          });
        }
        // If session was returned, the reactive router will redirect to /customer automatically
      }
    } catch (e) {
      if (mounted) {
        final authState = ref.read(authSessionProvider);
        setState(() {
          _isLoading = false;
          _errorMessage =
              authState.errorMessage ??
              'Registration failed. Please try again.';
        });
      }
    } finally {
      if (mounted && !_confirmationPending) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Customer Registration',
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
                  Text(
                    'Create PitMate Account',
                    style: AppTypography.pageTitle(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.compact),
                  Text(
                    'Register as a vehicle owner or fleet manager',
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
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

                  if (_confirmationPending) ...[
                    PitCard(
                      technicalLabel: 'CONFIRMATION PENDING',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.mark_email_unread_outlined,
                            color: AppColors.warning,
                            size: 48,
                          ),
                          const SizedBox(height: AppSpacing.standard),
                          Text(
                            'Verification link sent to ${_emailController.text.trim()}.',
                            style: AppTypography.bodyMedium(
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.compact),
                          Text(
                            'Please verify your email address to activate your customer telemetry portal.',
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
                      technicalLabel: 'NEW ACCOUNT',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name / Company',
                              prefixIcon: Icon(Icons.person_outline, size: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Full name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.standard),
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
                          const SizedBox(height: AppSpacing.standard),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number (Optional)',
                              prefixIcon: Icon(Icons.phone_outlined, size: 20),
                            ),
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
                            text: 'Register Account',
                            icon: Icons.app_registration,
                            isLoading: _isLoading,
                            onPressed: _handleRegister,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.section),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push(RoutePaths.login),
                      child: Text(
                        'Already have an account? Sign in',
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
