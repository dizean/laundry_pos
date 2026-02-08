class Staff {
  final String id;
  final String email;
  final String role;
  final DateTime createdAt;

  Staff({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  /// Convert Supabase row → Staff object
  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['id'].toString(),
      email: map['email'],
      role: map['role'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Convert Staff object → Supabase insert/update map
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
    };
  }
}
