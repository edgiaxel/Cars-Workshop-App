import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/app.dart';

void main() {
  testWidgets('PitMate App smoke test and landing page navigation', (
    WidgetTester tester,
  ) async {
    // Build our app wrapped in Riverpod ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: PitMateApp()));
    await tester.pumpAndSettle();

    // Verify that the Landing Page is displayed
    expect(find.text('PITMATE'), findsWidgets);
    expect(find.text('MOTORSPORT GARAGE OS'), findsOneWidget);
    expect(find.text('Precision Workshop Management'), findsOneWidget);
    expect(find.text('ACCESS PORTAL'), findsOneWidget);
    expect(find.text('About PitMate'), findsOneWidget);
    expect(find.text('OPERATIONAL TERMINALS'), findsOneWidget);

    // Tap the 'About PitMate' button and navigate to /about
    await tester.tap(find.text('About PitMate'));
    await tester.pumpAndSettle();

    // Verify that the About Page is displayed
    expect(find.text('About PitMate'), findsWidgets);
    expect(find.text('ARCHITECTURE SPECS'), findsOneWidget);

    // Tap back button to return to Landing
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Verify back on landing page
    expect(find.text('ACCESS PORTAL'), findsOneWidget);

    // Tap 'ACCESS PORTAL' to navigate to /login
    await tester.tap(find.text('ACCESS PORTAL'));
    await tester.pumpAndSettle();

    // Verify that Login Page is displayed
    expect(find.text('Access Workshop Portal'), findsOneWidget);
    expect(find.text('CREDENTIALS'), findsOneWidget);
  });
}
