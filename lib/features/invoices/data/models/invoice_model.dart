import 'dart:math';
import '../../../../core/utils/currency_formatter.dart';

/// Status of an invoice adhering to PostgreSQL enum `public.invoice_status`.
enum InvoiceStatus {
  draft,
  issued,
  partiallyPaid,
  paid,
  cancelled;

  static InvoiceStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'issued':
        return InvoiceStatus.issued;
      case 'partially_paid':
      case 'partiallypaid':
        return InvoiceStatus.partiallyPaid;
      case 'paid':
        return InvoiceStatus.paid;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      case 'draft':
      default:
        return InvoiceStatus.draft;
    }
  }

  String toDbString() {
    switch (this) {
      case InvoiceStatus.draft:
        return 'draft';
      case InvoiceStatus.issued:
        return 'issued';
      case InvoiceStatus.partiallyPaid:
        return 'partially_paid';
      case InvoiceStatus.paid:
        return 'paid';
      case InvoiceStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.issued:
        return 'Issued';
      case InvoiceStatus.partiallyPaid:
        return 'Partially Paid';
      case InvoiceStatus.paid:
        return 'Settled & Paid';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Item type classification matching `public.invoice_items.item_type`.
enum InvoiceItemType {
  labor,
  part,
  fee,
  discount;

  static InvoiceItemType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'labor':
        return InvoiceItemType.labor;
      case 'part':
        return InvoiceItemType.part;
      case 'fee':
        return InvoiceItemType.fee;
      case 'discount':
        return InvoiceItemType.discount;
      default:
        return InvoiceItemType.labor;
    }
  }

  String toDbString() => name.toLowerCase();

  String get displayName {
    switch (this) {
      case InvoiceItemType.labor:
        return 'Workshop Labor';
      case InvoiceItemType.part:
        return 'Replacement Part';
      case InvoiceItemType.fee:
        return 'Administrative / Environmental Fee';
      case InvoiceItemType.discount:
        return 'Promotional Discount';
    }
  }
}

/// Payment method options matching PostgreSQL enum `public.payment_method`.
enum PaymentMethod {
  cash,
  qris,
  card,
  bankTransfer;

  static PaymentMethod fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'qris':
        return PaymentMethod.qris;
      case 'card':
        return PaymentMethod.card;
      case 'bank_transfer':
      case 'banktransfer':
        return PaymentMethod.bankTransfer;
      default:
        return PaymentMethod.cash;
    }
  }

  String toDbString() {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.qris:
        return 'qris';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.qris:
        return 'QRIS (Instant Settlement)';
      case PaymentMethod.card:
        return 'Debit / Credit Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Virtual Account';
    }
  }
}

/// Status of payment record matching `public.payment_status`.
enum PaymentStatus {
  completed,
  pending,
  failed,
  refunded;

