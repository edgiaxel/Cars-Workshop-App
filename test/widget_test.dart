import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/main.dart';

void main() {
  testWidgets('PitMateApp boots with router and shows LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const PitMateApp());
    await tester.pumpAndSettle();

    expect(find.text('PITMATE'), findsWidgets);
    expect(find.text('Automotive Workshop Management'), findsOneWidget);
    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(find.byKey(const Key('login_password_field')), findsOneWidget);
    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
  });
}
