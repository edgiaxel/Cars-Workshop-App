/// Domain entity representing automated maintenance reminders (date & odometer based).
class MaintenanceReminder {
  const MaintenanceReminder({
    required this.id,
    required this.customerId,
    required this.vehicleId,
    this.serviceOrderId,
    required this.reminderType,
    required this.title,
    this.description,
    this.dueDate,
    this.dueOdometerKm,
    this.status = 'pending',
    this.lastNotifiedAt,
    this.dismissedAt,
    this.vehicleMake,
    this.vehicleModel,
    this.licensePlate,
    this.currentMileageKm,
    this.customerName,
  });

  final String id;
  final String customerId;
  final String vehicleId;
  final String? serviceOrderId;
  final String reminderType;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final int? dueOdometerKm;
  final String status;
  final DateTime? lastNotifiedAt;
  final DateTime? dismissedAt;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? licensePlate;
  final int? currentMileageKm;
  final String? customerName;

  factory MaintenanceReminder.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicles'] as Map<String, dynamic>?;
    final customer = json['customers'] as Map<String, dynamic>?;

    return MaintenanceReminder(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      serviceOrderId: json['service_order_id'] as String?,
      reminderType: (json['reminder_type'] as String?) ?? 'scheduled_date',
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'] as String) : null,
      dueOdometerKm: (json['due_odometer_km'] as num?)?.toInt(),
      status: (json['status'] as String?) ?? 'pending',
      lastNotifiedAt: json['last_notified_at'] != null
          ? DateTime.tryParse(json['last_notified_at'] as String)
          : null,
      dismissedAt: json['dismissed_at'] != null
          ? DateTime.tryParse(json['dismissed_at'] as String)
          : null,
      vehicleMake: vehicle?['make'] as String?,
      vehicleModel: vehicle?['model'] as String?,
      licensePlate: vehicle?['license_plate'] as String?,
      currentMileageKm: (vehicle?['mileage'] as num?)?.toInt(),
      customerName: customer?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'vehicle_id': vehicleId,
      'service_order_id': serviceOrderId,
      'reminder_type': reminderType,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'due_odometer_km': dueOdometerKm,
      'status': status,
      'last_notified_at': lastNotifiedAt?.toIso8601String(),
      'dismissed_at': dismissedAt?.toIso8601String(),
    };
  }

  MaintenanceReminder copyWith({
    String? id,
    String? customerId,
    String? vehicleId,
    String? serviceOrderId,
    String? reminderType,
    String? title,
    String? description,
    DateTime? dueDate,
    int? dueOdometerKm,
    String? status,
    DateTime? lastNotifiedAt,
    DateTime? dismissedAt,
    String? vehicleMake,
    String? vehicleModel,
    String? licensePlate,
    int? currentMileageKm,
    String? customerName,
  }) {
    return MaintenanceReminder(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      serviceOrderId: serviceOrderId ?? this.serviceOrderId,
      reminderType: reminderType ?? this.reminderType,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueOdometerKm: dueOdometerKm ?? this.dueOdometerKm,
      status: status ?? this.status,
      lastNotifiedAt: lastNotifiedAt ?? this.lastNotifiedAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      licensePlate: licensePlate ?? this.licensePlate,
      currentMileageKm: currentMileageKm ?? this.currentMileageKm,
      customerName: customerName ?? this.customerName,
    );
  }
}
