class ServiceOrderModel {
  const ServiceOrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.vehicleId,
    this.bookingId,
    this.intakeType = 'walk_in',
    required this.odometer,
    required this.customerComplaint,
    this.fuelLevel,
    this.initialNotes,
    this.status = 'inspection_pending',
    this.assignedBay,
    required this.createdAt,
    required this.updatedAt,
    this.customerName,
    this.customerPhone,
    this.vehiclePlate,
    this.vehicleMake,
    this.vehicleModel,
  });

  final String id;
  final String orderNumber;
  final String customerId;
  final String vehicleId;
  final String? bookingId;
  final String intakeType;
  final int odometer;
  final String customerComplaint;
  final String? fuelLevel;
  final String? initialNotes;
  final String status;
  final String? assignedBay;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined relational fields
  final String? customerName;
  final String? customerPhone;
  final String? vehiclePlate;
  final String? vehicleMake;
  final String? vehicleModel;

  String get vehicleDescription {
    if (vehiclePlate != null && vehicleMake != null) {
      return '$vehicleMake $vehicleModel [$vehiclePlate]';
    }
    if (vehiclePlate != null) {
      return vehiclePlate!;
    }
    return 'Vehicle ID: ${vehicleId.substring(0, vehicleId.length > 8 ? 8 : vehicleId.length)}';
  }

  factory ServiceOrderModel.fromJson(Map<String, dynamic> json) {
    final vehicleData = json['vehicles'] as Map<String, dynamic>?;
    final customerData = json['customers'] as Map<String, dynamic>?;

    final createdAtRaw = json['created_at'];
    final DateTime parsedCreated;
    if (createdAtRaw is DateTime) {
      parsedCreated = createdAtRaw;
    } else if (createdAtRaw is String) {
      parsedCreated = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      parsedCreated = DateTime.now();
    }

    final updatedAtRaw = json['updated_at'];
    final DateTime parsedUpdated;
    if (updatedAtRaw is DateTime) {
      parsedUpdated = updatedAtRaw;
    } else if (updatedAtRaw is String) {
      parsedUpdated = DateTime.tryParse(updatedAtRaw) ?? DateTime.now();
    } else {
      parsedUpdated = DateTime.now();
    }

    return ServiceOrderModel(
      id: json['id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      vehicleId: json['vehicle_id'] as String? ?? '',
      bookingId: json['booking_id'] as String?,
      intakeType: json['intake_type'] as String? ?? 'walk_in',
      odometer: (json['odometer'] as num?)?.toInt() ?? 0,
      customerComplaint: json['customer_complaint'] as String? ?? '',
      fuelLevel: json['fuel_level'] as String?,
      initialNotes: json['initial_notes'] as String?,
      status: json['status'] as String? ?? 'inspection_pending',
      assignedBay: json['assigned_bay'] as String?,
      createdAt: parsedCreated,
      updatedAt: parsedUpdated,
      customerName: (customerData?['full_name'] as String?) ?? (json['full_name'] as String?),
      customerPhone: (customerData?['phone_number'] as String?) ?? (json['phone_number'] as String?),
      vehiclePlate: (vehicleData?['license_plate'] as String?) ?? (json['license_plate'] as String?),
      vehicleMake: (vehicleData?['make'] as String?) ?? (json['make'] as String?),
      vehicleModel: (vehicleData?['model'] as String?) ?? (json['model'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'booking_id': bookingId,
      'intake_type': intakeType,
      'odometer': odometer,
      'customer_complaint': customerComplaint,
      'fuel_level': fuelLevel,
      'initial_notes': initialNotes,
      'status': status,
      'assigned_bay': assignedBay,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ServiceOrderModel copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? vehicleId,
    String? bookingId,
    String? intakeType,
    int? odometer,
    String? customerComplaint,
    String? fuelLevel,
    String? initialNotes,
    String? status,
    String? assignedBay,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerName,
    String? customerPhone,
    String? vehiclePlate,
    String? vehicleMake,
    String? vehicleModel,
  }) {
    return ServiceOrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      bookingId: bookingId ?? this.bookingId,
      intakeType: intakeType ?? this.intakeType,
      odometer: odometer ?? this.odometer,
      customerComplaint: customerComplaint ?? this.customerComplaint,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      initialNotes: initialNotes ?? this.initialNotes,
      status: status ?? this.status,
      assignedBay: assignedBay ?? this.assignedBay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceOrderModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          orderNumber == other.orderNumber &&
          customerId == other.customerId &&
          vehicleId == other.vehicleId &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, orderNumber, customerId, vehicleId, status);
}
