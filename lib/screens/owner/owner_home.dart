import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'my_spaces.dart';
import '../auth/login_page.dart';
import 'verification.dart';
import 'add_space.dart';
class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({super.key});

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  int selectedIndex = 0;
  bool isLoading = true;

  String ownerName = 'Owner';
  String ownerEmail = '';
  String ownerPhone = '';

  List<Map<String, dynamic>> spaces = [];
  List<Map<String, dynamic>> bookings = [];

  double earnings = 0;

  RealtimeChannel? bookingsChannel;

  late AnimationController animationController;

  final Color cream = const Color(0xFFF7F2EA);
  final Color softCream = const Color(0xFFFFFBF5);
  final Color brown = const Color(0xFF765548);
  final Color darkBrown = const Color(0xFF3E2C25);
  final Color lightBrown = const Color(0xFFC9AA91);
  final Color beige = const Color(0xFFE8D8C8);
  final Color gold = const Color(0xFFB99362);

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    loadOwnerData();
    listenToBookings();
  }

  Future<void> loadOwnerData({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        ownerName =
            profile['full_name']?.toString() ?? 'Owner';

        ownerEmail =
            profile['email']?.toString() ??
                user.email ??
                '';

        ownerPhone =
            profile['phone']?.toString() ?? '';
      }

      final spacesResult = await supabase
          .from('spaces')
          .select('*, space_images(image_url)')
          .eq('owner_id', user.id)
          .order(
            'created_at',
            ascending: false,
          );

      spaces =
          List<Map<String, dynamic>>.from(
        spacesResult,
      );

      bookings = [];

      if (spaces.isNotEmpty) {
        final spaceIds = spaces
            .map(
              (space) => space['id'].toString(),
            )
            .toList();

        final bookingsResult = await supabase
            .from('bookings')
            .select(
              '*, spaces(title, address, type)',
            )
            .inFilter(
              'space_id',
              spaceIds,
            )
            .order(
              'start_date',
              ascending: true,
            );

        bookings =
            List<Map<String, dynamic>>.from(
          bookingsResult,
        );

        for (final booking in bookings) {
          final renterId =
              booking['renter_id'];

          if (renterId != null) {
            final renter = await supabase
                .from('profiles')
                .select('full_name,email')
                .eq(
                  'id',
                  renterId,
                )
                .maybeSingle();

            booking['renter_profile'] =
                renter;
          }
        }
      }

      earnings = 0;

      for (final booking in bookings) {
        final status = booking['status']
            ?.toString()
            .toLowerCase();

        if (status == 'confirmed' ||
            status == 'completed') {
          earnings +=
              double.tryParse(
                    booking['total_price']
                            ?.toString() ??
                        '0',
                  ) ??
                  0;
        }
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'OWNER HOME ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  void listenToBookings() {
    bookingsChannel = supabase
        .channel(
          'owner-bookings-live-${DateTime.now().millisecondsSinceEpoch}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (payload) {
            debugPrint(
              'BOOKING CHANGE: ${payload.eventType}',
            );

            if (!mounted) return;

            loadOwnerData(
              showLoading: false,
            );

            if (payload.eventType ==
                PostgresChangeEvent.insert) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  behavior:
                      SnackBarBehavior.floating,
                  backgroundColor:
                      darkBrown,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  content: const Row(
                    children: [
                      Icon(
                        Icons
                            .notifications_active_rounded,
                        color: Colors.white,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'New booking received ✨',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    animationController.dispose();

    if (bookingsChannel != null) {
      supabase.removeChannel(
        bookingsChannel!,
      );
    }

    super.dispose();
  }

  int get pendingBookings {
    return bookings
        .where(
          (booking) =>
              booking['status']
                  ?.toString()
                  .toLowerCase() ==
              'pending',
        )
        .length;
  }

  int get confirmedBookings {
    return bookings
        .where(
          (booking) =>
              booking['status']
                  ?.toString()
                  .toLowerCase() ==
              'confirmed',
        )
        .length;
  }

  int get verifiedSpaces {
    return spaces
        .where(
          (space) =>
              space['verified'] == true,
        )
        .length;
  }

  String formatPrice(dynamic value) {
    final number =
        double.tryParse(
              value?.toString() ?? '0',
            ) ??
            0;

    if (number % 1 == 0) {
      return '${number.toInt()} SAR';
    }

    return '${number.toStringAsFixed(0)} SAR';
  }

  String formatDate(dynamic value) {
    if (value == null) return '-';

    try {
      final date =
          DateTime.parse(
        value.toString(),
      );

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String fallbackImage(String? type) {
    switch (type?.toLowerCase()) {
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

  String spaceTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'parking':
        return '🚗';

      case 'storage':
        return '📦';

      case 'basement':
        return '🏠';

      default:
        return '✨';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homePage(),
     const MySpacesPage(),
      _bookingsPage(),
      _profilePage(),
    ];

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: isLoading
            ? _loadingScreen()
            : AnimatedSwitcher(
                duration:
                    const Duration(
                  milliseconds: 350,
                ),
                child:
                    pages[selectedIndex],
              ),
      ),
      bottomNavigationBar:
          _bottomNavigation(),
    );
  }

  Widget _loadingScreen() {
    return Container(
      color: cream,
      child: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration:
                  BoxDecoration(
                color: darkBrown,
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        brown.withOpacity(.25),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.home_work_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SpaceOra',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 25,
                fontWeight:
                    FontWeight.bold,
                color: darkBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preparing your space...',
              style: TextStyle(
                color:
                    brown.withOpacity(.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homePage() {
    return RefreshIndicator(
      color: darkBrown,
      onRefresh: () =>
          loadOwnerData(
        showLoading: false,
      ),
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          35,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _topHeader(),
            const SizedBox(height: 18),
            _heroCard(),
            const SizedBox(height: 22),
            _sectionTitle(
              'Overview',
              'Your SpaceOra at a glance',
            ),
            const SizedBox(height: 14),
            _statsGrid(),
            const SizedBox(height: 28),
            _sectionTitle(
              'Your Spaces',
              '${spaces.length} listed spaces',
            ),
            const SizedBox(height: 14),
            _horizontalSpaces(),
            const SizedBox(height: 28),
            _sectionTitle(
              'Booking Activity',
              bookings.isEmpty
                  ? 'No activity yet'
                  : '$confirmedBookings confirmed',
            ),
            const SizedBox(height: 14),
            _bookingPreview(),
          ],
        ),
      ),
    );
  }

  Widget _topHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Good day,',
                style: TextStyle(
                  color:
                      brown.withOpacity(.65),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                ownerName,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontStyle:
                      FontStyle.italic,
                  fontSize: 27,
                  fontWeight:
                      FontWeight.bold,
                  color: darkBrown,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              selectedIndex = 3;
            });
          },
          child: Container(
            height: 48,
            width: 48,
            decoration:
                BoxDecoration(
              color: softCream,
              shape: BoxShape.circle,
              border: Border.all(
                color: beige,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      brown.withOpacity(.08),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: darkBrown,
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroCard() {
    return AnimatedBuilder(
      animation:
          animationController,
      builder: (context, child) {
        final glow =
            8 +
                (animationController
                        .value *
                    8);

        return Container(
          width: double.infinity,
          height: 300,
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              32,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    brown.withOpacity(.20),
                blurRadius:
                    glow + 15,
                offset:
                    const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(
              32,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/owner_background.jpeg',
                  fit: BoxFit.cover,
                ),

                Container(
                  decoration:
                      BoxDecoration(
                    gradient:
                        LinearGradient(
                      begin:
                          Alignment.topLeft,
                      end: Alignment
                          .bottomRight,
                      colors: [
                        Colors.black
                            .withOpacity(.28),
                        const Color(
                          0xff3B2921,
                        ).withOpacity(.55),
                        const Color(
                          0xff241914,
                        ).withOpacity(.72),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  right: -35,
                  top: -45,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration:
                        BoxDecoration(
                      shape:
                          BoxShape.circle,
                      color: Colors.white
                          .withOpacity(.10),
                    ),
                  ),
                ),

                Positioned(
                  left: -45,
                  bottom: -60,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration:
                        BoxDecoration(
                      shape:
                          BoxShape.circle,
                      color: gold
                          .withOpacity(.13),
                    ),
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.white
                              .withOpacity(.15),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            30,
                          ),
                          border: Border.all(
                            color: Colors
                                .white
                                .withOpacity(
                              .18,
                            ),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 7,
                              height: 7,
                              child:
                                  DecoratedBox(
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Color(
                                    0xffC8E6C9,
                                  ),
                                  shape:
                                      BoxShape
                                          .circle,
                                ),
                              ),
                            ),
                            SizedBox(width: 7),
                            Text(
                              'LIVE',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 10,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                letterSpacing:
                                    1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      const Text(
                        'Your spaces are\nworking for you.',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily:
                              'Georgia',
                          fontStyle:
                              FontStyle.italic,
                          fontSize: 28,
                          fontWeight:
                              FontWeight.bold,
                          height: 1.15,
                        ),
                      ),

                      const SizedBox(
                        height: 9,
                      ),

                      Text(
                        'Manage your spaces, '
                        'bookings and earnings '
                        'all in one place.',
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(
                            .82,
                          ),
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),

                      const SizedBox(
                        height: 17,
                      ),

                      Row(
                        children: [
                          _heroMiniStat(
                            '${spaces.length}',
                            'Spaces',
                          ),
                          const SizedBox(
                            width: 9,
                          ),
                          _heroMiniStat(
                            '$pendingBookings',
                            'Pending',
                          ),
                          const SizedBox(
                            width: 9,
                          ),
                          _heroMiniStat(
                            formatPrice(
                              earnings,
                            ),
                            'Earned',
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
      },
    );
  }

  Widget _heroMiniStat(
    String value,
    String label,
  ) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 11,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white
              .withOpacity(.10),
          borderRadius:
              BorderRadius.circular(17),
          border: Border.all(
            color: Colors.white
                .withOpacity(.10),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: Colors.white
                    .withOpacity(.55),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: darkBrown,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color:
                      brown.withOpacity(.55),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (title == 'Your Spaces')
          GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = 1;
              });
            },
            child: Text(
              'View all',
              style: TextStyle(
                color: brown,
                fontWeight:
                    FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _statsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _statCard(
          Icons.home_work_outlined,
          'Listed Spaces',
          '${spaces.length}',
          'active listings',
          beige,
        ),
        _statCard(
          Icons.calendar_month_outlined,
          'Bookings',
          '${bookings.length}',
          '$confirmedBookings confirmed',
          const Color(0xFFE4D6CC),
        ),
        _statCard(
          Icons.hourglass_top_rounded,
          'Pending',
          '$pendingBookings',
          'needs attention',
          const Color(0xFFEBDCC9),
        ),
        _statCard(
          Icons.payments_outlined,
          'Earnings',
          formatPrice(earnings),
          'confirmed bookings',
          const Color(0xFFE0D4C7),
        ),
      ],
    );
  }

  Widget _statCard(
    IconData icon,
    String title,
    String value,
    String subtitle,
    Color iconBg,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: softCream,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color:
              beige.withOpacity(.75),
        ),
        boxShadow: [
          BoxShadow(
            color:
                brown.withOpacity(.055),
            blurRadius: 18,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 37,
                width: 37,
                decoration:
                    BoxDecoration(
                  color: iconBg,
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  icon,
                  color: darkBrown,
                  size: 20,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                size: 15,
                color:
                    brown.withOpacity(.35),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color: darkBrown,
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: brown,
              fontWeight:
                  FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _horizontalSpaces() {
    if (spaces.isEmpty) {
      return _emptyCard(
        Icons.home_work_outlined,
        'No spaces yet',
        'Add your first space to start earning.',
      );
    }

    return SizedBox(
      height: 235,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        itemCount:
            spaces.length > 5
                ? 5
                : spaces.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(width: 13),
        itemBuilder:
            (context, index) {
          return _spaceCard(
            spaces[index],
          );
        },
      ),
    );
  }

  Widget _spaceCard(
    Map<String, dynamic> space,
  ) {
    final title =
        space['title']?.toString() ??
            'Untitled Space';

    final type =
        space['type']?.toString() ??
            'Other';

    final verified =
        space['verified'] == true;

    final price =
        space['daily_price'];

    String imageUrl = '';

    final images =
        space['space_images'];

    if (images is List &&
        images.isNotEmpty) {
      imageUrl =
          images.first['image_url']
                  ?.toString() ??
              '';
    }

    return Container(
      width: 205,
      decoration:
          BoxDecoration(
        color: softCream,
        borderRadius:
            BorderRadius.circular(26),
        border: Border.all(
          color:
              beige.withOpacity(.7),
        ),
        boxShadow: [
          BoxShadow(
            color:
                brown.withOpacity(.06),
            blurRadius: 18,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(26),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 125,
                  width: double.infinity,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) {
                            return Image.asset(
                              fallbackImage(
                                type,
                              ),
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          fallbackImage(
                            type,
                          ),
                          fit: BoxFit.cover,
                        ),
                ),

                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white
                          .withOpacity(.88),
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),
                    child: Text(
                      '${spaceTypeIcon(type)} $type',
                      style:
                          TextStyle(
                        color: darkBrown,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                if (verified)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      height: 29,
                      width: 29,
                      decoration:
                          BoxDecoration(
                        color: darkBrown,
                        shape:
                            BoxShape.circle,
                      ),
                      child:
                          const Icon(
                        Icons
                            .verified_rounded,
                        color:
                            Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding:
                  const EdgeInsets.all(
                13,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        TextStyle(
                      color: darkBrown,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(
                    height: 7,
                  ),
                  Row(
                    children: [
                      Text(
                        formatPrice(
                          price,
                        ),
                        style:
                            TextStyle(
                          color: brown,
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        ' / day',
                        style:
                            TextStyle(
                          color: brown
                              .withOpacity(
                            .5,
                          ),
                          fontSize: 10,
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
  // BOOKING PREVIEW
  // =========================================================

  Widget _bookingPreview() {
    if (bookings.isEmpty) {
      return _emptyCard(
        Icons.calendar_month_outlined,
        'No bookings yet',
        'New renter bookings will appear here automatically.',
      );
    }

    final recent = bookings.length > 3
        ? bookings.take(3).toList()
        : bookings;

    return Column(
      children: recent.map(
        (booking) {
          return Padding(
            padding: const EdgeInsets.only(
              bottom: 11,
            ),
            child: _bookingCard(booking),
          );
        },
      ).toList(),
    );
  }

  // =========================================================
  // BOOKING CARD
  // =========================================================

  Widget _bookingCard(
    Map<String, dynamic> booking,
  ) {
    final space = booking['spaces'];
    final renter = booking['renter_profile'];

    final title =
        space?['title']?.toString() ?? 'Space';

    final renterName =
        renter?['full_name']?.toString() ?? 'Renter';

    final status =
        booking['status']?.toString() ?? 'pending';

    final total = booking['total_price'];

    final isConfirmed = status == 'confirmed';
    final isPending = status == 'pending';

    final statusColor = isConfirmed
        ? const Color(0xFF65735B)
        : isPending
            ? const Color(0xFFA47C4B)
            : const Color(0xFF8C6255);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: softCream,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: beige.withOpacity(.8),
        ),
        boxShadow: [
          BoxShadow(
            color: brown.withOpacity(.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: beige.withOpacity(.65),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              Icons.event_available_rounded,
              color: darkBrown,
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
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: darkBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  renterName,
                  style: TextStyle(
                    color: brown.withOpacity(.65),
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${formatDate(booking['start_date'])}'
                  ' → '
                  '${formatDate(booking['end_date'])}',
                  style: TextStyle(
                    color: brown.withOpacity(.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                formatPrice(total),
                style: TextStyle(
                  color: darkBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 6),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: .6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SPACES PAGE
  // =========================================================

  Widget _spacesPage() {
    return RefreshIndicator(
      color: darkBrown,
      onRefresh: () => loadOwnerData(
        showLoading: false,
      ),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          35,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(
              'My Spaces',
              'Everything you currently have listed.',
              Icons.home_work_outlined,
            ),

            const SizedBox(height: 20),

            if (spaces.isEmpty)
              _emptyCard(
                Icons.add_home_work_outlined,
                'No spaces listed',
                'Your listed spaces will appear here.',
              )
            else
              ...spaces.map(
                (space) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 14,
                  ),
                  child: _largeSpaceCard(space),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LARGE SPACE CARD
  // =========================================================

  Widget _largeSpaceCard(
    Map<String, dynamic> space,
  ) {
    final title =
        space['title']?.toString() ?? 'Untitled';

    final type =
        space['type']?.toString() ?? 'Other';

    final address =
        space['address']?.toString() ?? '';

    final verified =
        space['verified'] == true;

    String imageUrl = '';

    final images = space['space_images'];

    if (images is List && images.isNotEmpty) {
      imageUrl =
          images.first['image_url']?.toString() ?? '';
    }

    return Container(
      height: 145,
      decoration: BoxDecoration(
        color: softCream,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: beige.withOpacity(.8),
        ),
        boxShadow: [
          BoxShadow(
            color: brown.withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(27),
              bottomLeft: Radius.circular(27),
            ),
            child: SizedBox(
              width: 125,
              height: double.infinity,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Image.asset(
                          fallbackImage(type),
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      fallbackImage(type),
                      fit: BoxFit.cover,
                    ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15),
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
                          style: TextStyle(
                            color: darkBrown,
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),

                      if (verified)
                        Icon(
                          Icons.verified_rounded,
                          color: brown,
                          size: 18,
                        ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  Text(
                    '$type  •  ${spaceTypeIcon(type)}',
                    style: TextStyle(
                      color: brown,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  if (address.isNotEmpty)
                    Text(
                      address,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: brown.withOpacity(.55),
                        fontSize: 10,
                      ),
                    ),

                  const Spacer(),

                  Row(
                    children: [
                      Text(
                        formatPrice(
                          space['daily_price'],
                        ),
                        style: TextStyle(
                          color: darkBrown,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),

                      Text(
                        ' / day',
                        style: TextStyle(
                          color: brown.withOpacity(.5),
                          fontSize: 10,
                        ),
                      ),

                      const Spacer(),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              beige.withOpacity(.55),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          space['status']?.toString() ??
                              'active',
                          style: TextStyle(
                            color: darkBrown,
                            fontSize: 9,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BOOKINGS PAGE
  // =========================================================

  Widget _bookingsPage() {
    return RefreshIndicator(
      color: darkBrown,
      onRefresh: () => loadOwnerData(
        showLoading: false,
      ),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          35,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(
              'Bookings',
              'Live activity from your spaces.',
              Icons.calendar_month_outlined,
            ),

            const SizedBox(height: 16),

            _liveBookingBanner(),

            const SizedBox(height: 18),

            if (bookings.isEmpty)
              _emptyCard(
                Icons.event_busy_outlined,
                'No bookings yet',
                'When a renter books your space, it will appear here automatically.',
              )
            else
              ...bookings.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 13,
                  ),
                  child: _fullBookingCard(booking),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LIVE BANNER
  // =========================================================

  Widget _liveBookingBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkBrown,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_tethering_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Live booking updates',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'New bookings appear automatically.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 9,
            width: 9,
            decoration: const BoxDecoration(
              color: Color(0xFFBDE7C2),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FULL BOOKING CARD
  // =========================================================

  Widget _fullBookingCard(
    Map<String, dynamic> booking,
  ) {
    final space = booking['spaces'];
    final renter = booking['renter_profile'];

    final title =
        space?['title']?.toString() ?? 'Space';

    final address =
        space?['address']?.toString() ?? '';

    final renterName =
        renter?['full_name']?.toString() ?? 'Renter';

    final renterEmail =
        renter?['email']?.toString() ?? '';

    final status =
        booking['status']?.toString() ?? 'pending';

    final statusColor =
        status == 'confirmed'
            ? const Color(0xFF65735B)
            : status == 'pending'
                ? const Color(0xFFA47C4B)
                : const Color(0xFF8C6255);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: softCream,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: beige.withOpacity(.8),
        ),
        boxShadow: [
          BoxShadow(
            color: brown.withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 47,
                width: 47,
                decoration: BoxDecoration(
                  color: beige.withOpacity(.65),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.home_work_outlined,
                  color: darkBrown,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: darkBrown,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        address,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              brown.withOpacity(.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      statusColor.withOpacity(.12),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          Divider(
            color: beige.withOpacity(.7),
            height: 1,
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: brown,
                size: 18,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      renterName,
                      style: TextStyle(
                        color: darkBrown,
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),

                    if (renterEmail.isNotEmpty)
                      Text(
                        renterEmail,
                        style: TextStyle(
                          color:
                              brown.withOpacity(.5),
                          fontSize: 9,
                        ),
                      ),
                  ],
                ),
              ),

              Text(
                formatPrice(
                  booking['total_price'],
                ),
                style: TextStyle(
                  color: darkBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              Expanded(
                child: _dateInfo(
                  Icons.login_rounded,
                  'Start',
                  formatDate(
                    booking['start_date'],
                  ),
                ),
              ),

              Expanded(
                child: _dateInfo(
                  Icons.logout_rounded,
                  'End',
                  formatDate(
                    booking['end_date'],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DATE INFO
  // =========================================================

  Widget _dateInfo(
    IconData icon,
    String title,
    String date,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: brown.withOpacity(.65),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: brown.withOpacity(.45),
                fontSize: 9,
              ),
            ),
            Text(
              date,
              style: TextStyle(
                color: darkBrown,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================
  // PROFILE PAGE
  // =========================================================

  Widget _profilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        35,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _pageHeader(
            'Profile',
            'Your owner account',
            Icons.person_outline_rounded,
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  darkBrown,
                  brown,
                ],
              ),
              borderRadius:
                  BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: brown.withOpacity(.18),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 66,
                  width: 66,
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withOpacity(.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          Colors.white.withOpacity(.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        ownerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Georgia',
                          fontStyle:
                              FontStyle.italic,
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        ownerEmail,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(.65),
                          fontSize: 11,
                        ),
                      ),

                      if (ownerPhone.isNotEmpty)
                        ...[
                          const SizedBox(height: 3),
                          Text(
                            ownerPhone,
                            style: TextStyle(
                              color: Colors.white
                                  .withOpacity(.55),
                              fontSize: 10,
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Owner Tools',
            style: TextStyle(
              color: darkBrown,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 12),

          _profileOption(
            Icons.home_work_outlined,
            'My Spaces',
            'Manage your listed spaces',
            () {
              setState(() {
                selectedIndex = 1;
              });
            },
          ),

          _profileOption(
            Icons.calendar_month_outlined,
            'Bookings',
            'View renter bookings',
            () {
              setState(() {
                selectedIndex = 2;
              });
            },
          ),

          _profileOption(
            Icons.verified_user_outlined,
            'Verification',
            'Verify your identity and space',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const VerificationPage(),
                ),
              );
            },
          ),

          _profileOption(
            Icons.payments_outlined,
            'Earnings',
            '${formatPrice(earnings)} earned so far',
            () {},
          ),

          _profileOption(
            Icons.settings_outlined,
            'Settings',
            'Account preferences',
            () {},
          ),

          const SizedBox(height: 15),

          GestureDetector(
            onTap: _logout,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 17,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF1E2DA),
                borderRadius:
                    BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFE2CFC5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(0xFFE7CFC3),
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFF80564A),
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 13),

                  const Expanded(
                    child: Text(
                      'Log Out',
                      style: TextStyle(
                        color: Color(0xFF80564A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    color: Color(0xFF80564A),
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PROFILE OPTION
  // =========================================================

  Widget _profileOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:
            const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: softCream,
          borderRadius:
              BorderRadius.circular(22),
          border: Border.all(
            color: beige.withOpacity(.8),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 43,
              width: 43,
              decoration: BoxDecoration(
                color: beige.withOpacity(.55),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: darkBrown,
                size: 20,
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
                      color: darkBrown,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color:
                          brown.withOpacity(.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color:
                  brown.withOpacity(.35),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PAGE HEADER
  // =========================================================

  Widget _pageHeader(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: darkBrown,
            borderRadius:
                BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: brown.withOpacity(.18),
                blurRadius: 15,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 23,
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
                  color: darkBrown,
                  fontFamily: 'Georgia',
                  fontStyle:
                      FontStyle.italic,
                  fontSize: 25,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: TextStyle(
                  color:
                      brown.withOpacity(.55),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        GestureDetector(
          onTap: () =>
              loadOwnerData(
            showLoading: false,
          ),
          child: Container(
            height: 42,
            width: 42,
            decoration:
                BoxDecoration(
              color: softCream,
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: beige,
              ),
            ),
            child: Icon(
              Icons.refresh_rounded,
              color: darkBrown,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // EMPTY CARD
  // =========================================================

  Widget _emptyCard(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 22,
      ),
      decoration: BoxDecoration(
        color: softCream,
        borderRadius:
            BorderRadius.circular(27),
        border: Border.all(
          color: beige.withOpacity(.8),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: beige.withOpacity(.55),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: brown,
              size: 26,
            ),
          ),

          const SizedBox(height: 13),

          Text(
            title,
            style: TextStyle(
              color: darkBrown,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: brown.withOpacity(.5),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BOTTOM NAVIGATION
  // =========================================================

  Widget _bottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: softCream,
        boxShadow: [
          BoxShadow(
            color: brown.withOpacity(.08),
            blurRadius: 25,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(
            14,
            9,
            14,
            9,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                0,
                Icons.dashboard_outlined,
                Icons.dashboard_rounded,
                'Home',
              ),
              _navItem(
                1,
                Icons.home_work_outlined,
                Icons.home_work_rounded,
                'Spaces',
              ),
              _navItem(
                2,
                Icons.calendar_month_outlined,
                Icons.calendar_month_rounded,
                'Bookings',
              ),
              _navItem(
                3,
                Icons.person_outline_rounded,
                Icons.person_rounded,
                'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // NAV ITEM
  // =========================================================

  Widget _navItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final active =
        selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 250),
        padding:
            EdgeInsets.symmetric(
          horizontal: active ? 15 : 11,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active
              ? beige.withOpacity(.65)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              active
                  ? activeIcon
                  : icon,
              color: active
                  ? darkBrown
                  : brown.withOpacity(.45),
              size: 21,
            ),

            if (active) ...[
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: darkBrown,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _logout() async {
    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }
}