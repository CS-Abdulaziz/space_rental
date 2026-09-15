import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'booking_payment.dart';

class RenterHomePage extends StatefulWidget {
  const RenterHomePage({super.key});

  @override
  State<RenterHomePage> createState() => _RenterHomePageState();
}

class _RenterHomePageState extends State<RenterHomePage> {
  final supabase = Supabase.instance.client;

  int currentIndex = 0;
  String selectedCategory = 'All';

  bool loading = true;

  List<Map<String, dynamic>> spaces = [];
  List<Map<String, dynamic>> savedSpaces = [];
  List<Map<String, dynamic>> bookings = [];

  String userName = 'User';
  String userEmail = '';

  final categories = [
    {'name': 'All', 'icon': Icons.apps},
    {'name': 'Parking', 'icon': Icons.local_parking},
    {'name': 'Storage', 'icon': Icons.inventory_2_outlined},
    {'name': 'Basement', 'icon': Icons.home_work_outlined},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
    });

    try {
      final user = supabase.auth.currentUser;

      if (user != null) {
        userEmail = user.email ?? '';

        final profileResponse = await supabase
            .from('profiles')
            .select('full_name, email')
            .eq('id', user.id)
            .maybeSingle();

        if (profileResponse != null) {
          userName =
              (profileResponse['full_name'] ?? 'User').toString();

          if ((profileResponse['email'] ?? '')
              .toString()
              .isNotEmpty) {
            userEmail =
                profileResponse['email'].toString();
          }
        }
      }

      final spacesResponse = await supabase
          .from('spaces')
          .select('*, space_images(*)')
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final loadedSpaces =
          List<Map<String, dynamic>>.from(spacesResponse);

      if (user != null) {
        final savedResponse = await supabase
            .from('saved_spaces')
            .select('space_id')
            .eq('user_id', user.id);

        savedSpaces =
            List<Map<String, dynamic>>.from(savedResponse);

        final bookingResponse = await supabase
            .from('bookings')
            .select('*, spaces(*)')
            .eq('renter_id', user.id)
            .order('start_date', ascending: false);

        bookings =
            List<Map<String, dynamic>>.from(bookingResponse);
      }

      if (!mounted) return;

      setState(() {
        spaces = loadedSpaces;
        loading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  bool isSaved(String spaceId) {
    return savedSpaces.any(
      (item) => item['space_id'].toString() == spaceId,
    );
  }

  Future<void> toggleSaved(String spaceId) async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      if (isSaved(spaceId)) {
        await supabase
            .from('saved_spaces')
            .delete()
            .eq('user_id', user.id)
            .eq('space_id', spaceId);

        setState(() {
          savedSpaces.removeWhere(
            (item) =>
                item['space_id'].toString() == spaceId,
          );
        });
      } else {
        await supabase.from('saved_spaces').insert({
          'user_id': user.id,
          'space_id': spaceId,
        });

        setState(() {
          savedSpaces.add({
            'space_id': spaceId,
          });
        });
      }
    } catch (e) {
      debugPrint('Saved error: $e');
    }
  }

  List<Map<String, dynamic>> get filteredSpaces {
    if (selectedCategory == 'All') {
      return spaces;
    }

    return spaces.where((space) {
      final type = (space['type'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      return type == selectedCategory.toLowerCase();
    }).toList();
  }

  String getSpaceImage(Map<String, dynamic> space) {
    final images = space['space_images'];

    if (images is List && images.isNotEmpty) {
      for (final image in images) {
        final url = image['image_url'];

        if (url != null &&
            url.toString().trim().isNotEmpty) {
          return url.toString();
        }
      }
    }

    return '';
  }

  String getFallbackImage(Map<String, dynamic> space) {
    final title =
        (space['title'] ?? '').toString().toLowerCase();

    final type =
        (space['type'] ?? '').toString().toLowerCase();

    if (title.contains('parking') || type == 'parking') {
      return 'assets/images/parking.jpeg';
    }

    if (type == 'storage') {
      return 'assets/images/storage.jpeg';
    }

    if (type == 'basement') {
      return 'assets/images/basement.jpeg';
    }

    return 'assets/images/other.jpeg';
  }

  String getPrice(Map<String, dynamic> space) {
    final daily = space['daily_price'];

    if (daily != null) {
      return '${daily.toString()} SAR / day';
    }

    final monthly = space['monthly_price'];

    if (monthly != null) {
      return '${monthly.toString()} SAR / month';
    }

    return 'Price unavailable';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f3ed),
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: [
            buildExplore(),
            buildSaved(),
            buildBookings(),
            buildAccount(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xff76563d),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EXPLORE
  // =========================================================

  Widget buildExplore() {
    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          30,
        ),
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'SpaceOra',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Color(0xff5f4633),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Find your perfect space',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    const Color(0xffe8dfd4),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xff76563d),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  color: Color(0xff76563d),
                ),
                hintText: 'Search spaces...',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(
                  vertical: 15,
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final category =
                    categories[index];

                final name =
                    category['name'] as String;

                final icon =
                    category['icon'] as IconData;

                final selected =
                    selectedCategory == name;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = name;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 17,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xff76563d)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: selected
                              ? Colors.white
                              : const Color(
                                  0xff76563d,
                                ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          name,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(
                                    0xff76563d,
                                  ),
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Spaces',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff3f3329),
                ),
              ),
              Text(
                '${filteredSpaces.length} spaces',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (filteredSpaces.isEmpty)
            Container(
              padding: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 45,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No spaces found',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            ...filteredSpaces.map(
              (space) => buildSpaceCard(space),
            ),
        ],
      ),
    );
  }

  Widget buildSpaceCard(
      Map<String, dynamic> space) {
    final id = space['id'].toString();

    final imageUrl =
        getSpaceImage(space);

    final fallback =
        getFallbackImage(space);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                BookingPaymentPage(
              space: space,
            ),
          ),
        );
      },
      child: Container(
        margin:
            const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.05),
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 190,
                          width:
                              double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context,
                                  error,
                                  stackTrace) {
                            return Image.asset(
                              fallback,
                              height: 190,
                              width:
                                  double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          fallback,
                          height: 190,
                          width:
                              double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),

                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () =>
                        toggleSaved(id),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.95),
                        shape:
                            BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved(id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: isSaved(id)
                            ? Colors.redAccent
                            : const Color(
                                0xff76563d,
                              ),
                      ),
                    ),
                  ),
                ),

                if (space['verified'] == true)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.95),
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: 15,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    space['title'] ??
                        'Available Space',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xff3f3329),
                    ),
                  ),

                  const SizedBox(height: 7),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 17,
                        color:
                            Color(0xff76563d),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          space['address'] ??
                              'Riyadh',
                          style:
                              const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xfff0e9e0,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(10),
                        ),
                        child: Text(
                          space['type'] ??
                              'Other',
                          style:
                              const TextStyle(
                            color:
                                Color(0xff76563d),
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Text(
                        getPrice(space),
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Color(0xff76563d),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SAVED
  // =========================================================

  Widget buildSaved() {
    final saved = spaces.where((space) {
      return isSaved(
        space['id'].toString(),
      );
    }).toList();

    return ListView(
      padding:
          const EdgeInsets.all(20),
      children: [
        const Text(
          'Saved Spaces',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Color(0xff5f4633),
          ),
        ),

        const SizedBox(height: 20),

        if (saved.isEmpty)
          const Padding(
            padding:
                EdgeInsets.only(top: 100),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 55,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'No saved spaces yet',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...saved.map(
            (space) =>
                buildSpaceCard(space),
          ),
      ],
    );
  }

  // =========================================================
  // BOOKING
  // =========================================================

  Widget buildBookings() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        30,
      ),
      children: [
        const Text(
          'Booking',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 30,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Color(0xff5f4633),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          '${bookings.length} bookings',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 22),

        if (bookings.isEmpty)
          const Padding(
            padding:
                EdgeInsets.only(top: 100),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 50,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'No bookings yet',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...bookings.map(
            (booking) =>
                buildBookingCard(booking),
          ),
      ],
    );
  }

  Widget buildBookingCard(
      Map<String, dynamic> booking) {
    final space = booking['spaces'];

    final title = space is Map
        ? (space['title'] ?? 'Space').toString()
        : 'Space';

    final address = space is Map
        ? (space['address'] ?? 'Riyadh').toString()
        : 'Riyadh';

    final type = space is Map
        ? (space['type'] ?? 'Other').toString()
        : 'Other';

    final rentalType =
        (booking['rental_type'] ?? 'daily')
            .toString();

    final status =
        (booking['status'] ?? 'pending')
            .toString()
            .toLowerCase();

    final startDate =
        booking['start_date']?.toString() ?? '-';

    final endDate =
        booking['end_date']?.toString() ?? '-';

    final totalPrice =
        booking['total_price']?.toString() ?? '0';

    final totalDays =
        booking['total_days']?.toString() ?? '-';

    final pricePerDay =
        booking['price_per_day']?.toString() ?? '0';

    final pricePerMonth =
        booking['price_per_month']?.toString() ?? '0';

    final serviceFee =
        booking['service_fee']?.toString() ?? '0';

    Color statusColor;

    if (status == 'confirmed') {
      statusColor = Colors.green;
    } else if (status == 'completed') {
      statusColor =
          const Color(0xff6f8f72);
    } else if (status == 'cancelled') {
      statusColor = Colors.redAccent;
    } else {
      statusColor = Colors.orange;
    }

    final bool isMonthly =
        rentalType.toLowerCase() == 'monthly';

    return Container(
      margin:
          const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [

          // HEADER
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.fromLTRB(
              18,
              17,
              18,
              17,
            ),
            decoration:
                const BoxDecoration(
              color: Color(0xff76563d),
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.16),
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                  child: const Icon(
                    Icons.home_work_outlined,
                    color: Colors.white,
                    size: 27,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color:
                                Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // BODY
          Padding(
            padding:
                const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                // TYPE + RENTAL + STATUS
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xfff3eee8,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.category_outlined,
                            size: 15,
                            color:
                                Color(0xff76563d),
                          ),
                          const SizedBox(
                              width: 5),
                          Text(
                            type,
                            style:
                                const TextStyle(
                              fontSize: 12,
                              color: Color(
                                  0xff76563d),
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xfff3eee8,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons
                                .calendar_month_outlined,
                            size: 15,
                            color:
                                Color(0xff76563d),
                          ),
                          const SizedBox(
                              width: 5),
                          Text(
                            rentalType,
                            style:
                                const TextStyle(
                              fontSize: 12,
                              color: Color(
                                  0xff76563d),
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    Icon(
                      Icons.check_circle,
                      size: 17,
                      color: statusColor,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      status[0].toUpperCase() +
                          status.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  'Rental period',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                    color: Color(0xff5f4633),
                  ),
                ),

                const SizedBox(height: 10),

                // DATES
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding:
                            const EdgeInsets
                                .all(13),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xfffaf8f5,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(15),
                          border: Border.all(
                            color:
                                const Color(
                              0xffeee7df,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Text(
                              'Start',
                              style:
                                  TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.grey,
                              ),
                            ),
                            const SizedBox(
                                height: 5),
                            Text(
                              startDate,
                              style:
                                  const TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight
                                        .w600,
                                color: Color(
                                    0xff3f3329),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        horizontal: 9,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 19,
                        color:
                            Color(0xff76563d),
                      ),
                    ),

                    Expanded(
                      child: Container(
                        padding:
                            const EdgeInsets
                                .all(13),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xfffaf8f5,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(15),
                          border: Border.all(
                            color:
                                const Color(
                              0xffeee7df,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Text(
                              'End',
                              style:
                                  TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.grey,
                              ),
                            ),
                            const SizedBox(
                                height: 5),
                            Text(
                              endDate,
                              style:
                                  const TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight
                                        .w600,
                                color: Color(
                                    0xff3f3329),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // PRICE DETAILS
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(15),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(0xfffaf8f5),
                    borderRadius:
                        BorderRadius.circular(
                      17,
                    ),
                  ),
                  child: Column(
                    children: [
                      bookingInfoRow(
                        'Duration',
                        '$totalDays days',
                      ),

                      bookingInfoRow(
                        isMonthly
                            ? 'Monthly price'
                            : 'Daily price',
                        '${isMonthly ? pricePerMonth : pricePerDay} SAR',
                      ),

                      bookingInfoRow(
                        'Service fee',
                        '$serviceFee SAR',
                      ),

                      const Padding(
                        padding:
                            EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        child: Divider(
                          color:
                              Color(0xffddd4ca),
                        ),
                      ),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w600,
                              color: Color(
                                  0xff3f3329),
                            ),
                          ),
                          Text(
                            '$totalPrice SAR',
                            style:
                                const TextStyle(
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.bold,
                              color: Color(
                                  0xff76563d),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 13),

                // CONFIRMED MESSAGE
                if (status == 'confirmed')
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xffedf5eb,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color:
                              Color(0xff5f8b62),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your booking is confirmed and saved successfully.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(
                                  0xff527457),
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget bookingInfoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color: Color(0xff3f3329),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ACCOUNT
  // =========================================================

  Widget buildAccount() {
    return ListView(
      padding:
          const EdgeInsets.all(20),
      children: [
        const Text(
          'My Account',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Color(0xff5f4633),
          ),
        ),

        const SizedBox(height: 22),

        Container(
          padding:
              const EdgeInsets.all(20),
          decoration:
              BoxDecoration(
            color:
                const Color(0xff76563d),
            borderRadius:
                BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor:
                    Colors.white,
                child: Icon(
                  Icons.person,
                  size: 38,
                  color:
                      Color(0xff76563d),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      userEmail,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        accountTile(
          Icons.calendar_month_outlined,
          'My Bookings',
          '${bookings.length} bookings',
          () {
            setState(() {
              currentIndex = 2;
            });
          },
        ),

        accountTile(
          Icons.favorite_border,
          'Saved Spaces',
          '${savedSpaces.length} saved',
          () {
            setState(() {
              currentIndex = 1;
            });
          },
        ),

        accountTile(
          Icons.person_outline,
          'Profile Information',
          'Personal information',
          () {},
        ),

        accountTile(
          Icons.settings_outlined,
          'Settings',
          'App preferences',
          () {},
        ),

        const SizedBox(height: 8),

        accountTile(
          Icons.logout,
          'Log Out',
          'Sign out of your account',
          () async {
            await supabase.auth.signOut();

            if (!mounted) return;

            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  Widget accountTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 11,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 2,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration:
              BoxDecoration(
            color:
                const Color(0xfff0e9e0),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color:
                const Color(0xff76563d),
          ),
        ),
        title: Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
            color:
                Color(0xff3f3329),
          ),
        ),
        subtitle: Text(
          subtitle,
          style:
              const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        trailing:
            const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
      ),
    );
  }
}