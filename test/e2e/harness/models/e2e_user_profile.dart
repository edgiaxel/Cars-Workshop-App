/// User role definitions matching PROJECT.md interface contract.
enum UserRole {
  admin,
  mechanic,
  customer;

  String get value => name;

  static UserRole fromString(String value) {
    return switch (value.toLowerCase()) {
      'admin' => UserRole.admin,
      'mechanic' => UserRole.mechanic,
      _ => UserRole.customer,
    };
  }
}

/// User profile domain model for E2E tests.
class UserProfile {
  final String id;
  final UserRole role;
  final String fullName;
  final String? phoneNumber;
  final String? email;

  const UserProfile({
    required this.id,
    required this.role,
    required this.fullName,
    this.phoneNumber,
    this.email,
  });

  UserProfile copyWith({
    String? id,
    UserRole? role,
    String? fullName,
    String? phoneNumber,
    String? email,
  }) {
    return UserProfile(
      id: id ?? this.id,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          role == other.role &&
          fullName == other.fullName;

  @override
  int get hashCode => id.hashCode ^ role.hashCode ^ fullName.hashCode;
}
