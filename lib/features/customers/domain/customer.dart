/// Domain model for PitMate customers (registered and walk-in guest).
class Customer {
  final String id;
  final String? profileId;
  final String customerType;
  final String name;
  final String? email;
  final String phone;
  final String? address;
  final String? taxNumber;
  final bool isGuest;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    this.profileId,
    this.customerType = 'individual',
    required this.name,
    this.email,
    required this.phone,
    this.address,
    this.taxNumber,
    this.isGuest = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      profileId: json['profile_id'] as String?,
      customerType: json['customer_type'] as String? ?? 'individual',
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String,
      address: json['address'] as String?,
      taxNumber: json['tax_number'] as String?,
      isGuest: json['is_guest'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'customer_type': customerType,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'tax_number': taxNumber,
      'is_guest': isGuest,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? profileId,
    String? customerType,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? taxNumber,
    bool? isGuest,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      customerType: customerType ?? this.customerType,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      taxNumber: taxNumber ?? this.taxNumber,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
