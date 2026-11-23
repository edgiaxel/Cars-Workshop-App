/// Part entity representing catalog item and live warehouse stock balances.
class PartModel {
  final String id;
  final String sku;
  final String name;
  final String category;
  final String unitOfMeasurement;
  final int purchaseCostCents;
  final int sellingPriceCents;
  final int minimumStock;
  final int quantityOnHand;
  final int quantityReserved;
  final int quantityAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PartModel({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    this.unitOfMeasurement = 'pcs',
    required this.purchaseCostCents,
    required this.sellingPriceCents,
    this.minimumStock = 0,
    this.quantityOnHand = 0,
    this.quantityReserved = 0,
    this.quantityAvailable = 0,
    this.createdAt,
    this.updatedAt,
  });

  bool get isLowStock => quantityAvailable <= minimumStock && quantityAvailable > 0;
  bool get isOutOfStock => quantityAvailable <= 0;

  double get purchaseCostFormatted => purchaseCostCents / 100.0;
  double get sellingPriceFormatted => sellingPriceCents / 100.0;
  int get totalValuationCents => quantityOnHand * purchaseCostCents;

  factory PartModel.fromJson(Map<String, dynamic> json) {
    final balance = json['inventory_balances'];
    int onHand = 0;
    int reserved = 0;
    int available = 0;

    if (balance is Map<String, dynamic>) {
      onHand = (balance['quantity_on_hand'] as num?)?.toInt() ?? 0;
      reserved = (balance['quantity_reserved'] as num?)?.toInt() ?? 0;
      available = (balance['quantity_available'] as num?)?.toInt() ?? (onHand - reserved);
    } else if (balance is List && balance.isNotEmpty && balance.first is Map<String, dynamic>) {
      final b = balance.first as Map<String, dynamic>;
      onHand = (b['quantity_on_hand'] as num?)?.toInt() ?? 0;
      reserved = (b['quantity_reserved'] as num?)?.toInt() ?? 0;
      available = (b['quantity_available'] as num?)?.toInt() ?? (onHand - reserved);
    } else {
      onHand = (json['quantity_on_hand'] as num?)?.toInt() ?? 0;
      reserved = (json['quantity_reserved'] as num?)?.toInt() ?? 0;
      available = (json['quantity_available'] as num?)?.toInt() ?? (onHand - reserved);
    }

    return PartModel(
      id: json['id'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      unitOfMeasurement: json['unit_of_measurement'] as String? ?? 'pcs',
      purchaseCostCents: (json['purchase_cost_cents'] as num?)?.toInt() ?? 0,
      sellingPriceCents: (json['selling_price_cents'] as num?)?.toInt() ?? 0,
      minimumStock: (json['minimum_stock'] as num?)?.toInt() ?? 0,
      quantityOnHand: onHand,
      quantityReserved: reserved,
      quantityAvailable: available,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toDbJson() {
    return {
      'sku': sku,
      'name': name,
      'category': category,
      'unit_of_measurement': unitOfMeasurement,
      'purchase_cost_cents': purchaseCostCents,
      'selling_price_cents': sellingPriceCents,
      'minimum_stock': minimumStock,
    };
  }

  PartModel copyWith({
    String? id,
    String? sku,
    String? name,
    String? category,
    String? unitOfMeasurement,
    int? purchaseCostCents,
    int? sellingPriceCents,
    int? minimumStock,
    int? quantityOnHand,
    int? quantityReserved,
    int? quantityAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PartModel(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      category: category ?? this.category,
      unitOfMeasurement: unitOfMeasurement ?? this.unitOfMeasurement,
      purchaseCostCents: purchaseCostCents ?? this.purchaseCostCents,
      sellingPriceCents: sellingPriceCents ?? this.sellingPriceCents,
      minimumStock: minimumStock ?? this.minimumStock,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      quantityReserved: quantityReserved ?? this.quantityReserved,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
