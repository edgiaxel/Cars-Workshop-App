import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/features/admin/presentation/admin_bookings_screen.dart';

void main() {
  Widget buildScreen() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: const AdminBookingsScreen(),
    );
  }

  group('AdminBookingsScreen', () {
    testWidgets('displays KPI summary tiles and booking cards', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('TOTAL BOOKINGS'), findsOneWidget);
      expect(find.text('PENDING REVIEW'), findsWidgets);
      expect(find.text('CONFIRMED'), findsWidgets);
      expect(find.text('CHECKED IN'), findsWidgets);

      expect(find.text('Alex Pratama'), findsOneWidget);
      expect(find.text('Bambang Soediro'), findsOneWidget);
      expect(find.text('Rian Hidayat'), findsOneWidget);
      expect(find.text('Hendra Wijaya'), findsOneWidget);
    });

    testWidgets('filters booking cards via search input', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('admin-booking-search-input'));
      await tester.enterText(searchField, 'Bambang');
      await tester.pumpAndSettle();

      expect(find.text('Bambang Soediro'), findsOneWidget);
      expect(find.text('Alex Pratama'), findsNothing);
    });

    testWidgets('approves pending booking and updates status to confirmed', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final approveBtn = find.byKey(const Key('approve-booking-btn-bk-adm-02'));
      await tester.ensureVisible(approveBtn);
      await tester.pumpAndSettle();
      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Booking for Bambang Soediro confirmed.'), findsOneWidget);
    });

    testWidgets('rejects booking with specified reason', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final rejectBtn = find.byKey(const Key('reject-booking-btn-bk-adm-02'));
      await tester.ensureVisible(rejectBtn);
      await tester.pumpAndSettle();
      await tester.tap(rejectBtn);
      await tester.pumpAndSettle();

      expect(find.text('Reject Booking Request'), findsOneWidget);
      final reasonField = find.byKey(const Key('reject-reason-input'));
      await tester.enterText(reasonField, 'Workshop at maximum bay capacity');
      await tester.pumpAndSettle();

      final confirmRejectBtn = find.byKey(const Key('confirm-reject-booking-button'));
      await tester.tap(confirmRejectBtn);
      await tester.pumpAndSettle();

      expect(find.text('Booking rejected.'), findsOneWidget);
    });

    testWidgets('opens Customer Intake Modal when tapping intake check-in', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final intakeBtn = find.byKey(const Key('intake-checkin-btn-bk-adm-01'));
      await tester.ensureVisible(intakeBtn);
      await tester.pumpAndSettle();
      await tester.tap(intakeBtn);
      await tester.pumpAndSettle();

      expect(find.text('BOOKING INTAKE CHECK-IN'), findsOneWidget);
      expect(find.byKey(const Key('submit-intake-button')), findsOneWidget);
    });

    testWidgets('opens Walk-in Intake Modal via action button', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final newIntakeBtn = find.byKey(const Key('admin-new-walkin-intake-btn'));
      await tester.ensureVisible(newIntakeBtn);
      await tester.pumpAndSettle();
      await tester.tap(newIntakeBtn);
      await tester.pumpAndSettle();

      expect(find.text('WORKSHOP VEHICLE INTAKE'), findsOneWidget);
      expect(find.byKey(const Key('intake-mode-registered')), findsOneWidget);
      expect(find.byKey(const Key('intake-mode-walk-in')), findsOneWidget);
    });
  });
}
