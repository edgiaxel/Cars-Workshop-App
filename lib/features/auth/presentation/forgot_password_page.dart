import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/pit_card.dart';
import '../../../shared/widgets/pit_primary_button.dart';
import 'providers/auth_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
      _submitted = false;
    });

    try {
      await ref.read(authControllerProvider.notifier).sendPasswordReset(_emailController.text);
      if (mounted) {
        setState(() => _submitted = true);
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
      appBar: AppBar(title: const Text('Password Recovery')),
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: PitCard(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Reset Password', style: AppTypography.headingSmall()),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Enter your email to receive password reset instructions.',
                      style: AppTypography.bodySmall(color: AppColors.neutral),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (_submitted) ...[
                      Container(
                        padding: AppSpacing.paddingSm,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Password reset email sent! Check your inbox.',
                          style: AppTypography.bodySmall(color: AppColors.success),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (_errorMessage != null) ...[
                      Container(
                        padding: AppSpacing.paddingSm,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall(color: AppColors.error),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    TextFormField(
                      key: const Key('forgot_password_email_input'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Registered Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || !value.contains('@') ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    PitPrimaryButton(
                      key: const Key('forgot_password_submit_button'),
                      text: 'Send Reset Link',
                      isLoading: authState.isLoading,
                      onPressed: _handleReset,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
