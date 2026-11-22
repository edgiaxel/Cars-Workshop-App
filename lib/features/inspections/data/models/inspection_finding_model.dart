/// Condition of an inspected vehicle component.
enum FindingCondition {
  good,
  fair,
  critical;

  /// Parses a string into [FindingCondition].
  static FindingCondition fromString(String? val) {
    return switch (val?.toLowerCase().trim()) {
      'good' => FindingCondition.good,
      'fair' => FindingCondition.fair,
      'critical' => FindingCondition.critical,
      _ => FindingCondition.good,
    };
  }

  /// Maps to Postgres enum string value.
  String get value => switch (this) {
        FindingCondition.good => 'good',
        FindingCondition.fair => 'fair',
        FindingCondition.critical => 'critical',
      };

  /// User-facing label.
  String get displayName => switch (this) {
        FindingCondition.good => 'Good',
        FindingCondition.fair => 'Fair',
        FindingCondition.critical => 'Critical',
      };

  bool get isGood => this == FindingCondition.good;
  bool get isFair => this == FindingCondition.fair;
  bool get isCritical => this == FindingCondition.critical;
}

/// Severity level for diagnostic findings requiring corrective action.
enum SeverityLevel {
  low,
  medium,
  urgent;

  /// Parses a string into [SeverityLevel].
  static SeverityLevel fromString(String? val) {
    return switch (val?.toLowerCase().trim()) {
      'low' => SeverityLevel.low,
      'medium' => SeverityLevel.medium,
      'urgent' => SeverityLevel.urgent,
      _ => SeverityLevel.low,
    };
  }

  /// Maps to Postgres enum string value.
  String get value => switch (this) {
        SeverityLevel.low => 'low',
        SeverityLevel.medium => 'medium',
        SeverityLevel.urgent => 'urgent',
      };

  /// User-facing label.
  String get displayName => switch (this) {
        SeverityLevel.low => 'Low',
        SeverityLevel.medium => 'Medium',
        SeverityLevel.urgent => 'Urgent',
      };

  bool get isLow => this == SeverityLevel.low;
  bool get isMedium => this == SeverityLevel.medium;
  bool get isUrgent => this == SeverityLevel.urgent;
}

/// Diagnostic finding recorded during an inspection session.
class InspectionFinding {
  const InspectionFinding({
    required this.id,
    required this.inspectionId,
    required this.category,
    required this.itemName,
    required this.condition,
    required this.severity,
    this.notes,
    this.photoUrls = const [],
    this.recommendedAction,
    required this.createdAt,
  });

  final String id;
  final String inspectionId;
  final String category;
  final String itemName;
  final FindingCondition condition;
  final SeverityLevel severity;
  final String? notes;
  final List<String> photoUrls;
  final String? recommendedAction;
  final DateTime createdAt;

  /// Creates an [InspectionFinding] from JSON map.
  factory InspectionFinding.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photo_urls'] ?? json['photoUrls'];
    List<String> photos = const [];
    if (rawPhotos is List) {
      photos = rawPhotos.map((e) => e.toString()).toList();
    }

    return InspectionFinding(
      id: json['id'] as String? ?? '',
      inspectionId: (json['inspection_id'] ?? json['inspectionId']) as String? ?? '',
      category: json['category'] as String? ?? '',
      itemName: (json['item_name'] ?? json['itemName']) as String? ?? '',
      condition: FindingCondition.fromString(json['condition'] as String?),
      severity: SeverityLevel.fromString(json['severity'] as String?),
      notes: json['notes'] as String?,
      photoUrls: photos,
      recommendedAction: (json['recommended_action'] ?? json['recommendedAction']) as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Serializes [InspectionFinding] to database JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inspection_id': inspectionId,
      'category': category,
      'item_name': itemName,
      'condition': condition.value,
      'severity': severity.value,
      if (notes != null) 'notes': notes,
      'photo_urls': photoUrls,
      if (recommendedAction != null) 'recommended_action': recommendedAction,
      'created_at': createdAt.toIso8601String(),
    };
  }

  InspectionFinding copyWith({
    String? id,
    String? inspectionId,
    String? category,
    String? itemName,
    FindingCondition? condition,
    SeverityLevel? severity,
    String? notes,
    List<String>? photoUrls,
    String? recommendedAction,
    DateTime? createdAt,
  }) {
    return InspectionFinding(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      category: category ?? this.category,
      itemName: itemName ?? this.itemName,
      condition: condition ?? this.condition,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectionFinding &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          inspectionId == other.inspectionId &&
          category == other.category &&
          itemName == other.itemName &&
          condition == other.condition &&
          severity == other.severity &&
          notes == other.notes &&
          recommendedAction == other.recommendedAction &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        inspectionId,
        category,
        itemName,
        condition,
        severity,
        notes,
        recommendedAction,
        createdAt,
      );

  @override
  String toString() =>
      'InspectionFinding(id: $id, item: $itemName, condition: ${condition.value}, severity: ${severity.value})';
}
