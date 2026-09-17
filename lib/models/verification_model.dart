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

  factory VerificationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return VerificationModel(
      id: json['id']?.toString() ?? '',
      ownerId:
          json['owner_id']?.toString() ?? '',
      fullName:
          json['full_name']?.toString() ?? '',
      demoIdNumber:
          json['demo_id_number']?.toString() ?? '',
      ownershipType:
          json['ownership_type']?.toString() ?? '',
      ownershipReference:
          json['ownership_reference']?.toString() ?? '',
      status:
          json['status']?.toString() ?? '',
      submittedAt:
          json['submitted_at'] != null
              ? DateTime.tryParse(
                  json['submitted_at'].toString(),
                )
              : null,
      reviewedAt:
          json['reviewed_at'] != null
              ? DateTime.tryParse(
                  json['reviewed_at'].toString(),
                )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'full_name': fullName,
      'demo_id_number': demoIdNumber,
      'ownership_type': ownershipType,
      'ownership_reference':
          ownershipReference,
      'status': status,
      'submitted_at':
          submittedAt?.toIso8601String(),
      'reviewed_at':
          reviewedAt?.toIso8601String(),
    };
  }
}