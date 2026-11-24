import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/auth/domain/user_profile.dart';
import 'package:pitmate/features/auth/domain/user_role.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pitmate/features/auth/presentation/providers/auth_state.dart';
import 'package:pitmate/features/customer_tracking/data/customer_tracking_repository.dart';
import 'package:pitmate/features/customer_tracking/models/customer_tracking_model.dart';
import 'package:pitmate/features/customer_tracking/presentation/customer_tracking_screen.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

class FakeCustomerTrackingRepository extends CustomerTrackingRepository {
  FakeCustomerTrackingRepository(this._summary);

  final CustomerTrackingSummary _summary;

  @override
  Future<String?> getCurrentCustomerId() async => 'cust-101';

  @override
  Future<CustomerTrackingSummary> fetchTrackingSummary({
    required String customerId,
    String? orderId,
  }) async {
    return _summary;
  }
}

void main() {
  const testProfile = UserProfile(
    id: 'user-1',
    role: UserRole.customer,
    fullName: 'Axel Zeed',
  );

  testWidgets('CustomerTrackingScreen renders empty state when no active order',
      (tester) async {
    final fakeRepo = FakeCustomerTrackingRepository(
      const CustomerTrackingSummary(hasActiveOrder: false),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthAuthenticated(testProfile)),
          ),
          customerTrackingRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: CustomerTrackingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No Vehicle Currently in Service'), findsOneWidget);
    expect(find.text('Book Workshop Service'), findsOneWidget);
  });

  testWidgets('CustomerTrackingScreen renders vehicle header, 8-stage stepper, and tasks',
      (tester) async {
    final activeSummary = CustomerTrackingSummary(
      hasActiveOrder: true,
      orderId: 'so-1',
      orderNumber: 'SO-2026-0001',
      status: 'in_progress',
      currentStageIndex: 4,
      vehicleMake: 'Toyota',
      vehicleModel: 'GR Yaris',
      licensePlate: 'B 1234 TOY',
      mileageKm: 10450,
      timeline: const [
        TrackingTimelineStage(stage: 'Booking Confirmed', completed: true, active: false),
        TrackingTimelineStage(stage: 'Vehicle Intake & Bay Arrival', completed: true, active: false),
        TrackingTimelineStage(stage: 'Multi-Point Inspection', completed: true, active: false),
        TrackingTimelineStage(stage: 'Estimate & Authorization', completed: true, active: false),
        TrackingTimelineStage(stage: 'Active Workshop Repair', completed: false, active: true),
        TrackingTimelineStage(stage: 'Quality Control Inspection', completed: false, active: false),
        TrackingTimelineStage(stage: 'Ready for Delivery & Invoice', completed: false, active: false),
        TrackingTimelineStage(stage: 'Delivered & Order Closed', completed: false, active: false),
      ],
      tasks: const [
        TrackingTaskItem(id: 't-1', taskName: 'Motul 300V Oil Service', status: 'completed'),
      ],
      findings: const [
        TrackingFindingItem(
          id: 'f-1',
          category: 'Brakes',
          itemName: 'Front Brake Pads',
          severity: 'high',
          description: 'Pad thickness below 3mm',
        ),
      ],
      invoiceId: 'inv-1',
      totalAmountCents: 150000000,
      outstandingBalanceCents: 150000000,
    );

    final fakeRepo = FakeCustomerTrackingRepository(activeSummary);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(const AuthAuthenticated(testProfile)),
          ),
          customerTrackingRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: CustomerTrackingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Toyota GR Yaris'), findsOneWidget);
    expect(find.text('B 1234 TOY'), findsOneWidget);
    expect(find.text('Service Workflow Progress'), findsOneWidget);
    expect(find.text('Stage 5 of 8'), findsOneWidget);
    expect(find.text('Active Workshop Repair'), findsOneWidget);
    expect(find.text('Motul 300V Oil Service'), findsOneWidget);
    expect(find.text('Front Brake Pads'), findsOneWidget);
    expect(find.text('Invoice Ready for Payment'), findsOneWidget);
    expect(find.text('Pay Now'), findsOneWidget);
  });
}
