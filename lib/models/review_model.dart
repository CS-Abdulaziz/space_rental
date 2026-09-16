class ReviewModel {
  final String id;
  final String bookingId;
  final String spaceId;
  final String renterId;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.spaceId,
    required this.renterId,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id']?.toString() ?? '',
      bookingId: map['booking_id']?.toString() ?? '',
      spaceId: map['space_id']?.toString() ?? '',
      renterId: map['renter_id']?.toString() ?? '',
      rating: int.tryParse(map['rating']?.toString() ?? '') ?? 0,
      comment: map['comment']?.toString() ?? '',
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'space_id': spaceId,
      'renter_id': renterId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}