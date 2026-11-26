import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/core/utils/result.dart';
import 'package:pitmate/features/customers/presentation/customer_estimate_approval_screen.dart';
import 'package:pitmate/features/estimates/data/models/estimate_authorization_model.dart';
import 'package:pitmate/features/estimates/data/models/estimate_item_model.dart';
import 'package:pitmate/features/estimates/data/models/estimate_model.dart';
import 'package:pitmate/features/estimates/data/repositories/estimate_repository.dart';

class _FakeCustomerEstimateRepository implements IEstimateRepository {
  _FakeCustomerEstimateRepository(this.estimate, this.items);

  EstimateModel estimate;
  List<EstimateItemModel> items;

  @override
  Future<Result<EstimateModel>> authorizeEstimate(
    String estimateId,
    EstimateStatus decision, {
    String? notes,
    String? signatureToken,
  }) async {
    estimate = estimate.copyWith(status: decision);
    return Result.success(estimate);
  }

  @override
  Future<Result<EstimateModel>> authorizeEstimateItems(
    String estimateId, {
    required List<String> approvedItemIds,
    required List<String> rejectedItemIds,
    String? notes,
  }) async {
    final nextStatus = approvedItemIds.isEmpty
        ? EstimateStatus.rejected
        : (rejectedItemIds.isNotEmpty
            ? EstimateStatus.partiallyApproved
            : EstimateStatus.approved);
    estimate = estimate.copyWith(status: nextStatus);
    items = items.map((item) {
      if (approvedItemIds.contains(item.id)) {
        return item.copyWith(authorizationStatus: AuthorizationStatus.approved);
      }
      if (rejectedItemIds.contains(item.id)) {
        return item.copyWith(authorizationStatus: AuthorizationStatus.rejected);
      }
      return item;
    }).toList();
    return Result.success(estimate);
  }

  @override
  Future<Result<EstimateModel>> createEstimateDraft(
    EstimateModel estimate,
    List<EstimateItemModel> items,
  ) async =>
      Result.success(estimate);

