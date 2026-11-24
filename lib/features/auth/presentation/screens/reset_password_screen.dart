import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_spacing.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Password Reset Screen for PKCE code flow and recovery link resolution.
class ResetPasswordScreen extends StatefulWidget {
  final String? code;

  const ResetPasswordScreen({super.key, this.code});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isExchangingCode = false;
  bool _isUpdatingPassword = false;
  bool _resetComplete = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleInitialCodeExchange();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleInitialCodeExchange() async {
    final code = widget.code;
    if (code == null || code.trim().isEmpty) return;

    setState(() {
      _isExchangingCode = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.exchangeCodeForSession(code.trim());
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Reset link has expired or has already been used. Please request a new one.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExchangingCode = false;
        });
      }
    }
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isUpdatingPassword = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );
      if (mounted) {
        setState(() {
          _resetComplete = true;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to reset password: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPassword = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set New Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Sign In',
          onPressed: () => context.go(RoutePaths.login),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: PitCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space24),
                  child: _resetComplete
                      ? _buildSuccessView(textColor)
                      : _buildFormView(textColor, isDark),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(Color textColor, bool isDark) {
    if (_isExchangingCode) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.racingRed),
          ),
          const SizedBox(height: AppSpacing.space16),
          Text(
            'Verifying password recovery session...',
            style: AppTypography.bodyMedium(color: textColor),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.racingRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset,
                color: AppColors.racingRed,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          Text(
            'Choose New Password',
            style: AppTypography.headlineSmall(color: textColor).copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            'Enter your new credentials below to restore secure account access.',
            style: AppTypography.bodyMedium(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space24),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.space12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: AppSpacing.roundedSmall,
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                  const SizedBox(width: AppSpacing.space8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.bodySmall(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
          ],

          // New Password Field
          TextFormField(
            key: const Key('reset_password_field'),
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.space16),

          // Confirm Password Field
          TextFormField(
            key: const Key('reset_password_confirm_field'),
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.space24),

          // Submit Button
          ElevatedButton(
            key: const Key('reset_password_submit_button'),
            onPressed: _isUpdatingPassword ? null : _onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.racingRed,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isUpdatingPassword
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Update Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: AppSpacing.space16),

          TextButton(
            onPressed: () => context.go(RoutePaths.login),
            child: const Text('Return to Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle_outline, color: AppColors.success, size: 56),
        const SizedBox(height: AppSpacing.space16),
        Text(
          'Password Restored',
          style: AppTypography.headlineSmall(color: textColor).copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.space8),
        Text(
          'Your credentials have been updated successfully. You can now sign in with your new password.',
          style: AppTypography.bodyMedium(color: textColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.space24),
        ElevatedButton(
          key: const Key('reset_password_return_login_button'),
          onPressed: () => context.go(RoutePaths.login),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.racingRed,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Sign In Now'),
        ),
      ],
    );
  }
}
