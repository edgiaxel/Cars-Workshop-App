/// Spare part domain model mapping to public.spare_parts table.
class SparePart {
  const SparePart({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    this.brand,
    this.description,
    this.unit = 'pcs',
    this.unitCost = 0.0,
    this.sellingPrice = 0.0,
    this.minimumStock = 0,
    this.stock = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String sku;
  final String name;
  final String category;
  final String? brand;
  final String? description;
  final String unit;
  final double unitCost;
  final double sellingPrice;
  final int minimumStock;
  final int stock;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isLowStock => stock <= minimumStock;

  factory SparePart.fromJson(Map<String, dynamic> json) {
    int calculatedStock = 0;
    if (json['inventory_transactions'] != null &&
        json['inventory_transactions'] is List) {
      for (final tx in json['inventory_transactions'] as List) {
        if (tx is Map<String, dynamic> && tx['quantity'] != null) {
          calculatedStock += (tx['quantity'] as num).toInt();
        }
      }
    } else if (json['stock'] != null) {
      calculatedStock = (json['stock'] as num).toInt();
    }

    return SparePart(
      id: json['id'] as String,
      sku: json['sku'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String?,
      description: json['description'] as String?,
      unit: json['unit'] as String? ?? 'pcs',
      unitCost: (json['unit_cost'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
      minimumStock: json['minimum_stock'] as int? ?? 0,
      stock: calculatedStock,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'category': category,
      if (brand != null) 'brand': brand,
      if (description != null) 'description': description,
      'unit': unit,
      'unit_cost': unitCost,
      'selling_price': sellingPrice,
      'minimum_stock': minimumStock,
      'is_active': isActive,
    };
  }

  SparePart copyWith({
    String? id,
    String? sku,
    String? name,
    String? category,
    String? brand,
    String? description,
    String? unit,
    double? unitCost,
    double? sellingPrice,
    int? minimumStock,
    int? stock,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SparePart(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      unitCost: unitCost ?? this.unitCost,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      minimumStock: minimumStock ?? this.minimumStock,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
