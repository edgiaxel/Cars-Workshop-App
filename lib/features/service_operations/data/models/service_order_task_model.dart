/// Operation execution priority.
enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  static TaskPriority fromString(String? value) {
    switch (value) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      case 'urgent':
        return TaskPriority.urgent;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }

  String toDbString() => name;
}

/// Operation execution lifecycle status.
enum TaskStatus {
  pending,
  assigned,
  inProgress,
  paused,
  completed,
  blocked;

  static TaskStatus fromString(String? value) {
    switch (value) {
      case 'assigned':
        return TaskStatus.assigned;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'paused':
        return TaskStatus.paused;
      case 'completed':
        return TaskStatus.completed;
      case 'blocked':
        return TaskStatus.blocked;
      case 'pending':
      default:
        return TaskStatus.pending;
    }
  }

  String toDbString() {
    switch (this) {
      case TaskStatus.inProgress:
        return 'in_progress';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.assigned:
        return 'Assigned';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.paused:
        return 'Paused';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.blocked:
        return 'Blocked';
    }
  }
}

/// Model for checklists within a task.
class TaskChecklistModel {
  const TaskChecklistModel({
    required this.id,
    required this.taskId,
    required this.itemDescription,
    this.isCompleted = false,
    this.completedAt,
    this.completedBy,
  });

  final String id;
  final String taskId;
  final String itemDescription;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedBy;

  factory TaskChecklistModel.fromJson(Map<String, dynamic> json) {
    final completedAtRaw = json['completed_at'];
    return TaskChecklistModel(
      id: json['id'] as String? ?? '',
      taskId: json['task_id'] as String? ?? '',
      itemDescription: json['item_description'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: completedAtRaw is String ? DateTime.tryParse(completedAtRaw) : null,
      completedBy: json['completed_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'item_description': itemDescription,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'completed_by': completedBy,
    };
  }

  TaskChecklistModel copyWith({
    String? id,
    String? taskId,
    String? itemDescription,
    bool? isCompleted,
    DateTime? completedAt,
    String? completedBy,
  }) {
    return TaskChecklistModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      itemDescription: itemDescription ?? this.itemDescription,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
    );
  }
}

/// Model for a discrete service operation attached to a service order.
class ServiceOrderTaskModel {
  const ServiceOrderTaskModel({
    required this.id,
    required this.serviceOrderId,
    this.estimateItemId,
    required this.title,
    this.description,
    this.estimatedDurationMinutes = 60,
    this.actualDurationMinutes = 0,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.sequenceOrder = 1,
    this.dependsOnTaskId,
    this.dependsOnTaskTitle,
    this.assignedMechanicId,
    this.assignedMechanicName,
    this.pauseReason,
    this.startedAt,
    this.pausedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.checklists = const [],
    this.orderNumber,
    this.vehiclePlate,
    this.vehicleModel,
  });

  final String id;
  final String serviceOrderId;
  final String? estimateItemId;
  final String title;
  final String? description;
  final int estimatedDurationMinutes;
  final int actualDurationMinutes;
  final TaskPriority priority;
  final TaskStatus status;
  final int sequenceOrder;
  final String? dependsOnTaskId;
  final String? dependsOnTaskTitle;
  final String? assignedMechanicId;
  final String? assignedMechanicName;
  final String? pauseReason;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TaskChecklistModel> checklists;

  // Joined fields
  final String? orderNumber;
  final String? vehiclePlate;
  final String? vehicleModel;

  bool get isCompleted => status == TaskStatus.completed;
  bool get isInProgress => status == TaskStatus.inProgress;
  bool get isPaused => status == TaskStatus.paused;
  bool get hasDependency => dependsOnTaskId != null && dependsOnTaskId!.isNotEmpty;

