import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _kPrimary = Color(0xFF0B2416);
const _kAccent  = Color(0xFF2ECC71);

class SideCardsSection extends ConsumerWidget {
  const SideCardsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: _kPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Side card 1: Gift/Occasion
          _SideCard(
            eyebrow: 'Occasion',
            title: "Mother's Day Special Offers",
            ctaText: 'Shop now',
            gradient: [const Color(0xFF1a0510), const Color(0xFF5c0a30)],
            icon: Icons.card_giftcard_rounded,
            iconColor: Color(0xFFff80b3),
            onTap: () => Navigator.pushNamed(context, '/categories'),
          ),
          const SizedBox(height: 10),

          // Side card 2: Truck/Delivery
          _SideCard(
            eyebrow: 'Free Delivery',
            title: 'Free delivery within 3km',
            ctaText: 'See details',
            gradient: [const Color(0xFF001a2e), const Color(0xFF003d6b)],
            icon: Icons.local_shipping_rounded,
            iconColor: Color(0xFF7fd4ff),
            onTap: () => Navigator.pushNamed(context, '/subscription'),
          ),
          const SizedBox(height: 10),

          // Side card 3: Download App
          _SideCard(
            eyebrow: 'Download',
            title: 'Yookatale App — Android & iOS',
            ctaText: 'Get the app',
            gradient: [const Color(0xFF0a1a00), const Color(0xFF294d00)],
            icon: Icons.download_rounded,
            iconColor: Color(0xFFa8e060),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open Play Store link')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SideCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String ctaText;
  final List<Color> gradient;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _SideCard({
    required this.eyebrow,
    required this.title,
    required this.ctaText,
    required this.gradient,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    eyebrow,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Icon(icon, color: iconColor, size: 14),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  ctaText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
