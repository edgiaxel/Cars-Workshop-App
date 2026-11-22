import 'estimate_model.dart';

/// Type of estimate line item.
enum EstimateItemType {
  part,
  labor,
  package;

  static EstimateItemType fromString(String? val) {
    switch (val) {
      case 'labor':
        return EstimateItemType.labor;
      case 'package':
        return EstimateItemType.package;
      case 'part':
      default:
        return EstimateItemType.part;
    }
  }

  String toDbString() => name;

  String get displayName {
    switch (this) {
      case EstimateItemType.part:
        return 'Part';
      case EstimateItemType.labor:
        return 'Labor';
      case EstimateItemType.package:
        return 'Package';
    }
  }
}

/// Authorization status for an individual line item.
enum AuthorizationStatus {
  pending,
  approved,
  rejected,
  deferred;

  static AuthorizationStatus fromString(String? val) {
    switch (val) {
      case 'approved':
        return AuthorizationStatus.approved;
      case 'rejected':
        return AuthorizationStatus.rejected;
      case 'deferred':
        return AuthorizationStatus.deferred;
      case 'pending':
      default:
        return AuthorizationStatus.pending;
    }
  }

  String toDbString() => name;

  String get displayName {
    switch (this) {
      case AuthorizationStatus.pending:
        return 'Pending';
      case AuthorizationStatus.approved:
        return 'Approved';
      case AuthorizationStatus.rejected:
        return 'Rejected';
      case AuthorizationStatus.deferred:
        return 'Deferred';
    }
  }
}

/// Itemized line in an estimate mapping `public.estimate_items` database table.
/// Monetary values are represented in integer cents (BIGINT in database).
class EstimateItemModel {
  const EstimateItemModel({
    required this.id,
    required this.estimateId,
    this.itemType = EstimateItemType.part,
    required this.description,
    this.quantity = 1,
    required this.unitPriceCents,
    required this.totalPriceCents,
    this.isOptional = false,
    this.authorizationStatus = AuthorizationStatus.pending,
    required this.createdAt,
  });

  final String id;
  final String estimateId;
  final EstimateItemType itemType;
  final String description;
  final int quantity;
  final int unitPriceCents;
  final int totalPriceCents;
  final bool isOptional;
  final AuthorizationStatus authorizationStatus;
  final DateTime createdAt;

  String get formattedUnitPrice => EstimateModel.formatIdr(unitPriceCents);
  String get formattedTotalPrice => EstimateModel.formatIdr(totalPriceCents);

  /// Helper factory to create a line item with auto-calculated total price.
  factory EstimateItemModel.create({
    String id = '',
    String estimateId = '',
    EstimateItemType itemType = EstimateItemType.part,
    required String description,
    int quantity = 1,
    required int unitPriceCents,
    bool isOptional = false,
    AuthorizationStatus authorizationStatus = AuthorizationStatus.pending,
    DateTime? createdAt,
  }) {
    final effectiveQuantity = quantity <= 0 ? 1 : quantity;
    final total = effectiveQuantity * unitPriceCents;
    return EstimateItemModel(
      id: id,
      estimateId: estimateId,
      itemType: itemType,
      description: description,
      quantity: effectiveQuantity,
      unitPriceCents: unitPriceCents,
      totalPriceCents: total,
      isOptional: isOptional,
      authorizationStatus: authorizationStatus,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  factory EstimateItemModel.fromJson(Map<String, dynamic> json) {
    final qty = ((json['quantity'] ?? 1) as num).toInt();
    final unitPrice = ((json['unit_price_cents'] ?? json['unitPriceCents'] ?? 0) as num).toInt();
    final totalPrice = ((json['total_price_cents'] ?? json['totalPriceCents'] ?? (qty * unitPrice)) as num).toInt();

    return EstimateItemModel(
      id: (json['id'] as String?) ?? '',
      estimateId: (json['estimate_id'] ?? json['estimateId'] ?? '') as String,
      itemType: EstimateItemType.fromString(json['item_type'] ?? json['itemType']),
      description: (json['description'] as String?) ?? '',
      quantity: qty,
      unitPriceCents: unitPrice,
      totalPriceCents: totalPrice,
      isOptional: (json['is_optional'] ?? json['isOptional'] ?? false) as bool,
      authorizationStatus: AuthorizationStatus.fromString(
        json['authorization_status'] ?? json['authorizationStatus'],
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'estimate_id': estimateId,
      'item_type': itemType.toDbString(),
      'description': description,
      'quantity': quantity,
      'unit_price_cents': unitPriceCents,
      'total_price_cents': totalPriceCents,
      'is_optional': isOptional,
      'authorization_status': authorizationStatus.toDbString(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  EstimateItemModel copyWith({
    String? id,
    String? estimateId,
    EstimateItemType? itemType,
    String? description,
    int? quantity,
    int? unitPriceCents,
    int? totalPriceCents,
    bool? isOptional,
    AuthorizationStatus? authorizationStatus,
    DateTime? createdAt,
  }) {
    final nextQuantity = quantity ?? this.quantity;
    final nextUnitPrice = unitPriceCents ?? this.unitPriceCents;
    final nextTotalPrice = totalPriceCents ?? (nextQuantity * nextUnitPrice);

    return EstimateItemModel(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      itemType: itemType ?? this.itemType,
      description: description ?? this.description,
      quantity: nextQuantity,
      unitPriceCents: nextUnitPrice,
      totalPriceCents: nextTotalPrice,
      isOptional: isOptional ?? this.isOptional,
      authorizationStatus: authorizationStatus ?? this.authorizationStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstimateItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          estimateId == other.estimateId &&
          itemType == other.itemType &&
          description == other.description &&
          quantity == other.quantity &&
          unitPriceCents == other.unitPriceCents &&
          totalPriceCents == other.totalPriceCents &&
          isOptional == other.isOptional &&
          authorizationStatus == other.authorizationStatus;

  @override
  int get hashCode => Object.hash(
        id,
        estimateId,
        itemType,
        description,
        quantity,
        unitPriceCents,
        totalPriceCents,
        isOptional,
        authorizationStatus,
      );
}
