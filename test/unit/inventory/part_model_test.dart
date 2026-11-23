import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/inventory/data/models/inventory_transaction_model.dart';
import 'package:pitmate/features/inventory/data/models/part_model.dart';

void main() {
  group('PartModel Unit Tests', () {
    test('fromJson correctly parses full database schema with joined inventory_balances', () {
      final json = {
        'id': 'part-101',
        'sku': 'OIL-5W30-SYN',
        'name': 'Motul 300V 5W-30 Full Synthetic 1L',
        'category': 'lubricants',
        'unit_of_measurement': 'liter',
        'purchase_cost_cents': 210000,
        'selling_price_cents': 295000,
        'minimum_stock': 15,
        'created_at': '2026-11-23T00:00:00Z',
        'inventory_balances': {
          'quantity_on_hand': 40,
          'quantity_reserved': 5,
          'quantity_available': 35,
        },
      };

      final part = PartModel.fromJson(json);

      expect(part.id, 'part-101');
      expect(part.sku, 'OIL-5W30-SYN');
      expect(part.name, 'Motul 300V 5W-30 Full Synthetic 1L');
      expect(part.category, 'lubricants');
      expect(part.unitOfMeasurement, 'liter');
      expect(part.purchaseCostCents, 210000);
      expect(part.sellingPriceCents, 295000);
      expect(part.minimumStock, 15);
      expect(part.quantityOnHand, 40);
      expect(part.quantityReserved, 5);
      expect(part.quantityAvailable, 35);
      expect(part.isLowStock, false);
      expect(part.isOutOfStock, false);
      expect(part.totalValuationCents, 40 * 210000);
    });

    test('low stock and out of stock evaluations', () {
      const normalPart = PartModel(
        id: 'p1',
        sku: 'P1',
        name: 'Normal',
        category: 'filters',
        purchaseCostCents: 10000,
        sellingPriceCents: 20000,
        minimumStock: 5,
        quantityOnHand: 20,
        quantityReserved: 0,
        quantityAvailable: 20,
      );
      expect(normalPart.isLowStock, false);
      expect(normalPart.isOutOfStock, false);

      const lowPart = PartModel(
        id: 'p2',
        sku: 'P2',
        name: 'Low',
        category: 'filters',
        purchaseCostCents: 10000,
        sellingPriceCents: 20000,
        minimumStock: 10,
        quantityOnHand: 8,
        quantityReserved: 0,
        quantityAvailable: 8,
      );
      expect(lowPart.isLowStock, true);
      expect(lowPart.isOutOfStock, false);

      const outPart = PartModel(
        id: 'p3',
        sku: 'P3',
        name: 'Out',
        category: 'filters',
        purchaseCostCents: 10000,
        sellingPriceCents: 20000,
        minimumStock: 5,
        quantityOnHand: 4,
        quantityReserved: 4,
        quantityAvailable: 0,
      );
      expect(outPart.isOutOfStock, true);
    });

    test('copyWith updates specified attributes', () {
      const part = PartModel(
        id: 'p1',
        sku: 'P1',
        name: 'Oil',
        category: 'lubricants',
        purchaseCostCents: 150000,
        sellingPriceCents: 250000,
        quantityOnHand: 10,
      );

      final updated = part.copyWith(quantityOnHand: 15, purchaseCostCents: 160000);
      expect(updated.quantityOnHand, 15);
      expect(updated.purchaseCostCents, 160000);
      expect(updated.sellingPriceCents, 250000);
    });
  });

  group('InventoryTransactionModel Unit Tests', () {
    test('fromJson and typeLabel helper', () {
      final json = {
        'id': 'tx-001',
        'part_id': 'part-101',
        'transaction_type': 'receiving',
        'quantity_change': 20,
        'balance_after_on_hand': 40,
        'balance_after_reserved': 5,
        'unit_cost_cents': 210000,
        'total_cost_cents': 4200000,
        'reason': 'PO-9912 Stock receipt',
        'reference_id': 'PO-9912',
        'performed_by': 'admin-uuid',
        'created_at': '2026-11-23T10:00:00Z',
      };

      final tx = InventoryTransactionModel.fromJson(json);

      expect(tx.id, 'tx-001');
      expect(tx.partId, 'part-101');
      expect(tx.transactionType, 'receiving');
      expect(tx.typeLabel, 'Stock Receipt');
      expect(tx.quantityChange, 20);
      expect(tx.balanceAfterOnHand, 40);
      expect(tx.unitCostCents, 210000);
      expect(tx.totalCostCents, 4200000);
      expect(tx.reason, 'PO-9912 Stock receipt');
    });
  });
}
