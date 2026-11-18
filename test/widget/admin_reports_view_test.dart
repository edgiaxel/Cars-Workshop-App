import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/data/models/report_telemetry.dart';
import 'package:pitmate/data/models/user_profile.dart';
import 'package:pitmate/data/models/user_role.dart';
import 'package:pitmate/features/admin/presentation/admin_reports_view.dart';
import 'package:pitmate/features/auth/domain/auth_session_state.dart';
import 'package:pitmate/shared/providers/auth_provider.dart';
import 'package:pitmate/shared/providers/report_provider.dart';

import '../helpers/fake_repositories.dart';

class _FakeAuthNotifier extends AuthSessionNotifier {
  _FakeAuthNotifier(this._state);
  final AuthSessionState _state;

  @override
  AuthSessionState build() => _state;
}

void main() {
  group('Phase 6 & Phase 7 Admin Reports View Widget Tests', () {
    const adminProfile = UserProfile(
      id: 'admin-1',
      role: UserRole.admin,
      fullName: 'Toto Wolff',
    );

    final testTelemetry = ReportTelemetryData(
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 31, 23, 59, 59),
      intakeBreakdown: const IntakeBreakdown(
        totalOrders: 30,
        bookingCount: 18,
        walkInCount: 9,
        legacyUnknownCount: 3,
      ),
      financialSummary: const FinancialSummary(
        estimatedTotal: 65000000.0,
        settledTotal: 48000000.0,
        settledOrdersCount: 22,
        pendingSettlementCount: 8,
      ),
      statusDistribution: const [
        StatusDistributionItem(status: 'completed', count: 22),
        StatusDistributionItem(status: 'in_progress', count: 5),
        StatusDistributionItem(status: 'diagnosing', count: 2),
        StatusDistributionItem(status: 'blocked', count: 1),
      ],
      volumeTimeline: const [
        VolumeTimelineItem(date: '2026-10-10', totalCount: 4, completedCount: 3),
        VolumeTimelineItem(date: '2026-10-11', totalCount: 6, completedCount: 5),
      ],
      mechanicWorkload: const [
        MechanicWorkloadItem(
          mechanicId: 'm1',
          mechanicName: 'Lewis Hamilton',
          employeeCode: 'TECH-44',
          specialization: 'Aerodynamics & Power Unit',
          assignedCount: 16,
          activeCount: 3,
          completedCount: 13,
        ),
        MechanicWorkloadItem(
          mechanicId: 'm2',
          mechanicName: 'George Russell',
          employeeCode: 'TECH-63',
          specialization: 'Brakes & Telemetry',
          assignedCount: 14,
          activeCount: 2,
          completedCount: 12,
        ),
      ],
    );

    Widget createTestWidget({ThemeMode themeMode = ThemeMode.dark}) {
      return ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            () => _FakeAuthNotifier(
              AuthSessionState.authenticated(
                userId: 'admin-1',
                email: 'admin@pitmate.co',
                profile: adminProfile,
              ),
            ),
          ),
          reportRepositoryProvider.overrideWithValue(
            FakeReportRepository(testTelemetry),
          ),
        ],
        child: MaterialApp(
          themeMode: themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: const AdminReportsPage(),
        ),
      );
    }

    testWidgets('Renders reports telemetry header and stat overview cards',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('WORKSHOP TELEMETRY & REPORTS'), findsOneWidget);
      expect(find.text('TOTAL VOLUME'), findsOneWidget);
      expect(find.text('30 Units'), findsOneWidget);
      expect(find.text('SETTLED REVENUE'), findsOneWidget);
      expect(find.text('PIPELINE ESTIMATE'), findsOneWidget);
      expect(find.text('ACTIVE TECHNICIANS'), findsOneWidget);
    });

    testWidgets('Renders date boundary toolbar and filter preset chips',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('Month to Date'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);
      expect(find.text('Custom Range'), findsOneWidget);

      // Tap 7 Days filter
      await tester.tap(find.text('7 Days'));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'Renders Intake Origin Comparison with active pre-booked and walk-in categories',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('INTAKE ORIGIN COMPARISON'), findsOneWidget);
      expect(find.text('PRE-BOOKED'), findsOneWidget);
      expect(find.text('WALK-IN ADMISSION'), findsOneWidget);
      expect(find.text('LEGACY / UNKNOWN'), findsNothing);

      expect(find.text('18 (60.0%)'), findsOneWidget);
      expect(find.text('9 (30.0%)'), findsOneWidget);
    });

    testWidgets(
        'Renders separate Financial Settlement and Pipeline Estimate sections',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
          find.text('FINANCIAL SETTLEMENT VS PIPELINE ESTIMATE'), findsOneWidget);
      expect(find.text('Settled Realized Revenue'), findsOneWidget);
      expect(find.text('Estimated Pipeline Total'), findsOneWidget);
      expect(find.text('AUDITED & REALIZED'), findsOneWidget);
      expect(find.text('WORK IN PROGRESS'), findsOneWidget);
    });

    testWidgets('Renders Mechanic Workload table with technicians and status counts',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('MECHANIC ALLOCATION & WORKLOAD'), findsOneWidget);
      expect(find.text('Lewis Hamilton'), findsOneWidget);
      expect(find.text('George Russell'), findsOneWidget);
      expect(find.text('Aerodynamics & Power Unit'), findsOneWidget);
      expect(find.text('Brakes & Telemetry'), findsOneWidget);
      expect(find.text('TECH-44'), findsOneWidget);
      expect(find.text('TECH-63'), findsOneWidget);
    });

    testWidgets('Export telemetry button opens modal dialog with telemetry summary',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final exportButton = find.text('EXPORT TELEMETRY');
      expect(exportButton, findsOneWidget);
      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      expect(find.text('REPORT TELEMETRY • REP-EXEC-2026'), findsOneWidget);
      expect(find.text('Executive Workshop Telemetry'), findsOneWidget);
      expect(find.text('Export Telemetry Packet'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('REPORT TELEMETRY • REP-EXEC-2026'), findsNothing);
    });

    testWidgets('Supports light mode rendering with legible contrast',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      await tester.pumpWidget(createTestWidget(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();

      expect(find.text('WORKSHOP TELEMETRY & REPORTS'), findsOneWidget);
      expect(find.text('Settled Realized Revenue'), findsOneWidget);
    });
  });
}
