import 'package:pitmate/features/service_orders/data/models/service_order_model.dart';

/// Status of a quality control inspection in the PitMate lifecycle.
enum QcStatus {
  inProgress,
  passed,
  failed;

  /// Parses a string representation from PostgreSQL enum or API.
  static QcStatus fromString(String? val) {
    return switch (val?.toLowerCase().trim()) {
      'in_progress' || 'inprogress' => QcStatus.inProgress,
      'passed' => QcStatus.passed,
      'failed' => QcStatus.failed,
      _ => QcStatus.inProgress,
    };
  }

  /// Maps to Postgres enum string value.
  String get value => switch (this) {
        QcStatus.inProgress => 'in_progress',
        QcStatus.passed => 'passed',
        QcStatus.failed => 'failed',
      };

  /// User-facing status label.
  String get displayName => switch (this) {
        QcStatus.inProgress => 'In Progress',
        QcStatus.passed => 'Passed',
        QcStatus.failed => 'Failed',
      };

  bool get isInProgress => this == QcStatus.inProgress;
  bool get isPassed => this == QcStatus.passed;
  bool get isFailed => this == QcStatus.failed;
}

/// Represents an individual checklist item in a quality control inspection.
class QcChecklistItemModel {
  const QcChecklistItemModel({
    required this.id,
    required this.qcInspectionId,
    required this.category,
    required this.itemName,
    this.isPassed = false,
    this.notes,
    this.checkedAt,
  });

  final String id;
  final String qcInspectionId;
  final String category;
  final String itemName;
  final bool isPassed;
  final String? notes;
  final DateTime? checkedAt;

  /// Creates a [QcChecklistItemModel] from JSON map.
  factory QcChecklistItemModel.fromJson(Map<String, dynamic> json) {
    final checkedAtRaw = json['checked_at'] ?? json['checkedAt'];
    return QcChecklistItemModel(
      id: json['id'] as String? ?? '',
      qcInspectionId: (json['qc_inspection_id'] ?? json['qcInspectionId']) as String? ?? '',
      category: json['category'] as String? ?? 'General',
      itemName: (json['item_name'] ?? json['itemName']) as String? ?? '',
      isPassed: (json['is_passed'] ?? json['isPassed']) as bool? ?? false,
      notes: json['notes'] as String?,
      checkedAt: checkedAtRaw != null ? DateTime.tryParse(checkedAtRaw.toString()) : null,
    );
  }

