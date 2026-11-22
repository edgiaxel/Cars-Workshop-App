/// Status of an inspection in the PitMate lifecycle.
enum InspectionStatus {
  assigned,
  inProgress,
  completed,
  reviewed;

  /// Parses a string representation from PostgreSQL enum or API.
  static InspectionStatus fromString(String? val) {
    return switch (val?.toLowerCase().trim()) {
      'assigned' => InspectionStatus.assigned,
      'in_progress' || 'inprogress' => InspectionStatus.inProgress,
      'completed' => InspectionStatus.completed,
      'reviewed' => InspectionStatus.reviewed,
      _ => InspectionStatus.assigned,
    };
  }

  /// Maps to Postgres enum string value.
  String get value => switch (this) {
        InspectionStatus.assigned => 'assigned',
        InspectionStatus.inProgress => 'in_progress',
        InspectionStatus.completed => 'completed',
        InspectionStatus.reviewed => 'reviewed',
      };

  /// User-facing status label.
  String get displayName => switch (this) {
        InspectionStatus.assigned => 'Assigned',
        InspectionStatus.inProgress => 'In Progress',
        InspectionStatus.completed => 'Completed',
        InspectionStatus.reviewed => 'Reviewed',
      };

  bool get isAssigned => this == InspectionStatus.assigned;
  bool get isInProgress => this == InspectionStatus.inProgress;
  bool get isCompleted => this == InspectionStatus.completed;
  bool get isReviewed => this == InspectionStatus.reviewed;
}

/// Represents an inspection record mapped to public.inspections table.
class InspectionModel {
  const InspectionModel({
    required this.id,
    required this.serviceOrderId,
    this.mechanicId,
    required this.status,
    this.summary,
    this.startedAt,
    this.completedAt,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String serviceOrderId;
  final String? mechanicId;
  final InspectionStatus status;
  final String? summary;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Creates an [InspectionModel] from JSON map.
  factory InspectionModel.fromJson(Map<String, dynamic> json) {
    return InspectionModel(
      id: json['id'] as String? ?? '',
      serviceOrderId: (json['service_order_id'] ?? json['serviceOrderId']) as String? ?? '',
      mechanicId: (json['mechanic_id'] ?? json['mechanicId']) as String?,
      status: InspectionStatus.fromString(json['status'] as String?),
      summary: json['summary'] as String?,
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'] as String) : null,
      reviewedBy: (json['reviewed_by'] ?? json['reviewedBy']) as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'] as String) : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Serializes [InspectionModel] to JSON matching database schema.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_order_id': serviceOrderId,
      if (mechanicId != null) 'mechanic_id': mechanicId,
      'status': status.value,
      if (summary != null) 'summary': summary,
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  InspectionModel copyWith({
    String? id,
    String? serviceOrderId,
    String? mechanicId,
    InspectionStatus? status,
    String? summary,
    DateTime? startedAt,
    DateTime? completedAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InspectionModel(
      id: id ?? this.id,
      serviceOrderId: serviceOrderId ?? this.serviceOrderId,
      mechanicId: mechanicId ?? this.mechanicId,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          serviceOrderId == other.serviceOrderId &&
          mechanicId == other.mechanicId &&
          status == other.status &&
          summary == other.summary &&
          startedAt == other.startedAt &&
          completedAt == other.completedAt &&
          reviewedBy == other.reviewedBy &&
          reviewedAt == other.reviewedAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        serviceOrderId,
        mechanicId,
        status,
        summary,
        startedAt,
        completedAt,
        reviewedBy,
        reviewedAt,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'InspectionModel(id: $id, orderId: $serviceOrderId, status: ${status.value}, mechanic: $mechanicId)';
}
