import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/core/utils/result.dart';
import 'package:pitmate/features/inspections/data/models/inspection_finding_model.dart';
import 'package:pitmate/features/inspections/data/models/inspection_model.dart';
import 'package:pitmate/features/inspections/data/models/service_order_telemetry.dart';
import 'package:pitmate/features/inspections/data/repositories/inspection_repository.dart';
import 'package:pitmate/features/mechanic/presentation/inspection_workspace_screen.dart';

class FakeInspectionRepository implements IInspectionRepository {
  FakeInspectionRepository({
    this.initialTelemetry,
    this.initialInspection,
    List<InspectionFinding>? initialFindings,
  }) : findings = initialFindings ?? [];

  final ServiceOrderTelemetry? initialTelemetry;
  final InspectionModel? initialInspection;
  final List<InspectionFinding> findings;

  String? lastSubmittedInspectionId;
  String? lastSubmittedSummary;
  bool submitCalled = false;

  @override
  Future<Result<InspectionModel?>> fetchInspectionByOrderId(String orderId) async {
    return Result.success(initialInspection);
  }

  @override
  Future<Result<InspectionModel?>> fetchInspectionById(String inspectionId) async {
    return Result.success(initialInspection);
  }

  @override
  Future<Result<List<InspectionFinding>>> fetchInspectionFindings(String inspectionId) async {
    return Result.success(List.unmodifiable(findings));
  }

  @override
  Future<Result<InspectionFinding>> saveFinding(InspectionFinding finding) async {
    findings.removeWhere((f) => f.id == finding.id || (f.category == finding.category && f.itemName == finding.itemName));
    findings.add(finding);
    return Result.success(finding);
  }

  @override
  Future<Result<void>> deleteFinding(String findingId) async {
    findings.removeWhere((f) => f.id == findingId);
    return const Result.success(null);
  }

  @override
  Future<Result<InspectionModel>> submitInspection(
    String inspectionId,
    String summary, {
    String? mechanicId,
  }) async {
    submitCalled = true;
    lastSubmittedInspectionId = inspectionId;
    lastSubmittedSummary = summary;

    final updated = (initialInspection ??
            InspectionModel(
              id: inspectionId,
              serviceOrderId: 'SO-2026-0143',
              status: InspectionStatus.inProgress,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ))
        .copyWith(
      status: InspectionStatus.completed,
      summary: summary,
      completedAt: DateTime.now(),
    );

    return Result.success(updated);
  }

