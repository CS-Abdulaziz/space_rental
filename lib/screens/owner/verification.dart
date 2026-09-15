import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final supabase = Supabase.instance.client;

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final idController = TextEditingController();
  final ownershipReferenceController = TextEditingController();

  String ownershipType = 'Property Owner';
  String status = 'Not Submitted';
  bool loading = true;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    loadVerification();
  }

  Future<void> loadVerification() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        fullNameController.text = profile['full_name'] ?? '';
        phoneController.text = profile['phone'] ?? '';
        emailController.text = profile['email'] ?? user.email ?? '';
      }

      final verification = await supabase
          .from('verification')
          .select()
          .eq('owner_id', user.id)
          .order('submitted_at', ascending: false)
          .limit(1);

      if (verification.isNotEmpty) {
        final data = verification.first;

        idController.text = data['demo_id_number'] ?? '';
        ownershipType = data['ownership_type'] ?? 'Property Owner';
        ownershipReferenceController.text =
            data['ownership_reference'] ?? '';
        status = data['status'] ?? 'Pending';
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> submitVerification() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    if (fullNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        idController.text.trim().isEmpty ||
        ownershipReferenceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields'),
        ),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      await supabase.from('profiles').update({
        'full_name': fullNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
      }).eq('id', user.id);

      final existing = await supabase
          .from('verification')
          .select('id')
          .eq('owner_id', user.id)
          .order('submitted_at', ascending: false)
          .limit(1);

      final data = {
        'owner_id': user.id,
        'full_name': fullNameController.text.trim(),
        'demo_id_number': idController.text.trim(),
        'ownership_type': ownershipType,
        'ownership_reference':
            ownershipReferenceController.text.trim(),
        'status': 'Pending',
        'submitted_at': DateTime.now().toIso8601String(),
      };

      if (existing.isNotEmpty) {
        await supabase
            .from('verification')
            .update(data)
            .eq('id', existing.first['id']);
      } else {
        await supabase.from('verification').insert(data);
      }

      setState(() {
        status = 'Pending';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification submitted successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => submitting = false);
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    idController.dispose();
    ownershipReferenceController.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xffF4EFE8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
    );
  }

  Widget buildField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xff4B382A),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: fieldDecoration(hint),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xffFBF8F3),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xff765640),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffFBF8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xffFBF8F3),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xff4B382A),
        ),
        title: const Text(
          'Verification',
          style: TextStyle(
            color: Color(0xff4B382A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verify your space',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xff4B382A),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Complete your information before publishing your space.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xff806F61),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffEEE5DB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xff765640),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Verification status: $status',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff4B382A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            buildField(
              'Full Name',
              fullNameController,
              'Enter your full name',
            ),

            buildField(
              'Phone',
              phoneController,
              'Enter your phone number',
            ),

            buildField(
              'Email',
              emailController,
              'Enter your email',
            ),

            buildField(
              'ID Number',
              idController,
              'Enter your ID number',
            ),

            const Text(
              'Ownership Type',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xff4B382A),
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xffF4EFE8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: ownershipType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'Property Owner',
                      child: Text('Property Owner'),
                    ),
                    DropdownMenuItem(
                      value: 'Tenant',
                      child: Text('Tenant'),
                    ),
                    DropdownMenuItem(
                      value: 'Authorized Representative',
                      child: Text('Authorized Representative'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        ownershipType = value;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 18),

            buildField(
              'Ownership Reference / Deed',
              ownershipReferenceController,
              'Enter deed or ownership reference',
            ),

            const SizedBox(height: 8),

            const Text(
              'Space photos and ownership documents can be added to the verification process later.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xff806F61),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: submitting ? null : submitVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff765640),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: submitting
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Submit Verification',
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