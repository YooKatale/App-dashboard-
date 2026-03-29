import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _kAccent = Color(0xFF2ECC71);

class PromoBannersSection extends ConsumerWidget {
  final List<Map<String, dynamic>> banners;

  const PromoBannersSection({
    super.key,
    this.banners = const [
      {
        'title': "Discover meals & cuisines everyday",
        'subtitle': "Authentic recipes from 21 countries — delivered fresh to your door",
        'cta': 'Explore Now',
        'ctaColor': Color(0xFFe07820),
        'gradient': 'linear-gradient(120deg, #0e1e0e 0%, #1a5c1a 50%, #2d8c2d 100%)',
        'bgColor1': Color(0xFF0e1e0e),
        'bgColor2': Color(0xFF1a5c1a),
        'bgColor3': Color(0xFF2d8c2d),
        'route': '/subscription',
      },
      {
        'title': 'Flexible Payment Options',
        'subtitle': 'Mobile money · Visa & Mastercard accepted',
        'cta': 'Learn More',
        'ctaColor': Color(0xFFf0c020),
        'gradient': 'linear-gradient(120deg, #0a1628 0%, #1a3a6b 55%, #2a5a9b 100%)',
        'bgColor1': Color(0xFF0a1628),
        'bgColor2': Color(0xFF1a3a6b),
        'bgColor3': Color(0xFF2a5a9b),
        'route': '/categories',
      },
      {
        'title': 'Get Yookatale Boda Loan',
        'subtitle': 'Instant delivery credit for boda boda riders — apply in 2 minutes',
        'cta': 'Apply Now',
        'ctaColor': Color(0xFFf0c020),
        'gradient': 'linear-gradient(120deg, #1a0a00 0%, #4a1a00 50%, #7a2e00 100%)',
        'bgColor1': Color(0xFF1a0a00),
        'bgColor2': Color(0xFF4a1a00),
        'bgColor3': Color(0xFF7a2e00),
        'route': '/subscription',
      },
    ],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: banners
          .asMap()
          .entries
          .map((e) => _PromoBanner(banner: e.value, index: e.key))
          .toList(),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final Map<String, dynamic> banner;
  final int index;

  const _PromoBanner({
    required this.banner,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final title = banner['title'] as String? ?? '';
    final subtitle = banner['subtitle'] as String? ?? '';
    final cta = banner['cta'] as String? ?? '';
    final ctaColor = banner['ctaColor'] as Color? ?? Colors.white;
    final bgColor1 = banner['bgColor1'] as Color? ?? Colors.black;
    final bgColor2 = banner['bgColor2'] as Color? ?? Colors.black;
    final bgColor3 = banner['bgColor3'] as Color? ?? Colors.black;
    final route = banner['route'] as String? ?? '/home';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgColor1, bgColor2, bgColor3],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
            if (cta.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: ctaColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cta,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
