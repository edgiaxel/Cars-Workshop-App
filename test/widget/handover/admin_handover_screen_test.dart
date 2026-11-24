import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/core/utils/result.dart';
import 'package:pitmate/features/handover/data/models/vehicle_handover_model.dart';
import 'package:pitmate/features/handover/data/repositories/handover_repository.dart';
import 'package:pitmate/features/handover/presentation/admin_handover_screen.dart';

class FakeHandoverRepository implements IHandoverRepository {
  FakeHandoverRepository({
    List<HandoverOrderCandidate>? pendingQueue,
    List<HandoverOrderCandidate>? historyQueue,
  })  : pending = pendingQueue ?? [],
        history = historyQueue ?? [];

  List<HandoverOrderCandidate> pending;
  List<HandoverOrderCandidate> history;

  bool recordCalled = false;
  String? lastOrderId;
  String? lastAdminId;
  HandoverChecklist? lastChecklist;
  bool? lastCustomerConfirmed;
  String? lastNotes;
  String? lastOverrideReason;

  @override
  Future<Result<List<HandoverOrderCandidate>>> fetchHandoverQueue() async {
    return Result.success(pending);
  }

  @override
  Future<Result<List<HandoverOrderCandidate>>> fetchHandoverHistory() async {
    return Result.success(history);
  }

  @override
  Future<Result<VehicleHandoverModel?>> fetchHandoverByOrderId(
      String orderId) async {
    return const Result.success(null);
  }

  @override
  Future<Result<VehicleHandoverModel>> recordVehicleHandover({
    required String serviceOrderId,
    required String adminId,
    required HandoverChecklist checklist,
    bool customerConfirmed = true,
    String? notes,
    String? paymentOverrideReason,
  }) async {
    recordCalled = true;
    lastOrderId = serviceOrderId;
    lastAdminId = adminId;
    lastChecklist = checklist;
    lastCustomerConfirmed = customerConfirmed;
    lastNotes = notes;
    lastOverrideReason = paymentOverrideReason;

    final created = VehicleHandoverModel(
      id: 'ho-created-1',
      serviceOrderId: serviceOrderId,
      customerId: 'cust-1',
      responsibleAdminId: adminId,
      handoverTimestamp: DateTime.now(),
      customerConfirmed: customerConfirmed,
      paymentOverrideReason: paymentOverrideReason,
      checklist: checklist,
      notes: notes,
      createdAt: DateTime.now(),
    );

    final foundIndex = pending.indexWhere((o) => o.orderId == serviceOrderId);
    if (foundIndex != -1) {
      final removed = pending.removeAt(foundIndex);
      history.add(
        HandoverOrderCandidate(
          orderId: removed.orderId,
          orderNumber: removed.orderNumber,
          status: 'closed',
          customerId: removed.customerId,
          customerName: removed.customerName,
          vehicleId: removed.vehicleId,
          vehiclePlate: removed.vehiclePlate,
          vehicleMake: removed.vehicleMake,
          vehicleModel: removed.vehicleModel,
          odometer: removed.odometer,
          createdAt: removed.createdAt,
          updatedAt: DateTime.now(),
          invoiceId: removed.invoiceId,
          invoiceNumber: removed.invoiceNumber,
          invoiceStatus: removed.invoiceStatus,
          totalAmountCents: removed.totalAmountCents,
          amountPaidCents: removed.amountPaidCents,
          outstandingBalanceCents: removed.outstandingBalanceCents,
          handover: created,
        ),
      );
    }

    return Result.success(created);
  }
}

