import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/shared/models/user_profile.dart';
import 'package:pitmate/shared/models/user_role.dart';

void main() {
  group('UserRole Tests', () {
    test('enum values match database strings', () {
      expect(UserRole.admin.value, equals('admin'));
      expect(UserRole.mechanic.value, equals('mechanic'));
      expect(UserRole.customer.value, equals('customer'));
    });

    test('fromString parses valid roles case-insensitively', () {
      expect(UserRole.fromString('ADMIN'), equals(UserRole.admin));
      expect(UserRole.fromString('admin'), equals(UserRole.admin));
      expect(UserRole.fromString('Mechanic'), equals(UserRole.mechanic));
      expect(UserRole.fromString('customer'), equals(UserRole.customer));
      expect(UserRole.fromString('CuStOmEr'), equals(UserRole.customer));
    });

    test('fromString defaults to customer on null, empty, or unknown strings', () {
      expect(UserRole.fromString(null), equals(UserRole.customer));
      expect(UserRole.fromString(''), equals(UserRole.customer));
      expect(UserRole.fromString('   '), equals(UserRole.customer));
      expect(UserRole.fromString('superuser'), equals(UserRole.customer));
      expect(UserRole.fromString('unknown_role'), equals(UserRole.customer));
    });

    test('toJson and fromJson serialize and deserialize accurately', () {
      expect(UserRole.admin.toJson(), equals('admin'));
      expect(UserRole.fromJson('admin'), equals(UserRole.admin));
      expect(UserRole.fromJson('mechanic'), equals(UserRole.mechanic));
      expect(UserRole.fromJson('customer'), equals(UserRole.customer));
      expect(UserRole.fromJson(null), equals(UserRole.customer));
    });

    test('role helper getters work properly', () {
      expect(UserRole.admin.isAdmin, isTrue);
      expect(UserRole.admin.isMechanic, isFalse);
      expect(UserRole.admin.isCustomer, isFalse);
      expect(UserRole.admin.label, equals('Admin'));

      expect(UserRole.mechanic.isAdmin, isFalse);
      expect(UserRole.mechanic.isMechanic, isTrue);
      expect(UserRole.mechanic.isCustomer, isFalse);
      expect(UserRole.mechanic.label, equals('Mechanic'));

      expect(UserRole.customer.isAdmin, isFalse);
      expect(UserRole.customer.isMechanic, isFalse);
      expect(UserRole.customer.isCustomer, isTrue);
      expect(UserRole.customer.label, equals('Customer'));
    });
  });

  group('UserProfile Tests', () {
    final testDate = DateTime.utc(2026, 11, 20, 10, 0, 0);

    test('fromJson deserializes snake_case database records', () {
      final json = {
        'id': 'usr-123',
        'role': 'admin',
        'full_name': 'Chief Mechanic Alex',
        'phone_number': '+628123456789',
        'email': 'alex@pitmate.dev',
        'avatar_url': 'https://pitmate.dev/avatar.png',
        'created_at': testDate.toIso8601String(),
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, equals('usr-123'));
      expect(profile.role, equals(UserRole.admin));
      expect(profile.fullName, equals('Chief Mechanic Alex'));
      expect(profile.phoneNumber, equals('+628123456789'));
      expect(profile.email, equals('alex@pitmate.dev'));
      expect(profile.avatarUrl, equals('https://pitmate.dev/avatar.png'));
      expect(profile.createdAt, equals(testDate));
    });

    test('fromJson deserializes camelCase records with missing optional fields', () {
      final json = {
        'id': 'usr-456',
        'role': 'mechanic',
        'fullName': 'Mechanic Budi',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, equals('usr-456'));
      expect(profile.role, equals(UserRole.mechanic));
      expect(profile.fullName, equals('Mechanic Budi'));
      expect(profile.phoneNumber, isNull);
      expect(profile.email, isNull);
      expect(profile.avatarUrl, isNull);
      expect(profile.createdAt, isNull);
    });

    test('toJson serializes model to database schema format', () {
      final profile = UserProfile(
        id: 'usr-789',
        role: UserRole.customer,
        fullName: 'Jane Doe',
        phoneNumber: '+628987654321',
        email: 'jane@example.com',
        avatarUrl: 'https://avatar.com/jane.jpg',
        createdAt: testDate,
      );

      final json = profile.toJson();

      expect(json['id'], equals('usr-789'));
      expect(json['role'], equals('customer'));
      expect(json['full_name'], equals('Jane Doe'));
      expect(json['phone_number'], equals('+628987654321'));
      expect(json['email'], equals('jane@example.com'));
      expect(json['avatar_url'], equals('https://avatar.com/jane.jpg'));
      expect(json['created_at'], equals(testDate.toIso8601String()));
    });

    test('copyWith produces modified copy preserving other properties', () {
      final profile = UserProfile(
        id: 'usr-1',
        role: UserRole.customer,
        fullName: 'Original Name',
        email: 'test@test.com',
      );

      final updated = profile.copyWith(
        fullName: 'Updated Name',
        role: UserRole.admin,
      );

      expect(updated.id, equals('usr-1'));
      expect(updated.fullName, equals('Updated Name'));
      expect(updated.role, equals(UserRole.admin));
      expect(updated.email, equals('test@test.com'));
    });

    test('equality and hashCode compare field values correctly', () {
      final p1 = UserProfile(
        id: 'usr-1',
        role: UserRole.admin,
        fullName: 'Admin User',
        createdAt: testDate,
      );
      final p2 = UserProfile(
        id: 'usr-1',
        role: UserRole.admin,
        fullName: 'Admin User',
        createdAt: testDate,
      );
      final p3 = UserProfile(
        id: 'usr-2',
        role: UserRole.customer,
        fullName: 'Other User',
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1 == p3, isFalse);
    });

    test('toString returns human readable summary', () {
      final profile = UserProfile(
        id: 'usr-99',
        role: UserRole.mechanic,
        fullName: 'Toro Rosso',
        email: 'toro@pitmate.dev',
      );

      expect(profile.toString(), contains('usr-99'));
      expect(profile.toString(), contains('mechanic'));
      expect(profile.toString(), contains('Toro Rosso'));
    });
  });
}
