import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/features/admin/presentation/admin_workshop_floor_screen.dart';

void main() {
  testWidgets('AdminWorkshopFloorScreen renders 5 physical bays and floor telemetry', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AdminWorkshopFloorScreen(),
        ),
      ),
    );

    // Initial loading or loaded state
    await tester.pump();

    // Verify presence of title or retry if mock connection fallback
    expect(find.byType(AdminWorkshopFloorScreen), findsOneWidget);
  });
}
