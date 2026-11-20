/// Vehicle domain model matching PROJECT.md interface contract.
class Vehicle {
  final String id;
  final String customerId;
  final String licensePlate;
  final String? vin;
  final String make;
  final String model;
  final int year;
  final int currentMileage;
  final String? color;
  final String? transmission;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.customerId,
    required this.licensePlate,
    this.vin,
    required this.make,
    required this.model,
    required this.year,
    this.currentMileage = 0,
    this.color,
    this.transmission,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Normalizes license plate: uppercase and single spacing between words.
  static String normalizePlate(String raw) {
    return raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Vehicle copyWith({
    String? id,
    String? customerId,
    String? licensePlate,
    String? vin,
    String? make,
    String? model,
    int? year,
    int? currentMileage,
    String? color,
    String? transmission,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      licensePlate: licensePlate != null ? normalizePlate(licensePlate) : this.licensePlate,
      vin: vin ?? this.vin,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      currentMileage: currentMileage ?? this.currentMileage,
      color: color ?? this.color,
      transmission: transmission ?? this.transmission,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehicle &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          licensePlate == other.licensePlate;

  @override
  int get hashCode => id.hashCode ^ licensePlate.hashCode;
}
