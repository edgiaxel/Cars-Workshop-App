import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/pit_primary_button.dart';
import 'providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    try {
      await ref.read(authControllerProvider.notifier).signUp(
            email: _emailController.text,
            password: _passwordController.text,
            fullName: _nameController.text,
            phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
          );
      if (mounted) {
        context.push('/otp-verify?email=${Uri.encodeComponent(_emailController.text)}');
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
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PitCard(
                    padding: AppSpacing.paddingLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Customer Registration', style: AppTypography.headingSmall()),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Register to track services, manage vehicles, and approve estimates.',
                          style: AppTypography.bodySmall(color: AppColors.neutral),
                        ),
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
                          key: const Key('register_name_input'),
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        TextFormField(
                          key: const Key('register_email_input'),
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
                          key: const Key('register_phone_input'),
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number (Optional)',
                            prefixIcon: Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        TextFormField(
                          key: const Key('register_password_input'),
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password (min. 6 characters)',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        PitPrimaryButton(
                          key: const Key('register_submit_button'),
                          text: 'Register Account',
                          isLoading: authState.isLoading,
                          onPressed: _handleRegister,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account?', style: AppTypography.bodyMedium()),
                      TextButton(
                        onPressed: () => context.go(RoutePaths.login),
                        child: Text(
                          'Sign In',
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