  static PaymentStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'completed':
        return PaymentStatus.completed;
      case 'pending':
        return PaymentStatus.pending;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.completed;
    }
  }

  String toDbString() => name.toLowerCase();

  String get displayName {
    switch (this) {
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.pending:
        return 'Pending Verification';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

/// Individual line item in an invoice mapping `public.invoice_items`.
class InvoiceItemModel {
  const InvoiceItemModel({
    required this.id,
    required this.invoiceId,
    required this.itemType,
    required this.description,
    this.quantity = 1,
    this.unitPriceCents = 0,
    this.totalPriceCents = 0,
    this.partId,
    this.taskId,
    required this.createdAt,
  });

  final String id;
  final String invoiceId;
  final InvoiceItemType itemType;
  final String description;
  final int quantity;
  final int unitPriceCents;
  final int totalPriceCents;
  final String? partId;
  final String? taskId;
  final DateTime createdAt;

  factory InvoiceItemModel.create({
    required String invoiceId,
    required InvoiceItemType itemType,
    required String description,
    int quantity = 1,
    required int unitPriceCents,
    String? partId,
    String? taskId,
  }) {
    return InvoiceItemModel(
      id: '',
      invoiceId: invoiceId,
      itemType: itemType,
      description: description,
      quantity: quantity,
      unitPriceCents: unitPriceCents,
      totalPriceCents: quantity * unitPriceCents,
      partId: partId,
      taskId: taskId,
      createdAt: DateTime.now(),
    );
  }

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      id: (json['id'] as String?) ?? '',
      invoiceId: (json['invoice_id'] as String?) ?? '',
      itemType: InvoiceItemType.fromString(json['item_type'] as String?),
      description: (json['description'] as String?) ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPriceCents: (json['unit_price_cents'] as num?)?.toInt() ?? 0,
      totalPriceCents: (json['total_price_cents'] as num?)?.toInt() ?? 0,
      partId: json['part_id'] as String?,
      taskId: json['task_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'invoice_id': invoiceId,
      'item_type': itemType.toDbString(),
      'description': description,
      'quantity': quantity,
      'unit_price_cents': unitPriceCents,
      'total_price_cents': totalPriceCents,
      if (partId != null) 'part_id': partId,
      if (taskId != null) 'task_id': taskId,
    };
  }

  InvoiceItemModel copyWith({
    String? id,
    String? invoiceId,
    InvoiceItemType? itemType,
    String? description,
    int? quantity,
    int? unitPriceCents,
    int? totalPriceCents,
    String? partId,
    String? taskId,
    DateTime? createdAt,
  }) {
    return InvoiceItemModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      itemType: itemType ?? this.itemType,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      totalPriceCents: totalPriceCents ?? this.totalPriceCents,
      partId: partId ?? this.partId,
      taskId: taskId ?? this.taskId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Settlement payment record mapping `public.payments`.
class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.paymentNumber,
    required this.invoiceId,
    required this.amountCents,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.completed,
    this.referenceNumber,
    this.cashTenderedCents,
    this.changeGivenCents = 0,
    this.notes,
    required this.recordedBy,
    required this.createdAt,
  });

  final String id;
  final String paymentNumber;
  final String invoiceId;
  final int amountCents;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? referenceNumber;
  final int? cashTenderedCents;
  final int changeGivenCents;
  final String? notes;
  final String recordedBy;
  final DateTime createdAt;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: (json['id'] as String?) ?? '',
      paymentNumber: (json['payment_number'] as String?) ?? '',
      invoiceId: (json['invoice_id'] as String?) ?? '',
      amountCents: (json['amount_cents'] as num?)?.toInt() ?? 0,
      paymentMethod: PaymentMethod.fromString(json['payment_method'] as String?),
      paymentStatus: PaymentStatus.fromString(json['payment_status'] as String?),
      referenceNumber: json['reference_number'] as String?,
      cashTenderedCents: (json['cash_tendered_cents'] as num?)?.toInt(),
      changeGivenCents: (json['change_given_cents'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      recordedBy: (json['recorded_by'] as String?) ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'payment_number': paymentNumber,
      'invoice_id': invoiceId,
      'amount_cents': amountCents,
      'payment_method': paymentMethod.toDbString(),
      'payment_status': paymentStatus.toDbString(),
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (cashTenderedCents != null) 'cash_tendered_cents': cashTenderedCents,
      'change_given_cents': changeGivenCents,
      if (notes != null) 'notes': notes,
      'recorded_by': recordedBy,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? paymentNumber,
    String? invoiceId,
    int? amountCents,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    String? referenceNumber,
    int? cashTenderedCents,
    int? changeGivenCents,
    String? notes,
    String? recordedBy,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      invoiceId: invoiceId ?? this.invoiceId,
      amountCents: amountCents ?? this.amountCents,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      cashTenderedCents: cashTenderedCents ?? this.cashTenderedCents,
      changeGivenCents: changeGivenCents ?? this.changeGivenCents,
      notes: notes ?? this.notes,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Comprehensive invoice model mapping `public.invoices`.
/// All monetary values are represented strictly in integer cents (BIGINT in database).
class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.serviceOrderId,
    required this.customerId,
    this.status = InvoiceStatus.draft,
    this.subtotalLaborCents = 0,
    this.subtotalPartsCents = 0,
    this.taxPercent = 11.0,
    this.taxAmountCents = 0,
    this.discountCents = 0,
    this.depositAppliedCents = 0,
    this.insuranceCoverageCents = 0,
    this.totalAmountCents = 0,
    this.amountPaidCents = 0,
    this.outstandingBalanceCents = 0,
    this.finalizedAt,
    this.finalizedBy,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.payments = const [],
    this.customerName,
    this.customerPhone,
    this.vehiclePlate,
    this.vehicleModel,
    this.orderNumber,
  });

  final String id;
  final String invoiceNumber;
  final String serviceOrderId;
  final String customerId;
  final InvoiceStatus status;
  final int subtotalLaborCents;
  final int subtotalPartsCents;
  final double taxPercent;
  final int taxAmountCents;
  final int discountCents;
  final int depositAppliedCents;
  final int insuranceCoverageCents;
  final int totalAmountCents;
  final int amountPaidCents;
  final int outstandingBalanceCents;
  final DateTime? finalizedAt;
  final String? finalizedBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined / enriched telemetry
  final List<InvoiceItemModel> items;
  final List<PaymentModel> payments;
  final String? customerName;
  final String? customerPhone;
  final String? vehiclePlate;
  final String? vehicleModel;
  final String? orderNumber;

  // Financial helper calculations
  int get subtotalCents => subtotalLaborCents + subtotalPartsCents;
  int get taxableSubtotalCents =>
      calculateTaxableSubtotal(subtotalLaborCents, subtotalPartsCents, discountCents);
  bool get isPaid => status == InvoiceStatus.paid || (totalAmountCents > 0 && outstandingBalanceCents == 0);
  bool get isPartiallyPaid =>
      status == InvoiceStatus.partiallyPaid ||
      (amountPaidCents > 0 && outstandingBalanceCents > 0 && status != InvoiceStatus.paid);

  String get formattedLabor => CurrencyFormatter.formatIdr(subtotalLaborCents);
  String get formattedParts => CurrencyFormatter.formatIdr(subtotalPartsCents);
  String get formattedSubtotal => CurrencyFormatter.formatIdr(subtotalCents);
  String get formattedTaxableSubtotal => CurrencyFormatter.formatIdr(taxableSubtotalCents);
  String get formattedTax => CurrencyFormatter.formatIdr(taxAmountCents);
  String get formattedDiscount => CurrencyFormatter.formatIdr(discountCents);
  String get formattedDeposit => CurrencyFormatter.formatIdr(depositAppliedCents);
  String get formattedInsurance => CurrencyFormatter.formatIdr(insuranceCoverageCents);
  String get formattedTotal => CurrencyFormatter.formatIdr(totalAmountCents);
  String get formattedAmountPaid => CurrencyFormatter.formatIdr(amountPaidCents);
  String get formattedOutstanding => CurrencyFormatter.formatIdr(outstandingBalanceCents);

  /// Computes taxable subtotal in integer cents.
  static int calculateTaxableSubtotal(int laborCents, int partsCents, [int discountCents = 0]) {
    final subtotal = laborCents + partsCents;
    return max(0, subtotal - max(0, discountCents));
  }

  /// Standard 11% PPN calculation or parameterized tax percent calculation using integer math.
  static int calculateTax(int taxableSubtotalCents, [double taxPercent = 11.0]) {
    if (taxableSubtotalCents <= 0 || taxPercent <= 0) return 0;
    if ((taxPercent - 11.0).abs() < 0.001) {
      return CurrencyFormatter.calculatePpn(taxableSubtotalCents);
    }
    return ((taxableSubtotalCents * taxPercent) / 100).round();
  }

  /// Calculates grand total amount based on labor, parts, discount, tax, and insurance deduction.
  static int calculateGrandTotal({
    required int subtotalLaborCents,
    required int subtotalPartsCents,
    int discountCents = 0,
    int insuranceCoverageCents = 0,
    double taxPercent = 11.0,
  }) {
    final taxable = calculateTaxableSubtotal(subtotalLaborCents, subtotalPartsCents, discountCents);
    final tax = calculateTax(taxable, taxPercent);
    final totalBeforeInsurance = taxable + tax;
    return max(0, totalBeforeInsurance - max(0, insuranceCoverageCents));
  }

  /// Calculates outstanding balance from total and paid amounts.
  static int calculateOutstandingBalance(int totalAmountCents, int amountPaidCents) {
    return max(0, totalAmountCents - max(0, amountPaidCents));
  }

  /// Calculates cash change for cash payments.
  static int calculateCashChange(int cashTenderedCents, int amountToPayCents) {
    if (cashTenderedCents < amountToPayCents) return 0;
    return cashTenderedCents - amountToPayCents;
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    // Parse joined relations if present
    List<InvoiceItemModel> parsedItems = const [];
    if (json['invoice_items'] is List) {
      parsedItems = (json['invoice_items'] as List)
          .map((e) => InvoiceItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<PaymentModel> parsedPayments = const [];
    if (json['payments'] is List) {
      parsedPayments = (json['payments'] as List)
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    String? customerName;
    String? customerPhone;
    if (json['customers'] is Map) {
      final cust = json['customers'] as Map<String, dynamic>;
      customerName = cust['full_name'] as String?;
      customerPhone = cust['phone_number'] as String?;
    }

    String? orderNumber;
    String? vehiclePlate;
    String? vehicleModel;
    if (json['service_orders'] is Map) {
      final order = json['service_orders'] as Map<String, dynamic>;
      orderNumber = order['order_number'] as String?;
      if (order['vehicles'] is Map) {
        final veh = order['vehicles'] as Map<String, dynamic>;
        vehiclePlate = veh['license_plate'] as String?;
        final make = veh['make'] as String? ?? '';
        final model = veh['model'] as String? ?? '';
        vehicleModel = '$make $model'.trim();
      }
    }

    final total = (json['total_amount_cents'] as num?)?.toInt() ?? 0;
    final paid = (json['amount_paid_cents'] as num?)?.toInt() ?? 0;
    final storedBalance = (json['outstanding_balance_cents'] as num?)?.toInt();
    final balance = storedBalance ?? calculateOutstandingBalance(total, paid);

    return InvoiceModel(
      id: (json['id'] as String?) ?? '',
      invoiceNumber: (json['invoice_number'] as String?) ?? '',
      serviceOrderId: (json['service_order_id'] as String?) ?? '',
      customerId: (json['customer_id'] as String?) ?? '',
      status: InvoiceStatus.fromString(json['status'] as String?),
      subtotalLaborCents: (json['subtotal_labor_cents'] as num?)?.toInt() ?? 0,
      subtotalPartsCents: (json['subtotal_parts_cents'] as num?)?.toInt() ?? 0,
      taxPercent: (json['tax_percent'] as num?)?.toDouble() ?? 11.0,
      taxAmountCents: (json['tax_amount_cents'] as num?)?.toInt() ?? 0,
      discountCents: (json['discount_cents'] as num?)?.toInt() ?? 0,
      depositAppliedCents: (json['deposit_applied_cents'] as num?)?.toInt() ?? 0,
      insuranceCoverageCents: (json['insurance_coverage_cents'] as num?)?.toInt() ?? 0,
      totalAmountCents: total,
      amountPaidCents: paid,
      outstandingBalanceCents: balance,
      finalizedAt: json['finalized_at'] != null
          ? DateTime.tryParse(json['finalized_at'] as String)
          : null,
      finalizedBy: json['finalized_by'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      items: parsedItems,
      payments: parsedPayments,
      customerName: customerName,
      customerPhone: customerPhone,
      vehiclePlate: vehiclePlate,
      vehicleModel: vehicleModel,
      orderNumber: orderNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'invoice_number': invoiceNumber,
      'service_order_id': serviceOrderId,
      'customer_id': customerId,
      'status': status.toDbString(),
      'subtotal_labor_cents': subtotalLaborCents,
      'subtotal_parts_cents': subtotalPartsCents,
      'tax_percent': taxPercent,
      'tax_amount_cents': taxAmountCents,
      'discount_cents': discountCents,
      'deposit_applied_cents': depositAppliedCents,
      'insurance_coverage_cents': insuranceCoverageCents,
      'total_amount_cents': totalAmountCents,
      'amount_paid_cents': amountPaidCents,
      if (finalizedAt != null) 'finalized_at': finalizedAt!.toIso8601String(),
      if (finalizedBy != null) 'finalized_by': finalizedBy,
      if (notes != null) 'notes': notes,
    };
  }

  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    String? serviceOrderId,
    String? customerId,
    InvoiceStatus? status,
    int? subtotalLaborCents,
    int? subtotalPartsCents,
    double? taxPercent,
    int? taxAmountCents,
    int? discountCents,
    int? depositAppliedCents,
    int? insuranceCoverageCents,
    int? totalAmountCents,
    int? amountPaidCents,
    int? outstandingBalanceCents,
    DateTime? finalizedAt,
    String? finalizedBy,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<InvoiceItemModel>? items,
    List<PaymentModel>? payments,
    String? customerName,
    String? customerPhone,
    String? vehiclePlate,
    String? vehicleModel,
    String? orderNumber,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      serviceOrderId: serviceOrderId ?? this.serviceOrderId,
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      subtotalLaborCents: subtotalLaborCents ?? this.subtotalLaborCents,
      subtotalPartsCents: subtotalPartsCents ?? this.subtotalPartsCents,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmountCents: taxAmountCents ?? this.taxAmountCents,
      discountCents: discountCents ?? this.discountCents,
      depositAppliedCents: depositAppliedCents ?? this.depositAppliedCents,
      insuranceCoverageCents: insuranceCoverageCents ?? this.insuranceCoverageCents,
      totalAmountCents: totalAmountCents ?? this.totalAmountCents,
      amountPaidCents: amountPaidCents ?? this.amountPaidCents,
      outstandingBalanceCents: outstandingBalanceCents ?? this.outstandingBalanceCents,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      finalizedBy: finalizedBy ?? this.finalizedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      payments: payments ?? this.payments,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      orderNumber: orderNumber ?? this.orderNumber,
    );
  }
}
