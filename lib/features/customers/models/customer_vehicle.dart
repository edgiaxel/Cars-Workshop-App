enum VehicleStatus {
  inWorkshop,
  passedQC,
  serviceDue,
  ready,
  awaitingAuth,
}

/// Customer vehicle model representing a registered vehicle in PitMate.
class CustomerVehicle {
  const CustomerVehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.mileageKm,
    required this.trim,
    required this.colorName,
    required this.status,
    this.activeServiceOrderId,
    this.bayAssignment,
    this.imageUrl,
  });

  final String id;
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final int mileageKm;
  final String trim;
  final String colorName;
  final VehicleStatus status;
  final String? activeServiceOrderId;
  final String? bayAssignment;
  final String? imageUrl;

  String get displayName => '$make $model';
  String get specsSubtitle => '$year • $trim • $colorName';

  CustomerVehicle copyWith({
    String? id,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    int? mileageKm,
    String? trim,
    String? colorName,
    VehicleStatus? status,
    String? activeServiceOrderId,
    String? bayAssignment,
    String? imageUrl,
  }) {
    return CustomerVehicle(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      mileageKm: mileageKm ?? this.mileageKm,
      trim: trim ?? this.trim,
      colorName: colorName ?? this.colorName,
      status: status ?? this.status,
      activeServiceOrderId: activeServiceOrderId ?? this.activeServiceOrderId,
      bayAssignment: bayAssignment ?? this.bayAssignment,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
