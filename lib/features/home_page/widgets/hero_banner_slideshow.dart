import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../providers/homepage_providers.dart';

const _kPrimary = Color(0xFF0B2416);
const _kAccent  = Color(0xFF2ECC71);
const _kGold    = Color(0xFFF39C12);

// 2 hero slides (removed "Download App" since already on app)
const List<Map<String, dynamic>> _heroSlides = [
  {
    'tag': 'BEST SELLERS',
    'title': 'Top Picks',
    'accent': 'This Week',
    'desc': 'Freshness curated daily. From local farms to your table, always at the best price.',
    'gradient': [Color(0xFF160800), Color(0xFF3D1800)],
    'accentColor': Color(0xFFFF8C42),
    'icon': Icons.star_rounded,
    'cta': 'Shop Now',
    'ctaRoute': '/categories',
  },
  {
    'tag': 'WORLD MENUS',
    'title': 'Authentic Meals',
    'accent': 'From Every Nation',
    'desc': 'Subscribe to receive authentic, chef-prepared world cuisine plans on your schedule.',
    'gradient': [Color(0xFF00130F), Color(0xFF003328)],
    'accentColor': Color(0xFF00C8A0),
    'icon': Icons.public_rounded,
    'cta': 'Subscribe',
    'ctaRoute': '/subscription',
  },
];

// Default network banner images (pulled from homepage config if available)
const List<String> _defaultBannerImages = [
  'https://yookatale.app/assets/images/banner.jpg',
  'https://yookatale.app/assets/images/new.jpeg',
  'https://yookatale.app/assets/images/b1.jpeg',
  'https://yookatale.app/assets/images/b2.jpeg',
  'https://yookatale.app/assets/images/banner2.jpeg',
  'https://yookatale.app/assets/images/banner3.jpeg',
];

class HeroBannerSlideshow extends ConsumerStatefulWidget {
  const HeroBannerSlideshow({super.key});

  @override
  ConsumerState<HeroBannerSlideshow> createState() => _HeroBannerSlideshowState();
}

class _HeroBannerSlideshowState extends ConsumerState<HeroBannerSlideshow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  void _startTimer(int length) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 5500), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(homepageConfigProvider);
    return configAsync.when(
      data: (config) {
        // Prefer backend image slides; fall back to gradient slides
        final heroSlides = config['heroSlides'] as List?;
        List<String> networkImages = [];
        if (heroSlides != null) {
          for (final s in heroSlides) {
            if (s is Map && (s['imageUrl'] ?? '').toString().isNotEmpty) {
              networkImages.add(s['imageUrl'] as String);
            }
          }
        }
        final useNetwork = networkImages.isNotEmpty;
        final count = useNetwork ? networkImages.length : _heroSlides.length;

        // Ensure timer is always running for slideshow
        if (_timer == null || !_timer!.isActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startTimer(count);
          });
        }

        return useNetwork
            ? _NetworkBanner(
                images: networkImages,
                pageController: _pageController,
                currentPage: _currentPage,
                onPageChanged: (i) => setState(() => _currentPage = i),
              )
            : _GradientBanner(
                slides: _heroSlides,
                pageController: _pageController,
                currentPage: _currentPage,
                onPageChanged: (i) => setState(() => _currentPage = i),
              );
      },
      loading: () => _GradientBanner(
        slides: _heroSlides,
        pageController: _pageController,
        currentPage: _currentPage,
        onPageChanged: (i) => setState(() {
          _currentPage = i;
          // Ensure timer is running
          if (_timer == null || !_timer!.isActive) {
            _startTimer(_heroSlides.length);
          }
        }),
      ),
      error: (_, __) => _GradientBanner(
        slides: _heroSlides,
        pageController: _pageController,
        currentPage: _currentPage,
        onPageChanged: (i) => setState(() => _currentPage = i),
      ),
    );
  }
}

// ── Gradient slide banner (when no backend images) ────────────────────────────
class _GradientBanner extends StatelessWidget {
  final List<Map<String, dynamic>> slides;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _GradientBanner({
    required this.slides,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: slides.length,
            itemBuilder: (_, i) => _GradientSlide(slide: slides[i]),
          ),
          // Indicator
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: pageController,
                count: slides.length,
                effect: const ExpandingDotsEffect(
                  dotHeight: 6,
                  dotWidth: 6,
                  expansionFactor: 3,
                  activeDotColor: _kAccent,
                  dotColor: Colors.white38,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientSlide extends StatelessWidget {
  final Map<String, dynamic> slide;
  const _GradientSlide({required this.slide});

  @override
  Widget build(BuildContext context) {
    final colors      = (slide['gradient'] as List).cast<Color>();
    final icon        = slide['icon'] as IconData? ?? Icons.star_rounded;
    final accentColor = slide['accentColor'] as Color? ?? _kAccent;
    final ctaRoute    = slide['ctaRoute'] as String? ?? '/home';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _NoisePainter())),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 10, 32),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tag pill — matches webapp slide.tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          slide['tag'] as String? ?? 'YOOKATALE',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      // Title — matches webapp slide.title
                      Text(
                        slide['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Raleway',
                          height: 1.1,
                        ),
                      ),
                      // Accent line — matches webapp slide.accent
                      if ((slide['accent'] as String?)?.isNotEmpty == true)
                        Text(
                          slide['accent'] as String,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Raleway',
                            height: 1.15,
                          ),
                        ),
                      const SizedBox(height: 5),
                      // Desc — matches webapp slide.desc
                      if ((slide['desc'] as String?)?.isNotEmpty == true)
                        Text(
                          slide['desc'] as String,
                          style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 10.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 12),
                      // CTA button
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, ctaRoute),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            slide['cta'] as String? ?? 'Explore',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Network image banner (when backend images available) ─────────────────────
class _NetworkBanner extends StatelessWidget {
  final List<String> images;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _NetworkBanner({
    required this.images,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: images.length,
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: images[i],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, __) => Container(color: _kPrimary),
              errorWidget: (_, __, ___) => _GradientSlide(slide: _heroSlides[i % _heroSlides.length]),
            ),
          ),
          // Bottom gradient fade
          Positioned(
            bottom: 0, left: 0, right: 0, height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                ),
              ),
            ),
          ),
          // Indicator
          Positioned(
            bottom: 14, left: 0, right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: pageController,
                count: images.length,
                effect: const ExpandingDotsEffect(
                  dotHeight: 6,
                  dotWidth: 6,
                  expansionFactor: 3,
                  activeDotColor: _kAccent,
                  dotColor: Colors.white38,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Noise texture painter ────────────────────────────────────────────────────
class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.03);
    const step = 12.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        if ((x + y).toInt() % 24 == 0) {
          canvas.drawCircle(Offset(x, y), 1, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
