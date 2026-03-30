import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/homepage_providers.dart';

const _kPrimary = Color(0xFF0B2416);
const _kAccent  = Color(0xFF2ECC71);
const _kGold    = Color(0xFFF39C12);

/// Mini cards (Occasion + Free Delivery) + Download App card
/// Falls back to hardcoded cards if no admin config
class HomepageBannersSection extends ConsumerWidget {
  const HomepageBannersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(homepageConfigProvider);
    return configAsync.when(
      data: (config) {
        final sideCards   = config['sideCards']   as List? ?? [];
        final promoBanners= config['promoBanners'] as List? ?? [];

        return Column(
          children: [
            _buildMiniCardsRow(context, sideCards),
            if (promoBanners.isNotEmpty)
              _buildPromoBanners(context, promoBanners),
            _buildDownloadCard(context),
          ],
        );
      },
      loading: () => _buildDownloadCard(context),
      error: (_, __) => _buildDownloadCard(context),
    );
  }

  Widget _buildMiniCardsRow(BuildContext context, List<dynamic> sideCards) {
    if (sideCards.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        children: [
          Expanded(child: _AdminSideCard(card: sideCards[0] as Map)),
          const SizedBox(width: 10),
          Expanded(child: _AdminSideCard(card: sideCards[1] as Map)),
        ],
      ),
    );
  }

  Widget _buildPromoBanners(BuildContext context, List<dynamic> promoBanners) {
    return Column(
      children: promoBanners.map((b) {
        final banner = b is Map ? b as Map : {};
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: _PromoBanner(
            title: banner['title']?.toString() ?? '',
            sub: banner['sub']?.toString() ?? '',
            cta: banner['cta']?.toString() ?? 'Explore',
            link: banner['link']?.toString() ?? '/subscription',
            ctaColor: banner['ctaColor']?.toString() ?? '#e07820',
            imageUrl: banner['imageUrl']?.toString(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDownloadCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: GestureDetector(
        onTap: () async {
          const url = 'https://play.google.com/store/apps/details?id=com.yookatale.app';
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0E3D22), Color(0xFF1A5C35)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kAccent.withOpacity(0.10),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _kAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cloud_download_rounded, color: _kAccent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('DOWNLOAD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _kAccent, letterSpacing: 0.7)),
                        SizedBox(height: 2),
                        Text('YooKatale App — Android & iOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Get the app', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11)),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini card (hardcoded fallback) ────────────────────────────────────────────
class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String tag;
  final String title;
  final List<Color> gradient;
  final String route;

  const _MiniCard({
    required this.icon,
    required this.tag,
    required this.title,
    required this.gradient,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(minHeight: 96),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 15),
            ),
            Text(
              tag,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Colors.white.withOpacity(0.55)),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, height: 1.25, fontFamily: 'Raleway'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Shop now', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 10, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Admin-driven side card ────────────────────────────────────────────────────
class _AdminSideCard extends StatelessWidget {
  final Map card;
  const _AdminSideCard({required this.card});

  Color _hex(String h) {
    final v = h.replaceAll('#', '');
    return Color(int.parse('FF${v.padLeft(6, '0')}', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final title  = card['title']?.toString() ?? '';
    final eyebrow= card['eyebrow']?.toString() ?? '';
    final cta    = card['ctaText']?.toString() ?? 'Shop now';
    final link   = card['link']?.toString() ?? '';
    final imgUrl = card['imageUrl']?.toString();
    final gc     = (card['gradientColors'] as List?)?.map((e) => _hex(e.toString())).toList()
        ?? [const Color(0xFF0B2416), const Color(0xFF1A6B3A)];
    if (gc.length < 2) gc.add(gc.first);

    return GestureDetector(
      onTap: () async {
        if (link.startsWith('http')) {
          final uri = Uri.parse(link);
          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else if (link.isNotEmpty) {
          Navigator.pushNamed(context, link);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gc, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: gc.last.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imgUrl != null && imgUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(imageUrl: imgUrl, height: 40, width: double.infinity, fit: BoxFit.cover),
              ),
            if (eyebrow.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(eyebrow.toUpperCase(), style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            ],
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, fontFamily: 'Raleway'), maxLines: 2),
            const SizedBox(height: 8),
            Text(cta + ' →', style: const TextStyle(color: _kGold, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ── Promo banner ──────────────────────────────────────────────────────────────
class _PromoBanner extends StatelessWidget {
  final String title, sub, cta, link, ctaColor;
  final String? imageUrl;

  const _PromoBanner({
    required this.title, required this.sub, required this.cta,
    required this.link, required this.ctaColor, this.imageUrl,
  });

  Color _parseCtaColor(String hex) {
    try { return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16)); }
    catch (_) { return const Color(0xFFe07820); }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (link.startsWith('http')) {
          final uri = Uri.parse(link);
          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else if (link.isNotEmpty) {
          Navigator.pushNamed(context, link);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0B2416), Color(0xFF1A6B3A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty) Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(sub, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)), maxLines: 2),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: _parseCtaColor(ctaColor), borderRadius: BorderRadius.circular(8)),
                    child: Text(cta, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
            if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(imageUrl: imageUrl!, width: 72, height: 72, fit: BoxFit.cover, errorWidget: (_, __, ___) => const SizedBox.shrink()),
              ),
          ],
        ),
      ),
    );
  }
}
