import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddSpacePage extends StatefulWidget {
  const AddSpacePage({super.key});

  @override
  State<AddSpacePage> createState() => _AddSpacePageState();
}

class _AddSpacePageState extends State<AddSpacePage> {
  final supabase = Supabase.instance.client;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final sizeController = TextEditingController();
  final dailyPriceController = TextEditingController();
  final monthlyPriceController = TextEditingController();

  String selectedType = 'Basement';

  bool loadingVerification = true;
  bool saving = false;

  Map<String, dynamic>? profile;
  Map<String, dynamic>? verification;

  static const cream = Color(0xffFBF8F3);
  static const brown = Color(0xff765640);
  static const darkBrown = Color(0xff4B382A);
  static const fieldColor = Color(0xffF4EFE8);

  @override
  void initState() {
    super.initState();
    loadVerification();
  }

  Future<void> loadVerification() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() => loadingVerification = false);
      return;
    }

    try {
      final profileData = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final verificationData = await supabase
          .from('verification')
          .select()
          .eq('owner_id', user.id)
          .order('submitted_at', ascending: false)
          .limit(1);

      if (mounted) {
        setState(() {
          profile = profileData;

          if (verificationData.isNotEmpty) {
            verification = verificationData.first;
          }

          loadingVerification = false;
        });
      }
    } catch (e) {
      debugPrint('Verification loading error: $e');

      if (mounted) {
        setState(() => loadingVerification = false);
      }
    }
  }

  bool get isVerified {
    final status =
        verification?['status']?.toString().toLowerCase();

    return status == 'approved';
  }

  InputDecoration decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fieldColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
    );
  }

  Widget field(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: darkBrown,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: decoration(hint),
          ),
        ],
      ),
    );
  }

  Future<void> saveSpace() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    if (!isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your owner verification must be approved first.',
          ),
          backgroundColor: brown,
        ),
      );
      return;
    }

    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        sizeController.text.trim().isEmpty ||
        dailyPriceController.text.trim().isEmpty ||
        monthlyPriceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all space details.'),
          backgroundColor: brown,
        ),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final space = await supabase
          .from('spaces')
          .insert({
            'owner_id': user.id,
            'title': titleController.text.trim(),
            'type': selectedType,
            'description': descriptionController.text.trim(),
            'address': addressController.text.trim(),
            'latitude': 24.7136,
            'longitude': 46.6753,
            'size': double.tryParse(
                  sizeController.text.trim(),
                ) ??
                0,
            'daily_price': double.tryParse(
                  dailyPriceController.text.trim(),
                ) ??
                0,
            'monthly_price': double.tryParse(
                  monthlyPriceController.text.trim(),
                ) ??
                0,
            'availability': 'Available',
            'status': 'active',
            'verified': true,
          })
          .select()
          .single();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Space added successfully ✨',
          ),
          backgroundColor: brown,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Add space error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding space: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    sizeController.dispose();
    dailyPriceController.dispose();
    monthlyPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loadingVerification) {
      return const Scaffold(
        backgroundColor: cream,
        body: Center(
          child: CircularProgressIndicator(
            color: brown,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: darkBrown,
        ),
        title: const Text(
          'Add New Space',
          style: TextStyle(
            color: darkBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          22,
          10,
          22,
          35,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'List your space',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: darkBrown,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Add the details of the space you want to rent.',
              style: TextStyle(
                color: Color(0xff806F61),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 22),

            // VERIFICATION CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: isVerified
                    ? const Color(0xffEEE5DB)
                    : const Color(0xffF1E2D8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    isVerified
                        ? Icons.verified_rounded
                        : Icons.warning_amber_rounded,
                    color: brown,
                    size: 29,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVerified
                              ? 'Owner Verified'
                              : 'Verification Required',
                          style: const TextStyle(
                            color: darkBrown,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isVerified
                              ? '${verification?['full_name'] ?? profile?['full_name'] ?? ''} • ${verification?['ownership_type'] ?? ''}'
                              : 'Complete owner verification before adding a space.',
                          style: const TextStyle(
                            color: Color(0xff806F61),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            field(
              'Space Name',
              titleController,
              'Example: Modern Private Basement',
            ),

            // TYPE
            const Text(
              'Space Type',
              style: TextStyle(
                color: darkBrown,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'Parking',
                      child: Text('Parking'),
                    ),
                    DropdownMenuItem(
                      value: 'Storage',
                      child: Text('Storage'),
                    ),
                    DropdownMenuItem(
                      value: 'Basement',
                      child: Text('Basement'),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 18),

            field(
              'Description',
              descriptionController,
              'Describe your space...',
              maxLines: 4,
            ),

            field(
              'Address',
              addressController,
              'Example: Al Malqa, Riyadh',
            ),

            field(
              'Size (m²)',
              sizeController,
              'Example: 45',
              keyboardType: TextInputType.number,
            ),

            field(
              'Daily Price (SAR)',
              dailyPriceController,
              'Example: 80',
              keyboardType: TextInputType.number,
            ),

            field(
              'Monthly Price (SAR)',
              monthlyPriceController,
              'Example: 1600',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: saving ? null : saveSpace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brown,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xffB9A99B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: saving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Add Space',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}