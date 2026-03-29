import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/api_service.dart';
import '../../categories/widgets/mobile_categories_page.dart';
import '../../products/widgets/mobile_products_page.dart';

const _kPrimary = Color(0xFF0B2416);
const _kAccent  = Color(0xFF2ECC71);

// ── Provider ──────────────────────────────────────────────────────────────────
final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final data = await ApiService.fetchCategories();
    final list = data['categories'] as List? ?? data['data'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  } catch (_) {
    return [];
  }
});

// ── 15 fallback categories matching webapp CategoriesJson exactly ─────────────
const _kFallback = [
  {'name': 'Vitamins',       'bg1': Color(0xFFE8F9F1), 'bg2': Color(0xFFD0F0E0), 'iconColor': Color(0xFF1A7A4A), 'navCategory': 'vitamins'},
  {'name': 'Protein',        'bg1': Color(0xFFFFF8E6), 'bg2': Color(0xFFFFF3D0), 'iconColor': Color(0xFFC9921F), 'navCategory': 'protein'},
  {'name': 'Dairy',          'bg1': Color(0xFFE6F6F8), 'bg2': Color(0xFFCCEEF2), 'iconColor': Color(0xFF0E7490), 'navCategory': 'dairy'},
  {'name': 'Vegetables',     'bg1': Color(0xFFF0FCE8), 'bg2': Color(0xFFD8F5BC), 'iconColor': Color(0xFF3A7A1A), 'navCategory': 'vegetables'},
  {'name': 'Fats & Oils',    'bg1': Color(0xFFFEF4E8), 'bg2': Color(0xFFFDE3C0), 'iconColor': Color(0xFFB04010), 'navCategory': 'fats'},
  {'name': 'Root Tubers',    'bg1': Color(0xFFFDE8E8), 'bg2': Color(0xFFFAD0CC), 'iconColor': Color(0xFFB91C1C), 'navCategory': 'root'},
  {'name': 'Carbohydrates',  'bg1': Color(0xFFE8F1FD), 'bg2': Color(0xFFD0E4FA), 'iconColor': Color(0xFF1A4A8A), 'navCategory': 'grains'},
  {'name': 'Herbs & Spices', 'bg1': Color(0xFFEFF8E8), 'bg2': Color(0xFFD8F0BC), 'iconColor': Color(0xFF2D7A1A), 'navCategory': 'herbs'},
  {'name': 'Breakfast',      'bg1': Color(0xFFF0F0FE), 'bg2': Color(0xFFD8D8FC), 'iconColor': Color(0xFFA040A0), 'navCategory': 'breakfast'},
  {'name': 'Markets',        'bg1': Color(0xFFF0F4FE), 'bg2': Color(0xFFD8E4FC), 'iconColor': Color(0xFF1A4A8A), 'navCategory': null},
  {'name': 'Juice',          'bg1': Color(0xFFFFF3E0), 'bg2': Color(0xFFFFE0B2), 'iconColor': Color(0xFFF57C00), 'navCategory': 'juice'},
  {'name': 'Meals',          'bg1': Color(0xFFFCE4EC), 'bg2': Color(0xFFF8BBD0), 'iconColor': Color(0xFFC62828), 'navCategory': 'meals'},
  {'name': 'Cuisines',       'bg1': Color(0xFFE8F9F1), 'bg2': Color(0xFFD0F0E0), 'iconColor': Color(0xFF1A7A4A), 'navCategory': null},
  {'name': 'Kitchen',        'bg1': Color(0xFFF3E5F5), 'bg2': Color(0xFFE1BEE7), 'iconColor': Color(0xFF6A1B9A), 'navCategory': 'kitchen'},
  {'name': 'Supplements',    'bg1': Color(0xFFFFF8E6), 'bg2': Color(0xFFFFF3D0), 'iconColor': Color(0xFFC9921F), 'navCategory': null},
];

class CategoriesSection extends ConsumerStatefulWidget {
  const CategoriesSection({super.key});

