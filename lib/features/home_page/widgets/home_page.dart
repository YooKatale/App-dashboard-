import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../notifiers/product_notifier.dart';
import 'products.dart';
import 'hero_banner_slideshow.dart';
import 'homepage_banners_section.dart';
import 'categories_section.dart';
import 'country_cuisines_section.dart';
import 'budget_filter_section.dart';
import 'discover_banner.dart';
import 'payment_banner.dart';
import 'boda_loan_card.dart';
import 'side_cards_section.dart';
import 'meal_sections.dart';
import '../providers/homepage_providers.dart';
import '../../../widgets/ratings_dialog.dart';
import '../../../services/ratings_service.dart';
import '../../cart/providers/cart_provider.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';

const _kPrimary = Color(0xFF0B2416);
const _kAccent  = Color(0xFF2ECC71);
const _kBg      = Color(0xFFF4F6F4);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasShownRatings = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_hasShownRatings) _checkAndShowRatings();
    });
  }

  Future<void> _checkAndShowRatings() async {
    if (!mounted) return;
    final shouldShowPlayStore = await RatingsService.shouldShowPlayStoreRating();
    if (shouldShowPlayStore && mounted) {
      await RatingsDialog.showPlayStoreRatingDialog(context);
      _hasShownRatings = true;
      return;
    }
    final shouldShowService = await RatingsService.shouldShowServiceRating();
    if (shouldShowService && mounted) {
      await RatingsDialog.showServiceRatingDialog(context);
      _hasShownRatings = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount         = ref.watch(cartCountProvider);
    final authState         = ref.watch(authStateProvider);
    final firstName         = authState.firstName ?? '';
    final initial           = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'Y';
    final filteredProducts  = ref.watch(productsFilteredByBudgetProvider);
    final popularProducts   = ref.watch(popularProductsProvider);
    final notificationCount = ref.watch(notificationCountProvider);
    final configAsync       = ref.watch(homepageConfigProvider);
    final promoBanners      = configAsync.valueOrNull?['promoBanners'] as List? ?? [];

    return Column(
      children: [
        // ── TOP BAR ─────────────────────────────────────────────────────────
        _TopBar(cartCount: cartCount, initial: initial, notificationCount: notificationCount),

        // ── SCROLLABLE BODY ─────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── DARK HERO AREA (matches webapp .hero-outer bg) ───────────
                Container(
                  color: _kPrimary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero carousel
                      const HeroBannerSlideshow(),

                      // Side promotional cards (next to hero)
                      const SideCardsSection(),

                      // Mini cards + Download App (still on dark bg)
                      const HomepageBannersSection(),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),

                // ── WHITE SHEET (rounded top corners) ───────────────────────
                Container(
                  decoration: const BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // World Cuisines – flag chips strip
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 22),
                        child: CountryCuisinesSection(),
                      ),

                      // Budget filter (label is inside BudgetFilterSection)
                      const BudgetFilterSection(),

                      // Categories
                      const CategoriesSection(),

                      // "Discover Meals" banner
                      const DiscoverBanner(),

                      // Popular Products
                      _SectionHeader(
                        icon: Icons.star_rounded,
                        iconBg: _kPrimary,
                        title: 'Popular',
                        onMore: () => Navigator.pushNamed(context, '/categories'),
                      ),
                      ProductsPage(productProvider: popularProducts, title: 'Most Popular'),
                      if (promoBanners.isNotEmpty)
                        _SectionPromoBanner(banner: promoBanners[0 % promoBanners.length]),

                      // Payment banner
                      const PaymentBanner(),

                      // Latest / Discover Products
                      _SectionHeader(
                        icon: Icons.search_rounded,
                        iconBg: const Color(0xFFF39C12),
                        iconColor: const Color(0xFF1A0E00),
                        title: 'Discover',
                        onMore: () => Navigator.pushNamed(context, '/categories'),
                      ),
                      ProductsPage(productProvider: filteredProducts, title: 'Latest Products'),
                      if (promoBanners.isNotEmpty)
                        _SectionPromoBanner(banner: promoBanners[1 % promoBanners.length]),

                      // Boda Loan card
                      const BodaLoanCard(),

                      // ── More product sections ──────────────────────────────
                      _SectionHeader(
                        icon: Icons.local_florist_rounded,
                        iconBg: const Color(0xFF1A5E38),
                        title: 'Fruits',
                        onMore: () => Navigator.pushNamed(context, '/categories'),
                      ),
                      ProductsPage(productProvider: ref.watch(fruitProvider), title: 'Fruits'),
                      if (promoBanners.isNotEmpty)
                        _SectionPromoBanner(banner: promoBanners[2 % promoBanners.length]),

                      _SectionHeader(
                        icon: Icons.grass_rounded,
                        iconBg: const Color(0xFF2D7A2D),
                        title: 'Vegetables',
                        onMore: () => Navigator.pushNamed(context, '/categories'),
                      ),
                      ProductsPage(productProvider: ref.watch(vegetablesProvider), title: 'Vegetables'),
                      if (promoBanners.isNotEmpty)
                        _SectionPromoBanner(banner: promoBanners[3 % promoBanners.length]),

                      _SectionHeader(
                        icon: Icons.grain_rounded,
                        iconBg: const Color(0xFF8B6914),
                        title: 'Grains & Flour',
                        onMore: () => Navigator.pushNamed(context, '/categories'),
                      ),
                      ProductsPage(productProvider: ref.watch(grainsProvider), title: 'Grains & Flour'),

                      _SectionHeader(
                        icon: Icons.restaurant_rounded,
                        iconBg: const Color(0xFF8B1A1A),
                        title: 'Meat',
                        onMore: () => Navigator.pushNamed(context, '/categories'),
                      ),
                      ProductsPage(productProvider: ref.watch(meatProvider), title: 'Meat'),
                      if (promoBanners.isNotEmpty)
                        _SectionPromoBanner(banner: promoBanners[4 % promoBanners.length]),

                      _SectionHeader(
                        icon: Icons.water_drop_rounded,
                        iconBg: const Color(0xFF0E5F7A),
                        title: 'Dairy',
                        onMore: () => Navigator.pushNamed(context, '/categories'),
                      ),
                      ProductsPage(productProvider: ref.watch(dairyProvider), title: 'Dairy'),

                      _SectionHeader(
                        icon: Icons.hexagon_rounded,
                        iconBg: const Color(0xFF5E3A1A),
                        title: 'Root Vegetables',
                        onMore: () => Navigator.pushNamed(context, '/categories'),
                      ),
                      ProductsPage(productProvider: ref.watch(rootProvider), title: 'Root Vegetables'),

                      _SectionHeader(
                        icon: Icons.local_drink_rounded,
                        iconBg: const Color(0xFF1A3A8B),
                        title: 'Juices',
                        onMore: () => Navigator.pushNamed(context, '/categories'),
                      ),
                      ProductsPage(productProvider: ref.watch(juiceProvider), title: 'Juices'),

                      // ── Meal Sections ───────────────────────────────────────
                      const SizedBox(height: 20),
                      const MealSectionsWidget(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section label (plain text, used for budget) ───────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0A0F0C), letterSpacing: -0.2),
  );
}