  @override
  Future<Result<List<EstimateAuthorizationModel>>> fetchAuthorizations(
    String estimateId,
  ) async {
    return Result.success([
      EstimateAuthorizationModel(
        id: 'auth-1',
        estimateId: estimateId,
        authorizedBy: 'cust-1',
        status: estimate.status,
        signatureToken: 'SIG-TEST-1234',
        authorizedAt: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<Result<EstimateModel?>> fetchEstimateById(String estimateId) async =>
      Result.success(estimate);

  @override
  Future<Result<EstimateModel?>> fetchEstimateByOrderId(String orderId) async =>
      Result.success(estimate);

  @override
  Future<Result<List<EstimateItemModel>>> fetchEstimateItems(
    String estimateId,
  ) async =>
      Result.success(items);

  @override
  Future<Result<Map<String, dynamic>?>> fetchServiceOrderSummary(
    String orderId,
  ) async =>
      const Result.success(null);

  @override
  Future<Result<EstimateModel>> publishEstimate(String estimateId) async =>
      Result.success(estimate);
}

void main() {
  final sampleEstimate = EstimateModel(
    id: 'est-cust-1',
    serviceOrderId: 'so-cust-1',
    revisionNumber: 1,
    status: EstimateStatus.sent,
    subtotalCents: 315000000,
    taxCents: 34650000,
    discountCents: 0,
    totalCents: 349650000,
    notes: 'Parts and labor warranty included.',
    createdAt: DateTime(2026, 11, 20),
    updatedAt: DateTime(2026, 11, 20),
  );

  final sampleItems = [
    EstimateItemModel.create(
      id: 'item-c-1',
      estimateId: 'est-cust-1',
      itemType: EstimateItemType.part,
      description: 'Front Brake Pad Set',
      quantity: 1,
      unitPriceCents: 220000000,
    ),
    EstimateItemModel.create(
      id: 'item-c-2',
      estimateId: 'est-cust-1',
      itemType: EstimateItemType.part,
      description: 'Racing Brake Fluid (500ml)',
      quantity: 2,
      unitPriceCents: 22500000,
    ),
    EstimateItemModel.create(
      id: 'item-c-3',
      estimateId: 'est-cust-1',
      itemType: EstimateItemType.labor,
      description: 'Front Brake Overhaul & Precision Bleeding Service',
      quantity: 1,
      unitPriceCents: 50000000,
    ),
  ];

  Widget buildCustomerApprovalScreen() {
    final fakeRepo = _FakeCustomerEstimateRepository(sampleEstimate, sampleItems);
    return ProviderScope(
      overrides: [
        estimateRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: CustomerEstimateApprovalScreen(
          initialEstimate: sampleEstimate,
          initialItems: sampleItems,
          initialVehicleName: 'Honda Civic Type R',
          initialLicensePlate: 'B 5678 CIV',
          initialOrderNumber: 'SO-202611-0001',
        ),
      ),
    );
  }

  group('CustomerEstimateApprovalScreen Tests', () {
    testWidgets('renders estimate header and transparent parts/labor breakdown', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildCustomerApprovalScreen());
      await tester.pumpAndSettle();

      expect(find.text('ESTIMATE FOR SERVICE'), findsOneWidget);
      expect(find.text('Honda Civic Type R'), findsOneWidget);
      expect(find.text('B 5678 CIV'), findsOneWidget);
      expect(find.text('SO-202611-0001'), findsOneWidget);
      expect(find.text('Revision 1'), findsWidgets);

      expect(find.text('PARTS CHARGES'), findsOneWidget);
      expect(find.byKey(const Key('text_parts_breakdown_total')), findsOneWidget);
      expect(find.text('Rp 2.650.000'), findsWidgets);

      expect(find.text('LABOR CHARGES'), findsOneWidget);
      expect(find.byKey(const Key('text_labor_breakdown_total')), findsOneWidget);
      expect(find.text('Rp 500.000'), findsWidgets);
    });

    testWidgets('renders itemized breakdown lines and prominent grand total', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildCustomerApprovalScreen());
      await tester.pumpAndSettle();

      expect(find.text('ITEMIZED REPAIR BREAKDOWN'), findsOneWidget);
      expect(find.text('Front Brake Pad Set'), findsOneWidget);
      expect(find.text('Racing Brake Fluid (500ml)'), findsOneWidget);
      expect(find.text('Front Brake Overhaul & Precision Bleeding Service'), findsOneWidget);

      expect(find.byKey(const Key('customer_grand_total_text')), findsOneWidget);
      expect(find.text('Rp 3.496.500'), findsOneWidget);
      expect(find.text('PPN (11% TAX)'), findsOneWidget);
      expect(find.text('Rp 346.500'), findsOneWidget);
    });

    testWidgets('triggers approve estimate flow and renders approval confirmation', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildCustomerApprovalScreen());
      await tester.pumpAndSettle();

      final approveBtn = find.byKey(const Key('btn_customer_approve_work'));
      expect(approveBtn, findsOneWidget);

      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      expect(find.text('AUTHORIZE ESTIMATE'), findsOneWidget);
      expect(find.text('Your authorization will be recorded in the workshop audit ledger.'), findsOneWidget);

      final confirmBtn = find.byKey(const Key('btn_confirm_dialog_approve'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('card_approval_confirmation')), findsOneWidget);
      expect(find.text('ESTIMATE AUTHORIZED & WORK APPROVED'), findsOneWidget);
      expect(find.text('APPROVED'), findsWidgets);
    });

    testWidgets('triggers decline work flow with reason dialog', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildCustomerApprovalScreen());
      await tester.pumpAndSettle();

      final rejectBtn = find.byKey(const Key('btn_customer_reject_work'));
      expect(rejectBtn, findsOneWidget);

      await tester.tap(rejectBtn);
      await tester.pumpAndSettle();

      expect(find.text('DECLINE WORK ESTIMATE'), findsOneWidget);

      final reasonField = find.byKey(const Key('field_rejection_reason'));
      await tester.enterText(reasonField, 'Cost too high, deferring to next month');
      await tester.pumpAndSettle();

      final confirmDeclineBtn = find.byKey(const Key('btn_confirm_dialog_reject'));
      await tester.tap(confirmDeclineBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('card_rejection_banner')), findsOneWidget);
      expect(find.text('WORK ESTIMATE DECLINED'), findsOneWidget);
    });
  });
}
