import 'user_role.dart';

/// User profile representation mapping to public.profiles table.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.role,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.isActive = true,
    this.themeMode = 'dark',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final UserRole role;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final String themeMode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: UserRole.fromDbString(json['role'] as String),
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      themeMode: json['theme_mode'] as String? ?? 'dark',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.toDbString(),
      'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'is_active': isActive,
      'theme_mode': themeMode,
    };
  }

  UserProfile copyWith({
    String? id,
    UserRole? role,
    String? fullName,
    String? phone,
    String? avatarUrl,
    bool? isActive,
    String? themeMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      themeMode: themeMode ?? this.themeMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
