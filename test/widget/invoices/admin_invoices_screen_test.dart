import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/core/utils/result.dart';
import 'package:pitmate/features/invoices/data/models/invoice_model.dart';
import 'package:pitmate/features/invoices/data/repositories/invoice_repository.dart';
import 'package:pitmate/features/invoices/presentation/admin_invoices_screen.dart';

class _FakeInvoiceRepository implements IInvoiceRepository {
  _FakeInvoiceRepository(this.invoices);

  List<InvoiceModel> invoices;

  @override
  Future<Result<List<InvoiceModel>>> fetchInvoices({
    String? customerId,
    InvoiceStatus? statusFilter,
  }) async {
    return Result.success(invoices);
  }

  @override
  Future<Result<InvoiceModel?>> fetchInvoiceById(String invoiceId) async {
    final inv = invoices.where((i) => i.id == invoiceId).firstOrNull;
    return Result.success(inv);
  }

  @override
  Future<Result<InvoiceModel?>> fetchInvoiceByOrderId(String orderId) async {
    final inv = invoices.where((i) => i.serviceOrderId == orderId).firstOrNull;
    return Result.success(inv);
  }

  @override
  Future<Result<String>> recordRefund({
    required String paymentId,
    required int refundAmountCents,
    required String refundReason,
  }) async {
    return const Result.success('ref-001');
  }

  @override
  Future<Result<List<InvoiceItemModel>>> fetchInvoiceItems(String invoiceId) async {
    final inv = invoices.where((i) => i.id == invoiceId).firstOrNull;
    return Result.success(inv?.items ?? []);
  }

  @override
  Future<Result<List<PaymentModel>>> fetchInvoicePayments(String invoiceId) async {
    final inv = invoices.where((i) => i.id == invoiceId).firstOrNull;
    return Result.success(inv?.payments ?? []);
  }

  @override
  Future<Result<String>> generateInvoice({
    required String serviceOrderId,
    double taxPercent = 11.0,
    int discountCents = 0,
    int depositCents = 0,
    int insuranceCents = 0,
    String? adminId,
  }) async {
    return const Result.success('new-inv-uuid');
  }

  @override
  Future<Result<String>> recordPayment({
    required String invoiceId,
    required int amountCents,
    required PaymentMethod paymentMethod,
    String? referenceNumber,
    int? cashTenderedCents,
    int changeCents = 0,
    String? adminId,
  }) async {
    return const Result.success('new-pay-uuid');
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> fetchEligibleServiceOrdersForInvoice() async {
    return Result.success([
      {
        'id': 'so-uuid-1',
        'order_number': 'SO-202611-0001',
        'status': 'completed',
        'customers': {'full_name': 'Alex Pratama'},
        'vehicles': {'license_plate': 'B 5678 CIV'},
      }
    ]);
  }
}

void main() {
  final now = DateTime.now();
  final sampleInvoices = [
    InvoiceModel(
      id: 'inv-1',
      invoiceNumber: 'INV-20261124-1001',
      serviceOrderId: 'so-1',
      customerId: 'cust-1',
      status: InvoiceStatus.issued,
      subtotalLaborCents: 50000000, // Rp 500.000
      subtotalPartsCents: 265000000, // Rp 2.650.000
      taxPercent: 11.0,
      taxAmountCents: 34650000, // Rp 346.500
      discountCents: 0,
      depositAppliedCents: 0,
      insuranceCoverageCents: 0,
      totalAmountCents: 349650000, // Rp 3.496.500
      amountPaidCents: 0,
      outstandingBalanceCents: 349650000,
      createdAt: now,
      updatedAt: now,
      customerName: 'Alex Pratama',
      customerPhone: '+62 812-3456-7890',
      vehiclePlate: 'B 5678 CIV',
      vehicleModel: 'Honda Civic Type R (FL5)',
      orderNumber: 'SO-202611-0001',
      items: [
        InvoiceItemModel(
          id: 'item-1',
          invoiceId: 'inv-1',
          itemType: InvoiceItemType.part,
          description: 'Honda OEM Brembo Front Brake Pad Set',
          quantity: 1,
          unitPriceCents: 220000000,
          totalPriceCents: 220000000,
          createdAt: now,
        ),
        InvoiceItemModel(
          id: 'item-2',
          invoiceId: 'inv-1',
          itemType: InvoiceItemType.labor,
          description: 'Front Brake Overhaul Service',
          quantity: 1,
          unitPriceCents: 50000000,
          totalPriceCents: 50000000,
          createdAt: now,
        ),
      ],
    ),
    InvoiceModel(
      id: 'inv-2',
      invoiceNumber: 'INV-20261124-1002',
      serviceOrderId: 'so-2',
      customerId: 'cust-2',
      status: InvoiceStatus.paid,
      subtotalLaborCents: 150000000, // Rp 1.500.000
      subtotalPartsCents: 100000000, // Rp 1.000.000
      taxPercent: 11.0,
      taxAmountCents: 27500000, // Rp 275.000
      discountCents: 0,
      depositAppliedCents: 0,
      insuranceCoverageCents: 0,
      totalAmountCents: 277500000, // Rp 2.775.000
      amountPaidCents: 277500000,
      outstandingBalanceCents: 0,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(days: 1)),
      customerName: 'Siti Rahma',
      customerPhone: '+62 813-9876-5432',
      vehiclePlate: 'B 1234 ABC',
      vehicleModel: 'Toyota GR Yaris',
      orderNumber: 'SO-202611-0002',
      items: [
        InvoiceItemModel(
          id: 'item-3',
          invoiceId: 'inv-2',
          itemType: InvoiceItemType.labor,
          description: 'Major Engine Inspection & Tune-up',
          quantity: 1,
          unitPriceCents: 150000000,
          totalPriceCents: 150000000,
          createdAt: now,
        ),
      ],
    ),
  ];

