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

  int selectedTab = 0;
  String selectedCategory = 'All';
  bool loading = true;

  List<Map<String, dynamic>> spaces = [];
  List<Map<String, dynamic>> savedSpaces = [];
  List<Map<String, dynamic>> bookings = [];

  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() => loading = true);

    await Future.wait([
      loadSpaces(),
      loadSavedSpaces(),
      loadBookings(),
      loadProfile(),
    ]);

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> loadProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      final data = await supabase
          .from('profiles')
          .select('full_name, email, phone, role, created_at')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          profile = data;
        });
      }
    } catch (e) {
      debugPrint('Profile error: $e');
    }
  }

  Future<void> loadSpaces() async {
    try {
      final data = await supabase
          .from('spaces')
          .select('''
            id,
            owner_id,
            title,
            type,
            description,
            address,
            latitude,
            longitude,
            size,
            daily_price,
            monthly_price,
            availability,
            status,
            verified,
            created_at,
            space_images (
              image_url
            )
          ''')
          .eq('status', 'active')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          spaces = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Spaces error: $e');

      if (mounted) {
        setState(() {
          spaces = [];
        });
      }
    }
  }

  List<Map<String, dynamic>> get filteredSpaces {
    if (selectedCategory == 'All') {
      return spaces;
    }

    return spaces.where((space) {
      final type = (space['type'] ?? '').toString().toLowerCase();

      return type == selectedCategory.toLowerCase();
    }).toList();
  }

  Future<void> loadSavedSpaces() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => savedSpaces = []);
      }
      return;
    }

    try {
      final data = await supabase
          .from('saved_spaces')
          .select('''
            id,
            user_id,
            space_id,
            created_at,
            spaces (
              id,
              owner_id,
              title,
              type,
              description,
              address,
              latitude,
              longitude,
              size,
              daily_price,
              monthly_price,
              availability,
              status,
              verified,
              created_at,
              space_images (
                image_url
              )
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          savedSpaces = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Saved error: $e');

      if (mounted) {
        setState(() {
          savedSpaces = [];
        });
      }
    }
  }

  bool isSaved(String spaceId) {
    return savedSpaces.any(
      (item) => item['space_id']?.toString() == spaceId,
    );
  }

  Future<void> toggleSaved(String spaceId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage('Please log in first.');
      return;
    }

    try {
      if (isSaved(spaceId)) {
        await supabase
            .from('saved_spaces')
            .delete()
            .eq('user_id', user.id)
            .eq('space_id', spaceId);
      } else {
        await supabase.from('saved_spaces').insert({
          'user_id': user.id,
          'space_id': spaceId,
        });
      }

      await loadSavedSpaces();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Saved error: $e');
      showMessage('Could not update saved spaces.');
    }
  }

  Future<void> loadBookings() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => bookings = []);
      }
      return;
    }

    try {
      final data = await supabase
          .from('bookings')
          .select('''
            id,
            space_id,
            renter_id,
            start_date,
            end_date,
            rental_type,
            total_days,
            price_per_day,
            price_per_month,
            service_fee,
            total_price,
            status,
            spaces (
              title,
              type,
              address
            )
          ''')
          .eq('renter_id', user.id)
          .order('start_date', ascending: false);

      if (mounted) {
        setState(() {
          bookings = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Bookings error: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String spaceImage(Map<String, dynamic> space) {
    final images = space['space_images'];

    if (images is List && images.isNotEmpty) {
      final firstImage = images.first;

      if (firstImage is Map) {
        final url = firstImage['image_url'];

        if (url != null && url.toString().trim().isNotEmpty) {
          return url.toString();
        }
      }
    }

    return '';
  }

  String assetImageForType(String type) {
    switch (type.toLowerCase()) {
      case 'parking':
        return 'assets/images/parking.jpeg';
      case 'storage':
        return 'assets/images/storage.jpeg';
      case 'basement':
        return 'assets/images/basement.jpeg';
      default:
        return 'assets/images/other.jpeg';
    }
  }

  Widget buildSpaceCard(Map<String, dynamic> space) {
    final id = space['id']?.toString() ?? '';

    final title = space['title'] ?? 'Space';
    final address = space['address'] ?? 'Riyadh';
    final type = space['type'] ?? '';
    final daily = space['daily_price'] ?? 0;
    final monthly = space['monthly_price'] ?? 0;
    final verified = space['verified'] == true;

    final onlineImage = spaceImage(space);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingPaymentPage(
              space: space,
            ),
          ),
        ).then((_) {
          loadBookings();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: onlineImage.isNotEmpty
                      ? Image.network(
                          onlineImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Image.asset(
                              assetImageForType(type.toString()),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return imageErrorWidget();
                              },
                            );
                          },
                        )
                      : Image.asset(
                          assetImageForType(type.toString()),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return imageErrorWidget();
                          },
                        ),
                ),
                if (verified)
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: Color(0xff71675d),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: GestureDetector(
                    onTap: () => toggleSaved(id),
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved(id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: const Color(0xff806b59),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                15,
                18,
                18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 17,
                        color: Color(0xff81786e),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          address.toString(),
                          style: const TextStyle(
                            color: Color(0xff77716b),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xfff2eee8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(type.toString()),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$daily SAR/day',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$monthly SAR/month',
                            style: const TextStyle(
                              color: Color(0xff77716b),
                              fontSize: 13,
                            ),
                          ),
                        ],
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

  Widget imageErrorWidget() {
    return Container(
      color: const Color(0xffeee9e1),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 50,
          color: Color(0xff9b9389),
        ),
      ),
    );
  }

  Widget buildExplore() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            22,
            18,
            100,
          ),
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SpaceOra',
                      style: TextStyle(
                        fontSize: 34,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Find your perfect space',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.notifications_none,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search spaces or locations...',
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  categoryButton('All'),
                  categoryButton('Parking'),
                  categoryButton('Storage'),
                  categoryButton('Basement'),
                  categoryButton('Other'),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Text(
              selectedCategory == 'All'
                  ? 'Available Spaces'
                  : '$selectedCategory Spaces',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
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
              Padding(
                padding: const EdgeInsets.all(50),
                child: Column(
                  children: [
                    const Icon(
                      Icons.search_off,
                      size: 55,
                      color: Color(0xffaaa29a),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'No $selectedCategory spaces available',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...filteredSpaces.map(buildSpaceCard),
          ],
        ),
      ),
    );
  }

  Widget categoryButton(String category) {
    final selected = selectedCategory == category;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
          selectedTab = 0;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 19,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xff777069)
              : Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          category,
          style: TextStyle(
            color: selected
                ? Colors.white
                : const Color(0xff625b55),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget buildSaved() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: loadSavedSpaces,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            25,
            18,
            100,
          ),
          children: [
            const Text(
              'Saved',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            if (savedSpaces.isEmpty)
              const Padding(
                padding: EdgeInsets.all(60),
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 60,
                      color: Color(0xffaaa29a),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'No saved spaces yet',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...savedSpaces.map((item) {
                final space = item['spaces'];

                if (space == null) {
                  return const SizedBox();
                }

                return buildSpaceCard(
                  Map<String, dynamic>.from(space),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget buildBookings() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          25,
          18,
          100,
        ),
        children: [
          const Text(
            'Booking',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bookings.isEmpty
                ? 'Your upcoming and previous bookings'
                : '${bookings.length} booking${bookings.length == 1 ? '' : 's'}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 22),
          if (bookings.isEmpty)
            Container(
              padding: const EdgeInsets.all(45),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 60,
                    color: Color(0xffaaa29a),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'No bookings yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Your confirmed and upcoming bookings will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          else
            ...bookings.map(buildBookingCard),
        ],
      ),
    );
  }

  Widget buildBookingCard(
    Map<String, dynamic> booking,
  ) {
    final space = booking['spaces'];

    final title = space?['title'] ?? 'SpaceOra Space';
    final type = space?['type'] ?? 'Space';
    final address = space?['address'] ?? 'Riyadh';

    final start = booking['start_date']?.toString() ?? '-';
    final end = booking['end_date']?.toString() ?? '-';

    final rentalType =
        booking['rental_type']?.toString() ?? 'Daily';

    final totalDays = booking['total_days'] ?? 0;
    final pricePerDay = booking['price_per_day'] ?? 0;
    final pricePerMonth = booking['price_per_month'] ?? 0;
    final serviceFee = booking['service_fee'] ?? 0;
    final total = booking['total_price'] ?? 0;

    final status =
        booking['status']?.toString() ?? 'pending';

    final statusLower = status.toLowerCase();

    final bool confirmed = statusLower == 'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xff5f5146),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              18,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.home_work_outlined,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: Color(0xffe5ddd5),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address.toString(),
                              style: const TextStyle(
                                color: Color(0xffe5ddd5),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: confirmed
                        ? const Color(0xffe7eee5)
                        : const Color(0xffffead2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    confirmed ? 'Confirmed' : status,
                    style: TextStyle(
                      color: confirmed
                          ? const Color(0xff4f624e)
                          : const Color(0xff8a6540),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xfff8f5f0),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    bookingInfoChip(
                      Icons.category_outlined,
                      type.toString(),
                    ),
                    const SizedBox(width: 8),
                    bookingInfoChip(
                      rentalType.toLowerCase() == 'monthly'
                          ? Icons.calendar_month
                          : Icons.today_outlined,
                      rentalType.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Rental period',
                  style: TextStyle(
                    color: Color(0xff77716b),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: dateBox(
                        'Start',
                        start,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: Color(0xff8a7d71),
                      ),
                    ),
                    Expanded(
                      child: dateBox(
                        'End',
                        end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Column(
                    children: [
                      bookingPriceRow(
                        'Duration',
                        '$totalDays days',
                      ),
                      const SizedBox(height: 10),
                      bookingPriceRow(
                        rentalType.toLowerCase() == 'monthly'
                            ? 'Monthly price'
                            : 'Daily price',
                        rentalType.toLowerCase() == 'monthly'
                            ? '$pricePerMonth SAR'
                            : '$pricePerDay SAR',
                      ),
                      const SizedBox(height: 10),
                      bookingPriceRow(
                        'Service fee',
                        '$serviceFee SAR',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        child: Divider(
                          height: 1,
                        ),
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '$total SAR',
                            style: const TextStyle(
                              color: Color(0xff705d4d),
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      confirmed
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      size: 18,
                      color: const Color(0xff806b59),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        confirmed
                            ? 'Your booking is confirmed and saved.'
                            : 'Your booking is currently $status.',
                        style: const TextStyle(
                          color: Color(0xff6f675f),
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
    );
  }

  Widget bookingInfoChip(
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffeee9e2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: const Color(0xff75685d),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xff625950),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget dateBox(
    String label,
    String date,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff8a8178),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: const TextStyle(
              color: Color(0xff49413b),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget bookingPriceRow(
    String title,
    String value,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xff77716b),
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xff514941),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget buildAccount() {
    final user = supabase.auth.currentUser;

    final name =
        profile?['full_name'] ?? 'SpaceOra User';

    final email =
        profile?['email'] ?? user?.email ?? '';

    final phone =
        profile?['phone'] ?? '';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          25,
          18,
          100,
        ),
        children: [
          const Text(
            'My Profile',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 43,
                  backgroundColor: Color(0xffeee9e1),
                  child: Icon(
                    Icons.person_outline,
                    size: 45,
                    color: Color(0xff71675d),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Renter',
                  style: TextStyle(
                    color: Color(0xff77716b),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                profileRow(
                  Icons.person_outline,
                  'Full name',
                  name.toString(),
                ),
                const Divider(height: 25),
                profileRow(
                  Icons.email_outlined,
                  'Email',
                  email.toString(),
                ),
                const Divider(height: 25),
                profileRow(
                  Icons.phone_outlined,
                  'Phone',
                  phone.toString().isEmpty
                      ? 'Not added'
                      : phone.toString(),
                ),
                const Divider(height: 25),
                profileRow(
                  Icons.badge_outlined,
                  'Account type',
                  'Renter',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Activity',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    activityBox(
                      Icons.favorite_outline,
                      'Saved',
                      savedSpaces.length.toString(),
                    ),
                    const SizedBox(width: 12),
                    activityBox(
                      Icons.calendar_today_outlined,
                      'Bookings',
                      bookings.length.toString(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.notifications_none,
                  ),
                  title: const Text(
                    'Notifications',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.settings_outlined,
                  ),
                  title: const Text(
                    'Settings',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.help_outline,
                  ),
                  title: const Text(
                    'Help & Support',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            leading: const Icon(
              Icons.logout,
              color: Color(0xff806b59),
            ),
            title: const Text(
              'Log out',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              await supabase.auth.signOut();

              if (!mounted) return;

              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget profileRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: const Color(0xfff0ece6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xff71675d),
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
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget activityBox(
    IconData icon,
    String title,
    String number,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xfff6f3ee),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xff71675d),
            ),
            const SizedBox(height: 10),
            Text(
              number,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBody() {
    switch (selectedTab) {
      case 1:
        return buildSaved();
      case 2:
        return buildBookings();
      case 3:
        return buildAccount();
      default:
        return buildExplore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f3ee),
      body: buildBody(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            selectedTab = index;
          });

          if (index == 1) {
            loadSavedSpaces();
          }

          if (index == 2) {
            loadBookings();
          }

          if (index == 3) {
            loadProfile();
            loadBookings();
            loadSavedSpaces();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Booking',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}