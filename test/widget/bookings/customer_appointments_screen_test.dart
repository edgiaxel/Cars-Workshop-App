import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/features/bookings/presentation/screens/customer_appointments_screen.dart';

void main() {
  Widget buildScreen() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: const CustomerAppointmentsScreen(),
    );
  }

  group('CustomerAppointmentsScreen', () {
    testWidgets('renders appointments list with telemetry and vehicle details', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('YOUR WORKSHOP APPOINTMENTS'), findsOneWidget);
      expect(find.text('BRAKE SERVICE'), findsOneWidget);
      expect(find.text('PERIODIC SERVICE'), findsOneWidget);
      expect(find.text('B 2044 RFS'), findsOneWidget);
      expect(find.text('B 9912 SPO'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsWidgets);
      expect(find.text('PENDING REVIEW'), findsWidgets);
    });

    testWidgets('cancels pending appointment with confirmation dialog', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final cancelBtn = find.byKey(const Key('cancel-booking-btn-bk-sample-02'));
      await tester.ensureVisible(cancelBtn);
      await tester.pumpAndSettle();
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(find.text('Cancel Appointment?'), findsOneWidget);

      final confirmBtn = find.byKey(const Key('confirm-cancel-booking-button'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.text('Appointment has been cancelled.'), findsOneWidget);
    });
  });
}
