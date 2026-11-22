import 'package:go_router/go_router.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/verify_otp_screen.dart';

/// GoRouter configuration routes for authentication flows.
final authRoutes = <GoRoute>[
  GoRoute(
    path: LoginScreen.routePath,
    name: LoginScreen.routeName,
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: RegisterScreen.routePath,
    name: RegisterScreen.routeName,
    builder: (context, state) => const RegisterScreen(),
  ),
  GoRoute(
    path: VerifyOtpScreen.routePath,
    name: VerifyOtpScreen.routeName,
    builder: (context, state) {
      final email = state.uri.queryParameters['email'] ?? '';
      return VerifyOtpScreen(email: email);
    },
  ),
  GoRoute(
    path: ForgotPasswordScreen.routePath,
    name: ForgotPasswordScreen.routeName,
    builder: (context, state) => const ForgotPasswordScreen(),
  ),
];
