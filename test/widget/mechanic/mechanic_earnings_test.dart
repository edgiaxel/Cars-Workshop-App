import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/features/mechanic/presentation/mechanic_earnings_screen.dart';

void main() {
  testWidgets('MechanicEarningsScreen renders estimated monthly earnings card and ledger', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MechanicEarningsScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(MechanicEarningsScreen), findsOneWidget);
    expect(find.text('MECHANIC COMPENSATION'), findsOneWidget);
    expect(find.text('ESTIMATED MONTHLY EARNINGS'), findsOneWidget);
    expect(find.text('BASE SALARY'), findsOneWidget);
    expect(find.text('ACCRUED INCENTIVES'), findsOneWidget);
  });
}
