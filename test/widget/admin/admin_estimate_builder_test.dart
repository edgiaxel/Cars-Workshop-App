import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/core/utils/result.dart';
import 'package:pitmate/features/admin/presentation/admin_estimate_builder_screen.dart';
import 'package:pitmate/features/estimates/data/models/estimate_authorization_model.dart';
import 'package:pitmate/features/estimates/data/models/estimate_item_model.dart';
import 'package:pitmate/features/estimates/data/models/estimate_model.dart';
import 'package:pitmate/features/estimates/data/repositories/estimate_repository.dart';

class _FakeAdminEstimateRepository implements IEstimateRepository {
  @override
  Future<Result<EstimateModel>> authorizeEstimate(
    String estimateId,
    EstimateStatus decision, {
    String? notes,
    String? signatureToken,
  }) async {
    return Result.failure(UnimplementedError() as dynamic);
  }

  @override
  Future<Result<EstimateModel>> authorizeEstimateItems(
    String estimateId, {
    required List<String> approvedItemIds,
    required List<String> rejectedItemIds,
    String? notes,
  }) async {
    return Result.failure(UnimplementedError() as dynamic);
  }

  @override
  Future<Result<EstimateModel>> createEstimateDraft(
    EstimateModel estimate,
    List<EstimateItemModel> items,
  ) async {
    return Result.success(
      estimate.copyWith(
        id: estimate.id.isEmpty ? 'est-saved-1' : estimate.id,
        status: EstimateStatus.draft,
      ),
    );
  }

  @override
  Future<Result<List<EstimateAuthorizationModel>>> fetchAuthorizations(
    String estimateId,
  ) async =>
      const Result.success([]);

  @override
  Future<Result<EstimateModel?>> fetchEstimateById(String estimateId) async =>
      const Result.success(null);

  @override
  Future<Result<EstimateModel?>> fetchEstimateByOrderId(String orderId) async =>
      const Result.success(null);

  @override
  Future<Result<List<EstimateItemModel>>> fetchEstimateItems(
    String estimateId,
  ) async =>
      const Result.success([]);

  @override
  Future<Result<Map<String, dynamic>?>> fetchServiceOrderSummary(
    String orderId,
  ) async =>
      const Result.success(null);

