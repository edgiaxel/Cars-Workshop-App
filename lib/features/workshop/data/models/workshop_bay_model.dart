/// Status of physical workshop bays.
enum BayStatus {
  available,
  occupied,
  maintenance;

  static BayStatus fromString(String? value) {
    switch (value) {
      case 'occupied':
        return BayStatus.occupied;
      case 'maintenance':
        return BayStatus.maintenance;
      case 'available':
      default:
        return BayStatus.available;
    }
  }

  String toDbString() => name;

  String get label {
    switch (this) {
      case BayStatus.available:
        return 'Available';
      case BayStatus.occupied:
        return 'Occupied';
      case BayStatus.maintenance:
        return 'Maintenance';
    }
  }
}

/// Workshop Bay representation.
class WorkshopBayModel {
  const WorkshopBayModel({
    required this.id,
    required this.bayNumber,
    required this.name,
    this.status = BayStatus.available,
    this.currentServiceOrderId,
    required this.createdAt,
    required this.updatedAt,
    this.currentOrderNumber,
    this.vehiclePlate,
    this.vehicleModel,
    this.customerName,
    this.leadMechanicName,
  });

  final String id;
  final int bayNumber;
  final String name;
  final BayStatus status;
  final String? currentServiceOrderId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relational display helpers
  final String? currentOrderNumber;
  final String? vehiclePlate;
  final String? vehicleModel;
  final String? customerName;
  final String? leadMechanicName;

  bool get isOccupied => status == BayStatus.occupied;
  bool get isAvailable => status == BayStatus.available;
  bool get isMaintenance => status == BayStatus.maintenance;

  factory WorkshopBayModel.fromJson(Map<String, dynamic> json) {
    final order = json['service_orders'] as Map<String, dynamic>?;
    final vehicle = order?['vehicles'] as Map<String, dynamic>?;
    final customer = order?['customers'] as Map<String, dynamic>?;

    final createdAtRaw = json['created_at'];
    final DateTime parsedCreated = createdAtRaw is String
        ? (DateTime.tryParse(createdAtRaw) ?? DateTime.now())
        : DateTime.now();

    final updatedAtRaw = json['updated_at'];
    final DateTime parsedUpdated = updatedAtRaw is String
        ? (DateTime.tryParse(updatedAtRaw) ?? DateTime.now())
        : DateTime.now();

    return WorkshopBayModel(
      id: json['id'] as String? ?? '',
      bayNumber: (json['bay_number'] as num?)?.toInt() ?? 1,
      name: json['name'] as String? ?? '',
      status: BayStatus.fromString(json['status'] as String?),
      currentServiceOrderId: json['current_service_order_id'] as String?,
      createdAt: parsedCreated,
      updatedAt: parsedUpdated,
      currentOrderNumber: order?['order_number'] as String?,
      vehiclePlate: vehicle?['license_plate'] as String?,
      vehicleModel: vehicle?['model'] as String?,
      customerName: customer?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bay_number': bayNumber,
      'name': name,
      'status': status.toDbString(),
      'current_service_order_id': currentServiceOrderId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  WorkshopBayModel copyWith({
    String? id,
    int? bayNumber,
    String? name,
    BayStatus? status,
    String? currentServiceOrderId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? currentOrderNumber,
    String? vehiclePlate,
    String? vehicleModel,
    String? customerName,
    String? leadMechanicName,
  }) {
    return WorkshopBayModel(
      id: id ?? this.id,
      bayNumber: bayNumber ?? this.bayNumber,
      name: name ?? this.name,
      status: status ?? this.status,
      currentServiceOrderId: currentServiceOrderId ?? this.currentServiceOrderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentOrderNumber: currentOrderNumber ?? this.currentOrderNumber,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      customerName: customerName ?? this.customerName,
      leadMechanicName: leadMechanicName ?? this.leadMechanicName,
    );
  }
}
