import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/main.dart';

void main() {
  testWidgets('PitMateApp boots with router and shows RoleHub', (WidgetTester tester) async {
    await tester.pumpWidget(const PitMateApp());
    await tester.pumpAndSettle();

    expect(find.text('PITMATE'), findsWidgets);
    expect(find.text('SELECT ROLE TO ENTER WORKSPACE'), findsOneWidget);
    expect(find.text('CUSTOMER GARAGE'), findsOneWidget);
    expect(find.text('ADMIN WORKSHOP DISPATCH'), findsOneWidget);
    expect(find.text('MECHANIC TELEMETRY'), findsOneWidget);
  });
}
