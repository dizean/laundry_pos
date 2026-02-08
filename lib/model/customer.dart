class Customer {
  final String id;
  final String fullName;
  final String? phone;

  Customer({
    required this.id,
    required this.fullName,
    this.phone,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      fullName: map['full_name'],
      phone: map['phone'],
    );
  }
}
