import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _kPrimary = Color(0xFF0B2416);
const _kAccent  = Color(0xFF2ECC71);

final mealsProvider = StateProvider<String>((ref) => 'breakfast');

class MealSectionsWidget extends ConsumerStatefulWidget {
  const MealSectionsWidget({super.key});

  @override
  ConsumerState<MealSectionsWidget> createState() => _MealSectionsState();
}

class _MealSectionsState extends ConsumerState<MealSectionsWidget> {
  final ScrollController _scrollController = ScrollController();

  // Dummy meal data - should come from backend in real app
  final List<Map<String, dynamic>> breakfast = [
    {'id': '1', 'name': 'Eggs & Bacon', 'type': 'Ready-to-eat', 'image': 'https://via.placeholder.com/150?text=Breakfast1'},
    {'id': '2', 'name': 'Pancakes', 'type': 'Ready-to-cook', 'image': 'https://via.placeholder.com/150?text=Breakfast2'},
    {'id': '3', 'name': 'Cereal', 'type': 'Ready-to-eat', 'image': 'https://via.placeholder.com/150?text=Breakfast3'},
  ];

  final List<Map<String, dynamic>> lunch = [
    {'id': '4', 'name': 'Grilled Chicken', 'type': 'Ready-to-cook', 'image': 'https://via.placeholder.com/150?text=Lunch1'},
    {'id': '5', 'name': 'Pasta Carbonara', 'type': 'Ready-to-eat', 'image': 'https://via.placeholder.com/150?text=Lunch2'},
    {'id': '6', 'name': 'Fish & Chips', 'type': 'Ready-to-eat', 'image': 'https://via.placeholder.com/150?text=Lunch3'},
  ];

  final List<Map<String, dynamic>> supper = [
    {'id': '7', 'name': 'Beef Stew', 'type': 'Ready-to-cook', 'image': 'https://via.placeholder.com/150?text=Supper1'},
    {'id': '8', 'name': 'Rice & Beans', 'type': 'Ready-to-eat', 'image': 'https://via.placeholder.com/150?text=Supper2'},
    {'id': '9', 'name': 'Grilled Vegetables', 'type': 'Ready-to-eat', 'image': 'https://via.placeholder.com/150?text=Supper3'},
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Budget level selector
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Budget Level:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Row(
                children: ['Low', 'Middle', 'High']
                    .asMap()
                    .entries
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: e.key == 1 ? _kPrimary : Colors.transparent,
                              border: Border.all(color: _kPrimary),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: e.key == 1 ? Colors.white : _kPrimary,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Breakfast section
        _MealSection(
          title: 'Breakfast',
          icon: Icons.sunny_snowing,
          color: Color(0xFFe07820),
          meals: breakfast,
        ),

        // Lunch section
        _MealSection(
          title: 'Lunch',
          icon: Icons.restaurant_menu_rounded,
          color: _kPrimary,
          meals: lunch,
        ),

        // Supper section
        _MealSection(
          title: 'Supper',
          icon: Icons.nights_stay_rounded,
          color: Color(0xFF7c3aed),
          meals: supper,
        ),
      ],
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
              return _MealCard(meal: meal);
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

  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/subscription'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 130,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: meal['image'] ?? '',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                ),
              ),

              // Info
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal['name'] ?? 'Meal',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A0F0C),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meal['type'] ?? 'Type',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