  /// Serializes [QcChecklistItemModel] to JSON matching database schema.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qc_inspection_id': qcInspectionId,
      'category': category,
      'item_name': itemName,
      'is_passed': isPassed,
      if (notes != null) 'notes': notes,
      if (checkedAt != null) 'checked_at': checkedAt!.toIso8601String(),
    };
  }

  /// JSON payload format expected by `record_qc_result` RPC.
  Map<String, dynamic> toRpcItemJson() {
    return {
      'id': id,
      'is_passed': isPassed,
      if (notes != null) 'notes': notes,
    };
  }

  /// Returns a copy of [QcChecklistItemModel] with updated fields.
  QcChecklistItemModel copyWith({
    String? id,
    String? qcInspectionId,
    String? category,
    String? itemName,
    bool? isPassed,
    String? notes,
    DateTime? checkedAt,
  }) {
    return QcChecklistItemModel(
      id: id ?? this.id,
      qcInspectionId: qcInspectionId ?? this.qcInspectionId,
      category: category ?? this.category,
      itemName: itemName ?? this.itemName,
      isPassed: isPassed ?? this.isPassed,
      notes: notes ?? this.notes,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QcChecklistItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          qcInspectionId == other.qcInspectionId &&
          category == other.category &&
          itemName == other.itemName &&
          isPassed == other.isPassed &&
          notes == other.notes &&
          checkedAt == other.checkedAt;

  @override
  int get hashCode => Object.hash(
        id,
        qcInspectionId,
        category,
        itemName,
        isPassed,
        notes,
        checkedAt,
      );

  @override
  String toString() =>
      'QcChecklistItemModel(id: $id, category: $category, item: $itemName, passed: $isPassed)';
}

/// Represents a quality control inspection mapped to public.qc_inspections table.
class QcInspectionModel {
  const QcInspectionModel({
    required this.id,
    required this.serviceOrderId,
    required this.inspectorId,
    this.status = QcStatus.inProgress,
    this.notes,
    this.failureReason,
    this.correctionNotes,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.orderNumber,
    this.customerName,
    this.customerPhone,
    this.vehiclePlate,
    this.vehicleMake,
    this.vehicleModel,
    this.serviceOrder,
  });

  final String id;
  final String serviceOrderId;
  final String inspectorId;
  final QcStatus status;
  final String? notes;
  final String? failureReason;
  final String? correctionNotes;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined / Relational entities
  final List<QcChecklistItemModel> items;
  final String? orderNumber;
  final String? customerName;
  final String? customerPhone;
  final String? vehiclePlate;
  final String? vehicleMake;
  final String? vehicleModel;
  final ServiceOrderModel? serviceOrder;

  // Relational getters
  String get vehicleDescription {
    if (vehiclePlate != null && vehicleMake != null) {
      return '$vehicleMake ${vehicleModel ?? ''} [$vehiclePlate]'.trim();
    }
    if (vehiclePlate != null) return vehiclePlate!;
    if (serviceOrder != null) return serviceOrder!.vehicleDescription;
    return 'Order $serviceOrderId';
  }

  int get totalItemsCount => items.length;
  int get passedItemsCount => items.where((i) => i.isPassed).length;
  int get failedItemsCount => totalItemsCount - passedItemsCount;
  bool get allItemsPassed => items.isNotEmpty && items.every((i) => i.isPassed);
  double get progressFraction => items.isEmpty ? 0.0 : passedItemsCount / items.length;

  /// Groups items by category preserving insertion order.
  Map<String, List<QcChecklistItemModel>> get itemsByCategory {
    final map = <String, List<QcChecklistItemModel>>{};
    for (final item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  /// Creates a [QcInspectionModel] from JSON map, with support for nested relations.
  factory QcInspectionModel.fromJson(Map<String, dynamic> json) {
    // Parse nested checklist items if present
    List<QcChecklistItemModel> itemsList = [];
    final rawItems = json['qc_checklist_items'] ?? json['items'];
    if (rawItems is List) {
      itemsList = rawItems
          .map((i) => QcChecklistItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    // Parse nested service order info if joined
    ServiceOrderModel? parsedOrder;
    String? orderNum = (json['order_number'] ?? json['orderNumber']) as String?;
    String? custName = (json['customer_name'] ?? json['customerName']) as String?;
    String? custPhone = (json['customer_phone'] ?? json['customerPhone']) as String?;
    String? vPlate = (json['vehicle_plate'] ?? json['vehiclePlate']) as String?;
    String? vMake = (json['vehicle_make'] ?? json['vehicleMake']) as String?;
    String? vModel = (json['vehicle_model'] ?? json['vehicleModel']) as String?;

    if (json['service_orders'] is Map<String, dynamic>) {
      parsedOrder = ServiceOrderModel.fromJson(json['service_orders'] as Map<String, dynamic>);
      orderNum ??= parsedOrder.orderNumber;
      custName ??= parsedOrder.customerName;
      custPhone ??= parsedOrder.customerPhone;
      vPlate ??= parsedOrder.vehiclePlate;
      vMake ??= parsedOrder.vehicleMake;
      vModel ??= parsedOrder.vehicleModel;
    }

    final createdAtRaw = json['created_at'] ?? json['createdAt'];
    final updatedAtRaw = json['updated_at'] ?? json['updatedAt'];
    final completedAtRaw = json['completed_at'] ?? json['completedAt'];

    return QcInspectionModel(
      id: json['id'] as String? ?? '',
      serviceOrderId: (json['service_order_id'] ?? json['serviceOrderId']) as String? ?? '',
      inspectorId: (json['inspector_id'] ?? json['inspectorId']) as String? ?? '',
      status: QcStatus.fromString(json['status'] as String?),
      notes: json['notes'] as String?,
      failureReason: (json['failure_reason'] ?? json['failureReason']) as String?,
      correctionNotes: (json['correction_notes'] ?? json['correctionNotes']) as String?,
      completedAt: completedAtRaw != null ? DateTime.tryParse(completedAtRaw.toString()) : null,
      createdAt: createdAtRaw != null
          ? DateTime.tryParse(createdAtRaw.toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: updatedAtRaw != null
          ? DateTime.tryParse(updatedAtRaw.toString()) ?? DateTime.now()
          : DateTime.now(),
      items: itemsList,
      orderNumber: orderNum,
      customerName: custName,
      customerPhone: custPhone,
      vehiclePlate: vPlate,
      vehicleMake: vMake,
      vehicleModel: vModel,
      serviceOrder: parsedOrder,
    );
  }

  /// Serializes [QcInspectionModel] to JSON matching database schema.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_order_id': serviceOrderId,
      'inspector_id': inspectorId,
      'status': status.value,
      if (notes != null) 'notes': notes,
      if (failureReason != null) 'failure_reason': failureReason,
      if (correctionNotes != null) 'correction_notes': correctionNotes,
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Returns a copy of [QcInspectionModel] with updated fields.
  QcInspectionModel copyWith({
    String? id,
    String? serviceOrderId,
    String? inspectorId,
    QcStatus? status,
    String? notes,
    String? failureReason,
    String? correctionNotes,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<QcChecklistItemModel>? items,
    String? orderNumber,
    String? customerName,
    String? customerPhone,
    String? vehiclePlate,
    String? vehicleMake,
    String? vehicleModel,
    ServiceOrderModel? serviceOrder,
  }) {
    return QcInspectionModel(
      id: id ?? this.id,
      serviceOrderId: serviceOrderId ?? this.serviceOrderId,
      inspectorId: inspectorId ?? this.inspectorId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      failureReason: failureReason ?? this.failureReason,
      correctionNotes: correctionNotes ?? this.correctionNotes,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      serviceOrder: serviceOrder ?? this.serviceOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QcInspectionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          serviceOrderId == other.serviceOrderId &&
          inspectorId == other.inspectorId &&
          status == other.status &&
          notes == other.notes &&
          failureReason == other.failureReason &&
          correctionNotes == other.correctionNotes &&
          completedAt == other.completedAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        serviceOrderId,
        inspectorId,
        status,
        notes,
        failureReason,
        correctionNotes,
        completedAt,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'QcInspectionModel(id: $id, orderId: $serviceOrderId, status: ${status.value}, items: ${items.length})';
}
