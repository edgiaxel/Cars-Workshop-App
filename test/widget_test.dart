import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/app.dart';

void main() {
  testWidgets('Root widget smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PitMateApp());
    await tester.pumpAndSettle();

    expect(find.byType(PitMateApp), findsOneWidget);
  });
}
