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
          Image.asset(
            'assets/images/spaceora_background.jpeg',
            fit: BoxFit.cover,
          ),

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

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 4),

                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Space',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Georgia',
                            fontSize: 48,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -2.0,
                          ),
                        ),
                        TextSpan(
                          text: 'Ora',
                          style: TextStyle(
                            color: lime,
                            fontFamily: 'Georgia',
                            fontSize: 48,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -2.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Find. Book. Make the most\nof your space.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                      letterSpacing: 0.7,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _spaceType(
                        icon: Icons.local_parking_rounded,
                        title: 'Parking',
                      ),
                      const SizedBox(width: 10),
                      _spaceType(
                        icon: Icons.inventory_2_outlined,
                        title: 'Storage',
                      ),
                      const SizedBox(width: 10),
                      _spaceType(
                        icon: Icons.home_work_outlined,
                        title: 'Basements',
                        secondLine: '& More',
                      ),
                    ],
                  ),

                  const Spacer(flex: 4),

                  _primaryButton(
                    icon: Icons.person_outline_rounded,
                    text: 'Log In',
                    onTap: () {},
                  ),

                  const SizedBox(height: 12),

                  _secondaryButton(
                    icon: Icons.person_add_alt_1_outlined,
                    text: 'Sign Up',
                    onTap: () {},
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.20),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Or continue as Guest',
                          style: TextStyle(
                            color: lime.withOpacity(0.78),
                            fontSize: 13,
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

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _spaceType({
    required IconData icon,
    required String title,
    String? secondLine,
  }) {
    return SizedBox(
      width: 90,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF082719).withOpacity(0.72),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: lime.withOpacity(0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: lime.withOpacity(0.16),
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
          const SizedBox(height: 7),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (secondLine != null)
            Text(
              secondLine,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  static Widget _primaryButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
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
            const SizedBox(width: 28),
            const Icon(
              Icons.person_outline_rounded,
              color: Colors.black,
              size: 28,
            ),
            const Spacer(),
            Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.black,
              size: 30,
            ),
            const SizedBox(width: 28),
          ],
        ),
      ),
    );
  }

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
            height: 64,
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
                const SizedBox(width: 28),
                Icon(
                  icon,
                  color: lime,
                  size: 28,
                ),
                const Spacer(),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: lime,
                  size: 30,
                ),
                const SizedBox(width: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

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