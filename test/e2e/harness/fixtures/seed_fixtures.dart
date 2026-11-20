import '../models/e2e_user_profile.dart';
import '../models/e2e_customer.dart';
import '../models/e2e_vehicle.dart';

/// Predefined seed fixtures for deterministic E2E test scenarios.
class SeedFixtures {
  const SeedFixtures._();

  // Users
  static const UserProfile adminUser = UserProfile(
    id: 'adm-001',
    role: UserRole.admin,
    fullName: 'Admin Owner',
    email: 'admin@pitmate.com',
    phoneNumber: '0811000001',
  );

  static const UserProfile mechanicUser = UserProfile(
    id: 'mech-001',
    role: UserRole.mechanic,
    fullName: 'Lead Tech Doni',
    email: 'mechanic@pitmate.com',
    phoneNumber: '0811000002',
  );

  static const UserProfile customerUser = UserProfile(
    id: 'cust-profile-001',
    role: UserRole.customer,
    fullName: 'Budi Santoso',
    email: 'budi@example.com',
    phoneNumber: '08123456789',
  );

  // Customers
  static Customer get registeredCustomer => Customer(
        id: 'cust-001',
        profileId: 'cust-profile-001',
        customerType: CustomerType.individual,
        name: 'Budi Santoso',
        phone: '08123456789',
        email: 'budi@example.com',
        address: 'Jl. Sudirman No. 12',
        isGuest: false,
      );

  static Customer get guestCustomer => Customer(
        id: 'guest-001',
        profileId: null,
        customerType: CustomerType.individual,
        name: 'Walk-in Guest Joko',
        phone: '08987654321',
        email: null,
        address: null,
        isGuest: true,
      );

  // Vehicles
  static Vehicle get vehicle1 => Vehicle(
        id: 'veh-001',
        customerId: 'cust-001',
        licensePlate: 'B 1234 CD',
        vin: 'VIN1234567890ABCD',
        make: 'Toyota',
        model: 'Avanza',
        year: 2020,
        currentMileage: 35000,
        color: 'Silver',
        transmission: 'Manual',
      );

  static Vehicle get vehicle2 => Vehicle(
        id: 'veh-002',
        customerId: 'cust-001',
        licensePlate: 'D 5678 EF',
        vin: 'VIN0987654321WXYZ',
        make: 'Honda',
        model: 'Civic RS',
        year: 2022,
        currentMileage: 12000,
        color: 'Rallye Red',
        transmission: 'CVT',
      );

  static Vehicle get guestVehicle => Vehicle(
        id: 'veh-003',
        customerId: 'guest-001',
        licensePlate: 'B 9999 ZZ',
        vin: 'VIN5555666677GUEST',
        make: 'Suzuki',
        model: 'Ertiga',
        year: 2019,
        currentMileage: 52000,
        color: 'Pearl White',
        transmission: 'Automatic',
      );
}
