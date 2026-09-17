class BookingModel {
  final String id;
  final String spaceId;
  final String renterId;
  final DateTime startDate;
  final DateTime endDate;
  final String rentalType;
  final int totalDays;
  final double? pricePerDay;
  final double? pricePerMonth;
  final double? serviceFee;
  final double? totalPrice;
  final String status;
  final DateTime? createdAt;

  BookingModel({
    required this.id,
    required this.spaceId,
    required this.renterId,
    required this.startDate,
    required this.endDate,
    required this.rentalType,
    required this.totalDays,
    this.pricePerDay,
    this.pricePerMonth,
    this.serviceFee,
    this.totalPrice,
    required this.status,
    this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      spaceId: json['space_id']?.toString() ?? '',
      renterId: json['renter_id']?.toString() ?? '',
      startDate: DateTime.parse(json['start_date'].toString()),
      endDate: DateTime.parse(json['end_date'].toString()),
      rentalType: json['rental_type']?.toString() ?? '',
      totalDays: (json['total_days'] as num?)?.toInt() ?? 0,
      pricePerDay: (json['price_per_day'] as num?)?.toDouble(),
      pricePerMonth: (json['price_per_month'] as num?)?.toDouble(),
      serviceFee: (json['service_fee'] as num?)?.toDouble(),
      totalPrice: (json['total_price'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'space_id': spaceId,
      'renter_id': renterId,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'rental_type': rentalType,
      'total_days': totalDays,
      'price_per_day': pricePerDay,
      'price_per_month': pricePerMonth,
      'service_fee': serviceFee,
      'total_price': totalPrice,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}