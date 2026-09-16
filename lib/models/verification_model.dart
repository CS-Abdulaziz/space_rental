class VerificationModel {
  final String id;
  final String ownerId;
  final String fullName;
  final String demoIdNumber;
  final String ownershipType;
  final String ownershipReference;
  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  VerificationModel({
    required this.id,
    required this.ownerId,
    required this.fullName,
    required this.demoIdNumber,
    required this.ownershipType,
    required this.ownershipReference,
    required this.status,
    this.submittedAt,
    this.reviewedAt,
  });

  factory VerificationModel.fromMap(Map<String, dynamic> map) {
    return VerificationModel(
      id: map['id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      demoIdNumber: map['demo_id_number']?.toString() ?? '',
      ownershipType: map['ownership_type']?.toString() ?? '',
      ownershipReference: map['ownership_reference']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      submittedAt: map['submitted_at'] == null
          ? null
          : DateTime.tryParse(map['submitted_at'].toString()),
      reviewedAt: map['reviewed_at'] == null
          ? null
          : DateTime.tryParse(map['reviewed_at'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'full_name': fullName,
      'demo_id_number': demoIdNumber,
      'ownership_type': ownershipType,
      'ownership_reference': ownershipReference,
      'status': status,
      'submitted_at': submittedAt?.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
    };
  }
}