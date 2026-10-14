class Customer {
  final int? id;
  final String name;
  final String? companyName;
  final String phone;
  final String city;
  final String? address;
  final double creditLimit;
  final double currentBalance; // Positive = Customer owes money (Udhaar)
  final int syncStatus;
  final String updatedAt;

  Customer({
    this.id,
    required this.name,
    this.companyName,
    required this.phone,
    this.city = 'Local Yard',
    this.address,
    this.creditLimit = 1000000.0,
    this.currentBalance = 0.0,
    this.syncStatus = 0,
    String? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'company_name': companyName,
      'phone': phone,
      'city': city,
      'address': address,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'sync_status': syncStatus,
      'updated_at': updatedAt,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'] ?? '',
      companyName: map['company_name'],
      phone: map['phone'] ?? '',
      city: map['city'] ?? 'Local Yard',
      address: map['address'],
      creditLimit: (map['credit_limit'] as num?)?.toDouble() ?? 1000000.0,
      currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0.0,
      syncStatus: map['sync_status'] ?? 0,
      updatedAt: map['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? companyName,
    String? phone,
    String? city,
    String? address,
    double? creditLimit,
    double? currentBalance,
    int? syncStatus,
    String? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      address: address ?? this.address,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }
}
