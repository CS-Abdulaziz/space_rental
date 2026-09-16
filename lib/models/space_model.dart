class SpaceModel {
  final String id;
  final String ownerId;
  final String title;
  final String type;
  final String description;
  final String address;
  final double? latitude;
  final double? longitude;
  final double? size;
  final double? dailyPrice;
  final double? monthlyPrice;
  final String availability;
  final String status;
  final bool verified;
  final DateTime? createdAt;
  final List<String> imageUrls;

  SpaceModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.type,
    required this.description,
    required this.address,
    this.latitude,
    this.longitude,
    this.size,
    this.dailyPrice,
    this.monthlyPrice,
    required this.availability,
    required this.status,
    required this.verified,
    this.createdAt,
    this.imageUrls = const [],
  });

  factory SpaceModel.fromJson(Map<String, dynamic> json) {
    final images = json['space_images'];

    return SpaceModel(
      id: json['id']?.toString() ?? '',
      ownerId: json['owner_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      size: (json['size'] as num?)?.toDouble(),
      dailyPrice: (json['daily_price'] as num?)?.toDouble(),
      monthlyPrice: (json['monthly_price'] as num?)?.toDouble(),
      availability: json['availability']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      verified: json['verified'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      imageUrls: images is List
          ? images
              .map((image) => image['image_url']?.toString() ?? '')
              .where((url) => url.isNotEmpty)
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'type': type,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'size': size,
      'daily_price': dailyPrice,
      'monthly_price': monthlyPrice,
      'availability': availability,
      'status': status,
      'verified': verified,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}