  Widget buildAdminInvoicesScreen({List<InvoiceModel>? invoices}) {
    final fakeRepo = _FakeInvoiceRepository(invoices ?? sampleInvoices);

    return ProviderScope(
      overrides: [
        invoiceRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: AdminInvoicesScreen(
          initialInvoices: invoices ?? sampleInvoices,
          repository: fakeRepo,
        ),
      ),
    );
  }

  group('AdminInvoicesScreen Widget Tests', () {
    testWidgets('renders screen title, financial metrics, and filter tabs', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminInvoicesScreen());
      await tester.pumpAndSettle();

      expect(find.text('INVOICES & SETTLEMENT'), findsOneWidget);
      expect(find.text('FINANCIAL SETTLEMENT'), findsOneWidget);
      expect(find.text('TAX RATE: 11% PPN STANDARD'), findsOneWidget);

      // Verify Metrics
      expect(find.text('SETTLED REVENUE'), findsOneWidget);
      expect(find.text('OUTSTANDING BALANCE'), findsOneWidget);
      expect(find.text('11% PPN TAX COLLECTED'), findsOneWidget);
      expect(find.text('TOTAL INVOICES'), findsOneWidget);

      // Verify Tabs
      expect(find.text('ALL INVOICES (2)'), findsOneWidget);
      expect(find.text('ISSUED & UNPAID (1)'), findsOneWidget);
      expect(find.text('PAID & SETTLED (1)'), findsOneWidget);
    });

    testWidgets('renders invoice cards with customer and financial telemetry', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminInvoicesScreen());
      await tester.pumpAndSettle();

      // Invoice 1 (Unpaid)
      expect(find.text('INV-20261124-1001'), findsOneWidget);
      expect(find.textContaining('Alex Pratama'), findsOneWidget);
      expect(find.textContaining('Honda Civic Type R (FL5)'), findsOneWidget);
      expect(find.text('Rp 3.496.500'), findsWidgets); // Metric card & Grand total
      expect(find.text('Balance: Rp 3.496.500'), findsOneWidget);
      expect(find.byKey(const Key('btn_record_payment_INV-20261124-1001')), findsOneWidget);

