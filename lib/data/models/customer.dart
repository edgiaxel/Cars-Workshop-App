import 'user_profile.dart';

/// Customer entity mapping to public.customers table.
class Customer {
  const Customer({
    required this.id,
    required this.profileId,
    required this.customerType,
    this.companyName,
    this.address,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.profile,
  });

  final String id;
  final String profileId;
  final String customerType; // 'individual' or 'company'
  final String? companyName;
  final String? address;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final UserProfile? profile;

  bool get isCompany => customerType == 'company';

  String get displayName =>
      (isCompany && companyName != null && companyName!.isNotEmpty)
      ? companyName!
      : (profile?.fullName ?? 'Unnamed Customer');

  factory Customer.fromJson(Map<String, dynamic> json) {
    UserProfile? prof;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      prof = UserProfile.fromJson(json['profiles'] as Map<String, dynamic>);
    }

    return Customer(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      customerType: json['customer_type'] as String? ?? 'individual',
      companyName: json['company_name'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
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
      'customer_type': customerType,
      if (companyName != null) 'company_name': companyName,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
    };
  }

  Customer copyWith({
    String? id,
    String? profileId,
    String? customerType,
    String? companyName,
    String? address,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserProfile? profile,
  }) {
    return Customer(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      customerType: customerType ?? this.customerType,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profile: profile ?? this.profile,
    );
  }
}
