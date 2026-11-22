import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/estimates/data/models/estimate_authorization_model.dart';
import 'package:pitmate/features/estimates/data/models/estimate_item_model.dart';
import 'package:pitmate/features/estimates/data/models/estimate_model.dart';

void main() {
  group('EstimateStatus Enum Tests', () {
    test('fromString parses all database status strings correctly', () {
      expect(EstimateStatus.fromString('draft'), EstimateStatus.draft);
      expect(EstimateStatus.fromString('sent'), EstimateStatus.sent);
      expect(EstimateStatus.fromString('approved'), EstimateStatus.approved);
      expect(EstimateStatus.fromString('partially_approved'), EstimateStatus.partiallyApproved);
      expect(EstimateStatus.fromString('rejected'), EstimateStatus.rejected);
      expect(EstimateStatus.fromString('superseded'), EstimateStatus.superseded);
      expect(EstimateStatus.fromString(null), EstimateStatus.draft);
      expect(EstimateStatus.fromString('unknown_status'), EstimateStatus.draft);
    });

    test('toDbString outputs exact PostgreSQL enum strings', () {
      expect(EstimateStatus.draft.toDbString(), 'draft');
      expect(EstimateStatus.sent.toDbString(), 'sent');
      expect(EstimateStatus.approved.toDbString(), 'approved');
      expect(EstimateStatus.partiallyApproved.toDbString(), 'partially_approved');
      expect(EstimateStatus.rejected.toDbString(), 'rejected');
      expect(EstimateStatus.superseded.toDbString(), 'superseded');
    });

    test('displayName returns readable UI labels', () {
      expect(EstimateStatus.draft.displayName, 'Draft');
      expect(EstimateStatus.sent.displayName, 'Sent to Customer');
      expect(EstimateStatus.approved.displayName, 'Approved');
      expect(EstimateStatus.partiallyApproved.displayName, 'Partially Approved');
      expect(EstimateStatus.rejected.displayName, 'Work Rejected');
      expect(EstimateStatus.superseded.displayName, 'Superseded');
    });
  });

  group('EstimateItemType Enum Tests', () {
    test('fromString parses item types correctly', () {
      expect(EstimateItemType.fromString('part'), EstimateItemType.part);
      expect(EstimateItemType.fromString('labor'), EstimateItemType.labor);
      expect(EstimateItemType.fromString('package'), EstimateItemType.package);
      expect(EstimateItemType.fromString(null), EstimateItemType.part);
    });

    test('toDbString and displayName match expected format', () {
      expect(EstimateItemType.part.toDbString(), 'part');
      expect(EstimateItemType.labor.toDbString(), 'labor');
      expect(EstimateItemType.package.toDbString(), 'package');
      expect(EstimateItemType.part.displayName, 'Part');
      expect(EstimateItemType.labor.displayName, 'Labor');
      expect(EstimateItemType.package.displayName, 'Package');
    });
  });

  group('AuthorizationStatus Enum Tests', () {
    test('fromString parses authorization statuses correctly', () {
      expect(AuthorizationStatus.fromString('pending'), AuthorizationStatus.pending);
      expect(AuthorizationStatus.fromString('approved'), AuthorizationStatus.approved);
      expect(AuthorizationStatus.fromString('rejected'), AuthorizationStatus.rejected);
      expect(AuthorizationStatus.fromString('deferred'), AuthorizationStatus.deferred);
      expect(AuthorizationStatus.fromString(null), AuthorizationStatus.pending);
    });

    test('toDbString and displayName match expectations', () {
      expect(AuthorizationStatus.pending.toDbString(), 'pending');
      expect(AuthorizationStatus.approved.toDbString(), 'approved');
      expect(AuthorizationStatus.rejected.toDbString(), 'rejected');
      expect(AuthorizationStatus.deferred.toDbString(), 'deferred');
      expect(AuthorizationStatus.pending.displayName, 'Pending');
    });
  });

  group('EstimateModel Serialization & Entity Tests', () {
    final testDate = DateTime.parse('2026-11-23T10:00:00Z');

    test('fromJson and toJson round-trip correctly', () {
      final json = {
        'id': 'est-123',
        'service_order_id': 'so-456',
        'inspection_id': 'insp-789',
        'revision_number': 2,
        'status': 'sent',
        'subtotal_cents': 315000000,
        'tax_cents': 34650000,
        'discount_cents': 0,
        'total_cents': 349650000,
        'notes': 'OEM brake pad and fluid flush',
        'created_by': 'admin-uuid',
        'created_at': testDate.toIso8601String(),
        'updated_at': testDate.toIso8601String(),
      };

      final estimate = EstimateModel.fromJson(json);

      expect(estimate.id, 'est-123');
      expect(estimate.serviceOrderId, 'so-456');
      expect(estimate.inspectionId, 'insp-789');
      expect(estimate.revisionNumber, 2);
      expect(estimate.status, EstimateStatus.sent);
      expect(estimate.subtotalCents, 315000000);
      expect(estimate.taxCents, 34650000);
      expect(estimate.discountCents, 0);
      expect(estimate.totalCents, 349650000);
      expect(estimate.notes, 'OEM brake pad and fluid flush');
      expect(estimate.createdBy, 'admin-uuid');
      expect(estimate.revisionLabel, 'Revision 2');

      final serialized = estimate.toJson();
      expect(serialized['id'], 'est-123');
      expect(serialized['service_order_id'], 'so-456');
      expect(serialized['status'], 'sent');
      expect(serialized['subtotal_cents'], 315000000);
      expect(serialized['total_cents'], 349650000);
    });

    test('copyWith updates specified attributes', () {
      final original = EstimateModel(
        id: 'est-1',
        serviceOrderId: 'so-1',
        revisionNumber: 1,
        status: EstimateStatus.draft,
        subtotalCents: 10000000,
        taxCents: 1100000,
        discountCents: 0,
        totalCents: 11100000,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final updated = original.copyWith(
        status: EstimateStatus.approved,
        revisionNumber: 2,
        discountCents: 500000,
      );

      expect(updated.id, 'est-1');
      expect(updated.status, EstimateStatus.approved);
      expect(updated.revisionNumber, 2);
      expect(updated.discountCents, 500000);
      expect(updated.subtotalCents, 10000000);
    });

    test('equality and hashCode work as expected', () {
      final est1 = EstimateModel(
        id: 'est-1',
        serviceOrderId: 'so-1',
        revisionNumber: 1,
        status: EstimateStatus.draft,
        subtotalCents: 1000,
        taxCents: 110,
        discountCents: 0,
        totalCents: 1110,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final est2 = EstimateModel(
        id: 'est-1',
        serviceOrderId: 'so-1',
        revisionNumber: 1,
        status: EstimateStatus.draft,
        subtotalCents: 1000,
        taxCents: 110,
        discountCents: 0,
        totalCents: 1110,
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(est1, equals(est2));
      expect(est1.hashCode, equals(est2.hashCode));
    });
  });

  group('EstimateItemModel Serialization & Entity Tests', () {
    final testDate = DateTime.parse('2026-11-23T10:00:00Z');

    test('create factory auto-calculates total price', () {
      final item = EstimateItemModel.create(
        id: 'item-1',
        estimateId: 'est-1',
        itemType: EstimateItemType.part,
        description: 'Brembo Pad Set',
        quantity: 2,
        unitPriceCents: 15000000,
        isOptional: true,
      );

      expect(item.quantity, 2);
      expect(item.unitPriceCents, 15000000);
      expect(item.totalPriceCents, 30000000);
      expect(item.isOptional, isTrue);
      expect(item.formattedUnitPrice, 'Rp 150.000');
      expect(item.formattedTotalPrice, 'Rp 300.000');
    });

    test('fromJson and toJson round-trip correctly', () {
      final json = {
        'id': 'item-99',
        'estimate_id': 'est-1',
        'item_type': 'labor',
        'description': 'Caliper Overhaul',
        'quantity': 1,
        'unit_price_cents': 50000000,
        'total_price_cents': 50000000,
        'is_optional': false,
        'authorization_status': 'pending',
        'created_at': testDate.toIso8601String(),
      };

      final item = EstimateItemModel.fromJson(json);
      expect(item.id, 'item-99');
      expect(item.itemType, EstimateItemType.labor);
      expect(item.unitPriceCents, 50000000);
      expect(item.totalPriceCents, 50000000);

      final map = item.toJson();
      expect(map['item_type'], 'labor');
      expect(map['total_price_cents'], 50000000);
    });
  });

  group('EstimateAuthorizationModel Tests', () {
    final testDate = DateTime.parse('2026-11-23T12:00:00Z');

    test('fromJson and toJson map correctly', () {
      final json = {
        'id': 'auth-1',
        'estimate_id': 'est-1',
        'authorized_by': 'user-123',
        'status': 'approved',
        'signature_token': 'SIG-TOKEN-999',
        'notes': 'Authorized via web portal',
        'authorized_at': testDate.toIso8601String(),
      };

      final auth = EstimateAuthorizationModel.fromJson(json);
      expect(auth.id, 'auth-1');
      expect(auth.status, EstimateStatus.approved);
      expect(auth.signatureToken, 'SIG-TOKEN-999');

      final map = auth.toJson();
      expect(map['signature_token'], 'SIG-TOKEN-999');
      expect(map['status'], 'approved');
    });
  });
}
