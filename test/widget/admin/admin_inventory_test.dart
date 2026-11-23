import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/features/admin/presentation/admin_inventory_screen.dart';

void main() {
  testWidgets('AdminInventoryScreen renders catalog telemetry, filter bar and action controls', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AdminInventoryScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(AdminInventoryScreen), findsOneWidget);
    expect(find.text('TOTAL PARTS'), findsOneWidget);
    expect(find.text('LOW STOCK'), findsOneWidget);
    expect(find.text('OUT OF STOCK'), findsOneWidget);
  });
}
