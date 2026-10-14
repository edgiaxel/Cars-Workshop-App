/// Authoritative application roles defined in DB-SCHEMA.md and migration schema.
enum UserRole {
  admin,
  mechanic,
  customer;

  String toDbString() => name;

  static UserRole fromDbString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'mechanic':
        return UserRole.mechanic;
      case 'customer':
        return UserRole.customer;
      default:
        throw ArgumentError('Unknown UserRole value: $value');
    }
  }

  static UserRole? tryFromDbString(String? value) {
    if (value == null) return null;
    try {
      return fromDbString(value);
    } catch (_) {
      return null;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.mechanic:
        return 'Mechanic';
      case UserRole.customer:
        return 'Customer';
    }
  }
}
