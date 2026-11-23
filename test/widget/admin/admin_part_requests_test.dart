import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitmate/features/admin/presentation/admin_part_requests_screen.dart';

void main() {
  testWidgets('AdminPartRequestsScreen renders filter bar and telemetry layout', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AdminPartRequestsScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(AdminPartRequestsScreen), findsOneWidget);
    expect(find.text('FLOOR PART COORDINATION'), findsOneWidget);
    expect(find.text('FILTER:'), findsOneWidget);
    expect(find.text('PENDING'), findsWidgets);
  });
}
