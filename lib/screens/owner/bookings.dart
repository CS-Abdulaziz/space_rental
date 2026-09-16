import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/space_model.dart';
import '../../models/booking_model.dart';

class OwnerBookingsPage extends StatefulWidget {
  const OwnerBookingsPage({super.key});

  @override
  State<OwnerBookingsPage> createState() => _OwnerBookingsPageState();
}

class _OwnerBookingsPageState extends State<OwnerBookingsPage> {
  final supabase = Supabase.instance.client;

  static const cream = Color(0xffF7F2EA);
  static const softCream = Color(0xffEFE7DC);
  static const brown = Color(0xff5A4030);
  static const darkBrown = Color(0xff39281E);
  static const mediumBrown = Color(0xff80624D);
  static const lightBrown = Color(0xffA98D78);
  static const white = Color(0xffFFFCF8);

  bool loading = true;

  List<BookingModel> bookings = [];
  List<SpaceModel> spaces = [];

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  Future<void> loadBookings() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      // =========================
      // LOAD OWNER SPACES
      // =========================

      final spacesResult = await supabase
          .from('spaces')
          .select('*, space_images(image_url)')
          .eq('owner_id', user.id);

      if (spacesResult.isEmpty) {
        if (!mounted) return;

        setState(() {
          spaces = [];
          bookings = [];
          loading = false;
        });

        return;
      }

      final Map<String, SpaceModel> uniqueSpaces = {};

      for (final item in spacesResult) {
        final json =
            Map<String, dynamic>.from(item);

        final space =
            SpaceModel.fromJson(json);

        uniqueSpaces[space.id] = space;
      }

      spaces = uniqueSpaces.values.toList();

      final spaceIds =
          spaces.map((space) => space.id).toList();

      // =========================
      // LOAD BOOKINGS
      // =========================

      final result = await supabase
          .from('bookings')
          .select('''
            *,
            spaces(
              title,
              address,
              type,
              daily_price,
              monthly_price
            )
          ''')
          .inFilter(
            'space_id',
            spaceIds,
          )
          .order(
            'start_date',
            ascending: true,
          );

      final Map<String, BookingModel>
          uniqueBookings = {};

      for (final item in result) {
        final json =
            Map<String, dynamic>.from(item);

        final booking =
            BookingModel.fromJson(json);

        uniqueBookings[booking.id] = booking;
      }

