import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/data/models/user_role.dart';

void main() {
  group('UserRole enum tests', () {
    test('fromDbString correctly parses valid roles', () {
      expect(UserRole.fromDbString('admin'), UserRole.admin);
      expect(UserRole.fromDbString('ADMIN'), UserRole.admin);
      expect(UserRole.fromDbString('mechanic'), UserRole.mechanic);
      expect(UserRole.fromDbString('MECHANIC'), UserRole.mechanic);
      expect(UserRole.fromDbString('customer'), UserRole.customer);
      expect(UserRole.fromDbString('CUSTOMER'), UserRole.customer);
    });

    test('tryFromDbString safely handles null and invalid values', () {
      expect(UserRole.tryFromDbString(null), isNull);
      expect(UserRole.tryFromDbString('unknown_role'), isNull);
      expect(UserRole.tryFromDbString('mechanic'), UserRole.mechanic);
    });

    test('displayName returns appropriate text', () {
      expect(UserRole.admin.displayName, 'Admin');
      expect(UserRole.mechanic.displayName, 'Mechanic');
      expect(UserRole.customer.displayName, 'Customer');
    });

    test('toDbString returns enum name', () {
      expect(UserRole.admin.toDbString(), 'admin');
      expect(UserRole.mechanic.toDbString(), 'mechanic');
      expect(UserRole.customer.toDbString(), 'customer');
    });
  });
}
