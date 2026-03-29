import 'package:flutter/material.dart';

const _kGold = Color(0xFFF39C12);

class DiscoverBanner extends StatelessWidget {
  const DiscoverBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/subscription'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 22),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A2E19), Color(0xFF1A5E35), Color(0xFF0F3D22)],
            stops: [0.0, 0.6, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // decorative circle
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.08), width: 30),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WORLD MENUS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: Color(0xFF2ECC71)),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Discover Meals &\nCuisines Everyday',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15, letterSpacing: -0.3, fontFamily: 'Raleway'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Authentic recipes from 21 countries —\ndelivered fresh to your door',
                  style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.5), height: 1.5),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(color: _kGold, borderRadius: BorderRadius.circular(22)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Explore Now', style: TextStyle(color: Color(0xFF1A0E00), fontSize: 12, fontWeight: FontWeight.w800)),
                          SizedBox(width: 5),
                          Icon(Icons.arrow_forward_rounded, color: Color(0xFF1A0E00), size: 13),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