// ── Section header with icon pill ────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final VoidCallback onMore;

  const _SectionHeader({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.onMore,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0A0F0C), letterSpacing: -0.2),
            ),
          ),
          GestureDetector(
            onTap: onMore,
            child: Row(
              children: const [
                Text('See all', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _kAccent)),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded, size: 11, color: _kAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final int cartCount;
  final String initial;
  final int notificationCount;
  const _TopBar({required this.cartCount, required this.initial, required this.notificationCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kPrimary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 10,
        left: 12,
        right: 12,
      ),
      child: Row(
        children: [
          // Hamburger (wrapped in Builder to get Scaffold context)
          Builder(
            builder: (scaffoldContext) => GestureDetector(
              onTap: () => Scaffold.of(scaffoldContext).openDrawer(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 18, height: 1.5, decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 4.5),
                    Container(width: 12, height: 1.5, decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 4.5),
                    Container(width: 18, height: 1.5, decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(2))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Search field
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/search'),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.45), size: 15),
                    const SizedBox(width: 8),
                    Text(
                      'Search products…',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Notification bell pill
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/notifications'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                ),
              ),
              if (notificationCount > 0)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kPrimary, width: 1.5),
                    ),
                    child: Text(
                      notificationCount > 9 ? '9+' : '$notificationCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION PROMO BANNER (between product sections)
// ─────────────────────────────────────────────────────────────────────────────
class _SectionPromoBanner extends StatelessWidget {
  final dynamic banner;
  const _SectionPromoBanner({required this.banner});

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFFe07820);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = banner is Map ? banner as Map : {};
    final title    = b['title']?.toString() ?? '';
    final sub      = b['sub']?.toString() ?? '';
    final cta      = b['cta']?.toString() ?? 'Explore';
    final link     = b['link']?.toString() ?? '/subscription';
    final ctaColor = b['ctaColor']?.toString() ?? '#e07820';
    final imageUrl = b['imageUrl']?.toString();

    if (title.isEmpty && sub.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GestureDetector(
        onTap: () async {
          if (link.startsWith('http')) {
            final uri = Uri.parse(link);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } else if (link.isNotEmpty) {
            Navigator.pushNamed(context, link);
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B2416), Color(0xFF1A6B3A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Raleway',
                        ),
                      ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        sub,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        maxLines: 2,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _parseColor(ctaColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cta,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
