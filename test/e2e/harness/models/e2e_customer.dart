/// Customer type enum for individual vs corporate clients.
enum CustomerType {
  individual,
  corporate;

  String get value => name;

  static CustomerType fromString(String value) {
    return value.toLowerCase() == 'corporate'
        ? CustomerType.corporate
        : CustomerType.individual;
  }
}

/// Customer domain model matching PROJECT.md interface contract.
class Customer {
  final String id;
  final String? profileId;
  final CustomerType customerType;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final bool isGuest;
  final DateTime createdAt;

  Customer({
    required this.id,
    this.profileId,
    this.customerType = CustomerType.individual,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.isGuest = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Customer copyWith({
    String? id,
    String? profileId,
    CustomerType? customerType,
    String? name,
    String? phone,
    String? email,
    String? address,
    bool? isGuest,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      customerType: customerType ?? this.customerType,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phone == other.phone &&
          isGuest == other.isGuest;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ phone.hashCode;
}
