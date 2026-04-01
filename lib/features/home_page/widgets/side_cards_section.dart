import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SideCardsSection extends ConsumerWidget {
  const SideCardsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card 1: We Are Hiring
            Expanded(
              child: _SideCard(
                eyebrow: 'Careers',
                title: "We're Hiring — Join Our Team",
                ctaText: 'Apply now',
                gradient: [const Color(0xFF0B2416), const Color(0xFF1A5E35)],
                icon: Icons.work_outline_rounded,
                iconColor: const Color(0xFF86EFAC),
                onTap: () => Navigator.pushNamed(context, '/careers'),
              ),
            ),
            const SizedBox(width: 10),
            // Card 2: Free Delivery within 3km
            Expanded(
              child: _SideCard(
                eyebrow: 'Free Delivery',
                title: 'Free delivery within 3km',
                ctaText: 'See details',
                gradient: [const Color(0xFF001a2e), const Color(0xFF003d6b)],
                icon: Icons.local_shipping_rounded,
                iconColor: const Color(0xFF7fd4ff),
                onTap: () => Navigator.pushNamed(context, '/subscription'),
              ),
            ),
          ],
        ),
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
    required this.eyebrow, required this.title, required this.ctaText,
    required this.gradient, required this.icon, required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(eyebrow,
                  style: const TextStyle(color: Colors.white70, fontSize: 10,
                      fontWeight: FontWeight.w600, letterSpacing: 0.5))),
              Icon(icon, color: iconColor, size: 14),
            ]),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w700, height: 1.3),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(children: [
              Text(ctaText, style: const TextStyle(color: Colors.white,
                  fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 10),
            ]),
          ],
        ),
      ),
    );
  }
}
