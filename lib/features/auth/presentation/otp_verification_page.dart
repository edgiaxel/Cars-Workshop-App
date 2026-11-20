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

class OtpVerificationPage extends ConsumerStatefulWidget {
  final String? email;

  const OtpVerificationPage({super.key, this.email});

  @override
  ConsumerState<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    try {
      await ref.read(authControllerProvider.notifier).verifyOtp(
            _emailController.text,
            _otpController.text,
          );
      if (mounted) {
        context.go(RoutePaths.customer);
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
      appBar: AppBar(title: const Text('Verify Email')),
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
                    Text('Verification Code', style: AppTypography.headingSmall()),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Enter the OTP code sent to your registered email address.',
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
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall(color: AppColors.error),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    TextFormField(
                      key: const Key('otp_email_input'),
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || !value.contains('@') ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      key: const Key('otp_code_input'),
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: '6-digit OTP Token',
                        prefixIcon: Icon(Icons.security),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().length != 6 ? 'Enter 6-digit code' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    PitPrimaryButton(
                      key: const Key('otp_submit_button'),
                      text: 'Verify Code',
                      isLoading: authState.isLoading,
                      onPressed: _handleVerify,
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
