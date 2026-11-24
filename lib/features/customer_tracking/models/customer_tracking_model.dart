/// Tracking stage in 8-stage workshop lifecycle.
class TrackingTimelineStage {
  const TrackingTimelineStage({
    required this.stage,
    required this.completed,
    required this.active,
  });

  final String stage;
  final bool completed;
  final bool active;

  factory TrackingTimelineStage.fromJson(Map<String, dynamic> json) {
    return TrackingTimelineStage(
      stage: json['stage'] as String,
      completed: (json['completed'] as bool?) ?? false,
      active: (json['active'] as bool?) ?? false,
    );
  }
}

/// Customer-visible service task (sanitized: zero internal hourly rate or compensation).
class TrackingTaskItem {
  const TrackingTaskItem({
    required this.id,
    required this.taskName,
    required this.status,
    this.description,
  });

  final String id;
  final String taskName;
  final String status;
  final String? description;

  factory TrackingTaskItem.fromJson(Map<String, dynamic> json) {
    return TrackingTaskItem(
      id: json['id'] as String,
      taskName: json['task_name'] as String,
      status: (json['status'] as String?) ?? 'pending',
      description: json['description'] as String?,
    );
  }
}

/// Customer-visible inspection finding.
class TrackingFindingItem {
  const TrackingFindingItem({
    required this.id,
    required this.category,
    required this.itemName,
    required this.severity,
    this.description,
    this.recommendedAction,
  });

  final String id;
  final String category;
  final String itemName;
  final String severity;
  final String? description;
  final String? recommendedAction;

  factory TrackingFindingItem.fromJson(Map<String, dynamic> json) {
    return TrackingFindingItem(
      id: json['id'] as String,
      category: json['category'] as String,
      itemName: json['item_name'] as String,
      severity: (json['severity'] as String?) ?? 'info',
      description: json['description'] as String?,
      recommendedAction: json['recommended_action'] as String?,
    );
  }
}

/// Complete sanitized tracking summary for customer vehicle.
class CustomerTrackingSummary {
  const CustomerTrackingSummary({
    required this.hasActiveOrder,
    this.orderId,
    this.orderNumber,
    this.status,
    this.currentStageIndex = 0,
    this.createdAt,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleYear,
    this.licensePlate,
    this.mileageKm,
    this.timeline = const [],
    this.tasks = const [],
    this.findings = const [],
    this.invoiceId,
    this.invoiceNumber,
    this.invoiceStatus,
    this.totalAmountCents,
    this.amountPaidCents,
    this.outstandingBalanceCents,
  });

  final bool hasActiveOrder;
  final String? orderId;
  final String? orderNumber;
  final String? status;
  final int currentStageIndex;
  final DateTime? createdAt;
  final String? vehicleMake;
  final String? vehicleModel;
  final int? vehicleYear;
  final String? licensePlate;
  final int? mileageKm;
  final List<TrackingTimelineStage> timeline;
  final List<TrackingTaskItem> tasks;
  final List<TrackingFindingItem> findings;
  final String? invoiceId;
  final String? invoiceNumber;
  final String? invoiceStatus;
  final int? totalAmountCents;
  final int? amountPaidCents;
  final int? outstandingBalanceCents;

  factory CustomerTrackingSummary.fromJson(Map<String, dynamic> json) {
    final hasActive = (json['has_active_order'] as bool?) ?? false;
    if (!hasActive) {
      return const CustomerTrackingSummary(hasActiveOrder: false);
    }

    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    final inv = json['invoice'] as Map<String, dynamic>?;
    final timelineList = (json['timeline'] as List<dynamic>?)
            ?.map((e) => TrackingTimelineStage.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final tasksList = (json['tasks'] as List<dynamic>?)
            ?.map((e) => TrackingTaskItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final findingsList = (json['findings'] as List<dynamic>?)
            ?.map((e) => TrackingFindingItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return CustomerTrackingSummary(
      hasActiveOrder: true,
      orderId: json['order_id'] as String?,
      orderNumber: json['order_number'] as String?,
      status: json['status'] as String?,
      currentStageIndex: (json['current_stage_index'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      vehicleMake: vehicle?['make'] as String?,
      vehicleModel: vehicle?['model'] as String?,
      vehicleYear: (vehicle?['year'] as num?)?.toInt(),
      licensePlate: vehicle?['license_plate'] as String?,
      mileageKm: (vehicle?['mileage'] as num?)?.toInt(),
      timeline: timelineList,
      tasks: tasksList,
      findings: findingsList,
      invoiceId: inv?['id'] as String?,
      invoiceNumber: inv?['invoice_number'] as String?,
      invoiceStatus: inv?['status'] as String?,
      totalAmountCents: (inv?['total_amount_cents'] as num?)?.toInt(),
      amountPaidCents: (inv?['amount_paid_cents'] as num?)?.toInt(),
      outstandingBalanceCents: (inv?['outstanding_balance_cents'] as num?)?.toInt(),
    );
  }
}
