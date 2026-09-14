import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  String? selectedRole;
  bool obscurePassword = true;
  bool isLoading = false;

  static const Color background = Color(0xFFF3EEE7);
  static const Color cardColor = Color(0xFFF8F5EF);
  static const Color brown = Color(0xFF806A58);
  static const Color darkBrown = Color(0xFF2D2925);
  static const Color lightBorder = Color(0xFFD8D0C6);

  Future<void> createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose what you are looking for.'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final user = response.user;

      if (user == null) {
        throw Exception('Account could not be created.');
      }

      await supabase.from('profiles').insert({
        'id': user.id,
        'full_name': fullNameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'role': selectedRole,
      });

      if (!mounted) return;

      if (selectedRole == 'renter') {
        Navigator.pushReplacementNamed(context, '/renter');
      } else {
        Navigator.pushReplacementNamed(context, '/owner');
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/spaceora_background.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              color: background.withOpacity(0.78),
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 1.5,
                sigmaY: 1.5,
              ),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  32,
                  24,
                  32,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),

                    Center(
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Space',
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: 'Georgia',
                                fontSize: 43,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -2,
                              ),
                            ),
                            TextSpan(
                              text: 'Ora',
                              style: TextStyle(
                                color: brown,
                                fontFamily: 'Georgia',
                                fontSize: 43,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Center(
                      child: Text(
                        'Find. Book. Make the most of your space.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: darkBrown.withOpacity(0.78),
                          fontFamily: 'Georgia',
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 145,
                      child: Row(
                        children: [
                          Expanded(
                            child: _spaceCard(
                              image: 'assets/images/parking.jpeg',
                              title: 'Parking',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _spaceCard(
                              image: 'assets/images/storage.jpeg',
                              title: 'Storage',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _spaceCard(
                              image: 'assets/images/basement.jpeg',
                              title: 'Basement',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _spaceCard(
                              image: 'assets/images/other.jpeg',
                              title: 'Other',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 35),

                    const Text(
                      'Create your account',
                      style: TextStyle(
                        color: darkBrown,
                        fontFamily: 'Georgia',
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 19),

                    _inputField(
                      controller: fullNameController,
                      hint: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your full name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 9),

                    _inputField(
                      controller: emailController,
                      hint: 'Email',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your email';
                        }

                        if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 9),

                    _inputField(
                      controller: phoneController,
                      hint: 'Phone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your phone number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 9),

                    _inputField(
                      controller: passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: obscurePassword,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: brown,
                          size: 21,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter a password';
                        }

                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 31),

                    const Text(
                      'What are you looking for?',
                      style: TextStyle(
                        color: darkBrown,
                        fontFamily: 'Georgia',
                        fontSize: 27,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 17),

                    Row(
                      children: [
                        Expanded(
                          child: _roleCard(
                            role: 'renter',
                            icon: Icons.person_rounded,
                            title: 'I want to rent',
                            subtitle: 'a space',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _roleCard(
                            role: 'owner',
                            icon: Icons.home_rounded,
                            title: 'I want to list',
                            subtitle: 'my space',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 23),

                    GestureDetector(
                      onTap: isLoading ? null : createAccount,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          color: brown,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: brown.withOpacity(0.22),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 23,
                                  height: 23,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Georgia',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(
                                  color: darkBrown.withOpacity(0.58),
                                  fontSize: 13,
                                ),
                              ),
                              const TextSpan(
                                text: 'Log In',
                                style: TextStyle(
                                  color: brown,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _spaceCard({
    required String image,
    required String title,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.94),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Image.asset(
              image,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: darkBrown,
                  fontFamily: 'Georgia',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(
        color: darkBrown,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.55),
        hintText: hint,
        hintStyle: TextStyle(
          color: darkBrown.withOpacity(0.48),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: darkBrown.withOpacity(0.65),
          size: 21,
        ),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: lightBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: brown,
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _roleCard({
    required String role,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 112,
        decoration: BoxDecoration(
          color: selected
              ? brown.withOpacity(0.10)
              : Colors.white.withOpacity(0.63),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? brown : lightBorder,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                selected ? 0.09 : 0.04,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: selected ? brown : const Color(0xFF765F4E),
                    size: 29,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: darkBrown,
                      fontFamily: 'Georgia',
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: darkBrown,
                      fontFamily: 'Georgia',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 11,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? brown : const Color(0xFF8A7A6C),
                    width: 1.3,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: brown,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}