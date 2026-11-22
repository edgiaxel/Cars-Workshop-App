import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/app/theme/app_theme.dart';
import 'package:pitmate/features/customers/presentation/customer_estimate_approval_screen.dart';

void main() {
  Widget buildCustomerApprovalScreen() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const CustomerEstimateApprovalScreen(),
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
      expect(find.text('Honda Civic Type R (FL5)'), findsOneWidget);
      expect(find.text('B 5678 CIV'), findsOneWidget);
      expect(find.text('SO-202611-0001'), findsOneWidget);
      expect(find.text('Revision 1'), findsWidgets);

      // Verify parts vs labor breakdown cards
      expect(find.text('PARTS CHARGES'), findsOneWidget);
      expect(find.byKey(const Key('text_parts_breakdown_total')), findsOneWidget);
      expect(find.text('Rp 2.650.000'), findsWidgets); // Parts: 2.200.000 + 450.000

      expect(find.text('LABOR CHARGES'), findsOneWidget);
      expect(find.byKey(const Key('text_labor_breakdown_total')), findsOneWidget);
      expect(find.text('Rp 500.000'), findsWidgets); // Labor: 500.000
    });

    testWidgets('renders itemized breakdown lines and prominent grand total', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildCustomerApprovalScreen());
      await tester.pumpAndSettle();

      expect(find.text('ITEMIZED REPAIR BREAKDOWN'), findsOneWidget);
      expect(find.text('Honda OEM Brembo Front Brake Pad Set (FL5)'), findsOneWidget);
      expect(find.text('Motul RBF 660 High-Temp Racing Brake Fluid (500ml)'), findsOneWidget);
      expect(find.text('Front Brake Overhaul & Precision Bleeding Service'), findsOneWidget);

      // Verify Grand Total prominence
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

      // Verify authorization modal popped up
      expect(find.text('AUTHORIZE ESTIMATE'), findsOneWidget);
      expect(find.text('A digital signature token will be securely generated and appended to this service order.'), findsOneWidget);

      // Confirm authorization
      final confirmBtn = find.byKey(const Key('btn_confirm_dialog_approve'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify confirmation card appears
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

      // Verify decline modal popped up
      expect(find.text('DECLINE WORK ESTIMATE'), findsOneWidget);

      // Enter decline reason
      final reasonField = find.byKey(const Key('field_rejection_reason'));
      await tester.enterText(reasonField, 'Cost too high, deferring to next month');
      await tester.pumpAndSettle();

      // Confirm decline
      final confirmDeclineBtn = find.byKey(const Key('btn_confirm_dialog_reject'));
      await tester.tap(confirmDeclineBtn);
      await tester.pumpAndSettle();

      // Verify rejection banner appears
      expect(find.byKey(const Key('card_rejection_banner')), findsOneWidget);
      expect(find.text('WORK ESTIMATE DECLINED'), findsOneWidget);
    });
  });
}
