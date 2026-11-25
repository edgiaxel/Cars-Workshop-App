import 'estimate_item_model.dart';

/// Lifecycle status for an estimate.
enum EstimateStatus {
  draft,
  sent,
  approved,
  partiallyApproved,
  rejected,
  superseded;

  static EstimateStatus fromString(String? val) {
    switch (val) {
      case 'sent':
        return EstimateStatus.sent;
      case 'approved':
        return EstimateStatus.approved;
      case 'partially_approved':
        return EstimateStatus.partiallyApproved;
      case 'rejected':
        return EstimateStatus.rejected;
      case 'superseded':
        return EstimateStatus.superseded;
      case 'draft':
      default:
        return EstimateStatus.draft;
    }
  }

  String toDbString() {
    switch (this) {
      case EstimateStatus.draft:
        return 'draft';
      case EstimateStatus.sent:
        return 'sent';
      case EstimateStatus.approved:
        return 'approved';
      case EstimateStatus.partiallyApproved:
        return 'partially_approved';
      case EstimateStatus.rejected:
        return 'rejected';
      case EstimateStatus.superseded:
        return 'superseded';
    }
  }

  String get displayName {
    switch (this) {
      case EstimateStatus.draft:
        return 'Draft';
      case EstimateStatus.sent:
        return 'Sent to Customer';
      case EstimateStatus.approved:
        return 'Approved';
      case EstimateStatus.partiallyApproved:
        return 'Partially Approved';
      case EstimateStatus.rejected:
        return 'Work Rejected';
      case EstimateStatus.superseded:
        return 'Superseded';
    }
  }
}

/// Estimate entity mapping `public.estimates` database table.
/// Monetary values are represented in integer cents (BIGINT in database).
class EstimateModel {
  const EstimateModel({
    required this.id,
    required this.serviceOrderId,
    this.inspectionId,
    this.revisionNumber = 1,
    this.status = EstimateStatus.draft,
    this.subtotalCents = 0,
    this.taxCents = 0,
    this.discountCents = 0,
    this.totalCents = 0,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String serviceOrderId;
  final String? inspectionId;
  final int revisionNumber;
  final EstimateStatus status;
  final int subtotalCents;
  final int taxCents;
  final int discountCents;
  final int totalCents;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Indonesian standard VAT rate (11% PPN).
  static const double vatRate = 0.11;

  /// Calculates taxable subtotal after discount in cents.
  static int calculateTaxableSubtotal(int subtotalCents, [int discountCents = 0]) {
    final taxable = subtotalCents - discountCents;
    return taxable < 0 ? 0 : taxable;
  }

  /// Calculates PPN tax from post-discount taxable subtotal in cents.
  static int calculateTax(int subtotalCents, {int discountCents = 0, double taxPercent = 11.0}) {
    final taxable = calculateTaxableSubtotal(subtotalCents, discountCents);
    if (taxable <= 0) return 0;
    if (taxPercent == 11.0) {
      return (taxable * 11) ~/ 100;
    }
    return (taxable * taxPercent / 100).round();
  }

  /// Calculates grand total in cents: (subtotal - discount) + tax.
  static int calculateGrandTotal(int subtotalCents, int taxCents, int discountCents) {
    final taxable = calculateTaxableSubtotal(subtotalCents, discountCents);
    final total = taxable + taxCents;
    return total < 0 ? 0 : total;
  }

  /// Calculates subtotal from a list of item models.
  static int calculateSubtotalFromItems(List<EstimateItemModel> items) {
    return items.fold<int>(0, (sum, item) => sum + item.totalPriceCents);
  }

  /// Formats integer cents into formatted IDR currency string (e.g. 349650000 -> "Rp 3.496.500").
  static String formatIdr(int cents) {
    final rupiah = (cents / 100).round();
    final isNegative = rupiah < 0;
    final absVal = rupiah.abs();
    final digits = absVal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return '${isNegative ? '-' : ''}Rp $buffer';
  }

  /// Converts IDR integer amount (e.g. 150000) to integer cents (15000000).
  static int idrToCents(int idrAmount) => idrAmount * 100;

  /// Converts cents (15000000) to IDR integer amount (150000).
  static int centsToIdr(int cents) => (cents / 100).round();

  String get formattedSubtotal => formatIdr(subtotalCents);
  String get formattedTax => formatIdr(taxCents);
  String get formattedDiscount => formatIdr(discountCents);
  String get formattedTotal => formatIdr(totalCents);
  String get revisionLabel => 'Revision $revisionNumber';

  factory EstimateModel.fromJson(Map<String, dynamic> json) {
    return EstimateModel(
      id: (json['id'] as String?) ?? '',
      serviceOrderId: (json['service_order_id'] ?? json['serviceOrderId'] ?? '') as String,
      inspectionId: (json['inspection_id'] ?? json['inspectionId']) as String?,
      revisionNumber: ((json['revision_number'] ?? json['revisionNumber'] ?? 1) as num).toInt(),
      status: EstimateStatus.fromString(json['status'] as String?),
      subtotalCents: ((json['subtotal_cents'] ?? json['subtotalCents'] ?? 0) as num).toInt(),
      taxCents: ((json['tax_cents'] ?? json['taxCents'] ?? 0) as num).toInt(),
      discountCents: ((json['discount_cents'] ?? json['discountCents'] ?? 0) as num).toInt(),
      totalCents: ((json['total_cents'] ?? json['totalCents'] ?? 0) as num).toInt(),
      notes: json['notes'] as String?,
      createdBy: (json['created_by'] ?? json['createdBy']) as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : (json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'service_order_id': serviceOrderId,
      if (inspectionId != null) 'inspection_id': inspectionId,
      'revision_number': revisionNumber,
      'status': status.toDbString(),
      'subtotal_cents': subtotalCents,
      'tax_cents': taxCents,
      'discount_cents': discountCents,
      'total_cents': totalCents,
      if (notes != null) 'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  EstimateModel copyWith({
    String? id,
    String? serviceOrderId,
    String? inspectionId,
    int? revisionNumber,
    EstimateStatus? status,
    int? subtotalCents,
    int? taxCents,
    int? discountCents,
    int? totalCents,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EstimateModel(
      id: id ?? this.id,
      serviceOrderId: serviceOrderId ?? this.serviceOrderId,
      inspectionId: inspectionId ?? this.inspectionId,
      revisionNumber: revisionNumber ?? this.revisionNumber,
      status: status ?? this.status,
      subtotalCents: subtotalCents ?? this.subtotalCents,
      taxCents: taxCents ?? this.taxCents,
      discountCents: discountCents ?? this.discountCents,
      totalCents: totalCents ?? this.totalCents,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstimateModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          serviceOrderId == other.serviceOrderId &&
          inspectionId == other.inspectionId &&
          revisionNumber == other.revisionNumber &&
          status == other.status &&
          subtotalCents == other.subtotalCents &&
          taxCents == other.taxCents &&
          discountCents == other.discountCents &&
          totalCents == other.totalCents &&
          notes == other.notes &&
          createdBy == other.createdBy;

  @override
  int get hashCode => Object.hash(
        id,
        serviceOrderId,
        inspectionId,
        revisionNumber,
        status,
        subtotalCents,
        taxCents,
        discountCents,
        totalCents,
        notes,
        createdBy,
      );
}
