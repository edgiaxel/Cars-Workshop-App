enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  rescheduled,
  // ignore: constant_identifier_names
  checked_in,
  rejected;

  static BookingStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'rescheduled':
        return BookingStatus.rescheduled;
      case 'checked_in':
        return BookingStatus.checked_in;
      case 'rejected':
        return BookingStatus.rejected;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }

  String toDbString() {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.rescheduled:
        return 'rescheduled';
      case BookingStatus.checked_in:
        return 'checked_in';
      case BookingStatus.rejected:
        return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.rescheduled:
        return 'Rescheduled';
      case BookingStatus.checked_in:
        return 'Checked In';
      case BookingStatus.rejected:
        return 'Rejected';
    }
  }
}

class BookingModel {
  const BookingModel({
    required this.id,
    required this.customerId,
    required this.vehicleId,
    required this.bookingDate,
    required this.timeSlot,
    required this.serviceType,
    this.customerNotes,
    this.adminNotes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.vehiclePlate,
    this.vehicleMake,
    this.vehicleModel,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
  });

  final String id;
  final String customerId;
  final String vehicleId;
  final DateTime bookingDate;
  final String timeSlot;
  final String serviceType;
  final String? customerNotes;
  final String? adminNotes;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined relational fields
  final String? vehiclePlate;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;

  String get vehicleDescription {
    if (vehiclePlate != null && vehicleMake != null) {
      return '$vehicleMake $vehicleModel [$vehiclePlate]';
    }
    if (vehiclePlate != null) {
      return vehiclePlate!;
    }
    return 'Vehicle ID: ${vehicleId.substring(0, vehicleId.length > 8 ? 8 : vehicleId.length)}';
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final vehicleData = json['vehicles'] as Map<String, dynamic>?;
    final customerData = json['customers'] as Map<String, dynamic>?;

    final bookingDateRaw = json['booking_date'];
    final DateTime parsedDate;
    if (bookingDateRaw is DateTime) {
      parsedDate = bookingDateRaw;
    } else if (bookingDateRaw is String) {
      parsedDate = DateTime.tryParse(bookingDateRaw) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

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

    return BookingModel(
      id: json['id'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      vehicleId: json['vehicle_id'] as String? ?? '',
      bookingDate: parsedDate,
      timeSlot: json['time_slot'] as String? ?? '',
      serviceType: json['service_type'] as String? ?? '',
      customerNotes: json['customer_notes'] as String?,
      adminNotes: json['admin_notes'] as String?,
      status: BookingStatus.fromString(json['status'] as String?),
      createdAt: parsedCreated,
      updatedAt: parsedUpdated,
      vehiclePlate: (vehicleData?['license_plate'] as String?) ?? (json['license_plate'] as String?),
      vehicleMake: (vehicleData?['make'] as String?) ?? (json['make'] as String?),
      vehicleModel: (vehicleData?['model'] as String?) ?? (json['model'] as String?),
      customerName: (customerData?['full_name'] as String?) ?? (json['full_name'] as String?),
      customerPhone: (customerData?['phone_number'] as String?) ?? (json['phone_number'] as String?),
      customerEmail: (customerData?['email'] as String?) ?? (json['email'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'booking_date':
          '${bookingDate.year.toString().padLeft(4, '0')}-${bookingDate.month.toString().padLeft(2, '0')}-${bookingDate.day.toString().padLeft(2, '0')}',
      'time_slot': timeSlot,
      'service_type': serviceType,
      'customer_notes': customerNotes,
      'admin_notes': adminNotes,
      'status': status.toDbString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BookingModel copyWith({
    String? id,
    String? customerId,
    String? vehicleId,
    DateTime? bookingDate,
    String? timeSlot,
    String? serviceType,
    String? customerNotes,
    String? adminNotes,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? vehiclePlate,
    String? vehicleMake,
    String? vehicleModel,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) {
    return BookingModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      bookingDate: bookingDate ?? this.bookingDate,
      timeSlot: timeSlot ?? this.timeSlot,
      serviceType: serviceType ?? this.serviceType,
      customerNotes: customerNotes ?? this.customerNotes,
      adminNotes: adminNotes ?? this.adminNotes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          customerId == other.customerId &&
          vehicleId == other.vehicleId &&
          timeSlot == other.timeSlot &&
          serviceType == other.serviceType &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, customerId, vehicleId, timeSlot, serviceType, status);
}