  @override
  Future<Result<EstimateModel>> publishEstimate(String estimateId) async {
    return Result.success(
      EstimateModel(
        id: estimateId,
        serviceOrderId: 'so-1',
        revisionNumber: 1,
        status: EstimateStatus.sent,
        subtotalCents: 315000000,
        taxCents: 34650000,
        discountCents: 0,
        totalCents: 349650000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}

void main() {
  final sampleEstimate = EstimateModel(
    id: 'est-1',
    serviceOrderId: 'so-test-1',
    revisionNumber: 1,
    status: EstimateStatus.draft,
    subtotalCents: 315000000,
    taxCents: 34650000,
    discountCents: 0,
    totalCents: 349650000,
    notes: 'OEM brake overhaul estimate.',
    createdAt: DateTime(2026, 11, 20),
    updatedAt: DateTime(2026, 11, 20),
  );

  final sampleItems = [
    EstimateItemModel.create(
      id: 'item-1',
      estimateId: 'est-1',
      itemType: EstimateItemType.part,
      description: 'Front Brake Pad Set',
      quantity: 1,
      unitPriceCents: 220000000,
    ),
    EstimateItemModel.create(
      id: 'item-2',
      estimateId: 'est-1',
      itemType: EstimateItemType.part,
      description: 'High-Temp Racing Brake Fluid (500ml)',
      quantity: 2,
      unitPriceCents: 22500000,
    ),
    EstimateItemModel.create(
      id: 'item-3',
      estimateId: 'est-1',
      itemType: EstimateItemType.labor,
      description: 'Front Brake Overhaul & Bleeding Service',
      quantity: 1,
      unitPriceCents: 50000000,
    ),
  ];

  final sampleFindings = [
    {
      'item_name': 'Front Brake Pads',
      'condition': 'critical',
      'severity': 'urgent',
      'notes': 'Pad material worn to 1.8mm.',
      'recommended_action': 'Replace front brake pad set.',
      'suggested_type': EstimateItemType.part,
      'suggested_price_cents': 220000000,
    },
    {
      'item_name': 'Brake Fluid Flush & Bleed',
      'condition': 'fair',
      'severity': 'medium',
      'notes': 'Moisture level 2.8%.',
      'recommended_action': 'Flush synthetic brake fluid.',
      'suggested_type': EstimateItemType.part,
      'suggested_price_cents': 45000000,
    },
  ];

  const sampleOrderInfo = {
    'order_number': 'SO-202611-0001',
    'customer_name': 'Axel Zeed',
    'customer_phone': '+62 812-3456-7890',
    'vehicle_display': 'Honda Civic Type R',
    'license_plate': 'B 5678 CIV',
    'assigned_bay': 'Bay 02',
    'odometer': 8200,
    'complaint': 'Grinding noise from front axle',
  };

  Widget buildAdminEstimateBuilderScreen() {
    return ProviderScope(
      overrides: [
        estimateRepositoryProvider.overrideWithValue(
          _FakeAdminEstimateRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: AdminEstimateBuilderScreen(
          serviceOrderId: 'so-test-1',
          initialEstimate: sampleEstimate,
          initialItems: sampleItems,
          initialFindings: sampleFindings,
          initialOrderInfo: sampleOrderInfo,
        ),
      ),
    );
  }

  group('AdminEstimateBuilderScreen Tests', () {
    testWidgets('renders service order and vehicle telemetry', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminEstimateBuilderScreen());
      await tester.pumpAndSettle();

      expect(find.text('ESTIMATE BUILDER'), findsWidgets);
      expect(find.text('SERVICE ORDER TELEMETRY'), findsOneWidget);
      expect(find.text('SO-202611-0001'), findsOneWidget);
      expect(find.text('Axel Zeed'), findsOneWidget);
      expect(find.text('Honda Civic Type R'), findsOneWidget);
      expect(find.text('B 5678 CIV'), findsOneWidget);
      expect(find.text('Bay 02'), findsOneWidget);
      expect(find.text('8200 KM'), findsOneWidget);
    });

    testWidgets('displays diagnostic findings summary with Add Line action', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminEstimateBuilderScreen());
      await tester.pumpAndSettle();

      expect(find.text('DIAGNOSTIC FINDINGS & INSPECTION SUMMARY'), findsOneWidget);
      expect(find.text('Front Brake Pads'), findsOneWidget);
      expect(find.text('URGENT'), findsOneWidget);
      expect(find.text('Brake Fluid Flush & Bleed'), findsOneWidget);
      expect(find.text('Add Line'), findsWidgets);
    });

    testWidgets('renders itemized lines editor with live line totals', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminEstimateBuilderScreen());
      await tester.pumpAndSettle();

      expect(find.text('ITEMIZED LINES EDITOR'), findsOneWidget);
      expect(find.text('Front Brake Pad Set'), findsOneWidget);
      expect(find.text('High-Temp Racing Brake Fluid (500ml)'), findsOneWidget);
      expect(find.text('Front Brake Overhaul & Bleeding Service'), findsOneWidget);

      expect(find.text('Rp 2.200.000'), findsOneWidget);
      expect(find.text('Rp 450.000'), findsOneWidget);
      expect(find.text('Rp 500.000'), findsOneWidget);
    });

    testWidgets('increments line quantity and updates grand total live', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminEstimateBuilderScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('text_grand_total')), findsOneWidget);
      expect(find.text('Rp 3.496.500'), findsOneWidget);

      final incBtn = find.byKey(const Key('btn_increment_qty_0'));
      await tester.tap(incBtn);
      await tester.pumpAndSettle();

      expect(find.text('Rp 4.400.000'), findsOneWidget);
      // Subtotal 5.350.000 + 11% tax 588.500 = 5.938.500
      expect(find.text('Rp 5.938.500'), findsOneWidget);
    });

    testWidgets('applies discount before tax and updates grand total', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminEstimateBuilderScreen());
      await tester.pumpAndSettle();

      final discountField = find.byKey(const Key('field_discount_input'));
      expect(discountField, findsOneWidget);

      await tester.enterText(discountField, '100000');
      await tester.pumpAndSettle();

      // Taxable subtotal = 3.150.000 - 100.000 = 3.050.000; 11% PPN = 335.500 -> Total 3.385.500
      expect(find.text('Rp 3.385.500'), findsOneWidget);
    });

    testWidgets('adds new line item when clicking + Part button', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminEstimateBuilderScreen());
      await tester.pumpAndSettle();

      final addPartBtn = find.byKey(const Key('btn_add_part'));
      await tester.tap(addPartBtn);
      await tester.pumpAndSettle();

      expect(find.text('New Part'), findsOneWidget);
    });

    testWidgets('triggers save draft and publish estimate actions', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildAdminEstimateBuilderScreen());
      await tester.pumpAndSettle();

      final saveDraftBtn = find.byKey(const Key('btn_save_draft'));
      await tester.tap(saveDraftBtn);
      await tester.pumpAndSettle();
      expect(find.text('Estimate draft saved successfully.'), findsOneWidget);

      final publishBtn = find.byKey(const Key('btn_publish_estimate'));
      await tester.tap(publishBtn);
      await tester.pumpAndSettle();
      expect(find.text('Estimate published to customer.'), findsOneWidget);
    });
  });
}
