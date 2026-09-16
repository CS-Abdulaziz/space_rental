class ProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final DateTime? createdAt;

  ProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.createdAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}