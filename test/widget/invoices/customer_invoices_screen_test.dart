import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/core/utils/result.dart';
import 'package:pitmate/features/invoices/data/models/invoice_model.dart';
import 'package:pitmate/features/invoices/data/repositories/invoice_repository.dart';
import 'package:pitmate/features/invoices/presentation/customer_invoices_screen.dart';

class _FakeCustomerInvoiceRepository implements IInvoiceRepository {
  _FakeCustomerInvoiceRepository(this.invoices);

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
    return const Result.success([]);
  }

  @override
  Future<Result<List<PaymentModel>>> fetchInvoicePayments(String invoiceId) async {
    return const Result.success([]);
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
    return const Result.success('inv-uuid');
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
    return const Result.success('pay-uuid');
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> fetchEligibleServiceOrdersForInvoice() async {
    return const Result.success([]);
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
      subtotalLaborCents: 50000000,
      subtotalPartsCents: 265000000,
      taxPercent: 11.0,
      taxAmountCents: 34650000,
      totalAmountCents: 349650000,
      amountPaidCents: 0,
      outstandingBalanceCents: 349650000,
      createdAt: now,
      updatedAt: now,
      customerName: 'Alex Pratama',
      vehiclePlate: 'B 5678 CIV',
      vehicleModel: 'Honda Civic Type R (FL5)',
    ),
  ];

  Widget buildCustomerInvoicesScreen({List<InvoiceModel>? invoices}) {
    final fakeRepo = _FakeCustomerInvoiceRepository(invoices ?? sampleInvoices);

    return ProviderScope(
      overrides: [
        invoiceRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: CustomerInvoicesScreen(
          initialInvoices: invoices ?? sampleInvoices,
          repository: fakeRepo,
          customerId: 'cust-1',
        ),
      ),
    );
  }

  group('CustomerInvoicesScreen Widget Tests', () {
    testWidgets('renders outstanding balance banner and invoice card with Pay Now', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildCustomerInvoicesScreen());
      await tester.pumpAndSettle();

      expect(find.text('INVOICES & PAYMENTS'), findsOneWidget);
      expect(find.text('TOTAL OUTSTANDING BALANCE DUE'), findsOneWidget);
      expect(find.text('Rp 3.496.500'), findsWidgets);
      expect(find.byKey(const Key('btn_pay_all_or_first_due')), findsOneWidget);

      expect(find.text('INV-20261124-1001'), findsOneWidget);
      expect(find.textContaining('Honda Civic Type R (FL5)'), findsOneWidget);
      expect(find.byKey(const Key('btn_customer_pay_now_INV-20261124-1001')), findsOneWidget);
      expect(find.byKey(const Key('btn_customer_view_receipt_INV-20261124-1001')), findsOneWidget);
    });

    testWidgets('opens 1-click settlement sheet and switches payment channels', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildCustomerInvoicesScreen());
      await tester.pumpAndSettle();

      // Tap Pay Now on the invoice card
      await tester.tap(find.byKey(const Key('btn_customer_pay_now_INV-20261124-1001')));
      await tester.pumpAndSettle();

      expect(find.text('SECURE 1-CLICK SETTLEMENT'), findsOneWidget);
      expect(find.text('Pay Rp 3.496.500'), findsOneWidget);
      expect(find.byKey(const Key('channel_tile_qris')), findsOneWidget);
      expect(find.byKey(const Key('channel_tile_card')), findsOneWidget);
      expect(find.byKey(const Key('channel_tile_bankTransfer')), findsOneWidget);

      // Tap Credit Card tile
      await tester.tap(find.byKey(const Key('channel_tile_card')));
      await tester.pumpAndSettle();

      expect(find.text('Saved Debit / Credit Card'), findsOneWidget);
      expect(find.byKey(const Key('btn_confirm_customer_settlement')), findsOneWidget);
    });
  });
}
