/// Inventory movement transaction model for immutable audit ledger.
class InventoryTransactionModel {
  final String id;
  final String partId;
  final String transactionType;
  final int quantityChange;
  final int balanceAfterOnHand;
  final int balanceAfterReserved;
  final int unitCostCents;
  final int totalCostCents;
  final String? reason;
  final String? referenceId;
  final String performedBy;
  final DateTime createdAt;

  const InventoryTransactionModel({
    required this.id,
    required this.partId,
    required this.transactionType,
    required this.quantityChange,
    required this.balanceAfterOnHand,
    required this.balanceAfterReserved,
    this.unitCostCents = 0,
    this.totalCostCents = 0,
    this.reason,
    this.referenceId,
    required this.performedBy,
    required this.createdAt,
  });

  factory InventoryTransactionModel.fromJson(Map<String, dynamic> json) {
    return InventoryTransactionModel(
      id: json['id'] as String? ?? '',
      partId: json['part_id'] as String? ?? '',
      transactionType: json['transaction_type'] as String? ?? 'adjustment',
      quantityChange: (json['quantity_change'] as num?)?.toInt() ?? 0,
      balanceAfterOnHand: (json['balance_after_on_hand'] as num?)?.toInt() ?? 0,
      balanceAfterReserved: (json['balance_after_reserved'] as num?)?.toInt() ?? 0,
      unitCostCents: (json['unit_cost_cents'] as num?)?.toInt() ?? 0,
      totalCostCents: (json['total_cost_cents'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String?,
      referenceId: json['reference_id'] as String?,
      performedBy: json['performed_by'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  String get typeLabel {
    switch (transactionType) {
      case 'receiving':
        return 'Stock Receipt';
      case 'adjustment':
        return 'Adjustment';
      case 'reservation':
        return 'Job Reservation';
      case 'reservation_release':
        return 'Reservation Release';
      case 'issue':
        return 'Floor Issue';
      case 'consumption':
        return 'Operation Usage';
      case 'return':
        return 'Stock Return';
      case 'damaged':
        return 'Damaged Write-off';
      default:
        return transactionType.toUpperCase();
    }
  }
}
