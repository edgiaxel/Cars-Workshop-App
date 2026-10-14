import 'package:pitmate/data/models/booking.dart';
import 'package:pitmate/data/models/customer.dart';
import 'package:pitmate/data/models/mechanic.dart';
import 'package:pitmate/data/models/service_notification.dart';
import 'package:pitmate/data/models/service_order.dart';
import 'package:pitmate/data/models/service_reminder.dart';
import 'package:pitmate/data/models/service_task.dart';
import 'package:pitmate/data/models/spare_part.dart';
import 'package:pitmate/data/models/user_profile.dart';
import 'package:pitmate/data/models/user_role.dart';
import 'package:pitmate/data/models/vehicle.dart';
import 'package:pitmate/data/repositories/booking_repository.dart';
import 'package:pitmate/data/repositories/customer_repository.dart';
import 'package:pitmate/data/repositories/mechanic_repository.dart';
import 'package:pitmate/data/repositories/notification_repository.dart';
import 'package:pitmate/data/repositories/reminder_repository.dart';
import 'package:pitmate/data/repositories/service_order_repository.dart';
import 'package:pitmate/data/repositories/spare_part_repository.dart';
import 'package:pitmate/data/repositories/task_repository.dart';
import 'package:pitmate/data/repositories/vehicle_repository.dart';

/// In-memory fake implementation of [CustomerRepository] for testing.
class FakeCustomerRepository implements CustomerRepository {
  FakeCustomerRepository([List<Customer>? initialCustomers]) {
    _customers = initialCustomers != null
        ? List.from(initialCustomers)
        : [
            Customer(
              id: 'c1',
              profileId: 'p-bmw',
              customerType: 'company',
              companyName: 'BMW M Motorsport',
              address: 'Munich, Germany',
              notes: 'Development and customer racing operations.',
              profile: const UserProfile(
                id: 'p-bmw',
                role: UserRole.customer,
                fullName: 'BMW M Motorsport',
                phone: '+49 89 382 0',
              ),
            ),
            Customer(
              id: 'c2',
              profileId: 'p-aston',
              customerType: 'company',
              companyName: 'Aston Martin',
              address: 'Gaydon, Warwickshire, United Kingdom',
              notes: 'Performance and motorsport vehicle operations.',
              profile: const UserProfile(
                id: 'p-aston',
                role: UserRole.customer,
                fullName: 'Aston Martin',
                phone: '+44 1926 644 644',
              ),
            ),
            Customer(
              id: 'c3',
              profileId: 'p-axel',
              customerType: 'individual',
              address: 'Bandung, Indonesia',
              notes: 'Development and test customer account.',
              profile: const UserProfile(
                id: 'p-axel',
                role: UserRole.customer,
                fullName: 'Axel Zeed',
                phone: '+62 812 0000 0000',
              ),
            ),
          ];
  }

  late List<Customer> _customers;

