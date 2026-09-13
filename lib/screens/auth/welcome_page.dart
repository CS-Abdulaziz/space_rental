import 'dart:ui';
import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const Color lime = Color(0xFFB8FF72);
  static const Color darkGreen = Color(0xFF03140D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGreen,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // =====================================================
          // BACKGROUND
          // =====================================================

          Image.asset(
            'assets/images/spaceora_background.jpeg',
            fit: BoxFit.cover,
          ),

          // طبقة خضراء غامقة فوق الخلفية
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.18),
                  const Color(0xFF002817).withOpacity(0.18),
                  const Color(0xFF00150C).withOpacity(0.48),
                  const Color(0xFF001008).withOpacity(0.92),
                ],
                stops: const [
                  0.0,
                  0.30,
                  0.65,
                  1.0,
                ],
              ),
            ),
          ),

          // =====================================================
          // GREEN GLOW
          // =====================================================

          Positioned(
            top: 70,
            right: -130,
            child: _glow(
              size: 330,
              color: lime.withOpacity(0.12),
            ),
          ),

          Positioned(
            bottom: 250,
            left: -160,
            child: _glow(
              size: 350,
              color: const Color(0xFF45FF70).withOpacity(0.12),
            ),
          ),

          // =====================================================
          // MAIN CONTENT
          // =====================================================

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [

                  const Spacer(flex: 5),

                  // =================================================
                  // SPACEOra
                  // =================================================

                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Space',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1.8,
                          ),
                        ),
                        TextSpan(
                          text: 'Ora',
                          style: TextStyle(
                            color: lime,
                            fontSize: 48,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // =================================================
                  // TAGLINE
                  // =================================================

                  Text(
                    'Find. Book. Make the most\nof your space.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.82),
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      height: 1.45,
                      letterSpacing: 1.0,
                    ),
                  ),

                  const SizedBox(height: 38),

                  // =================================================
                  // SPACE TYPES
                  // =================================================

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [

                      _spaceType(
                        icon: Icons.local_parking_rounded,
                        title: 'Parking',
                      ),

                      _spaceType(
                        icon: Icons.inventory_2_outlined,
                        title: 'Storage',
                      ),

                      _spaceType(
                        icon: Icons.home_work_outlined,
                        title: 'Basements',
                        secondLine: '& More',
                      ),
                    ],
                  ),

                  const Spacer(flex: 5),

                  // =================================================
                  // LOGIN BUTTON
                  // =================================================

                  _primaryButton(
                    icon: Icons.person_outline_rounded,
                    text: 'Log In',
                    onTap: () {
                      // بنربطه بصفحة Login بعد ما نضبط التصميم
                    },
                  ),

                  const SizedBox(height: 15),

                  // =================================================
                  // SIGN UP BUTTON
                  // =================================================

                  _secondaryButton(
                    icon: Icons.person_add_alt_1_outlined,
                    text: 'Sign Up',
                    onTap: () {
                      // بنربطه بصفحة Sign Up بعد ما نضبط التصميم
                    },
                  ),

                  const SizedBox(height: 30),

                  // =================================================
                  // GUEST
                  // =================================================

                  Row(
                    children: [

                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.20),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        child: Text(
                          'Or continue as Guest',
                          style: TextStyle(
                            color: lime.withOpacity(0.70),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.20),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // SPACE TYPE
  // =============================================================

  static Widget _spaceType({
    required IconData icon,
    required String title,
    String? secondLine,
  }) {
    return Column(
      children: [

        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF082719).withOpacity(0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: lime.withOpacity(0.32),
            ),
            boxShadow: [
              BoxShadow(
                color: lime.withOpacity(0.12),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: lime,
            size: 28,
          ),
        ),

        const SizedBox(height: 9),

        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),

        if (secondLine != null)
          Text(
            secondLine,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
      ],
    );
  }

  // =============================================================
  // PRIMARY BUTTON
  // =============================================================

  static Widget _primaryButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 68,
        width: double.infinity,
        decoration: BoxDecoration(
          color: lime,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: lime.withOpacity(0.40),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [

            const SizedBox(width: 30),

            Icon(
              icon,
              color: Colors.black,
              size: 29,
            ),

            const Spacer(),

            Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 21,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.black,
              size: 30,
            ),

            const SizedBox(width: 30),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // SECONDARY BUTTON
  // =============================================================

  static Widget _secondaryButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12,
            sigmaY: 12,
          ),
          child: Container(
            height: 68,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0B321F).withOpacity(0.58),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: lime.withOpacity(0.50),
                width: 1,
              ),
            ),
            child: Row(
              children: [

                const SizedBox(width: 30),

                Icon(
                  icon,
                  color: lime,
                  size: 29,
                ),

                const Spacer(),

                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(),

                const Icon(
                  Icons.arrow_forward_rounded,
                  color: lime,
                  size: 30,
                ),

                const SizedBox(width: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // GLOW
  // =============================================================

  static Widget _glow({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 120,
            spreadRadius: 35,
          ),
        ],
      ),
    );
  }
}