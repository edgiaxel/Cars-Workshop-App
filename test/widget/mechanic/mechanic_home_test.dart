import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/features/mechanic/presentation/mechanic_home_screen.dart';

void main() {
  Widget buildMechanicScreen() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: const MechanicHomeScreen(),
    );
  }

  group('MechanicHomeScreen', () {
    testWidgets('renders shift telemetry header and metrics', (tester) async {
      await tester.pumpWidget(buildMechanicScreen());
      await tester.pumpAndSettle();

      expect(find.text('GOOD MORNING, DIAN S.'), findsOneWidget);
      expect(find.text('ACTIVE SHIFT'), findsOneWidget);
      expect(find.text('Bay 02 • Hoist B'), findsWidgets);
      expect(find.text('Morning Shift (08:00 – 17:00)'), findsOneWidget);

      // Workload metrics
      expect(find.text('ASSIGNED'), findsOneWidget);
      expect(find.text('IN PROGRESS'), findsWidgets);
      expect(find.text('ON HOLD'), findsOneWidget);
      expect(find.text('PASSED QC'), findsOneWidget);
    });

    testWidgets('renders active job and queued jobs', (tester) async {
      await tester.pumpWidget(buildMechanicScreen());
      await tester.pumpAndSettle();

      // Active job
      expect(find.text('SO-2026-0143'), findsOneWidget);
      expect(find.text('Honda Civic Type R (FL5)'), findsOneWidget);
      expect(find.text('B 9912 SPO'), findsWidgets);
      expect(find.text('Brake Rotor & Pad Bedding + High-Temp Fluid Flush'), findsOneWidget);
      expect(find.text('3 of 5 (60%)'), findsOneWidget);
      expect(find.text('OPEN ACTIVE JOB WORKSPACE'), findsOneWidget);

      // Queue
      expect(find.text('ASSIGNED JOBS QUEUE'), findsOneWidget);
      expect(find.text('SO-2026-0144'), findsOneWidget);
      expect(find.text('B 3021 RFS'), findsWidgets);
      expect(find.text('SO-2026-0140'), findsOneWidget);
      expect(find.text('B 1555 ZT'), findsWidgets);
    });
  });
}
