/// Domain model for PitMate vehicles.
class Vehicle {
  final String id;
  final String customerId;
  final String licensePlate;
  final String? vin;
  final String make;
  final String model;
  final int year;
  final String? transmission;
  final String? color;
  final int currentMileage;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vehicle({
    required this.id,
    required this.customerId,
    required this.licensePlate,
    this.vin,
    required this.make,
    required this.model,
    required this.year,
    this.transmission,
    this.color,
    this.currentMileage = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      licensePlate: json['license_plate'] as String,
      vin: json['vin'] as String?,
      make: json['make'] as String,
      model: json['model'] as String,
      year: (json['year'] as num).toInt(),
      transmission: json['transmission'] as String?,
      color: json['color'] as String?,
      currentMileage: (json['current_mileage'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'license_plate': licensePlate,
      'vin': vin,
      'make': make,
      'model': model,
      'year': year,
      'transmission': transmission,
      'color': color,
      'current_mileage': currentMileage,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Vehicle copyWith({
    String? id,
    String? customerId,
    String? licensePlate,
    String? vin,
    String? make,
    String? model,
    int? year,
    String? transmission,
    String? color,
    int? currentMileage,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      transmission: transmission ?? this.transmission,
      color: color ?? this.color,
      currentMileage: currentMileage ?? this.currentMileage,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
