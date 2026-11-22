import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/features/bookings/presentation/screens/book_service_screen.dart';

void main() {
  Widget buildScreen() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: const BookServiceScreen(),
    );
  }

  group('BookServiceScreen', () {
    testWidgets('renders all booking form sections and controls', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('SCHEDULE SERVICE VISIT'), findsOneWidget);
      expect(find.text('1. SELECT VEHICLE'), findsOneWidget);
      expect(find.text('2. DATE & ARRIVAL WINDOW'), findsOneWidget);
      expect(find.text('3. SERVICE TYPE'), findsOneWidget);
      expect(find.text('4. COMPLAINTS & SPECIFIC REQUESTS'), findsOneWidget);

      expect(find.byKey(const Key('book-service-vehicle-dropdown')), findsOneWidget);
      expect(find.byKey(const Key('book-service-date-picker')), findsOneWidget);
      expect(find.byKey(const Key('book-service-type-dropdown')), findsOneWidget);
      expect(find.byKey(const Key('book-service-complaints-input')), findsOneWidget);
      expect(find.byKey(const Key('submit-booking-button')), findsOneWidget);
    });

    testWidgets('allows selecting time slot choice chip', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final slotChip = find.byKey(const Key('slot-chip-10:00 - 12:00'));
      await tester.ensureVisible(slotChip);
      await tester.pumpAndSettle();
      await tester.tap(slotChip);
      await tester.pumpAndSettle();

      final choiceChip = tester.widget<ChoiceChip>(slotChip);
      expect(choiceChip.selected, isTrue);
    });

    testWidgets('validates required complaints field before submitting', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Submit without complaints
      final submitBtn = find.byKey(const Key('submit-booking-button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please describe the symptoms or reason for service'), findsOneWidget);
    });

    testWidgets('submits booking and displays confirmation dialog', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.physicalSize = const Size(1280, 1024);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Enter complaints
      final complaintsField = find.byKey(const Key('book-service-complaints-input'));
      await tester.ensureVisible(complaintsField);
      await tester.enterText(complaintsField, 'Brake vibration during highway deceleration');
      await tester.pumpAndSettle();

      // Submit
      final submitBtn = find.byKey(const Key('submit-booking-button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Booking Confirmed'), findsOneWidget);
      expect(find.byKey(const Key('booking-success-ok-button')), findsOneWidget);
    });
  });
}
