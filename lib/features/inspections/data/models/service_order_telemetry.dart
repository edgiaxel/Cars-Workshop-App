/// Vehicle and order telemetry data used in inspection screens.
class ServiceOrderTelemetry {
  const ServiceOrderTelemetry({
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.year,
    required this.odometer,
    required this.customerComplaint,
    this.fuelLevel,
    this.assignedBay,
    this.status = 'inspection_pending',
  });

  final String orderId;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String licensePlate;
  final String make;
  final String model;
  final int year;
  final int odometer;
  final String customerComplaint;
  final String? fuelLevel;
  final String? assignedBay;
  final String status;

  String get vehicleDisplayName => '$year $make $model';
  String get formattedOdometer => '${odometer.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )} KM';

  factory ServiceOrderTelemetry.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicles'] as Map<String, dynamic>? ?? {};
    final customer = json['customers'] as Map<String, dynamic>? ?? {};

    return ServiceOrderTelemetry(
      orderId: json['id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? 'SO-PENDING',
      customerName: customer['full_name'] as String? ?? json['customer_name'] as String? ?? 'Valued Customer',
      customerPhone: customer['phone_number'] as String? ?? json['customer_phone'] as String? ?? '',
      licensePlate: vehicle['license_plate'] as String? ?? json['license_plate'] as String? ?? 'B ---- ---',
      make: vehicle['make'] as String? ?? json['make'] as String? ?? 'Vehicle',
      model: vehicle['model'] as String? ?? json['model'] as String? ?? 'Model',
      year: (vehicle['year'] ?? json['year']) as int? ?? DateTime.now().year,
      odometer: (json['odometer'] ?? vehicle['mileage']) as int? ?? 0,
      customerComplaint: json['customer_complaint'] as String? ?? 'General inspection',
      fuelLevel: json['fuel_level'] as String?,
      assignedBay: json['assigned_bay'] as String?,
      status: json['status'] as String? ?? 'inspection_pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'order_number': orderNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'license_plate': licensePlate,
      'make': make,
      'model': model,
      'year': year,
      'odometer': odometer,
      'customer_complaint': customerComplaint,
      'fuel_level': fuelLevel,
      'assigned_bay': assignedBay,
      'status': status,
    };
  }
}
