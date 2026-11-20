import 'user_profile.dart';

/// Mechanic domain model mapping to public.mechanics table.
class Mechanic {
  const Mechanic({
    required this.id,
    required this.profileId,
    required this.employeeCode,
    this.specialization,
    this.hourlyRate = 0,
    this.compensationPercentage = 30,
    this.hireDate,
    this.createdAt,
    this.updatedAt,
    this.profile,
  });

  final String id;
  final String profileId;
  final String employeeCode;
  final String? specialization;
  final double hourlyRate;
  final double compensationPercentage;
  final DateTime? hireDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final UserProfile? profile;

  String get displayName => profile?.fullName ?? employeeCode;

  factory Mechanic.fromJson(Map<String, dynamic> json) {
    UserProfile? prof;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      prof = UserProfile.fromJson(json['profiles'] as Map<String, dynamic>);
    }

    return Mechanic(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      employeeCode: json['employee_code'] as String? ?? '',
      specialization: json['specialization'] as String?,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 0.0,
      compensationPercentage:
          (json['compensation_percentage'] as num?)?.toDouble() ?? 30.0,
      hireDate: json['hire_date'] != null
          ? DateTime.tryParse(json['hire_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      profile: prof,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'employee_code': employeeCode,
      if (specialization != null) 'specialization': specialization,
      'hourly_rate': hourlyRate,
      'compensation_percentage': compensationPercentage,
      if (hireDate != null)
        'hire_date':
            "${hireDate!.year.toString().padLeft(4, '0')}-${hireDate!.month.toString().padLeft(2, '0')}-${hireDate!.day.toString().padLeft(2, '0')}",
    };
  }

  Mechanic copyWith({
    String? id,
    String? profileId,
    String? employeeCode,
    String? specialization,
    double? hourlyRate,
    double? compensationPercentage,
    DateTime? hireDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserProfile? profile,
  }) {
    return Mechanic(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      employeeCode: employeeCode ?? this.employeeCode,
      specialization: specialization ?? this.specialization,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      compensationPercentage:
          compensationPercentage ?? this.compensationPercentage,
      hireDate: hireDate ?? this.hireDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profile: profile ?? this.profile,
    );
  }
}
