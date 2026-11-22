import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/main.dart';

void main() {
  testWidgets('PitMateApp smoke test verifies launch screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PitMateApp());
    await tester.pumpAndSettle();

    expect(find.text('PITMATE'), findsOneWidget);
    expect(find.text('PitMate Automotive Workshop'), findsOneWidget);
    expect(find.text('Clean Development Foundation (M0)'), findsOneWidget);
  });
}