      // Invoice 2 (Paid)
      expect(find.text('INV-20261124-1002'), findsOneWidget);
      expect(find.textContaining('Siti Rahma'), findsOneWidget);
      expect(find.textContaining('Toyota GR Yaris'), findsOneWidget);
      expect(find.text('Rp 2.775.000'), findsWidgets);
      expect(find.byKey(const Key('btn_receipt_INV-20261124-1002')), findsOneWidget);
    });

    testWidgets('switches between filter tabs correctly', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminInvoicesScreen());
      await tester.pumpAndSettle();

      // Tap "ISSUED & UNPAID (1)" tab
      await tester.tap(find.text('ISSUED & UNPAID (1)'));
      await tester.pumpAndSettle();

      // Unpaid invoice should be visible, paid invoice should NOT be visible
      expect(find.text('INV-20261124-1001'), findsOneWidget);
      expect(find.text('INV-20261124-1002'), findsNothing);

      // Tap "PAID & SETTLED (1)" tab
      await tester.tap(find.text('PAID & SETTLED (1)'));
      await tester.pumpAndSettle();

      // Paid invoice visible, unpaid not visible
      expect(find.text('INV-20261124-1002'), findsOneWidget);
      expect(find.text('INV-20261124-1001'), findsNothing);
    });

    testWidgets('opens itemized breakdown bottom sheet and displays line items', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminInvoicesScreen());
      await tester.pumpAndSettle();

      // Tap breakdown on invoice 1
      await tester.tap(find.byKey(const Key('btn_breakdown_INV-20261124-1001')));
      await tester.pumpAndSettle();

      expect(find.text('INVOICE ITEMIZED BREAKDOWN'), findsOneWidget);
      expect(find.text('Honda OEM Brembo Front Brake Pad Set'), findsOneWidget);
      expect(find.text('Front Brake Overhaul Service'), findsOneWidget);
      expect(find.text('Labor Subtotal'), findsOneWidget);
      expect(find.text('Parts Subtotal'), findsOneWidget);
      expect(find.text('PPN (11%)'), findsOneWidget);
    });

    testWidgets('opens payment settlement modal and tests cash change calculation', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminInvoicesScreen());
      await tester.pumpAndSettle();

      // Tap Record Payment on invoice 1
      await tester.tap(find.byKey(const Key('btn_record_payment_INV-20261124-1001')));
      await tester.pumpAndSettle();

      expect(find.text('FINANCIAL SETTLEMENT'), findsWidgets);
      expect(find.text('SELECT SETTLEMENT METHOD'), findsOneWidget);
      expect(find.byKey(const Key('chip_payment_cash')), findsOneWidget);
      expect(find.byKey(const Key('chip_payment_qris')), findsOneWidget);
      expect(find.byKey(const Key('chip_payment_card')), findsOneWidget);
      expect(find.byKey(const Key('chip_payment_bankTransfer')), findsOneWidget);

      // Check default cash tendered is exact amount
      expect(find.byKey(const Key('card_cash_change')), findsOneWidget);
      expect(find.text('Rp 0'), findsWidgets); // change is 0 when exact

      // Enter higher cash tendered: 3500000 (Rp 3.500.000)
      // Due is Rp 3.496.500
      // Change should be Rp 3.500
      await tester.enterText(find.byKey(const Key('input_cash_tendered')), '3500000');
      await tester.pumpAndSettle();

      expect(find.text('Rp 3.500'), findsOneWidget);

      // Switch to QRIS method
      await tester.tap(find.byKey(const Key('chip_payment_qris')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('input_payment_reference')), findsOneWidget);
      expect(find.textContaining('Simulated dynamic QRIS code generated'), findsOneWidget);
    });

    testWidgets('opens digital receipt dialog with tax workshop header and status stamp', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminInvoicesScreen());
      await tester.pumpAndSettle();

      // Open receipt for paid invoice 2
      await tester.tap(find.byKey(const Key('btn_receipt_INV-20261124-1002')));
      await tester.pumpAndSettle();

      expect(find.text('PITMATE PERFORMANCE WORKSHOP'), findsOneWidget);
      expect(find.text('OFFICIAL TAX INVOICE & RECEIPT'), findsOneWidget);
      expect(find.text('INV-20261124-1002'), findsWidgets);
      expect(find.text('Toyota GR Yaris'), findsWidgets);
      expect(find.text('PAYMENT STATUS: SETTLED IN FULL'), findsOneWidget);
      expect(find.text('PRINT'), findsOneWidget);
    });
  });
}
