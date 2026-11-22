import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/app/theme/app_typography.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/pitmate_logo.dart';

/// Landing screen / Role Hub allowing quick navigation across PitMate roles.
class RoleHubScreen extends StatelessWidget {
  const RoleHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: PitMateLogo(size: 40)),
                  const SizedBox(height: 12),
                  Text(
                    'WORKSHOP MANAGEMENT OS',
                    textAlign: TextAlign.center,
                    style: AppTypography.telemetrySmall(
                      color: AppColors.accentRed,
                      fontWeight: FontWeight.w700,
                    ).copyWith(letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'SELECT ROLE TO ENTER WORKSPACE',
                    style: AppTypography.headlineSmall(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Customer Garage Card
                  PitCard(
                    accentBorderLeft: AppColors.accentRed,
                    onTap: () => context.go(RoutePaths.customerGarage),
                    child: Row(
                      children: [
                        const Icon(Icons.garage_outlined, color: AppColors.accentRed, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CUSTOMER GARAGE',
                                style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Track vehicles, inspections, service orders & history.',
                                style: AppTypography.bodySmall(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Admin Dispatch Card
                  PitCard(
                    accentBorderLeft: AppColors.success,
                    onTap: () => context.go(RoutePaths.admin),
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings_outlined, color: AppColors.success, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ADMIN WORKSHOP DISPATCH',
                                style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Customer registry, walk-in intake, bays, jobs & stock.',
                                style: AppTypography.bodySmall(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mechanic Card
                  PitCard(
                    accentBorderLeft: AppColors.warning,
                    onTap: () => context.go(RoutePaths.mechanic),
                    child: Row(
                      children: [
                        const Icon(Icons.precision_manufacturing, color: AppColors.warning, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MECHANIC TELEMETRY',
                                style: AppTypography.labelLarge(color: textColor, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Bay assignments, active tasks, torques & QC checks.',
                                style: AppTypography.bodySmall(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Auth Links Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => context.go(RoutePaths.login),
                        child: const Text('Sign In'),
                      ),
                      const Text('•'),
                      TextButton(
                        onPressed: () => context.go(RoutePaths.register),
                        child: const Text('Create Account'),
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

/// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SIGN IN'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.root),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: PitCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: PitMateLogo(size: 32)),
                  const SizedBox(height: 16),
                  Text(
                    'SIGN IN TO PITMATE',
                    style: AppTypography.headlineSmall(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go(RoutePaths.forgotPassword),
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go(RoutePaths.customerGarage),
                    child: const Text('SIGN IN'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'New to PitMate? ',
                        style: AppTypography.bodySmall(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(RoutePaths.register),
                        child: const Text('Register'),
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

/// Register Screen
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CREATE ACCOUNT'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.login),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: PitCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: PitMateLogo(size: 32)),
                  const SizedBox(height: 16),
                  Text(
                    'CREATE PITMATE ACCOUNT',
                    style: AppTypography.headlineSmall(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.go(RoutePaths.verifyOtp),
                    child: const Text('CONTINUE & VERIFY OTP'),
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

/// Verify OTP Screen
class VerifyOtpScreen extends StatelessWidget {
  const VerifyOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VERIFY OTP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.login),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: PitCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.accentRed),
                  const SizedBox(height: 14),
                  Text(
                    'ENTER VERIFICATION CODE',
                    style: AppTypography.headlineSmall(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit confirmation code to your phone/email.',
                    style: AppTypography.bodySmall(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const TextField(
                    textAlign: TextAlign.center,
                    style: TextStyle(letterSpacing: 12, fontSize: 24, fontWeight: FontWeight.bold),
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '000000',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.go(RoutePaths.customerGarage),
                    child: const Text('CONFIRM & ENTER WORKSPACE'),
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

/// Forgot Password Screen
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.graphitePrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RESET PASSWORD'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RoutePaths.login),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: PitCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_reset_outlined, size: 40, color: AppColors.accentRed),
                  const SizedBox(height: 14),
                  Text(
                    'PASSWORD RESET',
                    style: AppTypography.headlineSmall(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your registered email address to receive password reset instructions.',
                    style: AppTypography.bodySmall(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password reset link sent to your email.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      context.go(RoutePaths.login);
                    },
                    child: const Text('SEND RESET LINK'),
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
