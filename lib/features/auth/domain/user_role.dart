/// Represents the user's role in the PitMate workshop system.
enum UserRole {
  admin,
  mechanic,
  customer;

  /// Parses a string into a [UserRole], defaulting to [customer] if unrecognized.
  static UserRole fromString(String? role) {
    return switch (role?.toLowerCase().trim()) {
      'admin' => UserRole.admin,
      'mechanic' => UserRole.mechanic,
      'customer' => UserRole.customer,
      _ => UserRole.customer,
    };
  }

  /// Human-readable role label.
  String get displayName => switch (this) {
        UserRole.admin => 'Admin',
        UserRole.mechanic => 'Mechanic',
        UserRole.customer => 'Customer',
      };

  bool get isAdmin => this == UserRole.admin;
  bool get isMechanic => this == UserRole.mechanic;
  bool get isCustomer => this == UserRole.customer;
}