  @override
  ConsumerState<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends ConsumerState<CategoriesSection> {
  final ScrollController _scroll = ScrollController();
  Timer? _timer;
  double _offset = 0;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), _startScroll);
  }

  void _startScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (_paused || !mounted || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (max <= 0) return;
      _offset += 0.6;
      if (_offset >= max) _offset = 0;
      _scroll.jumpTo(_offset);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onTapBackend(BuildContext context, Map<String, dynamic> cat) {
    final name = cat['name']?.toString() ?? '';
    final slug = cat['slug']?.toString() ?? cat['category']?.toString() ?? name.toLowerCase();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MobileProductsPage(title: name, category: slug),
      ),
    );
  }

  void _onTapFallback(BuildContext context, Map cat) {
    final navCategory = cat['navCategory'] as String?;
    if (navCategory != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MobileProductsPage(title: cat['name'] as String, category: navCategory),
        ),
      );
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileCategoriesPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Shop by Category',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0A0F0C), letterSpacing: -0.2),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileCategoriesPage())),
                  child: const Row(
                    children: [
                      Text('View all', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _kAccent)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, size: 11, color: _kAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Category tiles
          Listener(
            onPointerDown: (_) => _paused = true,
            onPointerUp: (_) => Future.delayed(const Duration(seconds: 2), () => _paused = false),
            child: SizedBox(
              height: 98,
              child: categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return _FallbackList(scroll: _scroll, onTap: _onTapFallback);
                  }
                  return ListView.builder(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      final name = cat['name']?.toString() ?? '';
                      final imageUrl = cat['image']?.toString() ?? cat['imageUrl']?.toString() ?? '';
                      final fallback = _kFallback[i % _kFallback.length];

                      return GestureDetector(
                        onTap: () => _onTapBackend(context, cat),
                        child: Container(
                          width: 74,
                          margin: const EdgeInsets.only(right: 10),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      fallback['bg1'] as Color,
                                      fallback['bg2'] as Color,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Icon(
                                            _catIcon(i),
                                            color: fallback['iconColor'] as Color,
                                            size: 26,
                                          ),
                                          errorWidget: (_, __, ___) => Icon(
                                            _catIcon(i),
                                            color: fallback['iconColor'] as Color,
                                            size: 26,
                                          ),
                                        ),
                                      )
                                    : Icon(_catIcon(i), color: fallback['iconColor'] as Color, size: 26),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                name,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF3D5245)),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => _FallbackList(scroll: _scroll, onTap: _onTapFallback),
                error: (_, __) => _FallbackList(scroll: _scroll, onTap: _onTapFallback),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fallback static list ───────────────────────────────────────────────────────
class _FallbackList extends StatelessWidget {
  final ScrollController scroll;
  final void Function(BuildContext, Map) onTap;
  const _FallbackList({required this.scroll, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scroll,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
      physics: const BouncingScrollPhysics(),
      itemCount: _kFallback.length,
      itemBuilder: (context, i) {
        final cat = _kFallback[i];
        return GestureDetector(
          onTap: () => onTap(context, cat),
          child: Container(
            width: 74,
            margin: const EdgeInsets.only(right: 10),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cat['bg1'] as Color, cat['bg2'] as Color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Icon(_catIcon(i), color: cat['iconColor'] as Color, size: 26),
                ),
                const SizedBox(height: 7),
                Text(
                  cat['name'] as String,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF3D5245)),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

IconData _catIcon(int i) {
  const icons = [
    Icons.eco_rounded,                    // Vitamins
    Icons.local_fire_department_rounded,  // Protein
    Icons.water_drop_rounded,             // Dairy
    Icons.grass_rounded,                  // Vegetables
    Icons.opacity_rounded,                // Fats & Oils
    Icons.hexagon_rounded,                // Root Tubers
    Icons.grain_rounded,                  // Carbohydrates
    Icons.spa_rounded,                    // Herbs & Spices
    Icons.free_breakfast_rounded,         // Breakfast
    Icons.storefront_rounded,             // Markets
    Icons.local_drink_rounded,            // Juice
    Icons.restaurant_rounded,             // Meals
    Icons.public_rounded,                 // Cuisines
    Icons.kitchen_rounded,                // Kitchen
    Icons.medication_rounded,             // Supplements
  ];
  return icons[i % icons.length];
}