  @override
  Future<Result<InspectionModel>> createOrGetInspection(
    String serviceOrderId, {
    String? mechanicId,
  }) async {
    final existing = initialInspection ??
        InspectionModel(
          id: 'insp-session-123',
          serviceOrderId: serviceOrderId,
          status: InspectionStatus.inProgress,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    return Result.success(existing);
  }

  @override
  Future<Result<ServiceOrderTelemetry?>> fetchOrderTelemetry(String orderId) async {
    final telemetry = initialTelemetry ??
        const ServiceOrderTelemetry(
          orderId: 'SO-2026-0143',
          orderNumber: 'SO-2026-0143',
          customerName: 'Alex Pratama',
          customerPhone: '+62 812-9988-7766',
          licensePlate: 'B 9912 SPO',
          make: 'Honda',
          model: 'Civic Type R (FL5)',
          year: 2023,
          odometer: 14250,
          customerComplaint:
              'Brake judder at high speeds, spongy pedal feel on deceleration',
          assignedBay: 'Bay 02 • Hoist B',
          fuelLevel: '75%',
          status: 'inspection_pending',
        );
    return Result.success(telemetry);
  }
}

void main() {
  Widget buildScreen(FakeInspectionRepository repo) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: InspectionWorkspaceScreen(
        serviceOrderId: 'SO-2026-0143',
        repository: repo,
      ),
    );
  }

  group('InspectionWorkspaceScreen (UI-M03)', () {
    testWidgets('renders vehicle telemetry header and checklist categories', (tester) async {
      final repo = FakeInspectionRepository();
      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      // Telemetry header
      expect(find.text('B 9912 SPO'), findsOneWidget);
      expect(find.text('2023 Honda Civic Type R (FL5)'), findsOneWidget);
      expect(find.text('14,250 KM'), findsOneWidget);
      expect(find.text('Alex Pratama'), findsOneWidget);
      expect(
        find.text('Brake judder at high speeds, spongy pedal feel on deceleration'),
        findsOneWidget,
      );

      // Categories
      expect(find.text('POWERTRAIN'), findsOneWidget);
      expect(find.text('BRAKES & SUSPENSION'), findsOneWidget);
      expect(find.text('ELECTRICAL & BATTERY'), findsOneWidget);
      expect(find.text('FLUIDS & FILTERS'), findsOneWidget);
      expect(find.text('TIRES & CHASSIS'), findsOneWidget);

      // First category items (Powertrain)
      expect(find.text('Engine Oil'), findsOneWidget);
      expect(find.text('Transmission'), findsOneWidget);
      expect(find.text('Coolant'), findsOneWidget);
      expect(find.text('Spark Plugs'), findsOneWidget);
    });

    testWidgets('condition and severity toggles update item diagnostic state', (tester) async {
      final repo = FakeInspectionRepository();
      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      // Tap Critical condition on Engine Oil
      final criticalBtn = find.byKey(const Key('condition-Engine Oil-Critical'));
      await tester.ensureVisible(criticalBtn);
      await tester.tap(criticalBtn);
      await tester.pumpAndSettle();

      // Severity buttons appear when condition != good
      expect(find.byKey(const Key('severity-Engine Oil-Urgent')), findsOneWidget);
      await tester.tap(find.byKey(const Key('severity-Engine Oil-Urgent')));
      await tester.pumpAndSettle();

      // Enter notes
      final notesField = find.byKey(const Key('notes-input-Engine Oil'));
      await tester.ensureVisible(notesField);
      await tester.enterText(notesField, 'Oil level below minimum dipstick marker.');
      await tester.pumpAndSettle();

      expect(find.text('Oil level below minimum dipstick marker.'), findsOneWidget);
    });

    testWidgets('enforces completeness check and blocks submit when categories untouched', (tester) async {
      final repo = FakeInspectionRepository();
      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      // Scroll to submit button
      final submitBtn = find.byKey(const Key('submit-inspection-button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Snack bar with error appears
      expect(find.textContaining('Cannot submit: Untouched categories'), findsOneWidget);
      expect(repo.submitCalled, isFalse);
    });

    testWidgets('submits inspection when all 5 categories are evaluated', (tester) async {
      final repo = FakeInspectionRepository();
      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      // Mark all good in each of the 5 categories
      const categories = [
        'Powertrain',
        'Brakes & Suspension',
        'Electrical & Battery',
        'Fluids & Filters',
        'Tires & Chassis',
      ];

      for (final cat in categories) {
        // Switch tab
        final tab = find.byKey(Key('category-tab-$cat'));
        await tester.ensureVisible(tab);
        await tester.tap(tab);
        await tester.pumpAndSettle();

        // Mark all good
        final markAll = find.byKey(Key('mark-all-good-$cat'));
        await tester.ensureVisible(markAll);
        await tester.tap(markAll);
        await tester.pumpAndSettle();
      }

      // Enter inspection summary
      final summaryField = find.byKey(const Key('inspection-summary-input'));
      await tester.ensureVisible(summaryField);
      await tester.enterText(
        summaryField,
        'Vehicle passed full engineering multi-point inspection. Ready for estimate.',
      );
      await tester.pumpAndSettle();

      // Submit
      final submitBtn = find.byKey(const Key('submit-inspection-button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify submit was invoked on repo and success dialog shown
      expect(repo.submitCalled, isTrue);
      expect(find.text('INSPECTION SUBMITTED'), findsOneWidget);
      expect(
        find.text(
          'Inspection diagnostics successfully submitted. Service order transitioned to ESTIMATE PENDING.',
        ),
        findsOneWidget,
      );
    });
  });
}
