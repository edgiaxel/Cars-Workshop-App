/// Model representing recorded part consumption and returns for a specific operation task.
class ServiceTaskPartConsumptionModel {
  final String id;
  final String serviceOrderId;
  final String taskId;
  final String partId;
  final int quantityIssued;
  final int quantityConsumed;
  final int quantityReturned;
  final int unitCostCents;
  final int totalCostCents;
  final String recordedBy;
  final DateTime createdAt;

  // Joined fields
  final String? partSku;
  final String? partName;
  final String? partUnit;

  const ServiceTaskPartConsumptionModel({
    required this.id,
    required this.serviceOrderId,
    required this.taskId,
    required this.partId,
    required this.quantityIssued,
    required this.quantityConsumed,
    required this.quantityReturned,
    required this.unitCostCents,
    required this.totalCostCents,
    required this.recordedBy,
    required this.createdAt,
    this.partSku,
    this.partName,
    this.partUnit,
  });

  factory ServiceTaskPartConsumptionModel.fromJson(Map<String, dynamic> json) {
    String? sku;
    String? name;
    String? unit;
    if (json['parts'] is Map<String, dynamic>) {
      final p = json['parts'] as Map<String, dynamic>;
      sku = p['sku'] as String?;
      name = p['name'] as String?;
      unit = p['unit_of_measurement'] as String?;
    }

    return ServiceTaskPartConsumptionModel(
      id: json['id'] as String? ?? '',
      serviceOrderId: json['service_order_id'] as String? ?? '',
      taskId: json['task_id'] as String? ?? '',
      partId: json['part_id'] as String? ?? '',
      quantityIssued: (json['quantity_issued'] as num?)?.toInt() ?? 0,
      quantityConsumed: (json['quantity_consumed'] as num?)?.toInt() ?? 0,
      quantityReturned: (json['quantity_returned'] as num?)?.toInt() ?? 0,
      unitCostCents: (json['unit_cost_cents'] as num?)?.toInt() ?? 0,
      totalCostCents: (json['total_cost_cents'] as num?)?.toInt() ?? 0,
      recordedBy: json['recorded_by'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      partSku: sku,
      partName: name,
      partUnit: unit,
    );
  }
}