  factory ServiceOrderTaskModel.fromJson(Map<String, dynamic> json) {
    final mechanic = json['assigned_mechanic'] as Map<String, dynamic>?;
    final order = json['service_orders'] as Map<String, dynamic>?;
    final vehicle = order?['vehicles'] as Map<String, dynamic>?;
    final checklistsRaw = json['task_checklists'] as List?;

    final createdAtRaw = json['created_at'];
    final updatedAtRaw = json['updated_at'];
    final startedAtRaw = json['started_at'];
    final pausedAtRaw = json['paused_at'];
    final completedAtRaw = json['completed_at'];

    return ServiceOrderTaskModel(
      id: json['id'] as String? ?? '',
      serviceOrderId: json['service_order_id'] as String? ?? '',
      estimateItemId: json['estimate_item_id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      estimatedDurationMinutes: (json['estimated_duration_minutes'] as num?)?.toInt() ?? 60,
      actualDurationMinutes: (json['actual_duration_minutes'] as num?)?.toInt() ?? 0,
      priority: TaskPriority.fromString(json['priority'] as String?),
      status: TaskStatus.fromString(json['status'] as String?),
      sequenceOrder: (json['sequence_order'] as num?)?.toInt() ?? 1,
      dependsOnTaskId: json['depends_on_task_id'] as String?,
      dependsOnTaskTitle: json['depends_on_task_title'] as String?,
      assignedMechanicId: json['assigned_mechanic_id'] as String?,
      assignedMechanicName: mechanic?['full_name'] as String?,
      pauseReason: json['pause_reason'] as String?,
      startedAt: startedAtRaw is String ? DateTime.tryParse(startedAtRaw) : null,
      pausedAt: pausedAtRaw is String ? DateTime.tryParse(pausedAtRaw) : null,
      completedAt: completedAtRaw is String ? DateTime.tryParse(completedAtRaw) : null,
      createdAt: createdAtRaw is String ? (DateTime.tryParse(createdAtRaw) ?? DateTime.now()) : DateTime.now(),
      updatedAt: updatedAtRaw is String ? (DateTime.tryParse(updatedAtRaw) ?? DateTime.now()) : DateTime.now(),
      checklists: checklistsRaw != null
          ? checklistsRaw.map((c) => TaskChecklistModel.fromJson(c as Map<String, dynamic>)).toList()
          : const [],
      orderNumber: order?['order_number'] as String?,
      vehiclePlate: vehicle?['license_plate'] as String?,
      vehicleModel: vehicle?['model'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_order_id': serviceOrderId,
      'estimate_item_id': estimateItemId,
      'title': title,
      'description': description,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'actual_duration_minutes': actualDurationMinutes,
      'priority': priority.toDbString(),
      'status': status.toDbString(),
      'sequence_order': sequenceOrder,
      'depends_on_task_id': dependsOnTaskId,
      'assigned_mechanic_id': assignedMechanicId,
      'pause_reason': pauseReason,
      'started_at': startedAt?.toIso8601String(),
      'paused_at': pausedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ServiceOrderTaskModel copyWith({
    String? id,
    String? serviceOrderId,
    String? estimateItemId,
    String? title,
    String? description,
    int? estimatedDurationMinutes,
    int? actualDurationMinutes,
    TaskPriority? priority,
    TaskStatus? status,
    int? sequenceOrder,
    String? dependsOnTaskId,
    String? dependsOnTaskTitle,
    String? assignedMechanicId,
    String? assignedMechanicName,
    String? pauseReason,
    DateTime? startedAt,
    DateTime? pausedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TaskChecklistModel>? checklists,
    String? orderNumber,
    String? vehiclePlate,
    String? vehicleModel,
  }) {
    return ServiceOrderTaskModel(
      id: id ?? this.id,
      serviceOrderId: serviceOrderId ?? this.serviceOrderId,
      estimateItemId: estimateItemId ?? this.estimateItemId,
      title: title ?? this.title,
      description: description ?? this.description,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      dependsOnTaskId: dependsOnTaskId ?? this.dependsOnTaskId,
      dependsOnTaskTitle: dependsOnTaskTitle ?? this.dependsOnTaskTitle,
      assignedMechanicId: assignedMechanicId ?? this.assignedMechanicId,
      assignedMechanicName: assignedMechanicName ?? this.assignedMechanicName,
      pauseReason: pauseReason ?? this.pauseReason,
      startedAt: startedAt ?? this.startedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      checklists: checklists ?? this.checklists,
      orderNumber: orderNumber ?? this.orderNumber,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleModel: vehicleModel ?? this.vehicleModel,
    );
  }
}
