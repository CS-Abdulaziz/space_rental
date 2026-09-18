import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final supabase = Supabase.instance.client;

  final fullNameController = TextEditingController();
  final idController = TextEditingController();
  final ownershipReferenceController = TextEditingController();

  String ownershipType = 'Property Owner';
  String status = 'Not Submitted';

  bool submitting = false;

  final Color cream = const Color(0xFFF7F2EA);
  final Color softCream = const Color(0xFFFFFBF5);
  final Color brown = const Color(0xFF765548);
  final Color darkBrown = const Color(0xFF3E2C25);
  final Color beige = const Color(0xFFE8D8C8);

  @override
  void initState() {
    super.initState();
    loadVerification();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    idController.dispose();
    ownershipReferenceController.dispose();
    super.dispose();
  }

  Future<void> loadVerification() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        fullNameController.text =
            profile['full_name']?.toString() ?? '';
      }

      final verification = await supabase
          .from('verification')
          .select()
          .eq('owner_id', user.id)
          .order('submitted_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (verification != null && mounted) {
        setState(() {
          idController.text =
              verification['demo_id_number']?.toString() ?? '';

          ownershipType =
              verification['ownership_type']?.toString() ??
                  'Property Owner';

          ownershipReferenceController.text =
              verification['ownership_reference']?.toString() ?? '';

          status =
              verification['status']?.toString() ??
                  'Not Submitted';
        });
      }
    } catch (e) {
      debugPrint('Load verification error: $e');
    }
  }

  Future<void> submitVerification() async {
    if (submitting) return;

    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in first.'),
        ),
      );
      return;
    }

    final fullName = fullNameController.text.trim();
    final idNumber = idController.text.trim();
    final ownershipReference =
        ownershipReferenceController.text.trim();

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name.'),
        ),
      );
      return;
    }

    // ID = exactly 10 digits
    if (!RegExp(r'^\d{10}$').hasMatch(idNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ID Number must be exactly 10 digits.',
          ),
        ),
      );
      return;
    }

    // Ownership Reference = exactly 12 digits
    if (!RegExp(r'^\d{12}$').hasMatch(ownershipReference)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ownership Reference must be exactly 12 digits.',
          ),
        ),
      );
      return;
    }

    setState(() {
      submitting = true;
      status = 'Pending';
    });

    String? verificationId;

    try {
      final existing = await supabase
          .from('verification')
          .select('id')
          .eq('owner_id', user.id)
          .maybeSingle();

      if (existing != null) {
        verificationId = existing['id'].toString();

        await supabase
            .from('verification')
            .update({
          'full_name': fullName,
          'demo_id_number': idNumber,
          'ownership_type': ownershipType,
          'ownership_reference': ownershipReference,
          'status': 'pending',
          'submitted_at': DateTime.now().toIso8601String(),
        }).eq(
          'id',
          verificationId,
        );
      } else {
        final response = await supabase
            .from('verification')
            .insert({
          'owner_id': user.id,
          'full_name': fullName,
          'demo_id_number': idNumber,
          'ownership_type': ownershipType,
          'ownership_reference': ownershipReference,
          'status': 'pending',
          'submitted_at': DateTime.now().toIso8601String(),
        })
            .select()
            .single();

        verificationId = response['id'].toString();
      }

      // Demo verification:
      // Keep status Pending for 5 seconds,
      // then automatically approve.
      await Future.delayed(
        const Duration(seconds: 5),
      );

      if (verificationId != null) {
        await supabase
            .from('verification')
            .update({
          'status': 'approved',
        }).eq(
          'id',
          verificationId,
        );
      }

      if (!mounted) return;

      setState(() {
        status = 'Approved';
        submitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification successful! You can now add your space ✨',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        submitting = false;
        status = 'Not Submitted';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification failed: $e',
          ),
        ),
      );
    }
  }

  InputDecoration fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: brown.withOpacity(.45),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: beige.withOpacity(.7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: beige.withOpacity(.7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: brown,
          width: 1.4,
        ),
      ),
    );
  }

  Color statusColor() {
    if (status.toLowerCase() == 'approved') {
      return const Color(0xFF6F7D68);
    }

    if (status.toLowerCase() == 'pending') {
      return const Color(0xFFA77A45);
    }

    return brown;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Verification',
          style: TextStyle(
            color: darkBrown,
            fontSize: 25,
            fontWeight: FontWeight.w700,
            fontFamily: 'Georgia',
          ),
        ),
        iconTheme: IconThemeData(
          color: darkBrown,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.72),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(.85),
                ),
                boxShadow: [
                  BoxShadow(
                    color: brown.withOpacity(.07),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: beige.withOpacity(.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.verified_user_outlined,
                      color: darkBrown,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Owner Verification',
                          style: TextStyle(
                            color: darkBrown,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Georgia',
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Verify your information before listing your space.',
                          style: TextStyle(
                            color: brown.withOpacity(.55),
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

            Text(
              'Personal Information',
              style: TextStyle(
                color: darkBrown,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Georgia',
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: fullNameController,
              decoration: fieldDecoration('Full Name'),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: idController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: fieldDecoration(
                'ID Number — exactly 10 digits',
              ).copyWith(
                counterText: '',
              ),
            ),

            const SizedBox(height: 25),

            Text(
              'Ownership Information',
              style: TextStyle(
                color: darkBrown,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Georgia',
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: beige.withOpacity(.7),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: ownershipType,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: brown,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Property Owner',
                      child: Text('Property Owner'),
                    ),
                    DropdownMenuItem(
                      value: 'Authorized Representative',
                      child: Text(
                        'Authorized Representative',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Tenant',
                      child: Text('Tenant'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      ownershipType = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: ownershipReferenceController,
              keyboardType: TextInputType.number,
              maxLength: 12,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: fieldDecoration(
                'Ownership Reference — exactly 12 digits',
              ).copyWith(
                counterText: '',
              ),
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: softCream,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: beige.withOpacity(.7),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    status.toLowerCase() == 'approved'
                        ? Icons.check_circle_outline
                        : status.toLowerCase() == 'pending'
                            ? Icons.hourglass_empty_rounded
                            : Icons.info_outline,
                    color: statusColor(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification Status',
                          style: TextStyle(
                            color: darkBrown,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: submitting
                    ? null
                    : submitVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brown,
                  disabledBackgroundColor:
                      brown.withOpacity(.45),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Verification',
                        style: TextStyle(
                          fontSize: 15,
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
}