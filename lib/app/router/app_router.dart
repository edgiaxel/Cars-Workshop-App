import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pitmate/app/router/route_paths.dart';
import 'package:pitmate/features/admin/presentation/admin_bookings_screen.dart';
import 'package:pitmate/features/admin/presentation/admin_customers_screen.dart';
import 'package:pitmate/features/admin/presentation/admin_estimate_builder_screen.dart';
import 'package:pitmate/features/admin/presentation/admin_inventory_screen.dart';
import 'package:pitmate/features/admin/presentation/admin_mechanic_earnings_screen.dart';
import 'package:pitmate/features/admin/presentation/admin_part_requests_screen.dart';
import 'package:pitmate/features/admin/presentation/admin_workshop_floor_screen.dart';
import 'package:pitmate/features/mechanic/presentation/mechanic_earnings_screen.dart';
import 'package:pitmate/features/mechanic/presentation/operation_workspace_screen.dart';
import 'package:pitmate/features/admin/presentation/admin_inspection_review_screen.dart';
import 'package:pitmate/features/admin/presentation/admin_overview_screen.dart';
import 'package:pitmate/features/quality_control/presentation/admin_qc_screen.dart';
import 'package:pitmate/features/invoices/presentation/admin_invoices_screen.dart';
import 'package:pitmate/features/invoices/presentation/customer_invoices_screen.dart';
import 'package:pitmate/features/handover/presentation/admin_handover_screen.dart';
import 'package:pitmate/features/auth/domain/user_role.dart';
import 'package:pitmate/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:pitmate/features/auth/presentation/screens/login_screen.dart';
import 'package:pitmate/features/auth/presentation/screens/register_screen.dart';
import 'package:pitmate/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:pitmate/features/bookings/presentation/screens/book_service_screen.dart';
import 'package:pitmate/features/bookings/presentation/screens/customer_appointments_screen.dart';
import 'package:pitmate/features/customers/presentation/customer_estimate_approval_screen.dart';
import 'package:pitmate/features/customers/presentation/customer_garage_screen.dart';
import 'package:pitmate/features/mechanic/presentation/inspection_workspace_screen.dart';
import 'package:pitmate/features/mechanic/presentation/mechanic_home_screen.dart';
import 'package:pitmate/features/reports/presentation/admin_reports_screen.dart';
import 'package:pitmate/features/reminders/presentation/admin_reminders_screen.dart';
import 'package:pitmate/features/customer_tracking/presentation/customer_tracking_screen.dart';
import 'package:pitmate/features/reminders/presentation/customer_reminders_screen.dart';
import 'package:pitmate/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:pitmate/features/profile/presentation/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Application router for PitMate connected to live authentication.
final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.root,
  redirect: (BuildContext context, GoRouterState state) {
    // Intercept PKCE password recovery code from Supabase email link (state URI or browser Uri.base)
    final code = state.uri.queryParameters['code'] ?? Uri.base.queryParameters['code'];
    if (code != null && code.isNotEmpty && state.matchedLocation != RoutePaths.resetPassword) {
      return '${RoutePaths.resetPassword}?code=$code';
    }

    if (state.matchedLocation == RoutePaths.root) {
      try {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return RoutePaths.login;
        }
        final roleStr = session.user.userMetadata?['role'] as String?;
        final role = UserRole.fromString(roleStr);
        switch (role) {
          case UserRole.admin:
            return RoutePaths.admin;
          case UserRole.mechanic:
            return RoutePaths.mechanic;
          case UserRole.customer:
            return RoutePaths.customerGarage;
        }
      } catch (_) {
        return RoutePaths.login;
      }
    }
    return null;
  },
  routes: [
    GoRoute(
      path: RoutePaths.root,
      redirect: (context, state) => RoutePaths.login,
    ),
    GoRoute(
      path: RoutePaths.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RoutePaths.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: RoutePaths.verifyOtp,
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return VerifyOtpScreen(email: email);
      },
    ),
    GoRoute(
      path: RoutePaths.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: RoutePaths.resetPassword,
      builder: (context, state) {
        final code = state.uri.queryParameters['code'];
        return ResetPasswordScreen(code: code);
      },
    ),
    GoRoute(
      path: RoutePaths.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: RoutePaths.admin,
      builder: (context, state) => const AdminOverviewScreen(),
    ),
    GoRoute(
      path: RoutePaths.adminCustomers,
      builder: (context, state) => const AdminCustomersScreen(),
    ),
    GoRoute(
      path: RoutePaths.adminBookings,
      builder: (context, state) => const AdminBookingsScreen(),
    ),
    GoRoute(
      path: RoutePaths.adminInspectionReview,
      builder: (context, state) {
        final orderId = state.uri.queryParameters['orderId'];
        final inspectionId = state.uri.queryParameters['inspectionId'];
        return AdminInspectionReviewScreen(
          serviceOrderId: orderId,
          inspectionId: inspectionId,
        );
      },
    ),
    GoRoute(
      path: RoutePaths.adminEstimateBuilder,
      builder: (context, state) {
        final orderId = state.uri.queryParameters['orderId'];
        return AdminEstimateBuilderScreen(serviceOrderId: orderId);
      },
    ),
    GoRoute(
      path: RoutePaths.adminWorkshopFloor,
      builder: (context, state) => const AdminWorkshopFloorScreen(),
    ),
    GoRoute(
      path: RoutePaths.adminInventory,
      builder: (context, state) => const AdminInventoryScreen(),
    ),
    GoRoute(
      path: RoutePaths.adminPartRequests,
      builder: (context, state) => const AdminPartRequestsScreen(),
    ),
    GoRoute(
      path: RoutePaths.adminCompensation,
      builder: (context, state) => const AdminMechanicEarningsScreen(),
    ),
    GoRoute(
      path: RoutePaths.adminQualityControl,
      builder: (context, state) => const AdminQcScreen(),
    ),
    GoRoute(
      path: RoutePaths.adminInvoices,
      builder: (context, state) => const AdminInvoicesScreen(),
    ),
    GoRoute(
      path: RoutePaths.adminHandover,
      builder: (context, state) => const AdminHandoverScreen(),
    ),
    GoRoute(
      path: RoutePaths.adminReports,
      builder: (context, state) => const AdminReportsScreen(),
    ),
    GoRoute(
      path: RoutePaths.adminReminders,
      builder: (context, state) => const AdminRemindersScreen(),
    ),
    GoRoute(
      path: RoutePaths.mechanic,
      builder: (context, state) => const MechanicHomeScreen(),
    ),
    GoRoute(
      path: RoutePaths.mechanicEarnings,
      builder: (context, state) => const MechanicEarningsScreen(),
    ),
    GoRoute(
      path: RoutePaths.mechanicInspection,
      builder: (context, state) {
        final orderId = state.uri.queryParameters['orderId'];
        final inspectionId = state.uri.queryParameters['inspectionId'];
        return InspectionWorkspaceScreen(
          serviceOrderId: orderId,
          inspectionId: inspectionId,
        );
      },
    ),
    GoRoute(
      path: RoutePaths.mechanicOperation,
      builder: (context, state) {
        final taskId = state.uri.queryParameters['taskId'] ?? '';
        return OperationWorkspaceScreen(taskId: taskId);
      },
    ),
    GoRoute(
      path: RoutePaths.customer,
      redirect: (context, state) => RoutePaths.customerGarage,
    ),
    GoRoute(
      path: RoutePaths.customerGarage,
      builder: (context, state) => const CustomerGarageScreen(),
    ),
    GoRoute(
      path: RoutePaths.bookService,
      builder: (context, state) {
        final vehicleId = state.uri.queryParameters['vehicleId'];
        return BookServiceScreen(initialVehicleId: vehicleId);
      },
    ),
    GoRoute(
      path: RoutePaths.customerAppointments,
      builder: (context, state) => const CustomerAppointmentsScreen(),
    ),
    GoRoute(
      path: RoutePaths.customerEstimateApproval,
      builder: (context, state) {
        final estimateId = state.uri.queryParameters['estimateId'];
        final orderId = state.uri.queryParameters['orderId'];
        return CustomerEstimateApprovalScreen(
          estimateId: estimateId,
          serviceOrderId: orderId,
        );
      },
    ),
    GoRoute(
      path: RoutePaths.customerInvoices,
      builder: (context, state) => const CustomerInvoicesScreen(),
    ),
    GoRoute(
      path: RoutePaths.customerTracking,
      builder: (context, state) => const CustomerTrackingScreen(),
    ),
    GoRoute(
      path: RoutePaths.customerReminders,
      builder: (context, state) => const CustomerRemindersScreen(),
    ),
  ],
);
