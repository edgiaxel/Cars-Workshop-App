import 'package:flutter_test/flutter_test.dart';
import 'package:pitmate/features/auth/domain/user_profile.dart';
import 'package:pitmate/features/auth/domain/user_role.dart';

void main() {
  group('UserRole enum tests', () {
    test('fromString parses known roles correctly', () {
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('ADMIN'), UserRole.admin);
      expect(UserRole.fromString('mechanic'), UserRole.mechanic);
      expect(UserRole.fromString('Mechanic '), UserRole.mechanic);
      expect(UserRole.fromString('customer'), UserRole.customer);
    });

    test('fromString defaults to customer on null or unknown input', () {
      expect(UserRole.fromString(null), UserRole.customer);
      expect(UserRole.fromString(''), UserRole.customer);
      expect(UserRole.fromString('superadmin'), UserRole.customer);
      expect(UserRole.fromString('unknown_role'), UserRole.customer);
    });

    test('role booleans and display names work as expected', () {
      expect(UserRole.admin.isAdmin, isTrue);
      expect(UserRole.admin.isMechanic, isFalse);
      expect(UserRole.admin.displayName, 'Admin');

      expect(UserRole.mechanic.isMechanic, isTrue);
      expect(UserRole.mechanic.isAdmin, isFalse);
      expect(UserRole.mechanic.displayName, 'Mechanic');

      expect(UserRole.customer.isCustomer, isTrue);
      expect(UserRole.customer.displayName, 'Customer');
    });
  });

  group('UserProfile model tests', () {
    final now = DateTime(2026, 11, 22, 10, 0, 0);

    test('fromJson parses snake_case database schema correctly', () {
      final json = {
        'id': 'usr-001-uuid',
        'role': 'mechanic',
        'full_name': 'Eko Susanto',
        'phone': '+628123456789',
        'avatar_url': 'https://storage.pitmate.local/avatars/usr-001.jpg',
        'is_email_verified': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 'usr-001-uuid');
      expect(profile.role, UserRole.mechanic);
      expect(profile.fullName, 'Eko Susanto');
      expect(profile.phoneNumber, '+628123456789');
      expect(profile.avatarUrl, 'https://storage.pitmate.local/avatars/usr-001.jpg');
      expect(profile.isEmailVerified, isTrue);
      expect(profile.createdAt, now);
      expect(profile.updatedAt, now);
    });

    test('fromJson handles alternate camelCase and phone_number keys', () {
      final json = {
        'id': 'usr-002-uuid',
        'role': 'admin',
        'fullName': 'Siti Rahma',
        'phone_number': '+628987654321',
        'avatarUrl': null,
        'isEmailVerified': false,
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 'usr-002-uuid');
      expect(profile.role, UserRole.admin);
      expect(profile.fullName, 'Siti Rahma');
      expect(profile.phoneNumber, '+628987654321');
      expect(profile.avatarUrl, isNull);
      expect(profile.isEmailVerified, isFalse);
    });

    test('toJson serializes to valid database map', () {
      final profile = UserProfile(
        id: 'usr-003-uuid',
        role: UserRole.customer,
        fullName: 'Budi Hartono',
        phoneNumber: '+628111222333',
        avatarUrl: 'https://cdn.pitmate.local/budi.png',
        isEmailVerified: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = profile.toJson();

      expect(json['id'], 'usr-003-uuid');
      expect(json['role'], 'customer');
      expect(json['full_name'], 'Budi Hartono');
      expect(json['phone'], '+628111222333');
      expect(json['avatar_url'], 'https://cdn.pitmate.local/budi.png');
      expect(json['is_email_verified'], isTrue);
      expect(json['created_at'], now.toIso8601String());
      expect(json['updated_at'], now.toIso8601String());
    });

    test('copyWith updates specified attributes and preserves others', () {
      final original = UserProfile(
        id: 'usr-004-uuid',
        role: UserRole.customer,
        fullName: 'Original Name',
        isEmailVerified: false,
      );

      final updated = original.copyWith(
        fullName: 'Updated Name',
        isEmailVerified: true,
      );

      expect(updated.id, 'usr-004-uuid');
      expect(updated.role, UserRole.customer);
      expect(updated.fullName, 'Updated Name');
      expect(updated.isEmailVerified, isTrue);
    });

    test('equality and hashCode work as expected', () {
      final p1 = UserProfile(
        id: 'usr-005',
        role: UserRole.admin,
        fullName: 'Admin User',
      );
      final p2 = UserProfile(
        id: 'usr-005',
        role: UserRole.admin,
        fullName: 'Admin User',
      );
      final p3 = UserProfile(
        id: 'usr-006',
        role: UserRole.mechanic,
        fullName: 'Mechanic User',
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
    });
  });
}
