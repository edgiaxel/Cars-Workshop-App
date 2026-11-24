import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/handover/data/models/vehicle_handover_model.dart';

void main() {
  group('HandoverChecklist', () {
    test('default constructor initializes all 4 items to true and isComplete is true', () {
      const checklist = HandoverChecklist();
      expect(checklist.vehicleCleaned, isTrue);
      expect(checklist.personalItemsReturned, isTrue);
      expect(checklist.oldPartsPresented, isTrue);
      expect(checklist.keysReturned, isTrue);
      expect(checklist.isComplete, isTrue);
    });

    test('isComplete is false if any single item is false', () {
      expect(
        const HandoverChecklist(vehicleCleaned: false).isComplete,
        isFalse,
      );
      expect(
        const HandoverChecklist(personalItemsReturned: false).isComplete,
        isFalse,
      );
      expect(
        const HandoverChecklist(oldPartsPresented: false).isComplete,
        isFalse,
      );
      expect(
        const HandoverChecklist(keysReturned: false).isComplete,
        isFalse,
      );
    });

    test('toJson and fromJson correctly serialize and deserialize', () {
      const checklist = HandoverChecklist(
        vehicleCleaned: true,
        personalItemsReturned: true,
        oldPartsPresented: false,
        keysReturned: true,
      );

      final json = checklist.toJson();
      expect(json['vehicle_cleaned'], isTrue);
      expect(json['personal_items_returned'], isTrue);
      expect(json['old_parts_presented'], isFalse);
      expect(json['keys_returned'], isTrue);

      final deserialized = HandoverChecklist.fromJson(json);
      expect(deserialized, equals(checklist));
    });

    test('fromJson handles JSON string and null gracefully', () {
      final fromNull = HandoverChecklist.fromJson(null);
      expect(fromNull.isComplete, isTrue);

      const jsonStr =
          '{"vehicle_cleaned":true,"personal_items_returned":false,"old_parts_presented":true,"keys_returned":true}';
      final fromStr = HandoverChecklist.fromJson(jsonStr);
      expect(fromStr.vehicleCleaned, isTrue);
      expect(fromStr.personalItemsReturned, isFalse);
      expect(fromStr.isComplete, isFalse);
    });

    test('copyWith updates specified properties while preserving others', () {
      const original = HandoverChecklist();
      final updated = original.copyWith(vehicleCleaned: false);
      expect(updated.vehicleCleaned, isFalse);
      expect(updated.personalItemsReturned, isTrue);
      expect(updated.oldPartsPresented, isTrue);
      expect(updated.keysReturned, isTrue);
    });
  });

  group('VehicleHandoverModel', () {
    test('fromJson parses relational database records correctly', () {
      final json = {
        'id': 'ho-1111-2222',
        'service_order_id': 'so-3333-4444',
        'customer_id': 'cust-5555-6666',
        'responsible_admin_id': 'adm-7777-8888',
        'handover_timestamp': '2026-11-24T10:00:00.000Z',
        'customer_confirmed': true,
        'payment_override_reason': 'Fleet net-30 contract approved',
        'checklist': {
          'vehicle_cleaned': true,
          'personal_items_returned': true,
          'old_parts_presented': true,
          'keys_returned': true,
        },
        'notes': 'Customer requested old brake pads in a box.',
        'created_at': '2026-11-24T10:05:00.000Z',
        'service_orders': {
          'order_number': 'SO-20261124-001',
          'vehicles': {
            'license_plate': 'B 1234 PIT',
            'make': 'Porsche',
            'model': '911 GT3',
          },
        },
        'customers': {
          'full_name': 'Ayrton Senna',
          'phone_number': '+628119999888',
        },
        'profiles': {
          'full_name': 'Marcus Toto',
        },
      };

      final model = VehicleHandoverModel.fromJson(json);

      expect(model.id, equals('ho-1111-2222'));
      expect(model.serviceOrderId, equals('so-3333-4444'));
      expect(model.customerId, equals('cust-5555-6666'));
      expect(model.responsibleAdminId, equals('adm-7777-8888'));
      expect(model.customerConfirmed, isTrue);
      expect(model.paymentOverrideReason,
          equals('Fleet net-30 contract approved'));
      expect(model.checklist.isComplete, isTrue);
      expect(model.notes, equals('Customer requested old brake pads in a box.'));
      expect(model.orderNumber, equals('SO-20261124-001'));
      expect(model.customerName, equals('Ayrton Senna'));
      expect(model.customerPhone, equals('+628119999888'));
      expect(model.vehiclePlate, equals('B 1234 PIT'));
      expect(model.vehicleMake, equals('Porsche'));
      expect(model.vehicleModel, equals('911 GT3'));
      expect(model.adminName, equals('Marcus Toto'));
      expect(model.vehicleDescription, equals('Porsche 911 GT3 [B 1234 PIT]'));
    });

    test('toJson produces correct database payload', () {
      final model = VehicleHandoverModel(
        id: 'ho-1111',
        serviceOrderId: 'so-2222',
        customerId: 'cust-3333',
        responsibleAdminId: 'adm-4444',
        handoverTimestamp: DateTime.parse('2026-11-24T10:00:00.000Z'),
        customerConfirmed: true,
        paymentOverrideReason: 'VIP waiver',
        notes: 'Handover complete',
        createdAt: DateTime.parse('2026-11-24T10:00:00.000Z'),
      );

      final json = model.toJson();
      expect(json['id'], equals('ho-1111'));
      expect(json['service_order_id'], equals('so-2222'));
      expect(json['customer_id'], equals('cust-3333'));
      expect(json['responsible_admin_id'], equals('adm-4444'));
      expect(json['payment_override_reason'], equals('VIP waiver'));
      expect(json['checklist'], isA<Map<String, dynamic>>());
      expect(json['notes'], equals('Handover complete'));
    });
  });

  group('HandoverOrderCandidate', () {
    test('fromJson correctly parses order candidate with settled invoice', () {
      final json = {
        'id': 'so-9999',
        'order_number': 'SO-20261124-009',
        'status': 'completed',
        'customer_id': 'cust-100',
        'vehicle_id': 'veh-200',
        'odometer': 45200,
        'customer_complaint': 'Routine 40,000 km maintenance',
        'created_at': '2026-11-24T08:00:00.000Z',
        'updated_at': '2026-11-24T11:30:00.000Z',
        'customers': {
          'full_name': 'Lewis Hamilton',
          'phone_number': '+6281234567890',
        },
        'vehicles': {
          'license_plate': 'B 44 HAM',
          'make': 'Mercedes-AMG',
          'model': 'GT Black Series',
          'year': 2022,
          'color': 'Magno Magma Beam',
        },
        'invoices': [
          {
            'id': 'inv-888',
            'invoice_number': 'INV-20261124-0001',
            'status': 'paid',
            'total_amount_cents': 150000000,
            'amount_paid_cents': 150000000,
            'outstanding_balance_cents': 0,
          }
        ],
        'vehicle_handovers': [],
      };

      final candidate = HandoverOrderCandidate.fromJson(json);

      expect(candidate.orderId, equals('so-9999'));
      expect(candidate.orderNumber, equals('SO-20261124-009'));
      expect(candidate.customerName, equals('Lewis Hamilton'));
      expect(candidate.vehiclePlate, equals('B 44 HAM'));
      expect(candidate.vehicleDescription,
          equals('Mercedes-AMG GT Black Series (2022) • B 44 HAM'));
      expect(candidate.hasInvoice, isTrue);
      expect(candidate.totalAmountCents, equals(150000000));
      expect(candidate.amountPaidCents, equals(150000000));
      expect(candidate.outstandingBalanceCents, equals(0));
      expect(candidate.isPaid, isTrue);
      expect(candidate.isHandedOver, isFalse);
    });

    test('fromJson correctly identifies unpaid order with outstanding balance', () {
      final json = {
        'id': 'so-8888',
        'order_number': 'SO-20261124-008',
        'status': 'completed',
        'customer_id': 'cust-101',
        'vehicle_id': 'veh-201',
        'odometer': 12000,
        'created_at': '2026-11-24T08:00:00.000Z',
        'updated_at': '2026-11-24T11:30:00.000Z',
        'customers': {'full_name': 'Charles Leclerc'},
        'vehicles': {
          'license_plate': 'B 16 CL',
          'make': 'Ferrari',
          'model': '296 GTB',
        },
        'invoices': [
          {
            'id': 'inv-777',
            'invoice_number': 'INV-20261124-0002',
            'status': 'partially_paid',
            'total_amount_cents': 250000000,
            'amount_paid_cents': 100000000,
            'outstanding_balance_cents': 150000000,
          }
        ],
      };

      final candidate = HandoverOrderCandidate.fromJson(json);
      expect(candidate.isPaid, isFalse);
      expect(candidate.outstandingBalanceCents, equals(150000000));
    });
  });
}
