import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/auth/domain/user_profile.dart';
import 'package:pitmate/features/auth/domain/user_role.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/reports/data/reports_repository.dart';
import 'package:pitmate/features/reports/models/workshop_metrics_model.dart';
import 'package:pitmate/features/reports/presentation/admin_reports_screen.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

class FakeReportsRepository extends ReportsRepository {
  FakeReportsRepository({
    required this.daily,
    required this.monthly,
  });

  final WorkshopDailyMetrics daily;
  final WorkshopMonthlyMetrics monthly;

  @override
  Future<WorkshopDailyMetrics> fetchDailyMetrics([DateTime? date]) async => daily;

  @override
  Future<WorkshopMonthlyMetrics> fetchMonthlyMetrics([DateTime? month]) async => monthly;
}

void main() {
  const adminProfile = UserProfile(
    id: 'admin-1',
    role: UserRole.admin,
    fullName: 'Toto Wolf',
  );

  final sampleDaily = WorkshopDailyMetrics(
    reportDate: DateTime(2026, 11, 24),
    activeOrdersCount: 4,
    completedTodayCount: 2,
    totalBays: 5,
    baysOccupied: 1,
    bayOccupancyRate: 20.0,
    settledRevenueCents: 150000,
    outstandingReceivablesCents: 25000,
  );

  final sampleMonthly = WorkshopMonthlyMetrics(
    monthStart: DateTime(2026, 11, 1),
    monthEnd: DateTime(2026, 11, 30),
    totalOrdersCompleted: 12,
    grossRevenueCents: 550000,
    partsCogsCents: 120000,
    laborRevenueCents: 350000,
    grossMarginCents: 430000,
    topConsumedParts: const [
      TopPartMetric(
        sku: 'OIL-5W30',
        name: 'Full Synthetic Engine Oil',
        unitsConsumed: 15,
        totalCogsCents: 45000,
      ),
    ],
    mechanicWorkload: const [
      MechanicWorkloadMetric(
        mechanicId: 'm-1',
        fullName: 'Lewis Hamilton',
        completedTasksCount: 8,
        totalIncentiveCents: 75000,
      ),
    ],
  );

  testWidgets('AdminReportsScreen renders daily telemetry metrics and handles tab switching',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeRepo = FakeReportsRepository(
      daily: sampleDaily,
      monthly: sampleMonthly,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthAuthenticated(adminProfile)),
          ),
          reportsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: AdminReportsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Telemetry
    expect(find.text('Workshop Reports & Analytics'), findsOneWidget);
    expect(find.text('FINANCIAL TELEMETRY'), findsOneWidget);

    // Verify Daily KPI values
    expect(find.text('ACTIVE SERVICE ORDERS'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('COMPLETED TODAY'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('20.0%'), findsOneWidget);
    expect(find.text('Rp 1.500'), findsOneWidget);
    expect(find.text('Rp 250'), findsOneWidget);
    expect(find.text('1 Bays Engaged'), findsOneWidget);
    expect(find.text('4 Bays Available'), findsOneWidget);

    // Switch to Monthly tab
    await tester.tap(find.byKey(const Key('tab_monthly_reports')));
    await tester.pumpAndSettle();

    // Verify Monthly Financials & Breakdowns
    expect(find.text('MONTHLY FINANCIAL PERFORMANCE'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Rp 5.500'), findsOneWidget);
    expect(find.text('Rp 1.200'), findsOneWidget);
    expect(find.text('Rp 3.500'), findsOneWidget);
    expect(find.text('Rp 4.300'), findsOneWidget);

    // Verify Top Consumed Parts & Mechanic Workload
    expect(find.text('Full Synthetic Engine Oil'), findsOneWidget);
    expect(find.text('SKU: OIL-5W30'), findsOneWidget);
    expect(find.text('15 units'), findsOneWidget);
    expect(find.text('COGS: Rp 450'), findsOneWidget);

    expect(find.text('Lewis Hamilton'), findsOneWidget);
    expect(find.text('8 operations completed'), findsOneWidget);
    expect(find.text('Rp 750'), findsOneWidget);
  });
}
