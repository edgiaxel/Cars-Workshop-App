import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/app.dart';

void main() {
  testWidgets('PitMateApp boots and displays M0 landing screen', (tester) async {
    await tester.pumpWidget(const PitMateApp());
    await tester.pumpAndSettle();

    expect(find.text('PitMate'), findsOneWidget);
    expect(find.text('PitMate Automotive Workshop OS'), findsOneWidget);
    expect(find.textContaining('Version 2.0.0-dev'), findsOneWidget);
    expect(find.text('Technical Foundation Status:'), findsOneWidget);
  });
}
