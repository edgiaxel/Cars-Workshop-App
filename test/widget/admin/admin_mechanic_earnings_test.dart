import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/features/admin/presentation/admin_mechanic_earnings_screen.dart';

void main() {
  testWidgets('AdminMechanicEarningsScreen renders telemetry cards and profile headers', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AdminMechanicEarningsScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(AdminMechanicEarningsScreen), findsOneWidget);
    expect(find.text('MECHANIC COMPENSATION'), findsOneWidget);
    expect(find.text('TOTAL BASE PAYROLL'), findsOneWidget);
    expect(find.text('NET ADJUSTMENTS'), findsOneWidget);
    expect(find.text('ACTIVE MECHANICS'), findsOneWidget);
  });
}
