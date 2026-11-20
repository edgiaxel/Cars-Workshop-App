import 'customer.dart';
import 'vehicle.dart';

/// Domain model for public.service_reminders table.
class ServiceReminder {
  const ServiceReminder({
    required this.id,
    required this.customerId,
    required this.vehicleId,
    required this.reminderType,
    required this.title,
    this.description,
    this.dueDate,
    this.dueMileageKm,
    this.status = 'pending',
    this.completedAt,
    this.createdAt,
    this.customer,
    this.vehicle,
  });

  final String id;
  final String customerId;
  final String vehicleId;
  final String reminderType; // 'service', 'maintenance', 'inspection', 'custom'
  final String title;
  final String? description;
  final DateTime? dueDate;
  final int? dueMileageKm;
  final String status; // 'pending', 'completed', 'dismissed', 'cancelled'
  final DateTime? completedAt;
  final DateTime? createdAt;
  final Customer? customer;
  final Vehicle? vehicle;

  String get vehicleDisplayName => vehicle?.displayName ?? 'Vehicle';
  String get vehicleIdentifier => vehicle?.identifierLabel ?? '';

  factory ServiceReminder.fromJson(Map<String, dynamic> json) {
    Customer? cust;
    if (json['customers'] != null &&
        json['customers'] is Map<String, dynamic>) {
      cust = Customer.fromJson(json['customers'] as Map<String, dynamic>);
    }

    Vehicle? veh;
    if (json['vehicles'] != null && json['vehicles'] is Map<String, dynamic>) {
      veh = Vehicle.fromJson(json['vehicles'] as Map<String, dynamic>);
    }

    return ServiceReminder(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      reminderType: json['reminder_type'] as String? ?? 'maintenance',
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      dueMileageKm: json['due_mileage_km'] as int?,
      status: json['status'] as String? ?? 'pending',
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
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
      'reminder_type': reminderType,
      'title': title,
      if (description != null) 'description': description,
      if (dueDate != null)
        'due_date':
            "${dueDate!.year.toString().padLeft(4, '0')}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}",
      if (dueMileageKm != null) 'due_mileage_km': dueMileageKm,
      'status': status,
    };
  }

  ServiceReminder copyWith({
    String? id,
    String? customerId,
    String? vehicleId,
    String? reminderType,
    String? title,
    String? description,
    DateTime? dueDate,
    int? dueMileageKm,
    String? status,
    DateTime? completedAt,
    DateTime? createdAt,
    Customer? customer,
    Vehicle? vehicle,
  }) {
    return ServiceReminder(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      reminderType: reminderType ?? this.reminderType,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueMileageKm: dueMileageKm ?? this.dueMileageKm,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      customer: customer ?? this.customer,
      vehicle: vehicle ?? this.vehicle,
    );
  }
}
