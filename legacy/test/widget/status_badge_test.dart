import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_colors.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

void main() {
  testWidgets('StatusBadge displays label and applies badge color', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(
            label: 'IN PROGRESS',
            color: AppColors.statusInProgress,
          ),
        ),
      ),
    );

    expect(find.text('IN PROGRESS'), findsOneWidget);
    expect(find.byType(StatusBadge), findsOneWidget);
  });
}
