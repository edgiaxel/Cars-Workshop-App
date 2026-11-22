import 'user_role.dart';

/// User profile domain model for PitMate.
class UserProfile {
  final String id;
  final UserRole role;
  final String fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.role,
    required this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    this.isEmailVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory deserializer supporting database snake_case and Dart camelCase keys.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      role: json['role'] is UserRole
          ? json['role'] as UserRole
          : UserRole.fromString(json['role'] as String?),
      fullName: (json['full_name'] ?? json['fullName']) as String? ?? '',
      phoneNumber: (json['phone'] ??
              json['phone_number'] ??
              json['phoneNumber']) as String?,
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
      isEmailVerified:
          (json['is_email_verified'] ?? json['isEmailVerified'] ?? false)
              as bool,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : null),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : (json['updatedAt'] is DateTime
              ? json['updatedAt'] as DateTime
              : null),
    );
  }

  /// Serializer to JSON Map matching standard database schema.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'full_name': fullName,
      if (phoneNumber != null) 'phone': phoneNumber,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'is_email_verified': isEmailVerified,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    UserRole? role,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          role == other.role &&
          fullName == other.fullName &&
          phoneNumber == other.phoneNumber &&
          avatarUrl == other.avatarUrl &&
          isEmailVerified == other.isEmailVerified &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        role,
        fullName,
        phoneNumber,
        avatarUrl,
        isEmailVerified,
        createdAt,
        updatedAt,
      );

  @override
  String toString() {
    return 'UserProfile(id: $id, role: ${role.name}, fullName: $fullName, '
        'phoneNumber: $phoneNumber, avatarUrl: $avatarUrl, '
        'isEmailVerified: $isEmailVerified)';
  }
}
