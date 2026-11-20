import 'customer.dart';

/// Vehicle domain model mapping to public.vehicles table.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.customerId,
    required this.make,
    required this.model,
    this.variant,
    this.modelYear,
    this.licensePlate,
    this.vin,
    this.vehicleNumber,
    this.mileageKm = 0,
    this.color,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.customer,
  });

  final String id;
  final String customerId;
  final String make;
  final String model;
  final String? variant;
  final int? modelYear;
  final String? licensePlate;
  final String? vin;
  final String? vehicleNumber;
  final int mileageKm;
  final String? color;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Customer? customer;

  String get displayName {
    final buffer = StringBuffer('$make $model');
    if (variant != null && variant!.isNotEmpty) {
      buffer.write(' $variant');
    }
    return buffer.toString();
  }

  String get identifierLabel {
    if (licensePlate != null && licensePlate!.isNotEmpty) {
      return licensePlate!;
    }
    if (vehicleNumber != null && vehicleNumber!.isNotEmpty) {
      return vehicleNumber!;
    }
    if (vin != null && vin!.isNotEmpty) {
      return 'VIN: $vin';
    }
    return 'NO-PLATE';
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    Customer? cust;
    if (json['customers'] != null &&
        json['customers'] is Map<String, dynamic>) {
      cust = Customer.fromJson(json['customers'] as Map<String, dynamic>);
    }

    return Vehicle(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      variant: json['variant'] as String?,
      modelYear: json['model_year'] as int?,
      licensePlate: json['license_plate'] as String?,
      vin: json['vin'] as String?,
      vehicleNumber: json['vehicle_number'] as String?,
      mileageKm: json['mileage_km'] as int? ?? 0,
      color: json['color'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      customer: cust,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'make': make,
      'model': model,
      if (variant != null) 'variant': variant,
      if (modelYear != null) 'model_year': modelYear,
      if (licensePlate != null) 'license_plate': licensePlate,
      if (vin != null) 'vin': vin,
      if (vehicleNumber != null) 'vehicle_number': vehicleNumber,
      'mileage_km': mileageKm,
      if (color != null) 'color': color,
      if (notes != null) 'notes': notes,
    };
  }

  Vehicle copyWith({
    String? id,
    String? customerId,
    String? make,
    String? model,
    String? variant,
    int? modelYear,
    String? licensePlate,
    String? vin,
    String? vehicleNumber,
    int? mileageKm,
    String? color,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Customer? customer,
  }) {
    return Vehicle(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      make: make ?? this.make,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      modelYear: modelYear ?? this.modelYear,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      mileageKm: mileageKm ?? this.mileageKm,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customer: customer ?? this.customer,
    );
  }
}
