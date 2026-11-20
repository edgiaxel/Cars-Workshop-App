import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/shared/widgets/empty_state.dart';
import 'package:pitmate/shared/widgets/error_state.dart';
import 'package:pitmate/shared/widgets/loading_state.dart';
import 'package:pitmate/shared/widgets/pit_card.dart';
import 'package:pitmate/shared/widgets/pit_primary_button.dart';
import 'package:pitmate/shared/widgets/status_badge.dart';

void main() {
  Widget testWrapper(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('LoadingState Widget Tests', () {
    testWidgets('renders progress indicator and optional message', (tester) async {
      await tester.pumpWidget(testWrapper(const LoadingState(message: 'Initializing diagnostic telemetry...')));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Initializing diagnostic telemetry...'), findsOneWidget);
    });

    testWidgets('renders progress indicator without message when omitted', (tester) async {
      await tester.pumpWidget(testWrapper(const LoadingState()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });
  });

  group('ErrorState Widget Tests', () {
    testWidgets('renders title, message, and triggers onRetry callback', (tester) async {
      var retryClicked = false;

      await tester.pumpWidget(
        testWrapper(
          ErrorState(
            title: 'Telemetry Connection Failed',
            message: 'Unable to reach the OBD-II diagnostic gateway.',
            onRetry: () {
              retryClicked = true;
            },
          ),
        ),
      );

      expect(find.text('Telemetry Connection Failed'), findsOneWidget);
      expect(find.text('Unable to reach the OBD-II diagnostic gateway.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retryClicked, isTrue);
    });

    testWidgets('renders without retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        testWrapper(
          const ErrorState(
            title: 'Fatal Error',
            message: 'Engine communication link terminated.',
          ),
        ),
      );

      expect(find.text('Fatal Error'), findsOneWidget);
      expect(find.text('Engine communication link terminated.'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('EmptyState Widget Tests', () {
    testWidgets('renders title, description, and triggers onAction callback', (tester) async {
      var actionClicked = false;

      await tester.pumpWidget(
        testWrapper(
          EmptyState(
            title: 'No Active Work Orders',
            description: 'There are currently no repair orders queued for this workshop bay.',
            actionLabel: 'Create Work Order',
            onAction: () {
              actionClicked = true;
            },
          ),
        ),
      );

      expect(find.text('No Active Work Orders'), findsOneWidget);
      expect(find.text('There are currently no repair orders queued for this workshop bay.'), findsOneWidget);
      expect(find.text('Create Work Order'), findsOneWidget);

      await tester.tap(find.text('Create Work Order'));
      expect(actionClicked, isTrue);
    });
  });

  group('PitCard Widget Tests', () {
    testWidgets('renders header, title, child, and handles tap events', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        testWrapper(
          PitCard(
            title: 'Bay 1 — Diagnostic Rack',
            onTap: () {
              tapped = true;
            },
            child: const Text('Porsche 911 GT3 RS in service'),
          ),
        ),
      );

      expect(find.text('Bay 1 — Diagnostic Rack'), findsOneWidget);
      expect(find.text('Porsche 911 GT3 RS in service'), findsOneWidget);

      await tester.tap(find.text('Bay 1 — Diagnostic Rack'));
      expect(tapped, isTrue);
    });
  });

  group('PitPrimaryButton Widget Tests', () {
    testWidgets('renders text and executes onPressed callback', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        testWrapper(
          PitPrimaryButton(
            text: 'Dispatch Vehicle',
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      );

      expect(find.text('Dispatch Vehicle'), findsOneWidget);

      await tester.tap(find.text('Dispatch Vehicle'));
      expect(pressed, isTrue);
    });

    testWidgets('displays progress spinner and disables tap when isLoading is true', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        testWrapper(
          PitPrimaryButton(
            text: 'Save Changes',
            isLoading: true,
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save Changes'), findsNothing);

      await tester.tap(find.byType(PitPrimaryButton));
      expect(pressed, isFalse);
    });

    testWidgets('button is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        testWrapper(
          const PitPrimaryButton(
            text: 'Locked Operation',
            onPressed: null,
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('renders cleanly with ellipsis inside constrained width (60px) with icon', (tester) async {
      await tester.pumpWidget(
        testWrapper(
          const SizedBox(
            width: 60,
            child: PitPrimaryButton(
              text: 'Very Long Button Action Label That Exceeds Width',
              icon: Icons.check,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PitPrimaryButton), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('renders cleanly with ellipsis inside constrained width (60px) without icon', (tester) async {
      await tester.pumpWidget(
        testWrapper(
          const SizedBox(
            width: 60,
            child: PitPrimaryButton(
              text: 'Very Long Button Action Label That Exceeds Width',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PitPrimaryButton), findsOneWidget);
    });
  });

  group('StatusBadge Widget Tests', () {
    testWidgets('renders all status badge variants with labels', (tester) async {
      await tester.pumpWidget(
        testWrapper(
          const Column(
            children: [
              StatusBadge(label: 'Completed', variant: StatusBadgeVariant.success),
              StatusBadge(label: 'Pending Approval', variant: StatusBadgeVariant.warning),
              StatusBadge(label: 'Fault Detected', variant: StatusBadgeVariant.error),
              StatusBadge(label: 'In Progress', variant: StatusBadgeVariant.info),
              StatusBadge(label: 'Draft', variant: StatusBadgeVariant.neutral),
            ],
          ),
        ),
      );

      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Pending Approval'), findsOneWidget);
      expect(find.text('Fault Detected'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('renders dot mode instead of icon when showDot is true', (tester) async {
      await tester.pumpWidget(
        testWrapper(
          const StatusBadge(
            label: 'Live Telemetry',
            variant: StatusBadgeVariant.success,
            showDot: true,
          ),
        ),
      );

      expect(find.text('Live Telemetry'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('renders cleanly with ellipsis inside constrained width (60px)', (tester) async {
      await tester.pumpWidget(
        testWrapper(
          const SizedBox(
            width: 60,
            child: StatusBadge(
              label: 'Very Long Diagnostic Status Label That Exceeds Width',
              variant: StatusBadgeVariant.warning,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StatusBadge), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('renders cleanly with dot inside constrained width (60px)', (tester) async {
      await tester.pumpWidget(
        testWrapper(
          const SizedBox(
            width: 60,
            child: StatusBadge(
              label: 'Very Long Status Text Label',
              variant: StatusBadgeVariant.error,
              showDot: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StatusBadge), findsOneWidget);
    });
  });
}