void main() {
  late HandoverOrderCandidate paidOrder;
  late HandoverOrderCandidate unpaidOrder;
  late HandoverOrderCandidate historyOrder;

  setUp(() {
    paidOrder = HandoverOrderCandidate(
      orderId: 'so-001',
      orderNumber: 'SO-20261124-001',
      status: 'completed',
      customerId: 'cust-001',
      customerName: 'Marcus Ericsson',
      customerPhone: '+62811223344',
      vehicleId: 'veh-001',
      vehiclePlate: 'B 99 PIT',
      vehicleMake: 'BMW',
      vehicleModel: 'M3 Competition',
      vehicleYear: 2023,
      odometer: 18500,
      customerComplaint: 'Brake fluid flush and inspection',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      invoiceId: 'inv-001',
      invoiceNumber: 'INV-20261124-001',
      invoiceStatus: 'paid',
      totalAmountCents: 450000000,
      amountPaidCents: 450000000,
      outstandingBalanceCents: 0,
    );

    unpaidOrder = HandoverOrderCandidate(
      orderId: 'so-002',
      orderNumber: 'SO-20261124-002',
      status: 'completed',
      customerId: 'cust-002',
      customerName: 'Carlos Sainz',
      customerPhone: '+62899887766',
      vehicleId: 'veh-002',
      vehiclePlate: 'B 55 CS',
      vehicleMake: 'Williams',
      vehicleModel: 'FW46 Show Car',
      odometer: 5200,
      customerComplaint: 'Gearbox hydraulic check',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      invoiceId: 'inv-002',
      invoiceNumber: 'INV-20261124-002',
      invoiceStatus: 'issued',
      totalAmountCents: 350000000,
      amountPaidCents: 0,
      outstandingBalanceCents: 350000000,
    );

    historyOrder = HandoverOrderCandidate(
      orderId: 'so-000',
      orderNumber: 'SO-20261123-099',
      status: 'closed',
      customerId: 'cust-000',
      customerName: 'Niki Lauda',
      vehicleId: 'veh-000',
      vehiclePlate: 'B 1 NIKI',
      vehicleMake: 'Ferrari',
      vehicleModel: '312T',
      odometer: 1200,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      invoiceId: 'inv-000',
      invoiceNumber: 'INV-20261123-009',
      invoiceStatus: 'paid',
      totalAmountCents: 800000000,
      amountPaidCents: 800000000,
      outstandingBalanceCents: 0,
      handover: VehicleHandoverModel(
        id: 'ho-archived',
        serviceOrderId: 'so-000',
        customerId: 'cust-000',
        responsibleAdminId: 'adm-0',
        handoverTimestamp: DateTime.now().subtract(const Duration(days: 1)),
        customerConfirmed: true,
        checklist: const HandoverChecklist(),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );
  });

  Widget createTestWidget(IHandoverRepository repo) {
    return ProviderScope(
      overrides: [
        handoverRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        home: AdminHandoverScreen(repository: repo),
      ),
    );
  }

  testWidgets(
      'AdminHandoverScreen renders queue with pending orders and payment status',
      (tester) async {
    final fakeRepo = FakeHandoverRepository(
      pendingQueue: [paidOrder, unpaidOrder],
      historyQueue: [historyOrder],
    );

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget(fakeRepo));
    await tester.pumpAndSettle();

    expect(find.text('Vehicle Handover & Delivery Verification'),
        findsOneWidget);
    expect(find.text('2 READY FOR HANDOVER'), findsOneWidget);

    expect(find.text('SO-20261124-001'), findsOneWidget);
    expect(find.text('B 99 PIT'), findsOneWidget);
    expect(find.text('PAID IN FULL'), findsOneWidget);

    expect(find.text('SO-20261124-002'), findsOneWidget);
    expect(find.text('B 55 CS'), findsOneWidget);
    expect(find.textContaining('UNPAID:'), findsOneWidget);
  });

  testWidgets(
      'Selecting paid order displays 4 checklist items and allows handover completion',
      (tester) async {
    final fakeRepo = FakeHandoverRepository(
      pendingQueue: [paidOrder],
    );

    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget(fakeRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Process Handover'));
    await tester.pumpAndSettle();

    expect(find.text('Pre-Delivery Handover Checklist'), findsOneWidget);
    expect(find.text('Vehicle Cleaned & Sanitized'), findsOneWidget);
    expect(find.text('Personal Belongings Returned'), findsOneWidget);
    expect(find.text('Old / Replaced Parts Handled'), findsOneWidget);
    expect(find.text('Ignition Keys & Fob Returned'), findsOneWidget);

    expect(find.text('Customer Handover Acknowledged'), findsOneWidget);

    expect(find.text('Invoice is fully settled. No payment override required.'),
        findsOneWidget);

    final buttonFinder =
        find.text('Complete Handover & Close Service Order');
    await tester.ensureVisible(buttonFinder);
    await tester.pumpAndSettle();

    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(fakeRepo.recordCalled, isTrue);
    expect(fakeRepo.lastOrderId, equals('so-001'));
    expect(fakeRepo.lastChecklist?.isComplete, isTrue);
    expect(fakeRepo.lastCustomerConfirmed, isTrue);
    expect(fakeRepo.lastOverrideReason, isNull);

    expect(find.textContaining('handed over successfully'), findsOneWidget);
  });

  testWidgets(
      'Unpaid order enforces payment override reason before enabling handover',
      (tester) async {
    final fakeRepo = FakeHandoverRepository(
      pendingQueue: [unpaidOrder],
    );

    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget(fakeRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Process Handover'));
    await tester.pumpAndSettle();

    expect(find.text('Payment Incomplete: Authorized Override Required'),
        findsOneWidget);
    expect(find.text('Payment Override Reason *'), findsOneWidget);

    final buttonFinder = find.widgetWithText(
        ElevatedButton, 'Complete Handover & Close Service Order');
    await tester.ensureVisible(buttonFinder);
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNull);

    final overrideFieldFinder =
        find.widgetWithText(TextFormField, 'Payment Override Reason *');
    await tester.ensureVisible(overrideFieldFinder);
    await tester.pumpAndSettle();

    await tester.enterText(
      overrideFieldFinder,
      'Corporate Net-30 invoice agreement authorized by Toto',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(buttonFinder);
    await tester.pumpAndSettle();

    final updatedButton = tester.widget<ElevatedButton>(buttonFinder);
    expect(updatedButton.onPressed, isNotNull);

    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(fakeRepo.recordCalled, isTrue);
    expect(fakeRepo.lastOrderId, equals('so-002'));
    expect(fakeRepo.lastOverrideReason,
        equals('Corporate Net-30 invoice agreement authorized by Toto'));
  });

  testWidgets(
      'Unchecking checklist item disables handover button until re-checked',
      (tester) async {
    final fakeRepo = FakeHandoverRepository(
      pendingQueue: [paidOrder],
    );

    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget(fakeRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Process Handover'));
    await tester.pumpAndSettle();

    final buttonFinder = find.widgetWithText(
        ElevatedButton, 'Complete Handover & Close Service Order');
    await tester.ensureVisible(buttonFinder);
    await tester.pumpAndSettle();

    var button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNotNull);

    final itemFinder = find.text('Vehicle Cleaned & Sanitized');
    await tester.ensureVisible(itemFinder);
    await tester.pumpAndSettle();
    await tester.tap(itemFinder);
    await tester.pumpAndSettle();

    await tester.ensureVisible(buttonFinder);
    await tester.pumpAndSettle();
    button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNull);
    expect(find.text('CHECKLIST INCOMPLETE'), findsOneWidget);

    final verifyAllFinder = find.text('Verify All');
    await tester.ensureVisible(verifyAllFinder);
    await tester.pumpAndSettle();
    await tester.tap(verifyAllFinder);
    await tester.pumpAndSettle();

    await tester.ensureVisible(buttonFinder);
    await tester.pumpAndSettle();
    button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNotNull);
    expect(find.text('ALL 4 ITEMS VERIFIED'), findsOneWidget);
  });

  testWidgets('Switching between Ready for Handover and Handover History tabs',
      (tester) async {
    final fakeRepo = FakeHandoverRepository(
      pendingQueue: [paidOrder],
      historyQueue: [historyOrder],
    );

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createTestWidget(fakeRepo));
    await tester.pumpAndSettle();

    expect(find.text('SO-20261124-001'), findsOneWidget);
    expect(find.text('SO-20261123-099'), findsNothing);

    await tester.tap(find.text('Handover History (1)'));
    await tester.pumpAndSettle();

    expect(find.text('SO-20261123-099'), findsOneWidget);
    expect(find.text('B 1 NIKI'), findsOneWidget);
  });
}
