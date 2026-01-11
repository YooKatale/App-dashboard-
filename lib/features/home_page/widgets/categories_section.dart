import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/api_service.dart';
import '../../categories/widgets/mobile_categories_page.dart';

class CategoriesSection extends ConsumerStatefulWidget {
  const CategoriesSection({super.key});

  @override
  ConsumerState<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends ConsumerState<CategoriesSection> {
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await ApiService.fetchProducts();
      
      if (response['status'] == 'Success' && response['data'] != null) {
        final products = response['data'] is List 
            ? response['data'] as List 
            : [response['data']];
        
        // Get unique categories
        final categoryMap = <String, dynamic>{};
        for (var product in products) {
          final category = product['category']?.toString();
          if (category != null && !categoryMap.containsKey(category)) {
            // Capitalize first letter of category name
            final capitalizedCategory = category.isEmpty 
                ? category 
                : category[0].toUpperCase() + category.substring(1).toLowerCase();
            
            categoryMap[category] = {
              'name': capitalizedCategory,
              'image': product['images'] != null 
                  ? (product['images'] is List && (product['images'] as List).isNotEmpty
                      ? product['images'][0]
                      : product['images'])
                  : product['image'] ?? '',
            };
          }
        }
        
        if (mounted) {
          setState(() {
            _categories = categoryMap.values.toList();
            _isLoading = false;
          });
        }
      } else {
        _setDefaultCategories();
      }
    } catch (e) {
      _setDefaultCategories();
    }
  }

  void _setDefaultCategories() {
    if (!mounted) return;
    setState(() {
      _categories = [
        {'name': 'Supermarket', 'image': ''},
        {'name': 'Fruits', 'image': ''},
        {'name': 'Vegetables', 'image': ''},
        {'name': 'Grains', 'image': ''},
        {'name': 'Meat', 'image': ''},
        {'name': 'Dairy', 'image': ''},
        {'name': 'Root', 'image': ''},
        {'name': 'Promotional', 'image': ''},
        {'name': 'Discover', 'image': ''},
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            color: Color.fromRGBO(24, 95, 45, 1),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color.fromRGBO(0, 0, 0, 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shop by Category',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    Container(
                      height: 2.5,
                      width: 80,
                      color: const Color.fromRGBO(24, 95, 45, 1),
                    )
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MobileCategoriesPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color.fromRGBO(24, 95, 45, 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final categoryName = category['name']?.toString() ?? '';
                final categoryImage = category['image']?.toString() ?? '';
                
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 90,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MobileCategoriesPage(),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.1),
                                const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color.fromRGBO(24, 95, 45, 1).withValues(alpha: 0.2),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: categoryImage.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    categoryImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        Icons.category,
                                        color: const Color.fromRGBO(24, 95, 45, 1),
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.category,
                                    color: const Color.fromRGBO(24, 95, 45, 1),
                                    size: 32,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
