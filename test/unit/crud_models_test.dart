import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/data/models/booking.dart';
import 'package:pitmate/data/models/customer.dart';
import 'package:pitmate/data/models/mechanic.dart';
import 'package:pitmate/data/models/service_order.dart';
import 'package:pitmate/data/models/spare_part.dart';
import 'package:pitmate/data/models/vehicle.dart';

void main() {
  group('Customer model tests', () {
    test('Individual customer fromJson and displayName', () {
      final json = {
        'id': 'cust-1',
        'profile_id': 'prof-1',
        'customer_type': 'individual',
        'address': 'Jl. Asia Afrika No. 10',
        'notes': 'VIP client',
        'profiles': {
          'id': 'prof-1',
          'full_name': 'Alexander Albon',
          'email': 'albon@williams.co',
          'phone_number': '08123456789',
          'role': 'customer',
        },
      };

      final customer = Customer.fromJson(json);

      expect(customer.id, 'cust-1');
      expect(customer.profileId, 'prof-1');
      expect(customer.isCompany, isFalse);
      expect(customer.displayName, 'Alexander Albon');
      expect(customer.profile?.fullName, 'Alexander Albon');

      final serialized = customer.toJson();
      expect(serialized['id'], 'cust-1');
      expect(serialized['customer_type'], 'individual');
      expect(serialized['address'], 'Jl. Asia Afrika No. 10');
    });

    test('Company customer uses company_name as displayName', () {
      final json = {
        'id': 'cust-corp',
        'profile_id': 'prof-2',
        'customer_type': 'company',
        'company_name': 'Scuderia Ferrari Logistics',
        'address': 'Maranello Workshop',
      };

      final customer = Customer.fromJson(json);

      expect(customer.isCompany, isTrue);
      expect(customer.displayName, 'Scuderia Ferrari Logistics');

      final updated = customer.copyWith(companyName: 'Ferrari Fleet Division');
      expect(updated.displayName, 'Ferrari Fleet Division');
      expect(updated.id, 'cust-corp');
    });
  });

  group('Mechanic model tests', () {
    test('Mechanic deserialization and displayName formatting', () {
      final json = {
        'id': 'mech-1',
        'profile_id': 'prof-m1',
        'employee_code': 'MEC-001',
        'specialization': 'Engine & Turbocharger Overhaul',
        'hourly_rate': 125000.0,
        'compensation_percentage': 35.0,
        'hire_date': '2024-03-01',
        'profiles': {
          'id': 'prof-m1',
          'full_name': 'Max Verstappen',
          'role': 'mechanic',
        },
      };

      final mechanic = Mechanic.fromJson(json);

      expect(mechanic.employeeCode, 'MEC-001');
      expect(mechanic.specialization, 'Engine & Turbocharger Overhaul');
      expect(mechanic.displayName, 'Max Verstappen');
      expect(mechanic.hourlyRate, 125000.0);
      expect(mechanic.compensationPercentage, 35.0);

      final serialized = mechanic.toJson();
      expect(serialized['employee_code'], 'MEC-001');
      expect(serialized['hire_date'], '2024-03-01');
    });

    test('Mechanic falls back to employeeCode if profile is absent', () {
      final json = {
        'id': 'mech-unknown',
        'profile_id': 'prof-none',
        'employee_code': 'TECH-999',
      };

      final mechanic = Mechanic.fromJson(json);
      expect(mechanic.displayName, 'TECH-999');
    });
  });

  group('Vehicle model tests', () {
    test('Vehicle displayName and identifierLabel resolution', () {
      final vehicle = Vehicle(
        id: 'veh-1',
        customerId: 'cust-1',
        make: 'Porsche',
        model: '911 GT3 RS',
        variant: 'Weissach Package',
        licensePlate: 'B 911 GTS',
        vin: 'WP0ZZZ99ZTS123456',
        mileageKm: 8500,
      );

      expect(vehicle.displayName, 'Porsche 911 GT3 RS Weissach Package');
      expect(vehicle.identifierLabel, 'B 911 GTS');

      final noPlateVehicle = Vehicle(
        id: 'veh-vin',
        customerId: 'cust-1',
        make: 'Porsche',
        model: '911 GT3 RS',
        vin: 'WP0ZZZ99ZTS123456',
      );
      expect(noPlateVehicle.identifierLabel, 'VIN: WP0ZZZ99ZTS123456');

      final minimalVehicle = Vehicle(
        id: 'veh-min',
        customerId: 'cust-1',
        make: 'Porsche',
        model: '911 GT3 RS',
      );
      expect(minimalVehicle.identifierLabel, 'NO-PLATE');
    });

    test('Vehicle JSON serialization roundtrip', () {
      final json = {
        'id': 'veh-2',
        'customer_id': 'cust-2',
        'make': 'Toyota',
        'model': 'GR Yaris',
        'model_year': 2024,
        'license_plate': 'D 1 GR',
        'mileage_km': 15000,
        'color': 'Platinum White Pearl',
      };

      final vehicle = Vehicle.fromJson(json);
      expect(vehicle.make, 'Toyota');
      expect(vehicle.model, 'GR Yaris');
      expect(vehicle.modelYear, 2024);

      final exported = vehicle.toJson();
      expect(exported['make'], 'Toyota');
      expect(exported['model_year'], 2024);
      expect(exported['license_plate'], 'D 1 GR');
    });
  });

  group('SparePart model tests', () {
    test('Calculates aggregated stock from inventory_transactions array', () {
      final json = {
        'id': 'part-oil',
        'sku': 'LUB-MOTUL-300V',
        'name': 'Motul 300V 5W-40',
        'category': 'fluids',
        'unit': 'liter',
        'unit_cost': 280000.0,
        'selling_price': 350000.0,
        'minimum_stock': 10,
        'inventory_transactions': [
          {'quantity': 30},
          {'quantity': -8},
          {'quantity': 4},
        ],
      };

      final part = SparePart.fromJson(json);

      expect(part.sku, 'LUB-MOTUL-300V');
      expect(part.stock, 26);
      expect(part.isLowStock, isFalse);

      final lowStockPart = part.copyWith(stock: 8);
      expect(lowStockPart.isLowStock, isTrue);
    });

    test('Falls back to stock field when transactions list is absent', () {
      final json = {
        'id': 'part-brake',
        'sku': 'BRK-ENDLESS-CCRG',
        'name': 'Endless CC-Rg Brake Pads',
        'category': 'brakes',
        'minimum_stock': 5,
        'stock': 2,
      };

      final part = SparePart.fromJson(json);
      expect(part.stock, 2);
      expect(part.isLowStock, isTrue);
    });
  });

  group('Booking model tests', () {
    test('Booking status parsing and enum helper', () {
      expect(BookingStatus.fromString('REQUESTED'), BookingStatus.requested);
      expect(BookingStatus.fromString('approved'), BookingStatus.approved);
      expect(BookingStatus.fromString('scheduled'), BookingStatus.scheduled);
      expect(
        BookingStatus.fromString('unknown_status'),
        BookingStatus.requested,
      );
    });

    test('Booking fromJson with nested customer and vehicle', () {
      final json = {
        'id': 'book-100',
        'customer_id': 'cust-1',
        'vehicle_id': 'veh-1',
        'requested_service': 'Major 40k Service & Alignment',
        'status': 'scheduled',
        'preferred_date': '2026-10-20',
        'preferred_time': '09:00',
        'customers': {
          'id': 'cust-1',
          'profile_id': 'prof-1',
          'customer_type': 'individual',
          'profiles': {
            'id': 'prof-1',
            'full_name': 'George Russell',
            'role': 'customer',
          },
        },
        'vehicles': {
          'id': 'veh-1',
          'customer_id': 'cust-1',
          'make': 'Mercedes-AMG',
          'model': 'GT Black Series',
          'license_plate': 'B 63 AMG',
        },
      };

      final booking = Booking.fromJson(json);

      expect(booking.id, 'book-100');
      expect(booking.status, BookingStatus.scheduled);
      expect(booking.customer?.displayName, 'George Russell');
      expect(booking.vehicle?.displayName, 'Mercedes-AMG GT Black Series');

      final serialized = booking.toJson();
      expect(serialized['requested_service'], 'Major 40k Service & Alignment');
      expect(serialized['status'], 'scheduled');
    });
  });

  group('ServiceOrder model tests', () {
    test('ServiceStatus enum parsing adheres to workshop state machine', () {
      expect(ServiceStatus.fromString('requested'), ServiceStatus.requested);
      expect(ServiceStatus.fromString('inspection'), ServiceStatus.inspection);
      expect(
        ServiceStatus.fromString('waiting_for_parts'),
        ServiceStatus.waitingForParts,
      );
      expect(ServiceStatus.fromString('in_progress'), ServiceStatus.inProgress);
      expect(ServiceStatus.fromString('completed'), ServiceStatus.completed);
      expect(ServiceStatus.fromString('closed'), ServiceStatus.closed);
    });

    test(
      'ServiceOrder fromJson with nested assignments and primary mechanic',
      () {
        final json = {
          'id': 'order-501',
          'order_number': 'PM-2026-0042',
          'customer_id': 'cust-1',
          'vehicle_id': 'veh-1',
          'title': 'Turbo Replacement & Intercooler Upgrade',
          'status': 'in_progress',
          'estimated_total': 18500000.0,
          'customer_approved': true,
          'service_assignments': [
            {
              'id': 'assign-1',
              'service_order_id': 'order-501',
              'mechanic_id': 'mech-1',
              'role_description': 'Lead Engine Specialist',
              'mechanics': {
                'id': 'mech-1',
                'profile_id': 'prof-m1',
                'employee_code': 'MEC-001',
                'profiles': {
                  'id': 'prof-m1',
                  'full_name': 'Adrian Newey',
                  'role': 'mechanic',
                },
              },
            },
          ],
        };

        final order = ServiceOrder.fromJson(json);

        expect(order.orderNumber, 'PM-2026-0042');
        expect(order.status, ServiceStatus.inProgress);
        expect(order.customerApproved, isTrue);
        expect(order.assignments.length, 1);
        expect(order.primaryMechanic?.displayName, 'Adrian Newey');
        expect(order.mechanicDisplayName, 'Adrian Newey');

        final unassigned = order.copyWith(assignments: []);
        expect(unassigned.mechanicDisplayName, 'Unassigned');
      },
    );
  });
}