  @override
  Future<List<Customer>> getCustomers({
    String? searchQuery,
    String? typeFilter,
  }) async {
    return _customers.where((c) {
      final matchesSearch =
          searchQuery == null ||
          searchQuery.isEmpty ||
          c.displayName.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesFilter =
          typeFilter == null ||
          typeFilter.isEmpty ||
          typeFilter.toLowerCase() == 'all' ||
          c.customerType.toLowerCase() == typeFilter.toLowerCase();
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Future<Customer> getCustomerById(String id) async {
    return _customers.firstWhere((c) => c.id == id);
  }

  @override
  Future<Customer> createCustomer({
    required String profileId,
    required String customerType,
    String? companyName,
    String? address,
    String? notes,
  }) async {
    final customer = Customer(
      id: 'cust-${_customers.length + 1}',
      profileId: profileId,
      customerType: customerType,
      companyName: companyName,
      address: address,
      notes: notes,
    );
    _customers.add(customer);
    return customer;
  }

  @override
  Future<Customer> updateCustomer({
    required String id,
    required String customerType,
    String? companyName,
    String? address,
    String? notes,
    String? fullName,
    String? phone,
  }) async {
    final index = _customers.indexWhere((c) => c.id == id);
    if (index == -1) throw Exception('Customer not found');
    final old = _customers[index];
    final updated = old.copyWith(
      customerType: customerType,
      companyName: companyName,
      address: address,
      notes: notes,
      profile: fullName != null || phone != null
          ? UserProfile(
              id: old.profileId,
              role: UserRole.customer,
              fullName: fullName ?? old.profile?.fullName ?? '',
              phone: phone ?? old.profile?.phone,
            )
          : old.profile,
    );
    _customers[index] = updated;
    return updated;
  }

  @override
  Future<Customer?> getCurrentCustomer() async {
    return _customers.isNotEmpty ? _customers.first : null;
  }

  @override
  Future<void> deleteCustomer(String id) async {
    _customers.removeWhere((c) => c.id == id);
  }
}

/// In-memory fake implementation of [MechanicRepository] for testing.
class FakeMechanicRepository implements MechanicRepository {
  FakeMechanicRepository([List<Mechanic>? initialMechanics]) {
    _mechanics = initialMechanics != null
        ? List.from(initialMechanics)
        : [
            Mechanic(
              id: 'm1',
              profileId: 'p-max',
              employeeCode: 'MEC-001',
              specialization: 'Performance Powertrain & Diagnostics',
              hourlyRate: 350000,
              compensationPercentage: 30,
              hireDate: DateTime(2025, 1, 15),
              profile: const UserProfile(
                id: 'p-max',
                role: UserRole.mechanic,
                fullName: 'Max Verstappen',
                phone: '+62 811 1000 0002',
              ),
            ),
            Mechanic(
              id: 'm2',
              profileId: 'p-checo',
              employeeCode: 'MEC-002',
              specialization: 'Chassis, Suspension & Vehicle Dynamics',
              hourlyRate: 325000,
              compensationPercentage: 28,
              hireDate: DateTime(2025, 3, 1),
              profile: const UserProfile(
                id: 'p-checo',
                role: UserRole.mechanic,
                fullName: 'Sergio Perez',
                phone: '+62 811 1000 0003',
              ),
            ),
          ];
  }

  late List<Mechanic> _mechanics;

  @override
  Future<List<Mechanic>> getMechanics({String? searchQuery}) async {
    return _mechanics.where((m) {
      if (searchQuery == null || searchQuery.isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return m.displayName.toLowerCase().contains(q) ||
          m.employeeCode.toLowerCase().contains(q) ||
          (m.specialization?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Future<Mechanic> getMechanicById(String id) async {
    return _mechanics.firstWhere((m) => m.id == id);
  }

  @override
  Future<Mechanic?> getMechanicByProfileId(String profileId) async {
    try {
      return _mechanics.firstWhere((m) => m.profileId == profileId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Mechanic> createMechanic({
    required String profileId,
    required String employeeCode,
    String? specialization,
    double hourlyRate = 0,
    double compensationPercentage = 30,
    DateTime? hireDate,
  }) async {
    final mechanic = Mechanic(
      id: 'mech-${_mechanics.length + 1}',
      profileId: profileId,
      employeeCode: employeeCode,
      specialization: specialization,
      hourlyRate: hourlyRate,
      compensationPercentage: compensationPercentage,
      hireDate: hireDate,
    );
    _mechanics.add(mechanic);
    return mechanic;
  }

  @override
  Future<Mechanic> updateMechanic({
    required String id,
    String? employeeCode,
    String? specialization,
    double? hourlyRate,
    double? compensationPercentage,
    DateTime? hireDate,
    String? fullName,
    String? phone,
  }) async {
    final index = _mechanics.indexWhere((m) => m.id == id);
    if (index == -1) throw Exception('Mechanic not found');
    final old = _mechanics[index];
    final updated = old.copyWith(
      employeeCode: employeeCode ?? old.employeeCode,
      specialization: specialization ?? old.specialization,
      hourlyRate: hourlyRate ?? old.hourlyRate,
      compensationPercentage:
          compensationPercentage ?? old.compensationPercentage,
      hireDate: hireDate ?? old.hireDate,
      profile: fullName != null || phone != null
          ? UserProfile(
              id: old.profileId,
              role: UserRole.mechanic,
              fullName: fullName ?? old.profile?.fullName ?? '',
              phone: phone ?? old.profile?.phone,
            )
          : old.profile,
    );
    _mechanics[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteMechanic(String id) async {
    _mechanics.removeWhere((m) => m.id == id);
  }
}

/// In-memory fake implementation of [VehicleRepository] for testing.
class FakeVehicleRepository implements VehicleRepository {
  FakeVehicleRepository([List<Vehicle>? initialVehicles]) {
    _vehicles = initialVehicles != null
        ? List.from(initialVehicles)
        : [
            const Vehicle(
              id: 'v1',
              customerId: 'c3',
              make: 'BMW',
              model: 'M3 Touring',
              variant: 'Competition G81',
              modelYear: 2024,
              licensePlate: 'D 1999 AZ',
              mileageKm: 28650,
              color: 'Black Sapphire',
              notes: 'Personal vehicle.',
            ),
            const Vehicle(
              id: 'v2',
              customerId: 'c3',
              make: 'Toyota',
              model: 'Innova Zenix',
              variant: 'Hybrid',
              modelYear: 2024,
              licensePlate: 'D 1234 ZEN',
              mileageKm: 17420,
              color: 'Platinum White Pearl',
              notes: 'Family vehicle.',
            ),
            const Vehicle(
              id: 'v3',
              customerId: 'c1',
              make: 'BMW',
              model: 'M Hybrid V8',
              variant: 'LMDh',
              modelYear: 2026,
              vehicleNumber: '#15',
              mileageKm: 18420,
              color: 'BMW Motorsport White',
              notes: 'Prototype.',
            ),
          ];
  }

  late List<Vehicle> _vehicles;

  @override
  Future<List<Vehicle>> getVehicles({
    String? customerId,
    String? searchQuery,
    String? filterMake,
  }) async {
    return _vehicles.where((v) {
      if (customerId != null && v.customerId != customerId) return false;
      if (filterMake != null &&
          filterMake.isNotEmpty &&
          filterMake.toLowerCase() != 'all' &&
          !v.make.toLowerCase().contains(filterMake.toLowerCase())) {
        return false;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return v.displayName.toLowerCase().contains(q) ||
            (v.licensePlate?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();
  }

  @override
  Future<Vehicle> getVehicleById(String id) async {
    return _vehicles.firstWhere((v) => v.id == id);
  }

  @override
  Future<Vehicle> createVehicle({
    required String customerId,
    required String make,
    required String model,
    String? variant,
    int? modelYear,
    String? licensePlate,
    String? vin,
    String? vehicleNumber,
    int mileageKm = 0,
    String? color,
    String? notes,
  }) async {
    final vehicle = Vehicle(
      id: 'veh-${_vehicles.length + 1}',
      customerId: customerId,
      make: make,
      model: model,
      variant: variant,
      modelYear: modelYear,
      licensePlate: licensePlate,
      vin: vin,
      vehicleNumber: vehicleNumber,
      mileageKm: mileageKm,
      color: color,
      notes: notes,
    );
    _vehicles.add(vehicle);
    return vehicle;
  }

  @override
  Future<Vehicle> updateVehicle({
    required String id,
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
  }) async {
    final index = _vehicles.indexWhere((v) => v.id == id);
    if (index == -1) throw Exception('Vehicle not found');
    final old = _vehicles[index];
    final updated = old.copyWith(
      customerId: customerId,
      make: make,
      model: model,
      variant: variant,
      modelYear: modelYear,
      licensePlate: licensePlate,
      vin: vin,
      vehicleNumber: vehicleNumber,
      mileageKm: mileageKm,
      color: color,
      notes: notes,
    );
    _vehicles[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteVehicle(String id) async {
    _vehicles.removeWhere((v) => v.id == id);
  }
}

/// In-memory fake implementation of [SparePartRepository] for testing.
class FakeSparePartRepository implements SparePartRepository {
  FakeSparePartRepository([List<SparePart>? initialParts]) {
    _parts = initialParts != null
        ? List.from(initialParts)
        : [
            const SparePart(
              id: 'sp-1',
              sku: 'OIL-5W40-001',
              name: '5W-40 Full Synthetic Engine Oil',
              category: 'Fluids',
              brand: 'Castrol',
              stock: 60,
              minimumStock: 12,
              unit: 'liter',
              unitCost: 140000,
              sellingPrice: 185000,
            ),
            const SparePart(
              id: 'sp-2',
              sku: 'AIR-FLTR-001',
              name: 'High-Flow Air Filter',
              category: 'Filters',
              brand: 'MANN-FILTER',
              stock: 3,
              minimumStock: 4,
              unit: 'pcs',
              unitCost: 280000,
              sellingPrice: 395000,
            ),
          ];
  }

  late List<SparePart> _parts;

  @override
  Future<List<SparePart>> getSpareParts({
    String? searchQuery,
    String? categoryFilter,
    bool? lowStockOnly,
  }) async {
    return _parts.where((p) {
      final matchesSearch =
          searchQuery == null ||
          searchQuery.isEmpty ||
          p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory =
          categoryFilter == null ||
          categoryFilter.isEmpty ||
          categoryFilter.toLowerCase() == 'all' ||
          p.category.toLowerCase() == categoryFilter.toLowerCase();
      final matchesLowStock = lowStockOnly != true || p.isLowStock;
      return matchesSearch && matchesCategory && matchesLowStock;
    }).toList();
  }

  @override
  Future<SparePart> getSparePartById(String id) async {
    return _parts.firstWhere((p) => p.id == id);
  }

  @override
  Future<SparePart> createSparePart({
    required String sku,
    required String name,
    required String category,
    String? brand,
    String? description,
    String unit = 'pcs',
    required double unitCost,
    required double sellingPrice,
    int minimumStock = 0,
    bool isActive = true,
  }) async {
    final part = SparePart(
      id: 'sp-${_parts.length + 1}',
      sku: sku,
      name: name,
      category: category,
      brand: brand,
      description: description,
      unit: unit,
      unitCost: unitCost,
      sellingPrice: sellingPrice,
      minimumStock: minimumStock,
      isActive: isActive,
    );
    _parts.add(part);
    return part;
  }

  @override
  Future<SparePart> updateSparePart({
    required String id,
    String? sku,
    String? name,
    String? category,
    String? brand,
    String? description,
    String? unit,
    double? unitCost,
    double? sellingPrice,
    int? minimumStock,
    bool? isActive,
  }) async {
    final index = _parts.indexWhere((p) => p.id == id);
    if (index == -1) throw Exception('Spare part not found');
    final old = _parts[index];
    final updated = old.copyWith(
      sku: sku,
      name: name,
      category: category,
      brand: brand,
      description: description,
      unit: unit,
      unitCost: unitCost,
      sellingPrice: sellingPrice,
      minimumStock: minimumStock,
      isActive: isActive,
    );
    _parts[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteSparePart(String id) async {
    _parts.removeWhere((p) => p.id == id);
  }
}

/// In-memory fake implementation of [BookingRepository] for testing.
class FakeBookingRepository implements BookingRepository {
  FakeBookingRepository([List<Booking>? initialBookings]) {
    _bookings = initialBookings != null
        ? List.from(initialBookings)
        : [
            const Booking(
              id: 'bk-1',
              customerId: 'c1',
              vehicleId: 'v1',
              requestedService: 'Pre-Race Inspection & Telemetry Calibration',
              description: 'Competition pre-flight checks.',
              preferredDate: '2026-10-15',
              preferredTime: '09:00:00',
              status: BookingStatus.requested,
            ),
          ];
  }

  late List<Booking> _bookings;

  @override
  Future<List<Booking>> getBookings({
    String? searchQuery,
    String? statusFilter,
    String? customerId,
  }) async {
    return _bookings.where((b) {
      final matchesSearch =
          searchQuery == null ||
          searchQuery.isEmpty ||
          b.requestedService.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesStatus =
          statusFilter == null ||
          statusFilter.isEmpty ||
          statusFilter.toLowerCase() == 'all' ||
          b.status.value.toLowerCase() == statusFilter.toLowerCase();
      final matchesCustomer =
          customerId == null ||
          customerId.isEmpty ||
          b.customerId == customerId;
      return matchesSearch && matchesStatus && matchesCustomer;
    }).toList();
  }

  @override
  Future<Booking> getBookingById(String id) async {
    return _bookings.firstWhere((b) => b.id == id);
  }

  @override
  Future<Booking> createBooking({
    required String customerId,
    required String vehicleId,
    required String requestedService,
    String? description,
    String? preferredDate,
    String? preferredTime,
    String? adminNotes,
  }) async {
    final booking = Booking(
      id: 'bk-${_bookings.length + 1}',
      customerId: customerId,
      vehicleId: vehicleId,
      requestedService: requestedService,
      description: description,
      preferredDate: preferredDate,
      preferredTime: preferredTime,
      adminNotes: adminNotes,
      status: BookingStatus.requested,
    );
    _bookings.add(booking);
    return booking;
  }

  @override
  Future<Booking> updateBookingStatus({
    required String id,
    required BookingStatus status,
    String? adminNotes,
  }) async {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index == -1) throw Exception('Booking not found');
    final old = _bookings[index];
    final updated = old.copyWith(
      status: status,
      adminNotes: adminNotes ?? old.adminNotes,
    );
    _bookings[index] = updated;
    return updated;
  }

  @override
  Future<Booking> updateBooking({
    required String id,
    String? requestedService,
    String? description,
    String? preferredDate,
    String? preferredTime,
    BookingStatus? status,
    String? adminNotes,
  }) async {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index == -1) throw Exception('Booking not found');
    final old = _bookings[index];
    final updated = old.copyWith(
      requestedService: requestedService,
      description: description,
      preferredDate: preferredDate,
      preferredTime: preferredTime,
      status: status,
      adminNotes: adminNotes,
    );
    _bookings[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteBooking(String id) async {
    _bookings.removeWhere((b) => b.id == id);
  }
}

/// In-memory fake implementation of [ServiceOrderRepository] for testing.
class FakeServiceOrderRepository implements ServiceOrderRepository {
  FakeServiceOrderRepository([List<ServiceOrder>? initialOrders]) {
    _orders = initialOrders != null
        ? List.from(initialOrders)
        : [
            const ServiceOrder(
              id: 'so-1',
              orderNumber: 'SO-2026-001',
              customerId: 'c1',
              vehicleId: 'v1',
              title: 'Powertrain Diagnostics & Hybrid Battery Inspection',
              status: ServiceStatus.inProgress,
              estimatedTotal: 4500000,
            ),
          ];
  }

  late List<ServiceOrder> _orders;

  @override
  Future<List<ServiceOrder>> getServiceOrders({
    String? searchQuery,
    String? statusFilter,
    String? customerId,
    String? mechanicId,
  }) async {
    return _orders.where((o) {
      final matchesSearch =
          searchQuery == null ||
          searchQuery.isEmpty ||
          o.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          o.orderNumber.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesStatus =
          statusFilter == null ||
          statusFilter.isEmpty ||
          statusFilter.toLowerCase() == 'all' ||
          o.status.value.toLowerCase() ==
              statusFilter.toLowerCase().replaceAll(' ', '_');
      final matchesCustomer =
          customerId == null ||
          customerId.isEmpty ||
          o.customerId == customerId;
      final matchesMechanic =
          mechanicId == null ||
          mechanicId.isEmpty ||
          o.assignments.any((a) => a.mechanicId == mechanicId);
      return matchesSearch &&
          matchesStatus &&
          matchesCustomer &&
          matchesMechanic;
    }).toList();
  }

  @override
  Future<ServiceOrder> getServiceOrderById(String id) async {
    return _orders.firstWhere((o) => o.id == id);
  }

  @override
  Future<ServiceOrder> createServiceOrder({
    required String customerId,
    required String vehicleId,
    required String title,
    String? description,
    String? mechanicId,
    double estimatedTotal = 0.0,
    int? odometerKm,
  }) async {
    final order = ServiceOrder(
      id: 'so-${_orders.length + 1}',
      orderNumber: 'SO-2026-00${_orders.length + 1}',
      customerId: customerId,
      vehicleId: vehicleId,
      title: title,
      description: description,
      estimatedTotal: estimatedTotal,
      odometerKm: odometerKm,
      status: ServiceStatus.requested,
    );
    _orders.add(order);
    return order;
  }

  @override
  Future<ServiceOrder> updateServiceOrderStatus({
    required String id,
    required ServiceStatus status,
  }) async {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index == -1) throw Exception('Order not found');
    final old = _orders[index];
    final updated = old.copyWith(status: status);
    _orders[index] = updated;
    return updated;
  }

  @override
  Future<ServiceOrder> updateServiceOrder({
    required String id,
    String? title,
    String? description,
    ServiceStatus? status,
    double? estimatedTotal,
    double? finalTotal,
    int? odometerKm,
    String? mechanicId,
  }) async {
    final index = _orders.indexWhere((o) => o.id == id);
    if (index == -1) throw Exception('Order not found');
    final old = _orders[index];
    final updated = old.copyWith(
      title: title,
      description: description,
      status: status,
      estimatedTotal: estimatedTotal,
      finalTotal: finalTotal,
      odometerKm: odometerKm,
    );
    _orders[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteServiceOrder(String id) async {
    _orders.removeWhere((o) => o.id == id);
  }
}

class FakeReminderRepository implements ReminderRepository {
  FakeReminderRepository([List<ServiceReminder>? initial]) {
    _reminders = initial != null
        ? List.from(initial)
        : [
            ServiceReminder(
              id: 'rem-1',
              customerId: 'c1',
              vehicleId: 'v1',
              reminderType: 'maintenance',
              title: 'BMW M3 Touring Scheduled Maintenance',
              description: 'Review engine oil, brake system, tires and vehicle inspection items.',
              dueDate: DateTime.now().add(const Duration(days: 30)),
              dueMileageKm: 30000,
              status: 'pending',
              vehicle: Vehicle(
                id: 'v1',
                customerId: 'c1',
                make: 'BMW',
                model: 'M3 Touring',
                variant: 'Competition G81',
                licensePlate: 'D 1999 AZ',
                mileageKm: 28650,
              ),
            ),
            ServiceReminder(
              id: 'rem-2',
              customerId: 'c1',
              vehicleId: 'v2',
              reminderType: 'inspection',
              title: 'Toyota Innova Zenix Hybrid Check',
              description: 'Routine 20,000 KM hybrid drive battery cooling duct inspection and tire rotation.',
              dueDate: DateTime.now().add(const Duration(days: 60)),
              dueMileageKm: 20000,
              status: 'pending',
              vehicle: Vehicle(
                id: 'v2',
                customerId: 'c1',
                make: 'Toyota',
                model: 'Innova Zenix',
                variant: 'Hybrid',
                licensePlate: 'D 1234 ZEN',
                mileageKm: 17420,
              ),
            ),
          ];
  }

  late List<ServiceReminder> _reminders;

  @override
  Future<List<ServiceReminder>> getReminders({String? customerId}) async {
    if (customerId != null) {
      return _reminders.where((r) => r.customerId == customerId).toList();
    }
    return _reminders;
  }

  @override
  Future<ServiceReminder> createReminder(Map<String, dynamic> payload) async {
    final reminder = ServiceReminder.fromJson(payload);
    _reminders.add(reminder);
    return reminder;
  }

  @override
  Future<void> updateReminderStatus(String id, String status) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(status: status);
    }
  }
}

class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository([List<ServiceNotification>? initial]) {
    _notifications = initial != null
        ? List.from(initial)
        : [
            ServiceNotification(
              id: 'n1',
              recipientId: 'p-axel',
              type: 'booking',
              priority: 'normal',
              title: 'Booking Confirmed',
              message: 'Your appointment for BMW M3 Touring on Oct 15 at 13:00 WIB has been confirmed.',
              isRead: false,
              createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            ),
            ServiceNotification(
              id: 'n2',
              recipientId: 'p-axel',
              type: 'service',
              priority: 'high',
              title: 'Service Order Closed',
              message: 'Work order SO-2026-003 has been completed. Your invoice receipt is now available.',
              isRead: true,
              createdAt: DateTime.now().subtract(const Duration(days: 1)),
            ),
          ];
  }

  late List<ServiceNotification> _notifications;

  @override
  Future<List<ServiceNotification>> getNotifications({
    String? recipientId,
  }) async {
    if (recipientId != null) {
      return _notifications.where((n) => n.recipientId == recipientId).toList();
    }
    return _notifications;
  }

  @override
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead(String recipientId) async {
    _notifications = _notifications.map((n) {
      if (n.recipientId == recipientId) return n.copyWith(isRead: true);
      return n;
    }).toList();
  }
}

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository([List<ServiceTask>? initial]) {
    _tasks = initial != null
        ? List.from(initial)
        : [
            ServiceTask(
              id: 't1',
              serviceOrderId: 'so1',
              assignedMechanicId: 'm1',
              title: 'Engine Diagnostic Inspection',
              status: 'completed',
              estimatedMinutes: 60,
              actualMinutes: 55,
              description: 'Run diagnostic scan, inspect fault codes and verify engine operating parameters.',
            ),
            ServiceTask(
              id: 't2',
              serviceOrderId: 'so1',
              assignedMechanicId: 'm1',
              title: 'High Voltage System Inspection',
              status: 'in_progress',
              estimatedMinutes: 90,
              actualMinutes: 45,
              description: 'Inspect hybrid high-voltage system status and associated diagnostic telemetry.',
            ),
            ServiceTask(
              id: 't3',
              serviceOrderId: 'so1',
              assignedMechanicId: 'm1',
              title: 'Brake System Inspection',
              status: 'pending',
              estimatedMinutes: 45,
              description: 'Inspect brake discs, pads, calipers, lines and Motul racing fluid condition.',
            ),
          ];
  }

  late List<ServiceTask> _tasks;

  @override
  Future<List<ServiceTask>> getTasks({
    String? mechanicId,
    String? serviceOrderId,
  }) async {
    return _tasks.where((t) {
      if (mechanicId != null && t.assignedMechanicId != mechanicId) {
        return false;
      }
      if (serviceOrderId != null && t.serviceOrderId != serviceOrderId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> updateTaskStatus(String id, String status) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(status: status);
    }
  }
}
