class ProfileModel {
  final String id;
  final DateTime? createdAt;
  final String fullName;
  final String email;
  final String phone;
  final String role;

  ProfileModel({
    required this.id,
    this.createdAt,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt?.toIso8601String(),
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
    };
  }
}