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

  factory SpaceModel.fromMap(Map<String, dynamic> map) {
    return SpaceModel(
      id: map['id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      latitude: map['latitude'] == null
          ? null
          : double.tryParse(map['latitude'].toString()),
      longitude: map['longitude'] == null
          ? null
          : double.tryParse(map['longitude'].toString()),
      size: map['size'] == null
          ? null
          : double.tryParse(map['size'].toString()),
      dailyPrice: map['daily_price'] == null
          ? null
          : double.tryParse(map['daily_price'].toString()),
      monthlyPrice: map['monthly_price'] == null
          ? null
          : double.tryParse(map['monthly_price'].toString()),
      availability: map['availability']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      verified: map['verified'] == true,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
      imageUrls: map['image_urls'] is List
          ? List<String>.from(
              (map['image_urls'] as List).map(
                (image) => image.toString(),
              ),
            )
          : [],
    );
  }

  Map<String, dynamic> toMap() {
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