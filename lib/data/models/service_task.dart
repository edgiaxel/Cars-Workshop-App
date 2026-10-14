import 'mechanic.dart';
import 'service_order.dart';

/// Domain model for public.service_tasks table.
class ServiceTask {
  const ServiceTask({
    required this.id,
    required this.serviceOrderId,
    this.assignedMechanicId,
    this.templateId,
    required this.title,
    this.description,
    this.status = 'pending',
    this.estimatedMinutes,
    this.actualMinutes,
    this.startedAt,
    this.completedAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.mechanic,
    this.serviceOrder,
  });

  final String id;
  final String serviceOrderId;
  final String? assignedMechanicId;
  final String? templateId;
  final String title;
  final String? description;
  final String
  status; // 'pending', 'in_progress', 'completed', 'blocked', 'cancelled'
  final int? estimatedMinutes;
  final int? actualMinutes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Mechanic? mechanic;
  final ServiceOrder? serviceOrder;

  String get orderNumber => serviceOrder?.orderNumber ?? 'SO-PENDING';
  String get vehicleDisplayName =>
      serviceOrder?.vehicle?.displayName ?? 'Vehicle';

  factory ServiceTask.fromJson(Map<String, dynamic> json) {
    Mechanic? mech;
    if (json['mechanics'] != null &&
        json['mechanics'] is Map<String, dynamic>) {
      mech = Mechanic.fromJson(json['mechanics'] as Map<String, dynamic>);
    }

    ServiceOrder? order;
    if (json['service_orders'] != null &&
        json['service_orders'] is Map<String, dynamic>) {
      order = ServiceOrder.fromJson(
        json['service_orders'] as Map<String, dynamic>,
      );
    }

    return ServiceTask(
      id: json['id'] as String,
      serviceOrderId: json['service_order_id'] as String,
      assignedMechanicId: json['assigned_mechanic_id'] as String?,
      templateId: json['template_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'pending',
      estimatedMinutes: json['estimated_minutes'] as int?,
      actualMinutes: json['actual_minutes'] as int?,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      mechanic: mech,
      serviceOrder: order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_order_id': serviceOrderId,
      if (assignedMechanicId != null)
        'assigned_mechanic_id': assignedMechanicId,
      'title': title,
      if (description != null) 'description': description,
      'status': status,
      if (estimatedMinutes != null) 'estimated_minutes': estimatedMinutes,
      if (actualMinutes != null) 'actual_minutes': actualMinutes,
      if (notes != null) 'notes': notes,
    };
  }

  ServiceTask copyWith({
    String? id,
    String? serviceOrderId,
    String? assignedMechanicId,
    String? templateId,
    String? title,
    String? description,
    String? status,
    int? estimatedMinutes,
    int? actualMinutes,
    DateTime? startedAt,
    DateTime? completedAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Mechanic? mechanic,
    ServiceOrder? serviceOrder,
  }) {
    return ServiceTask(
      id: id ?? this.id,
      serviceOrderId: serviceOrderId ?? this.serviceOrderId,
      assignedMechanicId: assignedMechanicId ?? this.assignedMechanicId,
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mechanic: mechanic ?? this.mechanic,
      serviceOrder: serviceOrder ?? this.serviceOrder,
    );
  }
}
