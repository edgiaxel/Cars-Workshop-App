import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/core/utils/result.dart';
import 'package:pitmate/features/quality_control/data/models/qc_inspection_model.dart';
import 'package:pitmate/features/quality_control/data/repositories/qc_repository.dart';
import 'package:pitmate/features/quality_control/presentation/admin_qc_screen.dart';
import 'package:pitmate/features/service_orders/data/models/service_order_model.dart';

class FakeQcRepository implements IQcRepository {
  FakeQcRepository({
    this.pendingOrders = const [],
    this.inspection,
  });

  List<ServiceOrderModel> pendingOrders;
  QcInspectionModel? inspection;

  bool recordQcResultCalled = false;
  QcStatus? lastRecordedStatus;
  String? lastFailureReason;
  List<QcChecklistItemModel>? lastRecordedItems;

  bool returnToRepairCalled = false;
  String? lastCorrectionNotes;

  @override
  Future<Result<List<ServiceOrderModel>>> fetchQcPendingOrders() async {
    return Result.success(pendingOrders);
  }

  @override
  Future<Result<QcInspectionModel?>> fetchActiveInspectionForOrder(String orderId) async {
    return Result.success(inspection);
  }

  @override
  Future<Result<QcInspectionModel?>> fetchInspectionById(String inspectionId) async {
    return Result.success(inspection);
  }

  @override
  Future<Result<String>> submitOrderForQc({
    required String serviceOrderId,
    required String inspectorId,
  }) async {
    return const Result.success('qc-new-1');
  }

  @override
  Future<Result<bool>> recordQcResult({
    required String qcInspectionId,
    required QcStatus status,
    String? notes,
    String? failureReason,
    List<QcChecklistItemModel>? items,
  }) async {
    recordQcResultCalled = true;
    lastRecordedStatus = status;
    lastFailureReason = failureReason;
    lastRecordedItems = items;
    if (inspection != null) {
      inspection = inspection!.copyWith(
        status: status,
        notes: notes,
        failureReason: failureReason,
        items: items,
      );
    }
    return const Result.success(true);
  }

  @override
  Future<Result<bool>> returnToRepairFromQc({
    required String qcInspectionId,
    required String correctionNotes,
  }) async {
    returnToRepairCalled = true;
    lastCorrectionNotes = correctionNotes;
    if (inspection != null) {
      inspection = inspection!.copyWith(
        status: QcStatus.failed,
        failureReason: correctionNotes,
        correctionNotes: correctionNotes,
      );
    }
    return const Result.success(true);
  }
}

