import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/login_page.dart';
import 'verification.dart';

class OwnerProfilePage extends StatefulWidget {
  const OwnerProfilePage({super.key});

  @override
  State<OwnerProfilePage> createState() => _OwnerProfilePageState();
}

class _OwnerProfilePageState extends State<OwnerProfilePage> {
  final supabase = Supabase.instance.client;

  static const cream = Color(0xffF7F2EA);
  static const softCream = Color(0xffEEE5DB);
  static const brown = Color(0xff765640);
  static const darkBrown = Color(0xff4B382A);
  static const mediumBrown = Color(0xff806F61);
  static const lightBrown = Color(0xffA98D78);
  static const white = Color(0xffFFFCF8);

  bool loading = true;
  bool loggingOut = false;

  String fullName = 'Owner';
  String email = '';
  String phone = '';

  int spacesCount = 0;
  int bookingsCount = 0;
  double earnings = 0;

  String verificationStatus = 'Not Submitted';

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
      return;
    }

    try {
      // PROFILE
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // SPACES
      final spaces = await supabase
          .from('spaces')
          .select('id')
          .eq('owner_id', user.id);

      // BOOKINGS
      double totalEarnings = 0;
      int totalBookings = 0;

      if (spaces.isNotEmpty) {
        final spaceIds = spaces
            .map((space) => space['id'].toString())
            .toList();

        final bookings = await supabase
            .from('bookings')
            .select('total_price, status')
            .inFilter('space_id', spaceIds);

        totalBookings = bookings.length;

        for (final booking in bookings) {
          final bookingStatus =
              booking['status']?.toString();

          if (bookingStatus == 'confirmed' ||
              bookingStatus == 'completed') {
            totalEarnings +=
                double.tryParse(
                      booking['total_price']
                              ?.toString() ??
                          '0',
                    ) ??
                    0;
          }
        }
      }

      // VERIFICATION
      final verificationResult = await supabase
          .from('verification')
          .select('status')
          .eq('owner_id', user.id)
          .order(
            'submitted_at',
            ascending: false,
          )
          .limit(1);

      String currentVerificationStatus =
          'Not Submitted';

      if (verificationResult.isNotEmpty) {
        currentVerificationStatus =
            verificationResult.first['status']
                    ?.toString() ??
                'Pending';
      }

      if (!mounted) return;

      setState(() {
        fullName =
            profile?['full_name']
                        ?.toString()
                        .trim()
                        .isNotEmpty ==
                    true
                ? profile!['full_name'].toString()
                : 'Owner';

        email =
            profile?['email']?.toString() ??
                user.email ??
                '';

        phone =
            profile?['phone']?.toString() ?? '';

        spacesCount = spaces.length;
        bookingsCount = totalBookings;
        earnings = totalEarnings;

        verificationStatus =
            currentVerificationStatus;

        loading = false;
      });
    } catch (e) {
      debugPrint(
        'OWNER PROFILE ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Color verificationColor() {
    switch (verificationStatus.toLowerCase()) {
      case 'approved':
        return brown;

      case 'pending':
        return const Color(0xff9A7655);

      case 'rejected':
        return const Color(0xff8A5547);

      default:
        return mediumBrown;
    }
  }

  IconData verificationIcon() {
    switch (verificationStatus.toLowerCase()) {
      case 'approved':
        return Icons.verified_rounded;

      case 'pending':
        return Icons.schedule_rounded;

      case 'rejected':
        return Icons.error_outline_rounded;

      default:
        return Icons.shield_outlined;
    }
  }

  Future<void> logout() async {
    if (loggingOut) return;

    setState(() {
      loggingOut = true;
    });

    try {
      await supabase.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logout error: $e',
          ),
          backgroundColor: brown,
        ),
      );
    }
  }

  Future<void> openVerification() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VerificationPage(),
      ),
    );

    if (!mounted) return;

    loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: brown,
                ),
              )
            : RefreshIndicator(
                color: brown,
                onRefresh: loadProfile,
                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    30,
                  ),
                  children: [
                    _header(),

                    const SizedBox(height: 22),

                    _profileHero(),

                    const SizedBox(height: 20),

                    _stats(),

                    const SizedBox(height: 25),

                    _sectionTitle('Account'),

                    const SizedBox(height: 10),

                    _verificationTile(),

                    _profileTile(
                      icon:
                          Icons.person_outline_rounded,
                      title:
                          'Personal Information',
                      subtitle:
                          'Name, email and phone',
                      onTap:
                          _showPersonalInfo,
                    ),

                    _profileTile(
                      icon:
                          Icons.settings_outlined,
                      title: 'Settings',
                      subtitle:
                          'App preferences',
                      onTap: _showSettings,
                    ),

                    const SizedBox(height: 22),

                    _sectionTitle('Owner'),

                    const SizedBox(height: 10),

                    _earningsCard(),

                    const SizedBox(height: 22),

                    _logoutButton(),

                    const SizedBox(height: 18),

                    const Center(
                      child: Text(
                        'SpaceOra • Owner Account',
                        style: TextStyle(
                          color: lightBrown,
                          fontSize: 11,
                        ),
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
                'My Profile',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: darkBrown,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your SpaceOra owner account',
                style: TextStyle(
                  fontSize: 13,
                  color: lightBrown,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: softCream,
            borderRadius:
                BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: brown,
          ),
        ),
      ],
    );
  }

  Widget _profileHero() {
    final firstLetter =
        fullName.isNotEmpty
            ? fullName[0].toUpperCase()
            : 'O';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: brown,
        borderRadius:
            BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xffE8D8C8),
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    Colors.white.withOpacity(.25),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: darkBrown,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  email,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),

                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    phone,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Icon(
            Icons.workspace_premium_outlined,
            color: Colors.white70,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _stats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            spacesCount.toString(),
            'Spaces',
            Icons.home_work_outlined,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _statCard(
            bookingsCount.toString(),
            'Bookings',
            Icons.calendar_month_outlined,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _statCard(
            earnings.toStringAsFixed(0),
            'SAR Earned',
            Icons.payments_outlined,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String value,
    String label,
    IconData icon,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 17,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xffE5D9CC),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: brown,
            size: 22,
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w700,
              color: darkBrown,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              color: lightBrown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: darkBrown,
      ),
    );
  }

  Widget _verificationTile() {
    return GestureDetector(
      onTap: openVerification,
      child: Container(
        margin:
            const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xffE5D9CC),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: softCream,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                verificationIcon(),
                color: verificationColor(),
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verification',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,
                      color: darkBrown,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    verificationStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          verificationColor(),
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: lightBrown,
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:
            const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xffE5D9CC),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: softCream,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: brown,
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
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w700,
                      color: darkBrown,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: lightBrown,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: lightBrown,
            ),
          ],
        ),
      ),
    );
  }

  Widget _earningsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: softCream,
        borderRadius:
            BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: brown,
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons
                  .account_balance_wallet_outlined,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total earnings',
                  style: TextStyle(
                    color: mediumBrown,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${earnings.toStringAsFixed(0)} SAR',
                  style: const TextStyle(
                    color: darkBrown,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.trending_up_rounded,
            color: brown,
            size: 27,
          ),
        ],
      ),
    );
  }

  void _showPersonalInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cream,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return Padding(
          padding:
              const EdgeInsets.fromLTRB(
            22,
            20,
            22,
            30,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                  color: darkBrown,
                ),
              ),

              const SizedBox(height: 20),

              _infoRow(
                Icons.person_outline,
                'Full Name',
                fullName,
              ),

              _infoRow(
                Icons.email_outlined,
                'Email',
                email,
              ),

              _infoRow(
                Icons.phone_outlined,
                'Phone',
                phone.isEmpty
                    ? 'Not added'
                    : phone,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(
            icon,
            color: brown,
            size: 21,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: lightBrown,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value.isEmpty
                      ? '-'
                      : value,
                  style: const TextStyle(
                    color: darkBrown,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cream,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return Padding(
          padding:
              const EdgeInsets.fromLTRB(
            22,
            20,
            22,
            30,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                  color: darkBrown,
                ),
              ),

              const SizedBox(height: 20),

              _settingsRow(
                Icons
                    .notifications_none_rounded,
                'Notifications',
              ),

              _settingsRow(
                Icons.language_outlined,
                'Language',
              ),

              _settingsRow(
                Icons.help_outline_rounded,
                'Help & Support',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _settingsRow(
    IconData icon,
    String title,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: brown,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: darkBrown,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 15,
        color: lightBrown,
      ),
      onTap: () {
        Navigator.pop(context);

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              '$title will be available soon.',
            ),
            backgroundColor: brown,
          ),
        );
      },
    );
  }

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed:
            loggingOut ? null : logout,
        icon: loggingOut
            ? const SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: brown,
                ),
              )
            : const Icon(
                Icons.logout_rounded,
              ),
        label: Text(
          loggingOut
              ? 'Logging out...'
              : 'Log Out',
        ),
        style:
            OutlinedButton.styleFrom(
          foregroundColor: brown,
          side: const BorderSide(
            color: Color(0xffCBB7A4),
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }
}