      bookings =
          uniqueBookings.values.toList();

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    } catch (e) {
      debugPrint(
        'OWNER BOOKINGS ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  SpaceModel? getSpaceForBooking(
    BookingModel booking,
  ) {
    try {
      return spaces.firstWhere(
        (space) =>
            space.id == booking.spaceId,
      );
    } catch (_) {
      return null;
    }
  }

  int get confirmedCount {
    return bookings.where(
      (booking) =>
          booking.status.toLowerCase() ==
          'confirmed',
    ).length;
  }

  int get pendingCount {
    return bookings.where(
      (booking) =>
          booking.status.toLowerCase() ==
          'pending',
    ).length;
  }

  double get earnings {
    double total = 0;

    for (final booking in bookings) {
      final status =
          booking.status.toLowerCase();

      if (status == 'confirmed' ||
          status == 'completed') {
        total += booking.totalPrice ?? 0;
      }
    }

    return total;
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';

    try {
      final date = value is DateTime
          ? value
          : DateTime.parse(
              value.toString(),
            );

      return '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: loading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color: brown,
                ),
              )
            : RefreshIndicator(
                color: brown,
                onRefresh: loadBookings,
                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    30,
                  ),
                  children: [
                    _header(),
                    const SizedBox(height: 23),
                    _summary(),
                    const SizedBox(height: 27),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text(
                          'All Bookings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.w700,
                            color: darkBrown,
                          ),
                        ),
                        Text(
                          '${bookings.length}',
                          style:
                              const TextStyle(
                            fontSize: 13,
                            color:
                                lightBrown,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (bookings.isEmpty)
                      _emptyState()
                    else
                      ...bookings.map(
                        (booking) =>
                            _bookingCard(
                          booking,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Bookings',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight:
                      FontWeight.w700,
                  color: darkBrown,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Manage your space reservations',
                style: TextStyle(
                  fontSize: 13,
                  color: lightBrown,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: loadBookings,
          child: Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color: softCream,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: brown,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summary() {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color: brown,
        borderRadius:
            BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.10),
            blurRadius: 20,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              confirmedCount.toString(),
              'Confirmed',
              Icons
                  .check_circle_outline_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color:
                Colors.white.withOpacity(.18),
          ),
          Expanded(
            child: _summaryItem(
              pendingCount.toString(),
              'Pending',
              Icons.schedule_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color:
                Colors.white.withOpacity(.18),
          ),
          Expanded(
            child: _summaryItem(
              earnings.toStringAsFixed(0),
              'SAR earned',
              Icons.payments_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    String value,
    String title,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          textAlign:
              TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _bookingCard(
    BookingModel booking,
  ) {
    final space =
        getSpaceForBooking(booking);

    final title = space != null &&
            space.title.isNotEmpty
        ? space.title
        : 'Space';

    final address =
        space?.address ?? '';

    final type =
        space?.type ?? '';

    final status =
        booking.status.isNotEmpty
            ? booking.status.toLowerCase()
            : 'pending';

    final total =
        booking.totalPrice ?? 0;

    final rentalType =
        booking.rentalType.isNotEmpty
            ? booking.rentalType
            : 'Daily';

    return Container(
      margin:
          const EdgeInsets.only(bottom: 16),
      padding:
          const EdgeInsets.all(17),
      decoration:
          BoxDecoration(
        color: white,
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color:
              const Color(0xffE5D9CC),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.035),
            blurRadius: 12,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w700,
                    color: darkBrown,
                  ),
                ),
              ),
              _status(status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons
                    .location_on_outlined,
                size: 14,
                color: lightBrown,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color: lightBrown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _pill(
                Icons.category_outlined,
                type,
              ),
              const SizedBox(width: 8),
              _pill(
                Icons
                    .calendar_today_outlined,
                rentalType,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _dateBox(
                  'START DATE',
                  formatDate(
                    booking.startDate,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _dateBox(
                  'END DATE',
                  formatDate(
                    booking.endDate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 12,
            ),
            decoration:
                BoxDecoration(
              color: cream,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons
                      .account_balance_wallet_outlined,
                  size: 18,
                  color: brown,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Booking total',
                    style: TextStyle(
                      fontSize: 11,
                      color: mediumBrown,
                    ),
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(0)} SAR',
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                    color: brown,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons
                    .check_circle_rounded,
                size: 15,
                color: mediumBrown,
              ),
              const SizedBox(width: 5),
              Text(
                status == 'confirmed'
                    ? 'Payment confirmed'
                    : status == 'pending'
                        ? 'Waiting for confirmation'
                        : status == 'completed'
                            ? 'Payment completed'
                            : 'Booking cancelled',
                style:
                    const TextStyle(
                  fontSize: 10,
                  color: mediumBrown,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _status(String status) {
    String text = status;

    if (status == 'confirmed') {
      text = 'CONFIRMED';
    } else if (status == 'pending') {
      text = 'PENDING';
    } else if (status == 'completed') {
      text = 'COMPLETED';
    } else if (status == 'cancelled') {
      text = 'CANCELLED';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color: status == 'confirmed' ||
                status == 'completed'
            ? const Color(0xffE8DED2)
            : const Color(0xffF1E6D8),
        borderRadius:
            BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style:
            const TextStyle(
          fontSize: 8,
          fontWeight:
              FontWeight.w700,
          color: brown,
        ),
      ),
    );
  }

  Widget _pill(
    IconData icon,
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color: softCream,
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: mediumBrown,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style:
                const TextStyle(
              fontSize: 9,
              fontWeight:
                  FontWeight.w600,
              color: mediumBrown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox(
    String label,
    String date,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(11),
      decoration:
          BoxDecoration(
        color: cream,
        borderRadius:
            BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                const TextStyle(
              fontSize: 8,
              color: lightBrown,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            date,
            style:
                const TextStyle(
              fontSize: 11,
              color: brown,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      margin:
          const EdgeInsets.only(top: 20),
      padding:
          const EdgeInsets.all(35),
      decoration:
          BoxDecoration(
        color: white,
        borderRadius:
            BorderRadius.circular(25),
        border: Border.all(
          color:
              const Color(0xffE5D9CC),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons
                .calendar_month_outlined,
            size: 48,
            color: lightBrown,
          ),
          SizedBox(height: 15),
          Text(
            'No bookings yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
              color: darkBrown,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'When renters book your spaces, '
            'their reservations will appear here.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: lightBrown,
            ),
          ),
        ],
      ),
    );
  }
}