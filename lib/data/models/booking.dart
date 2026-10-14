import 'customer.dart';
import 'vehicle.dart';

enum BookingStatus {
  requested('requested', 'Requested'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected'),
  scheduled('scheduled', 'Scheduled'),
  cancelled('cancelled', 'Cancelled'),
  completed('completed', 'Completed');

  const BookingStatus(this.value, this.label);
  final String value;
  final String label;

  static BookingStatus fromString(String val) {
    return BookingStatus.values.firstWhere(
      (s) => s.value == val.toLowerCase(),
      orElse: () => BookingStatus.requested,
    );
  }
}

/// Booking domain model mapping to public.bookings table.
class Booking {
  const Booking({
    required this.id,
    required this.customerId,
    required this.vehicleId,
    required this.requestedService,
    this.description,
    this.preferredDate,
    this.preferredTime,
    this.status = BookingStatus.requested,
    this.adminNotes,
    this.createdAt,
    this.updatedAt,
    this.customer,
    this.vehicle,
  });

  final String id;
  final String customerId;
  final String vehicleId;
  final String requestedService;
  final String? description;
  final String? preferredDate;
  final String? preferredTime;
  final BookingStatus status;
  final String? adminNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Customer? customer;
  final Vehicle? vehicle;

  factory Booking.fromJson(Map<String, dynamic> json) {
    Customer? cust;
    if (json['customers'] != null &&
        json['customers'] is Map<String, dynamic>) {
      cust = Customer.fromJson(json['customers'] as Map<String, dynamic>);
    }

    Vehicle? veh;
    if (json['vehicles'] != null && json['vehicles'] is Map<String, dynamic>) {
      veh = Vehicle.fromJson(json['vehicles'] as Map<String, dynamic>);
    }

    return Booking(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      requestedService: json['requested_service'] as String,
      description: json['description'] as String?,
      preferredDate: json['preferred_date'] as String?,
      preferredTime: json['preferred_time'] as String?,
      status: BookingStatus.fromString(
        json['status'] as String? ?? 'requested',
      ),
      adminNotes: json['admin_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      customer: cust,
      vehicle: veh,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'requested_service': requestedService,
      if (description != null) 'description': description,
      if (preferredDate != null) 'preferred_date': preferredDate,
      if (preferredTime != null) 'preferred_time': preferredTime,
      'status': status.value,
      if (adminNotes != null) 'admin_notes': adminNotes,
    };
  }

  Booking copyWith({
    String? id,
    String? customerId,
    String? vehicleId,
    String? requestedService,
    String? description,
    String? preferredDate,
    String? preferredTime,
    BookingStatus? status,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Customer? customer,
    Vehicle? vehicle,
  }) {
    return Booking(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      requestedService: requestedService ?? this.requestedService,
      description: description ?? this.description,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTime: preferredTime ?? this.preferredTime,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customer: customer ?? this.customer,
      vehicle: vehicle ?? this.vehicle,
    );
  }
}
