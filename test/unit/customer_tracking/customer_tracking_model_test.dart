import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/customer_tracking/models/customer_tracking_model.dart';

void main() {
  group('CustomerTrackingSummary Model Tests', () {
    test('fromJson parses empty active order state properly', () {
      final json = {'has_active_order': false};
      final summary = CustomerTrackingSummary.fromJson(json);

      expect(summary.hasActiveOrder, isFalse);
      expect(summary.orderId, isNull);
      expect(summary.timeline, isEmpty);
    });

    test('fromJson parses sanitized active order payload with 8 stages', () {
      final json = {
        'has_active_order': true,
        'order_id': 'so-1001',
        'order_number': 'SO-2026-0001',
        'status': 'in_progress',
        'current_stage_index': 4,
        'created_at': '2026-11-24T09:00:00.000Z',
        'vehicle': {
          'make': 'Toyota',
          'model': 'GR Yaris',
          'year': 2022,
          'license_plate': 'B 1234 TOY',
          'mileage': 10500,
        },
        'timeline': [
          {'stage': 'Booking Confirmed', 'completed': true, 'active': false},
          {'stage': 'Vehicle Intake & Bay Arrival', 'completed': true, 'active': false},
          {'stage': 'Multi-Point Inspection', 'completed': true, 'active': false},
          {'stage': 'Estimate & Authorization', 'completed': true, 'active': false},
          {'stage': 'Active Workshop Repair', 'completed': false, 'active': true},
          {'stage': 'Quality Control Inspection', 'completed': false, 'active': false},
          {'stage': 'Ready for Delivery & Invoice', 'completed': false, 'active': false},
          {'stage': 'Delivered & Order Closed', 'completed': false, 'active': false},
        ],
        'tasks': [
          {'id': 't-1', 'task_name': 'Synthetic Engine Oil Flush', 'status': 'completed'},
          {'id': 't-2', 'task_name': 'Brembo Brake Rotor Replacement', 'status': 'in_progress'},
        ],
        'findings': [
          {
            'id': 'f-1',
            'category': 'Brakes',
            'item_name': 'Front Rotors',
            'severity': 'high',
            'description': 'Heat hairline cracks detected',
          }
        ],
        'invoice': {
          'id': 'inv-1',
          'invoice_number': 'INV-2026-001',
          'status': 'issued',
          'total_amount_cents': 250000000,
          'amount_paid_cents': 0,
          'outstanding_balance_cents': 250000000,
        }
      };

      final summary = CustomerTrackingSummary.fromJson(json);

      expect(summary.hasActiveOrder, isTrue);
      expect(summary.orderId, 'so-1001');
      expect(summary.orderNumber, 'SO-2026-0001');
      expect(summary.vehicleMake, 'Toyota');
      expect(summary.vehicleModel, 'GR Yaris');
      expect(summary.licensePlate, 'B 1234 TOY');
      expect(summary.mileageKm, 10500);
      expect(summary.currentStageIndex, 4);
      expect(summary.timeline.length, 8);
      expect(summary.timeline[4].active, isTrue);
      expect(summary.tasks.length, 2);
      expect(summary.findings.length, 1);
      expect(summary.invoiceNumber, 'INV-2026-001');
      expect(summary.outstandingBalanceCents, 250000000);
    });
  });
}
