import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingPaymentPage extends StatefulWidget {
  final Map<String, dynamic> space;

  const BookingPaymentPage({
    super.key,
    required this.space,
  });

  @override
  State<BookingPaymentPage> createState() => _BookingPaymentPageState();
}

class _BookingPaymentPageState extends State<BookingPaymentPage> {
  final supabase = Supabase.instance.client;

  String rentalType = 'daily';
  String paymentMethod = 'card';

  DateTime? startDate;
  DateTime? endDate;

  bool processing = false;

  double get dailyPrice =>
      double.tryParse(
        widget.space['daily_price']?.toString() ?? '0',
      ) ??
      0;

  double get monthlyPrice =>
      double.tryParse(
        widget.space['monthly_price']?.toString() ?? '0',
      ) ??
      0;

  int get totalDays {
    if (startDate == null || endDate == null) return 0;

    return endDate!.difference(startDate!).inDays + 1;
  }

  double get rentalPrice {
    if (rentalType == 'daily') {
      return dailyPrice * totalDays;
    }

    if (monthlyPrice <= 0) {
      return dailyPrice * totalDays;
    }

    final months = (totalDays / 30).ceil();
    return monthlyPrice * months;
  }

  double get serviceFee => rentalPrice * 0.05;

  double get totalPrice => rentalPrice + serviceFee;

  Future<void> selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
      initialDate: startDate ?? DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      startDate = picked;

      if (endDate != null && endDate!.isBefore(picked)) {
        endDate = null;
      }
    });
  }

  Future<void> selectEndDate() async {
    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the start date first.'),
        ),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      firstDate: startDate!,
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
      initialDate: endDate ?? startDate!,
    );

    if (picked == null) return;

    setState(() {
      endDate = picked;
    });
  }

  Future<void> confirmPayment() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in first.'),
        ),
      );
      return;
    }

    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your start and end dates.'),
        ),
      );
      return;
    }

    if (totalDays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select valid dates.'),
        ),
      );
      return;
    }

    setState(() {
      processing = true;
    });

    try {
      final spaceId = widget.space['id'];

      final selectedStart =
          startDate!.toIso8601String().split('T').first;

      final selectedEnd =
          endDate!.toIso8601String().split('T').first;

      // Check existing bookings for this space
      final existingBookings = await supabase
          .from('bookings')
          .select('id, start_date, end_date, status')
          .eq('space_id', spaceId)
          .inFilter(
            'status',
            ['confirmed', 'pending'],
          );

      bool alreadyBooked = false;

      final newStart = DateTime.parse(selectedStart);
      final newEnd = DateTime.parse(selectedEnd);

      for (final booking in existingBookings) {
        final bookingStart =
            DateTime.parse(booking['start_date'].toString());

        final bookingEnd =
            DateTime.parse(booking['end_date'].toString());

        // Check if the new booking overlaps
        // with an existing booking.
        if (!newEnd.isBefore(bookingStart) &&
            !newStart.isAfter(bookingEnd)) {
          alreadyBooked = true;
          break;
        }
      }

      // Space is already booked
      if (alreadyBooked) {
        if (!mounted) return;

        setState(() {
          processing = false;
        });

        await showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text(
                'Space Already Booked',
              ),
              content: const Text(
                'This space is already booked for these dates. '
                'Please choose different dates or another space.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        return;
      }

      // Create booking
      final booking = await supabase
          .from('bookings')
          .insert({
            'space_id': spaceId,
            'renter_id': user.id,
            'start_date': selectedStart,
            'end_date': selectedEnd,
            'rental_type': rentalType,
            'total_days': totalDays,
            'price_per_day': dailyPrice,
            'price_per_month': monthlyPrice,
            'service_fee': serviceFee,
            'total_price': totalPrice,
            'status': 'confirmed',
          })
          .select()
          .single();

      final bookingId = booking['id'];

      // Demo payment
      final transactionReference =
          'DEMO-PAY-${DateTime.now().millisecondsSinceEpoch}';

      await supabase.from('payments').insert({
        'booking_id': bookingId,
        'renter_id': user.id,
        'amount': totalPrice,
        'payment_method': paymentMethod,
        'transaction_reference': transactionReference,
        'status': 'successful',
        'paid_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      setState(() {
        processing = false;
      });

      // Success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            title: const Text(
              'Booking Confirmed',
            ),
            content: Text(
              'Your booking has been confirmed.\n\n'
              'Total: ${totalPrice.toStringAsFixed(2)} SAR',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      // Return true so the previous page
      // knows that a new booking was created.
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint(
        'Booking/payment error: $e',
      );

      if (!mounted) return;

      setState(() {
        processing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment failed: $e',
          ),
        ),
      );
    }
  }

  Widget dateBox({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xffddd7d0),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xff77716b),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget paymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final selected = paymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          paymentMethod = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xfff0ece6)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xff776d64)
                : const Color(0xffddd7d0),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: const Color(0xffe8e3dc),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xff77716b),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f3ee),
      appBar: AppBar(
        backgroundColor: const Color(0xfff6f3ee),
        elevation: 0,
        title: const Text(
          'Booking & Payment',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          18,
          10,
          18,
          30,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              widget.space['title'] ?? 'Space',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              widget.space['address'] ?? 'Riyadh',
              style: const TextStyle(
                color: Color(0xff77716b),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Rental type',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text(
                      'Daily • '
                      '${dailyPrice.toStringAsFixed(0)} SAR',
                    ),
                    selected: rentalType == 'daily',
                    onSelected: (_) {
                      setState(() {
                        rentalType = 'daily';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: Text(
                      'Monthly • '
                      '${monthlyPrice.toStringAsFixed(0)} SAR',
                    ),
                    selected: rentalType == 'monthly',
                    onSelected: (_) {
                      setState(() {
                        rentalType = 'monthly';
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Text(
              'Choose dates',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                dateBox(
                  title: 'Start date',
                  value: startDate == null
                      ? 'Select date'
                      : '${startDate!.day}/'
                          '${startDate!.month}/'
                          '${startDate!.year}',
                  onTap: selectStartDate,
                ),
                const SizedBox(width: 12),
                dateBox(
                  title: 'End date',
                  value: endDate == null
                      ? 'Select date'
                      : '${endDate!.day}/'
                          '${endDate!.month}/'
                          '${endDate!.year}',
                  onTap: selectEndDate,
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'Payment method',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            paymentOption(
              title: 'Card',
              subtitle: 'Demo payment',
              icon: Icons.credit_card_outlined,
              value: 'card',
            ),

            paymentOption(
              title: 'Wallet',
              subtitle: 'Demo payment',
              icon: Icons.account_balance_wallet_outlined,
              value: 'wallet',
            ),

            const SizedBox(height: 18),

            const Text(
              'Price breakdown',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  priceRow(
                    'Rental',
                    '${rentalPrice.toStringAsFixed(2)} SAR',
                  ),
                  const SizedBox(height: 12),
                  priceRow(
                    'Service fee',
                    '${serviceFee.toStringAsFixed(2)} SAR',
                  ),
                  const Divider(height: 28),
                  priceRow(
                    'Total',
                    '${totalPrice.toStringAsFixed(2)} SAR',
                    bold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed:
                    processing ? null : confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xff716960),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(30),
                  ),
                ),
                child: processing
                    ? const SizedBox(
                        height: 23,
                        width: 23,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirm & Pay',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget priceRow(
    String title,
    String value, {
    bool bold = false,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: bold ? 18 : 16,
            fontWeight: bold
                ? FontWeight.w700
                : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 18 : 16,
            fontWeight: bold
                ? FontWeight.w700
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}