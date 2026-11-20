/// Primary user roles within the PitMate workshop operating system.
/// Values align with the PostgreSQL `user_role` database enum.
enum UserRole {
  admin('admin'),
  mechanic('mechanic'),
  customer('customer');

  const UserRole(this.value);

  /// Database string representation.
  final String value;

  /// Returns user-friendly capitalized display label.
  String get label {
    return switch (this) {
      UserRole.admin => 'Admin',
      UserRole.mechanic => 'Mechanic',
      UserRole.customer => 'Customer',
    };
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isMechanic => this == UserRole.mechanic;
  bool get isCustomer => this == UserRole.customer;

  /// Parses a string into [UserRole] (case-insensitive).
  /// Defaults to [UserRole.customer] for invalid, missing, or unrecognized values.
  static UserRole fromString(String? val) {
    if (val == null || val.trim().isEmpty) {
      return UserRole.customer;
    }

    final normalized = val.trim().toLowerCase();
    for (final role in UserRole.values) {
      if (role.value == normalized || role.name == normalized) {
        return role;
      }
    }
    return UserRole.customer;
  }

  /// Serializes role to JSON string value.
  String toJson() => value;

  /// Deserializes role from JSON.
  static UserRole fromJson(dynamic json) => fromString(json?.toString());
}
