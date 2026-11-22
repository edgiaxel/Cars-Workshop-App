import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/core/utils/result.dart';
import 'package:pitmate/features/admin/presentation/admin_inspection_review_screen.dart';
import 'package:pitmate/features/inspections/data/models/inspection_finding_model.dart';
import 'package:pitmate/features/inspections/data/models/inspection_model.dart';
import 'package:pitmate/features/inspections/data/models/service_order_telemetry.dart';
import 'package:pitmate/features/inspections/data/repositories/inspection_repository.dart';

class FakeAdminReviewRepository implements IInspectionRepository {
  FakeAdminReviewRepository({
    required this.telemetry,
    required this.inspection,
    required this.findings,
  });

  final ServiceOrderTelemetry telemetry;
  final InspectionModel inspection;
  final List<InspectionFinding> findings;

  @override
  Future<Result<InspectionModel?>> fetchInspectionByOrderId(String orderId) async {
    return Result.success(inspection);
  }

  @override
  Future<Result<InspectionModel?>> fetchInspectionById(String inspectionId) async {
    return Result.success(inspection);
  }

  @override
  Future<Result<List<InspectionFinding>>> fetchInspectionFindings(String inspectionId) async {
    return Result.success(findings);
  }

  @override
  Future<Result<InspectionFinding>> saveFinding(InspectionFinding finding) async {
    return Result.success(finding);
  }

  @override
  Future<Result<void>> deleteFinding(String findingId) async {
    return const Result.success(null);
  }

  @override
  Future<Result<InspectionModel>> submitInspection(
    String inspectionId,
    String summary, {
    String? mechanicId,
  }) async {
    return Result.success(inspection);
  }

  @override
  Future<Result<InspectionModel>> createOrGetInspection(
    String serviceOrderId, {
    String? mechanicId,
  }) async {
    return Result.success(inspection);
  }

  @override
  Future<Result<ServiceOrderTelemetry?>> fetchOrderTelemetry(String orderId) async {
    return Result.success(telemetry);
  }
}

void main() {
  final testTelemetry = const ServiceOrderTelemetry(
    orderId: 'so-101',
    orderNumber: 'SO-2026-0143',
    customerName: 'Alex Pratama',
    customerPhone: '+62 812-9988-7766',
    licensePlate: 'B 9912 SPO',
    make: 'Honda',
    model: 'Civic Type R (FL5)',
    year: 2023,
    odometer: 14250,
    customerComplaint: 'Brake judder at high speeds',
    assignedBay: 'Bay 02',
    status: 'estimate_pending',
  );

  final testInspection = InspectionModel(
    id: 'insp-101',
    serviceOrderId: 'so-101',
    mechanicId: 'mech-01',
    status: InspectionStatus.completed,
    summary: 'Front pads severely worn. Rotors glazed.',
    startedAt: DateTime.now().subtract(const Duration(hours: 2)),
    completedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
  );

  final testFindings = [
    InspectionFinding(
      id: 'f1',
      inspectionId: 'insp-101',
      category: 'Powertrain',
      itemName: 'Engine Oil',
      condition: FindingCondition.good,
      severity: SeverityLevel.low,
      notes: 'Oil level optimal',
      recommendedAction: 'None',
      createdAt: DateTime.now(),
    ),
    InspectionFinding(
      id: 'f2',
      inspectionId: 'insp-101',
      category: 'Brakes & Suspension',
      itemName: 'Front Brake Pads',
      condition: FindingCondition.critical,
      severity: SeverityLevel.urgent,
      notes: 'Pad thickness 2.5mm',
      recommendedAction: 'Replace with track/street compound pads',
      createdAt: DateTime.now(),
    ),
    InspectionFinding(
      id: 'f3',
      inspectionId: 'insp-101',
      category: 'Brakes & Suspension',
      itemName: 'Rotors',
      condition: FindingCondition.fair,
      severity: SeverityLevel.medium,
      notes: 'Surface heat scoring',
      recommendedAction: 'Skim rotors',
      createdAt: DateTime.now(),
    ),
  ];

  Widget buildScreen(FakeAdminReviewRepository repo, {VoidCallback? onCreateEstimate}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: AdminInspectionReviewScreen(
        serviceOrderId: 'so-101',
        inspectionId: 'insp-101',
        repository: repo,
        onCreateEstimate: onCreateEstimate,
      ),
    );
  }

  group('AdminInspectionReviewScreen (UI-A08)', () {
    testWidgets('renders telemetry header, summary counters, and findings', (tester) async {
      final repo = FakeAdminReviewRepository(
        telemetry: testTelemetry,
        inspection: testInspection,
        findings: testFindings,
      );

      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      // Header telemetry
      expect(find.text('B 9912 SPO'), findsOneWidget);
      expect(find.text('SO-2026-0143'), findsOneWidget);
      expect(find.text('2023 Honda Civic Type R (FL5)'), findsOneWidget);
      expect(find.text('Alex Pratama'), findsOneWidget);

      // Summary counters
      expect(find.text('TOTAL CHECKED'), findsOneWidget);
      expect(find.text('CRITICAL ITEMS'), findsOneWidget);
      expect(find.text('FAIR ITEMS'), findsOneWidget);
      expect(find.text('GOOD ITEMS'), findsOneWidget);

      expect(find.text('3'), findsOneWidget); // Total
      expect(find.text('1'), findsNWidgets(3)); // 1 Critical, 1 Fair, 1 Good

      // Master summary
      expect(find.text('Front pads severely worn. Rotors glazed.'), findsOneWidget);

      // Findings list
      expect(find.text('Engine Oil'), findsOneWidget);
      expect(find.text('Front Brake Pads'), findsOneWidget);
      expect(find.text('Rotors'), findsOneWidget);
      expect(find.text('Action: Replace with track/street compound pads'), findsOneWidget);
    });

    testWidgets('filters findings based on selected tab', (tester) async {
      final repo = FakeAdminReviewRepository(
        telemetry: testTelemetry,
        inspection: testInspection,
        findings: testFindings,
      );

      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      // Tap CRITICAL filter tab
      final criticalTab = find.byKey(const Key('filter-tab-CRITICAL'));
      await tester.tap(criticalTab);
      await tester.pumpAndSettle();

      // Only Front Brake Pads (critical) visible
      expect(find.text('Front Brake Pads'), findsOneWidget);
      expect(find.text('Engine Oil'), findsNothing);
      expect(find.text('Rotors'), findsNothing);

      // Tap GOOD filter tab
      final goodTab = find.byKey(const Key('filter-tab-GOOD'));
      await tester.tap(goodTab);
      await tester.pumpAndSettle();

      expect(find.text('Engine Oil'), findsOneWidget);
      expect(find.text('Front Brake Pads'), findsNothing);
    });

    testWidgets('triggers create estimate action when button is pressed', (tester) async {
      bool createEstimateCalled = false;
      final repo = FakeAdminReviewRepository(
        telemetry: testTelemetry,
        inspection: testInspection,
        findings: testFindings,
      );

      await tester.pumpWidget(buildScreen(
        repo,
        onCreateEstimate: () => createEstimateCalled = true,
      ));
      await tester.pumpAndSettle();

      final estimateBtn = find.byKey(const Key('create-estimate-button'));
      await tester.ensureVisible(estimateBtn);
      await tester.tap(estimateBtn);
      await tester.pumpAndSettle();

      expect(createEstimateCalled, isTrue);
    });
  });
}
