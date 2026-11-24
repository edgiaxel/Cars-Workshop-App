import 'dart:convert';

/// Represents the physical checklist required before vehicle handover.
class HandoverChecklist {
  const HandoverChecklist({
    this.vehicleCleaned = true,
    this.personalItemsReturned = true,
    this.oldPartsPresented = true,
    this.keysReturned = true,
  });

  /// Vehicle exterior washed, interior cleaned, protection covers removed.
  final bool vehicleCleaned;

  /// Customer's personal belongings in cabin/trunk verified and returned.
  final bool personalItemsReturned;

  /// Replaced worn parts presented or safely packaged for customer.
  final bool oldPartsPresented;

  /// Vehicle ignition keys, remotes, and service booklet handed back.
  final bool keysReturned;

  /// All physical inspection items must be checked for handover completion.
  bool get isComplete =>
      vehicleCleaned &&
      personalItemsReturned &&
      oldPartsPresented &&
      keysReturned;

  /// Factory from JSON map or string.
  factory HandoverChecklist.fromJson(dynamic json) {
    if (json == null) {
      return const HandoverChecklist();
    }
    final Map<String, dynamic> map;
    if (json is String) {
      try {
        map = jsonDecode(json) as Map<String, dynamic>;
      } catch (_) {
        return const HandoverChecklist();
      }
    } else if (json is Map) {
      map = Map<String, dynamic>.from(json);
    } else {
      return const HandoverChecklist();
    }

    return HandoverChecklist(
      vehicleCleaned: map['vehicle_cleaned'] as bool? ?? false,
      personalItemsReturned: map['personal_items_returned'] as bool? ?? false,
      oldPartsPresented: map['old_parts_presented'] as bool? ?? false,
      keysReturned: map['keys_returned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'vehicle_cleaned': vehicleCleaned,
        'personal_items_returned': personalItemsReturned,
        'old_parts_presented': oldPartsPresented,
        'keys_returned': keysReturned,
      };

  HandoverChecklist copyWith({
    bool? vehicleCleaned,
    bool? personalItemsReturned,
    bool? oldPartsPresented,
    bool? keysReturned,
  }) {
    return HandoverChecklist(
      vehicleCleaned: vehicleCleaned ?? this.vehicleCleaned,
      personalItemsReturned:
          personalItemsReturned ?? this.personalItemsReturned,
      oldPartsPresented: oldPartsPresented ?? this.oldPartsPresented,
      keysReturned: keysReturned ?? this.keysReturned,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HandoverChecklist &&
          runtimeType == other.runtimeType &&
          vehicleCleaned == other.vehicleCleaned &&
          personalItemsReturned == other.personalItemsReturned &&
          oldPartsPresented == other.oldPartsPresented &&
          keysReturned == other.keysReturned;

  @override
  int get hashCode => Object.hash(
        vehicleCleaned,
        personalItemsReturned,
        oldPartsPresented,
        keysReturned,
      );
}

/// Represents a persistent record in `public.vehicle_handovers`.
class VehicleHandoverModel {
  const VehicleHandoverModel({
    required this.id,
    required this.serviceOrderId,
    required this.customerId,
    required this.responsibleAdminId,
    required this.handoverTimestamp,
    this.customerConfirmed = true,
    this.paymentOverrideReason,
    this.checklist = const HandoverChecklist(),
    this.notes,
    required this.createdAt,
    this.orderNumber,
    this.customerName,
    this.customerPhone,
    this.vehiclePlate,
    this.vehicleMake,
    this.vehicleModel,
    this.adminName,
  });

  final String id;
  final String serviceOrderId;
  final String customerId;
  final String responsibleAdminId;
  final DateTime handoverTimestamp;
  final bool customerConfirmed;
  final String? paymentOverrideReason;
  final HandoverChecklist checklist;
  final String? notes;
  final DateTime createdAt;

  // Joined relational fields
  final String? orderNumber;
  final String? customerName;
  final String? customerPhone;
  final String? vehiclePlate;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? adminName;

  String get vehicleDescription {
    if (vehiclePlate != null && vehicleMake != null) {
      return '$vehicleMake $vehicleModel [$vehiclePlate]';
    }
    if (vehiclePlate != null) return vehiclePlate!;
    return 'Vehicle';
  }

  factory VehicleHandoverModel.fromJson(Map<String, dynamic> json) {
    final rawChecklist = json['checklist'];
    final parsedChecklist = HandoverChecklist.fromJson(rawChecklist);

    final rawHandoverTime = json['handover_timestamp'];
    final DateTime parsedHandoverTime;
    if (rawHandoverTime is DateTime) {
      parsedHandoverTime = rawHandoverTime;
    } else if (rawHandoverTime is String) {
      parsedHandoverTime =
          DateTime.tryParse(rawHandoverTime) ?? DateTime.now();
    } else {
      parsedHandoverTime = DateTime.now();
    }

    final rawCreatedAt = json['created_at'];
    final DateTime parsedCreatedAt;
    if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    final serviceOrderData = json['service_orders'] as Map<String, dynamic>?;
    final customerData = json['customers'] as Map<String, dynamic>?;
    final vehicleData = serviceOrderData?['vehicles'] as Map<String, dynamic>? ??
        json['vehicles'] as Map<String, dynamic>?;
    final adminProfileData = json['profiles'] as Map<String, dynamic>? ??
        json['responsible_admin'] as Map<String, dynamic>?;

    return VehicleHandoverModel(
      id: json['id'] as String? ?? '',
      serviceOrderId: json['service_order_id'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      responsibleAdminId: json['responsible_admin_id'] as String? ?? '',
      handoverTimestamp: parsedHandoverTime,
      customerConfirmed: json['customer_confirmed'] as bool? ?? true,
      paymentOverrideReason: json['payment_override_reason'] as String?,
      checklist: parsedChecklist,
      notes: json['notes'] as String?,
      createdAt: parsedCreatedAt,
      orderNumber: (serviceOrderData?['order_number'] as String?) ??
          (json['order_number'] as String?),
      customerName: (customerData?['full_name'] as String?) ??
          (json['customer_name'] as String?),
      customerPhone: (customerData?['phone_number'] as String?) ??
          (json['customer_phone'] as String?),
      vehiclePlate: (vehicleData?['license_plate'] as String?) ??
          (json['license_plate'] as String?),
      vehicleMake: (vehicleData?['make'] as String?) ??
          (json['vehicle_make'] as String?),
      vehicleModel: (vehicleData?['model'] as String?) ??
          (json['vehicle_model'] as String?),
      adminName: (adminProfileData?['full_name'] as String?) ??
          (json['admin_name'] as String?),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'service_order_id': serviceOrderId,
      'customer_id': customerId,
      'responsible_admin_id': responsibleAdminId,
      'handover_timestamp': handoverTimestamp.toIso8601String(),
      'customer_confirmed': customerConfirmed,
      'payment_override_reason': paymentOverrideReason,
      'checklist': checklist.toJson(),
      'notes': notes,
    };
    if (includeId && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  VehicleHandoverModel copyWith({
    String? id,
    String? serviceOrderId,
    String? customerId,
    String? responsibleAdminId,
    DateTime? handoverTimestamp,
    bool? customerConfirmed,
    String? paymentOverrideReason,
    HandoverChecklist? checklist,
    String? notes,
    DateTime? createdAt,
    String? orderNumber,
    String? customerName,
    String? customerPhone,
    String? vehiclePlate,
    String? vehicleMake,
    String? vehicleModel,
    String? adminName,
  }) {
    return VehicleHandoverModel(
      id: id ?? this.id,
      serviceOrderId: serviceOrderId ?? this.serviceOrderId,
      customerId: customerId ?? this.customerId,
      responsibleAdminId: responsibleAdminId ?? this.responsibleAdminId,
      handoverTimestamp: handoverTimestamp ?? this.handoverTimestamp,
      customerConfirmed: customerConfirmed ?? this.customerConfirmed,
      paymentOverrideReason:
          paymentOverrideReason ?? this.paymentOverrideReason,
      checklist: checklist ?? this.checklist,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      adminName: adminName ?? this.adminName,
    );
  }
}

/// Represents an item in the queue of service orders ready for or already handed over.
class HandoverOrderCandidate {
  const HandoverOrderCandidate({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.vehicleId,
    required this.vehiclePlate,
    required this.vehicleMake,
    required this.vehicleModel,
    this.vehicleYear,
    this.vehicleColor,
    required this.odometer,
    this.customerComplaint,
    required this.createdAt,
    required this.updatedAt,
    this.invoiceId,
    this.invoiceNumber,
    this.invoiceStatus,
    this.totalAmountCents = 0,
    this.amountPaidCents = 0,
    this.outstandingBalanceCents = 0,
    this.handover,
  });

  final String orderId;
  final String orderNumber;
  final String status;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String vehicleId;
  final String vehiclePlate;
  final String vehicleMake;
  final String vehicleModel;
  final int? vehicleYear;
  final String? vehicleColor;
  final int odometer;
  final String? customerComplaint;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Invoice / Payment info
  final String? invoiceId;
  final String? invoiceNumber;
  final String? invoiceStatus;
  final int totalAmountCents;
  final int amountPaidCents;
  final int outstandingBalanceCents;

  // Existing handover if already completed
  final VehicleHandoverModel? handover;

  bool get isPaid => outstandingBalanceCents <= 0;
  bool get hasInvoice => invoiceId != null && invoiceId!.isNotEmpty;
  bool get isHandedOver => handover != null || status == 'closed';

  String get vehicleDescription {
    final buffer = StringBuffer('$vehicleMake $vehicleModel');
    if (vehicleYear != null) buffer.write(' ($vehicleYear)');
    buffer.write(' • $vehiclePlate');
    return buffer.toString();
  }

  factory HandoverOrderCandidate.fromJson(Map<String, dynamic> json) {
    final customerData = json['customers'] as Map<String, dynamic>?;
    final vehicleData = json['vehicles'] as Map<String, dynamic>?;

    // Handle invoices: could be a List or Map from Supabase select
    Map<String, dynamic>? invoiceData;
    final rawInvoices = json['invoices'];
    if (rawInvoices is List && rawInvoices.isNotEmpty) {
      invoiceData = rawInvoices.first as Map<String, dynamic>?;
    } else if (rawInvoices is Map<String, dynamic>) {
      invoiceData = rawInvoices;
    }

    // Handle vehicle_handovers: could be a List or Map
    Map<String, dynamic>? handoverData;
    final rawHandovers = json['vehicle_handovers'];
    if (rawHandovers is List && rawHandovers.isNotEmpty) {
      handoverData = rawHandovers.first as Map<String, dynamic>?;
    } else if (rawHandovers is Map<String, dynamic>) {
      handoverData = rawHandovers;
    }

    final rawCreatedAt = json['created_at'];
    final DateTime parsedCreatedAt = rawCreatedAt is DateTime
        ? rawCreatedAt
        : (rawCreatedAt is String
            ? DateTime.tryParse(rawCreatedAt) ?? DateTime.now()
            : DateTime.now());

    final rawUpdatedAt = json['updated_at'];
    final DateTime parsedUpdatedAt = rawUpdatedAt is DateTime
        ? rawUpdatedAt
        : (rawUpdatedAt is String
            ? DateTime.tryParse(rawUpdatedAt) ?? DateTime.now()
            : DateTime.now());

    final totalCents = (invoiceData?['total_amount_cents'] as num?)?.toInt() ?? 0;
    final paidCents = (invoiceData?['amount_paid_cents'] as num?)?.toInt() ?? 0;
    final outstandingCents = (invoiceData?['outstanding_balance_cents'] as num?)?.toInt() ??
        (totalCents > paidCents ? totalCents - paidCents : 0);

    return HandoverOrderCandidate(
      orderId: json['id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
      customerId: json['customer_id'] as String? ?? '',
      customerName: (customerData?['full_name'] as String?) ??
          (json['customer_name'] as String? ?? 'Unknown Customer'),
      customerPhone: (customerData?['phone_number'] as String?) ??
          (json['customer_phone'] as String?),
      vehicleId: json['vehicle_id'] as String? ?? '',
      vehiclePlate: (vehicleData?['license_plate'] as String?) ??
          (json['license_plate'] as String? ?? '-'),
      vehicleMake: (vehicleData?['make'] as String?) ??
          (json['vehicle_make'] as String? ?? 'Vehicle'),
      vehicleModel: (vehicleData?['model'] as String?) ??
          (json['vehicle_model'] as String? ?? ''),
      vehicleYear: (vehicleData?['year'] as num?)?.toInt(),
      vehicleColor: vehicleData?['color'] as String?,
      odometer: (json['odometer'] as num?)?.toInt() ?? 0,
      customerComplaint: json['customer_complaint'] as String?,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      invoiceId: invoiceData?['id'] as String?,
      invoiceNumber: invoiceData?['invoice_number'] as String?,
      invoiceStatus: invoiceData?['status'] as String?,
      totalAmountCents: totalCents,
      amountPaidCents: paidCents,
      outstandingBalanceCents: outstandingCents,
      handover: handoverData != null
          ? VehicleHandoverModel.fromJson(handoverData)
          : null,
    );
  }
}
