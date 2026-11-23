/// Model representing a mechanic floor request for spare parts.
class PartRequestModel {
  final String id;
  final String serviceOrderId;
  final String? taskId;
  final String partId;
  final String requestedBy;
  final int quantityRequested;
  final int quantityFulfilled;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? partSku;
  final String? partName;
  final String? partUnit;
  final String? requestedByName;

  const PartRequestModel({
    required this.id,
    required this.serviceOrderId,
    this.taskId,
    required this.partId,
    required this.requestedBy,
    required this.quantityRequested,
    this.quantityFulfilled = 0,
    this.status = 'pending',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.partSku,
    this.partName,
    this.partUnit,
    this.requestedByName,
  });

  bool get isPending => status == 'pending';
  bool get isFulfilled => status == 'fulfilled';
  bool get isPartiallyFulfilled => status == 'partially_fulfilled';
  bool get isRejected => status == 'rejected';

  int get remainingQuantity => quantityRequested - quantityFulfilled;

  factory PartRequestModel.fromJson(Map<String, dynamic> json) {
    String? sku;
    String? name;
    String? unit;
    if (json['parts'] is Map<String, dynamic>) {
      final p = json['parts'] as Map<String, dynamic>;
      sku = p['sku'] as String?;
      name = p['name'] as String?;
      unit = p['unit_of_measurement'] as String?;
    }

    String? requesterName;
    if (json['profiles'] is Map<String, dynamic>) {
      final pr = json['profiles'] as Map<String, dynamic>;
      requesterName = pr['full_name'] as String?;
    }

    return PartRequestModel(
      id: json['id'] as String? ?? '',
      serviceOrderId: json['service_order_id'] as String? ?? '',
      taskId: json['task_id'] as String?,
      partId: json['part_id'] as String? ?? '',
      requestedBy: json['requested_by'] as String? ?? '',
      quantityRequested: (json['quantity_requested'] as num?)?.toInt() ?? 1,
      quantityFulfilled: (json['quantity_fulfilled'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      partSku: sku,
      partName: name,
      partUnit: unit,
      requestedByName: requesterName,
    );
  }
}
