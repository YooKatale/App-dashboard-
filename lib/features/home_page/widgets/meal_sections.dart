import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/api_service.dart';

const _kPrimary = Color(0xFF0B2416);
const _kAccent  = Color(0xFF2ECC71);

final mealsProvider = StateProvider<String>((ref) => 'breakfast');

final _mealSlotsProvider = FutureProvider<Map<String, List<Map<String, dynamic>>>>((ref) async {
  final res = await ApiService.fetchMealSlotsPublic();
  final slots = (res['data'] ?? res['slots'] ?? res) as List? ?? [];
  final Map<String, List<Map<String, dynamic>>> grouped = {
    'breakfast': [],
    'lunch': [],
    'supper': [],
  };
  for (final slot in slots) {
    final s = slot is Map ? Map<String, dynamic>.from(slot as Map) : <String, dynamic>{};
    final type = (s['mealType'] ?? s['type'] ?? '').toString().toLowerCase();
    if (grouped.containsKey(type)) {
      grouped[type]!.add(s);
    } else if (type.contains('break')) {
      grouped['breakfast']!.add(s);
    } else if (type.contains('lunch') || type.contains('dinner')) {
      grouped['lunch']!.add(s);
    } else if (type.contains('supp') || type.contains('dinner')) {
      grouped['supper']!.add(s);
    }
  }
  return grouped;
});

class MealSectionsWidget extends ConsumerWidget {
  const MealSectionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealSlotsAsync = ref.watch(_mealSlotsProvider);

    return mealSlotsAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: _kPrimary)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (grouped) {
        final breakfast = grouped['breakfast']!;
        final lunch = grouped['lunch']!;
        final supper = grouped['supper']!;

        if (breakfast.isEmpty && lunch.isEmpty && supper.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            const SizedBox(height: 4),
            if (breakfast.isNotEmpty)
              _MealSection(
                title: 'Breakfast',
                icon: Icons.sunny_snowing,
                color: Color(0xFFe07820),
                meals: breakfast,
              ),
            if (lunch.isNotEmpty)
              _MealSection(
                title: 'Lunch',
                icon: Icons.restaurant_menu_rounded,
                color: _kPrimary,
                meals: lunch,
              ),
            if (supper.isNotEmpty)
              _MealSection(
                title: 'Supper',
                icon: Icons.nights_stay_rounded,
                color: Color(0xFF7c3aed),
                meals: supper,
              ),
          ],
        );
      },
    );
  }
}

class _MealSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> meals;

  const _MealSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.meals,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0A0F0C),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/subscription'),
                child: Row(
                  children: [
                    const Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kAccent,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: _kAccent),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Meals horizontal scroll
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
              return _MealCard(meal: meal, accentColor: color);
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  final Color accentColor;

  const _MealCard({required this.meal, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final name  = meal['name']?.toString() ?? meal['title']?.toString() ?? 'Meal';
    final type  = meal['mealType']?.toString() ?? meal['type']?.toString() ?? '';
    final image = meal['image']?.toString() ?? meal['imageUrl']?.toString() ?? '';
    final price = meal['price'] ?? meal['basePrice'];
    final priceStr = price != null ? 'UGX ${(price as num).toInt()}' : '';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/subscription'),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with gradient overlay
            SizedBox(
              height: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: image, fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: accentColor.withOpacity(0.12),
                              child: Icon(Icons.restaurant_rounded, color: accentColor.withOpacity(0.4), size: 32)),
                          errorWidget: (_, __, ___) => Container(color: accentColor.withOpacity(0.12),
                              child: Icon(Icons.restaurant_rounded, color: accentColor.withOpacity(0.4), size: 32)),
                        )
                      : Container(color: accentColor.withOpacity(0.12),
                          child: Icon(Icons.restaurant_rounded, color: accentColor.withOpacity(0.4), size: 32)),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
                      ),
                    ),
                  ),
                  // Meal type badge
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        type.isNotEmpty ? type.replaceAll('_', ' ') : 'Meal',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0A0F0C), height: 1.2),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                if (priceStr.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(priceStr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accentColor)),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Subscribe', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accentColor)),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded, size: 10, color: accentColor),
                  ]),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
