import 'customer.dart';
import 'mechanic.dart';
import 'vehicle.dart';

enum ServiceStatus {
  requested('requested', 'Requested'),
  approved('approved', 'Approved'),
  scheduled('scheduled', 'Scheduled'),
  inspection('inspection', 'Inspection'),
  diagnosis('diagnosis', 'Diagnosis'),
  waitingForApproval('waiting_for_approval', 'Waiting for Approval'),
  waitingForParts('waiting_for_parts', 'Waiting for Parts'),
  inProgress('in_progress', 'In Progress'),
  completionReview('completion_review', 'Completion Review'),
  completed('completed', 'Completed'),
  payment('payment', 'Payment'),
  closed('closed', 'Closed'),
  cancelled('cancelled', 'Cancelled');

  const ServiceStatus(this.value, this.label);
  final String value;
  final String label;

  static ServiceStatus fromString(String val) {
    return ServiceStatus.values.firstWhere(
      (s) => s.value == val.toLowerCase(),
      orElse: () => ServiceStatus.requested,
    );
  }
}

/// Service assignment mapping to public.service_assignments table.
class ServiceAssignment {
  const ServiceAssignment({
    required this.id,
    required this.serviceOrderId,
    required this.mechanicId,
    this.roleDescription,
    this.assignedAt,
    this.completedAt,
    this.mechanic,
  });

  final String id;
  final String serviceOrderId;
  final String mechanicId;
  final String? roleDescription;
  final DateTime? assignedAt;
  final DateTime? completedAt;
  final Mechanic? mechanic;

  factory ServiceAssignment.fromJson(Map<String, dynamic> json) {
    Mechanic? mech;
    if (json['mechanics'] != null &&
        json['mechanics'] is Map<String, dynamic>) {
      mech = Mechanic.fromJson(json['mechanics'] as Map<String, dynamic>);
    }

    return ServiceAssignment(
      id: json['id'] as String,
      serviceOrderId: json['service_order_id'] as String,
      mechanicId: json['mechanic_id'] as String,
      roleDescription: json['role_description'] as String?,
      assignedAt: json['assigned_at'] != null
          ? DateTime.tryParse(json['assigned_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      mechanic: mech,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_order_id': serviceOrderId,
      'mechanic_id': mechanicId,
      if (roleDescription != null) 'role_description': roleDescription,
    };
  }
}

/// Service order domain model mapping to public.service_orders table.
class ServiceOrder {
  const ServiceOrder({
    required this.id,
    required this.orderNumber,
    this.bookingId,
    required this.customerId,
    required this.vehicleId,
    required this.title,
    this.description,
    this.status = ServiceStatus.requested,
    this.scheduledStart,
    this.scheduledEnd,
    this.odometerKm,
    this.estimatedTotal = 0.0,
    this.finalTotal,
    this.customerApproved = false,
    this.completedAt,
    this.closedAt,
    this.createdAt,
    this.updatedAt,
    this.customer,
    this.vehicle,
    this.assignments = const [],
  });

  final String id;
  final String orderNumber;
  final String? bookingId;
  final String customerId;
  final String vehicleId;
  final String title;
  final String? description;
  final ServiceStatus status;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final int? odometerKm;
  final double estimatedTotal;
  final double? finalTotal;
  final bool customerApproved;
  final DateTime? completedAt;
  final DateTime? closedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Customer? customer;
  final Vehicle? vehicle;
  final List<ServiceAssignment> assignments;

  Mechanic? get primaryMechanic =>
      assignments.isNotEmpty ? assignments.first.mechanic : null;

  String get mechanicDisplayName =>
      primaryMechanic?.displayName ?? 'Unassigned';

  factory ServiceOrder.fromJson(Map<String, dynamic> json) {
    Customer? cust;
    if (json['customers'] != null &&
        json['customers'] is Map<String, dynamic>) {
      cust = Customer.fromJson(json['customers'] as Map<String, dynamic>);
    }

    Vehicle? veh;
    if (json['vehicles'] != null && json['vehicles'] is Map<String, dynamic>) {
      veh = Vehicle.fromJson(json['vehicles'] as Map<String, dynamic>);
    }

    final assignmentsList = <ServiceAssignment>[];
    if (json['service_assignments'] != null &&
        json['service_assignments'] is List) {
      for (final a in json['service_assignments'] as List) {
        if (a is Map<String, dynamic>) {
          assignmentsList.add(ServiceAssignment.fromJson(a));
        }
      }
    }

    return ServiceOrder(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      bookingId: json['booking_id'] as String?,
      customerId: json['customer_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: ServiceStatus.fromString(
        json['status'] as String? ?? 'requested',
      ),
      scheduledStart: json['scheduled_start'] != null
          ? DateTime.tryParse(json['scheduled_start'] as String)
          : null,
      scheduledEnd: json['scheduled_end'] != null
          ? DateTime.tryParse(json['scheduled_end'] as String)
          : null,
      odometerKm: json['odometer_km'] as int?,
      estimatedTotal: (json['estimated_total'] as num?)?.toDouble() ?? 0.0,
      finalTotal: (json['final_total'] as num?)?.toDouble(),
      customerApproved: json['customer_approved'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.tryParse(json['closed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      customer: cust,
      vehicle: veh,
      assignments: assignmentsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      if (bookingId != null) 'booking_id': bookingId,
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'title': title,
      if (description != null) 'description': description,
      'status': status.value,
      if (scheduledStart != null)
        'scheduled_start': scheduledStart!.toIso8601String(),
      if (scheduledEnd != null)
        'scheduled_end': scheduledEnd!.toIso8601String(),
      if (odometerKm != null) 'odometer_km': odometerKm,
      'estimated_total': estimatedTotal,
      if (finalTotal != null) 'final_total': finalTotal,
      'customer_approved': customerApproved,
    };
  }

  ServiceOrder copyWith({
    String? id,
    String? orderNumber,
    String? bookingId,
    String? customerId,
    String? vehicleId,
    String? title,
    String? description,
    ServiceStatus? status,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    int? odometerKm,
    double? estimatedTotal,
    double? finalTotal,
    bool? customerApproved,
    DateTime? completedAt,
    DateTime? closedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Customer? customer,
    Vehicle? vehicle,
    List<ServiceAssignment>? assignments,
  }) {
    return ServiceOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      odometerKm: odometerKm ?? this.odometerKm,
      estimatedTotal: estimatedTotal ?? this.estimatedTotal,
      finalTotal: finalTotal ?? this.finalTotal,
      customerApproved: customerApproved ?? this.customerApproved,
      completedAt: completedAt ?? this.completedAt,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customer: customer ?? this.customer,
      vehicle: vehicle ?? this.vehicle,
      assignments: assignments ?? this.assignments,
    );
  }
}
