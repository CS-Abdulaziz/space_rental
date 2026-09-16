class BookingModel {
  final String id;
  final String spaceId;
  final String renterId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String rentalType;
  final int? totalDays;
  final double? pricePerDay;
  final double? pricePerMonth;
  final double? serviceFee;
  final double? totalPrice;
  final String status;

  BookingModel({
    required this.id,
    required this.spaceId,
    required this.renterId,
    this.startDate,
    this.endDate,
    required this.rentalType,
    this.totalDays,
    this.pricePerDay,
    this.pricePerMonth,
    this.serviceFee,
    this.totalPrice,
    required this.status,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id']?.toString() ?? '',
      spaceId: map['space_id']?.toString() ?? '',
      renterId: map['renter_id']?.toString() ?? '',
      startDate: map['start_date'] == null
          ? null
          : DateTime.tryParse(map['start_date'].toString()),
      endDate: map['end_date'] == null
          ? null
          : DateTime.tryParse(map['end_date'].toString()),
      rentalType: map['rental_type']?.toString() ?? '',
      totalDays: map['total_days'] == null
          ? null
          : int.tryParse(map['total_days'].toString()),
      pricePerDay: map['price_per_day'] == null
          ? null
          : double.tryParse(map['price_per_day'].toString()),
      pricePerMonth: map['price_per_month'] == null
          ? null
          : double.tryParse(map['price_per_month'].toString()),
      serviceFee: map['service_fee'] == null
          ? null
          : double.tryParse(map['service_fee'].toString()),
      totalPrice: map['total_price'] == null
          ? null
          : double.tryParse(map['total_price'].toString()),
      status: map['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'space_id': spaceId,
      'renter_id': renterId,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'rental_type': rentalType,
      'total_days': totalDays,
      'price_per_day': pricePerDay,
      'price_per_month': pricePerMonth,
      'service_fee': serviceFee,
      'total_price': totalPrice,
      'status': status,
    };
  }
}