void main() {
  final testOrder = ServiceOrderModel(
    id: 'so-101',
    orderNumber: 'SO-2026-0045',
    customerId: 'cust-1',
    vehicleId: 'veh-1',
    odometer: 32500,
    customerComplaint: 'Brake pads replacement and full oil service',
    assignedBay: 'Bay 02',
    status: 'qc_pending',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
    customerName: 'Budi Santoso',
    customerPhone: '+62 812-3456-7890',
    vehiclePlate: 'B 1234 SPO',
    vehicleMake: 'Honda',
    vehicleModel: 'Civic Type R',
  );

  final testItems = [
    const QcChecklistItemModel(
      id: 'item-mech-1',
      qcInspectionId: 'qc-101',
      category: 'Mechanical',
      itemName: 'Braking system test & pedal firmness',
      isPassed: true,
    ),
    const QcChecklistItemModel(
      id: 'item-fluid-1',
      qcInspectionId: 'qc-101',
      category: 'Fluids',
      itemName: 'Engine oil, coolant & brake fluid levels',
      isPassed: true,
    ),
    const QcChecklistItemModel(
      id: 'item-elec-1',
      qcInspectionId: 'qc-101',
      category: 'Electrical',
      itemName: 'Headlights, indicators & battery terminals',
      isPassed: false,
    ),
    const QcChecklistItemModel(
      id: 'item-safe-1',
      qcInspectionId: 'qc-101',
      category: 'Safety',
      itemName: 'Torque spec verification on wheel nuts',
      isPassed: true,
    ),
    const QcChecklistItemModel(
      id: 'item-cosm-1',
      qcInspectionId: 'qc-101',
      category: 'Cosmetics',
      itemName: 'Vehicle clean, floor mats & protective film removed',
      isPassed: false,
    ),
  ];

  final testInspection = QcInspectionModel(
    id: 'qc-101',
    serviceOrderId: 'so-101',
    inspectorId: 'insp-1',
    status: QcStatus.inProgress,
    notes: 'Initial road test done',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
    items: testItems,
    orderNumber: 'SO-2026-0045',
    customerName: 'Budi Santoso',
    customerPhone: '+62 812-3456-7890',
    vehiclePlate: 'B 1234 SPO',
    vehicleMake: 'Honda',
    vehicleModel: 'Civic Type R',
    serviceOrder: testOrder,
  );

  Widget buildScreen(FakeQcRepository repo, {String? serviceOrderId}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: AdminQcScreen(
          repository: repo,
          serviceOrderId: serviceOrderId,
        ),
      ),
    );
  }

  group('AdminQcScreen Widget Tests', () {
    testWidgets('renders empty state when no orders are in qc_pending', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeQcRepository(pendingOrders: []);

      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      expect(find.text('No Orders Awaiting Quality Control'), findsOneWidget);
      expect(find.text('REFRESH QUEUE'), findsOneWidget);
    });

    testWidgets('renders pending orders queue and active checklist items', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeQcRepository(
        pendingOrders: [testOrder],
        inspection: testInspection,
      );

      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      // Verify order queue
      expect(find.text('SO-2026-0045'), findsWidgets);
      expect(find.text('Budi Santoso'), findsWidgets);
      expect(find.text('Honda Civic Type R [B 1234 SPO]'), findsWidgets);

      // Verify 5 categories
      expect(find.text('MECHANICAL'), findsOneWidget);
      expect(find.text('FLUIDS'), findsOneWidget);
      expect(find.text('ELECTRICAL'), findsOneWidget);
      expect(find.text('SAFETY'), findsOneWidget);
      expect(find.text('COSMETICS'), findsOneWidget);

      // Verify checklist items
      expect(find.text('Braking system test & pedal firmness'), findsOneWidget);
      expect(find.text('Engine oil, coolant & brake fluid levels'), findsOneWidget);
      expect(find.text('Headlights, indicators & battery terminals'), findsOneWidget);
      expect(find.text('Torque spec verification on wheel nuts'), findsOneWidget);
      expect(find.text('Vehicle clean, floor mats & protective film removed'), findsOneWidget);

      // Verify buttons
      expect(find.byKey(const Key('qc_pass_button')), findsOneWidget);
      expect(find.byKey(const Key('qc_fail_return_button')), findsOneWidget);
    });

    testWidgets('toggling checklist item updates pass status', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeQcRepository(
        pendingOrders: [testOrder],
        inspection: testInspection,
      );

      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      // Electrical item is initially failed; scroll to and tap PASS on it
      final passToggleKey = const Key('qc_toggle_pass_item-elec-1');
      await tester.ensureVisible(find.byKey(passToggleKey));
      await tester.tap(find.byKey(passToggleKey));
      await tester.pumpAndSettle();

      // Cosmetics item is initially failed; scroll to and tap PASS on it
      final cosmPassKey = const Key('qc_toggle_pass_item-cosm-1');
      await tester.ensureVisible(find.byKey(cosmPassKey));
      await tester.tap(find.byKey(cosmPassKey));
      await tester.pumpAndSettle();

      // Completion text should now indicate 5 OF 5 VERIFIED (100%)
      expect(find.text('CHECKLIST COMPLETION: 5 OF 5 VERIFIED'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('pass quality control records passed result when all items pass', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Inspection where all items are passed
      final allPassedItems = testItems.map((i) => i.copyWith(isPassed: true)).toList();
      final allPassedInspection = testInspection.copyWith(items: allPassedItems);

      final repo = FakeQcRepository(
        pendingOrders: [testOrder],
        inspection: allPassedInspection,
      );

      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      final passButton = find.byKey(const Key('qc_pass_button'));
      await tester.ensureVisible(passButton);
      await tester.tap(passButton);
      await tester.pumpAndSettle();

      expect(repo.recordQcResultCalled, isTrue);
      expect(repo.lastRecordedStatus, QcStatus.passed);
    });

    testWidgets('fail and return to repair opens dialog and calls returnToRepairFromQc', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = FakeQcRepository(
        pendingOrders: [testOrder],
        inspection: testInspection,
      );

      await tester.pumpWidget(buildScreen(repo));
      await tester.pumpAndSettle();

      final returnButton = find.byKey(const Key('qc_fail_return_button'));
      await tester.ensureVisible(returnButton);
      await tester.tap(returnButton);
      await tester.pumpAndSettle();

      // Dialog is open
      expect(find.text('FAIL & RETURN TO REPAIR'), findsWidgets);
      expect(find.byKey(const Key('qc_correction_notes_input')), findsOneWidget);

      // Enter defect notes
      await tester.enterText(
        find.byKey(const Key('qc_correction_notes_input')),
        'Left headlight indicator wiring loose. Fix connection.',
      );
      await tester.pumpAndSettle();

      // Tap confirm button
      await tester.tap(find.byKey(const Key('qc_confirm_return_button')));
      await tester.pumpAndSettle();

      expect(repo.returnToRepairCalled, isTrue);
      expect(repo.lastCorrectionNotes, 'Left headlight indicator wiring loose. Fix connection.');
    });
  });
}
