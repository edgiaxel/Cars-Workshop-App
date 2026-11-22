import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import '../../domain/user_role.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'verify_otp_screen.dart';

/// PitMate Authentication Sign In screen connected to live Supabase backend.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const String routePath = '/login';
  static const String routeName = 'login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authNotifierProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  void _fillAccountAndSignIn(String email, [String password = '000000']) {
    _emailController.text = email;
    _passwordController.text = password;
    ref.read(authNotifierProvider.notifier).signIn(email, password);
  }

  void _onForgotPasswordPressed() {
    if (GoRouter.maybeOf(context) != null) {
      context.push(RoutePaths.forgotPassword);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ForgotPasswordScreen(),
        ),
      );
    }
  }

  void _onRegisterPressed() {
    if (GoRouter.maybeOf(context) != null) {
      context.push(RoutePaths.register);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const RegisterScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    // Listen for auth state transitions
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: const Color(0xFFB2221C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next is AuthUnverifiedCustomer) {
        if (GoRouter.maybeOf(context) != null) {
          context.push('${RoutePaths.verifyOtp}?email=${Uri.encodeComponent(next.email)}');
        } else {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => VerifyOtpScreen(email: next.email),
            ),
          );
        }
      } else if (next is AuthAuthenticated) {
        if (GoRouter.maybeOf(context) != null) {
          switch (next.userProfile.role) {
            case UserRole.admin:
              context.go(RoutePaths.admin);
            case UserRole.mechanic:
              context.go(RoutePaths.mechanic);
            case UserRole.customer:
              context.go(RoutePaths.customerGarage);
          }
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Brand Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB2221C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'PITMATE',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: const Color(0xFFB2221C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Automotive Workshop Management',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Login Form Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Sign In',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Email input
                            TextFormField(
                              key: const Key('login_email_field'),
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'admin@pitmate.co',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w\-\.]+@([\w-]+\.)+[\w-]{2,}$')
                                    .hasMatch(value.trim())) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password input
                            TextFormField(
                              key: const Key('login_password_field'),
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  key: const Key('login_password_toggle'),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                key: const Key('forgot_password_button'),
                                onPressed: _onForgotPasswordPressed,
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Sign In Button
                            ElevatedButton(
                              key: const Key('login_submit_button'),
                              onPressed: isLoading ? null : _onLoginPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB2221C),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Register navigation link
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        key: const Key('login_to_register_button'),
                        onPressed: _onRegisterPressed,
                        child: const Text('Create Account'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Quick Demo Accounts Panel
                  Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2229) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[400]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bolt,
                              size: 16,
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'QUICK SIGN IN (SEEDED ACCOUNTS • PW: 000000)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              key: const Key('demo_role_admin'),
                              avatar: const Icon(Icons.shield, size: 16),
                              label: const Text('Toto Wolf (Admin)'),
                              onPressed: () => _fillAccountAndSignIn('admin@pitmate.co'),
                            ),
                            ActionChip(
                              key: const Key('demo_role_mechanic'),
                              avatar: const Icon(Icons.build, size: 16),
                              label: const Text('Max Verstappen (Mech)'),
                              onPressed: () => _fillAccountAndSignIn('verstappen@pitmate.co'),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.build, size: 16),
                              label: const Text('Sergio Perez (Mech)'),
                              onPressed: () => _fillAccountAndSignIn('perez@pitmate.co'),
                            ),
                            ActionChip(
                              key: const Key('demo_role_customer'),
                              avatar: const Icon(Icons.person, size: 16),
                              label: const Text('Axel Zeed (Individual)'),
                              onPressed: () => _fillAccountAndSignIn('lexazeed@gmail.com'),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.business, size: 16),
                              label: const Text('Aston Martin (Company)'),
                              onPressed: () => _fillAccountAndSignIn('motorsport@astonmartin.com'),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.business, size: 16),
                              label: const Text('BMW (Company)'),
                              onPressed: () => _fillAccountAndSignIn('motorsport@bmw-m.com'),
                            ),
                          ],
                        ),
                      ],
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
