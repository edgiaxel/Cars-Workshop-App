import 'user_role.dart';

/// User profile entity representing authenticated profile records in PitMate.
class UserProfile {
  final String id;
  final UserRole role;
  final String fullName;
  final String? phoneNumber;
  final String? email;
  final String? avatarUrl;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.role,
    required this.fullName,
    this.phoneNumber,
    this.email,
    this.avatarUrl,
    this.createdAt,
  });

  /// Factory constructor to deserialize [UserProfile] from JSON map.
  /// Tolerates both snake_case (database) and camelCase property keys.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val);
      }
      return null;
    }

    final id = json['id']?.toString() ?? '';
    final roleRaw = json['role'];
    final role = roleRaw is UserRole ? roleRaw : UserRole.fromString(roleRaw?.toString());
    final fullName = (json['full_name'] ?? json['fullName'])?.toString() ?? '';
    final phoneNumber = (json['phone_number'] ?? json['phoneNumber'])?.toString();
    final email = json['email']?.toString();
    final avatarUrl = (json['avatar_url'] ?? json['avatarUrl'])?.toString();
    final createdAt = parseDate(json['created_at'] ?? json['createdAt']);

    return UserProfile(
      id: id,
      role: role,
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
    );
  }

  /// Serializes [UserProfile] to database-compatible snake_case JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.value,
      'full_name': fullName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Creates a copy of [UserProfile] with optionally updated fields.
  UserProfile copyWith({
    String? id,
    UserRole? role,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.role == role &&
        other.fullName == fullName &&
        other.phoneNumber == phoneNumber &&
        other.email == email &&
        other.avatarUrl == avatarUrl &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      role,
      fullName,
      phoneNumber,
      email,
      avatarUrl,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, role: ${role.value}, fullName: $fullName, email: $email)';
  }
}
