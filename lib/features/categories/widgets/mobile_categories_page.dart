import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/api_service.dart';
import '../../products/widgets/mobile_products_page.dart';
import '../../products/widgets/mobile_product_card.dart';
import '../../common/models/products_model.dart';
import '../../common/widgets/bottom_navigation_bar.dart';

class MobileCategoriesPage extends ConsumerStatefulWidget {
  const MobileCategoriesPage({super.key});

  @override
  ConsumerState<MobileCategoriesPage> createState() =>
      _MobileCategoriesPageState();
}

class _MobileCategoriesPageState extends ConsumerState<MobileCategoriesPage> {
  List<dynamic> _categories = [];
  List<dynamic> _products = [];
  String? _selectedCategory;
  bool _isLoading = true;
  bool _isLoadingProducts = false;
  String? _sortBy; // 'low-to-high' or 'high-to-low'

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
            final capitalizedCategory = category.isEmpty
                ? category
                : category[0].toUpperCase() + category.substring(1).toLowerCase();

            categoryMap[category] = {
              'name': capitalizedCategory,
              'image': product['images'] != null
                  ? (product['images'] is List &&
                          (product['images'] as List).isNotEmpty
                      ? product['images'][0]
                      : product['images'])
                  : product['image'] ?? '',
            };
          }
        }

        setState(() {
          _categories = categoryMap.values.toList();
          if (_categories.isNotEmpty && _selectedCategory == null) {
            _selectedCategory = _categories[0]['name']?.toString();
          }
          _isLoading = false;
        });
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
      ];
      if (_selectedCategory == null) {
        _selectedCategory = 'Supermarket';
      }
      _isLoading = false;
    });
  }

  Future<void> _loadProductsForCategory(String category) async {
    setState(() {
      _isLoadingProducts = true;
      _selectedCategory = category;
    });

    try {
      final response = await ApiService.fetchProducts();

      if (response['status'] == 'Success' && response['data'] != null) {
        final allProducts = response['data'] is List
            ? response['data'] as List
            : [response['data']];

        final filtered = allProducts.where((product) {
          final productCategory = product['category']?.toString().toLowerCase();
          return productCategory == category.toLowerCase();
        }).toList();

        final sorted = _sortProducts(filtered);

        setState(() {
          _products = sorted;
          _isLoadingProducts = false;
        });
      } else {
        setState(() {
          _products = [];
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      setState(() {
        _products = [];
        _isLoadingProducts = false;
      });
    }
  }

  List<dynamic> _sortProducts(List<dynamic> products) {
    if (_sortBy == null) return products;

    final sorted = List<dynamic>.from(products);
    sorted.sort((a, b) {
      final priceA = double.tryParse(a['price']?.toString() ?? '0') ?? 0.0;
      final priceB = double.tryParse(b['price']?.toString() ?? '0') ?? 0.0;

      if (_sortBy == 'low-to-high') {
        return priceA.compareTo(priceB);
      } else {
        return priceB.compareTo(priceA);
      }
    });

    return sorted;
  }

  void _openCategoryBottomSheet(String categoryName) {
    _loadProductsForCategory(categoryName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 4),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Sheet header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              categoryName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: 'Raleway',
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      // Sort chips
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Text(
                              'Sort:',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(width: 10),
                            _sortChipSheet('Low to High', 'low-to-high', setSheetState),
                            const SizedBox(width: 8),
                            _sortChipSheet('High to Low', 'high-to-low', setSheetState),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MobileProductsPage(
                                      title: categoryName,
                                      category: categoryName.toLowerCase(),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward_ios, size: 13),
                              label: const Text('All'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color.fromRGBO(24, 95, 45, 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Products grid
                      Expanded(
                        child: _isLoadingProducts
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color.fromRGBO(24, 95, 45, 1),
                                ),
                              )
                            : _products.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.inventory_2_outlined,
                                            size: 64, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No products in this category',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    controller: scrollController,
                                    padding: const EdgeInsets.all(12),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.60,
                                    ),
                                    itemCount: _products.length,
                                    itemBuilder: (context, index) {
                                      final product = _products[index];
                                      final name = product['name']?.toString() ??
                                          product['title']?.toString() ??
                                          'Product';
                                      final image = product['images'] != null
                                          ? (product['images'] is List &&
                                                  (product['images'] as List).isNotEmpty
                                              ? product['images'][0]
                                              : product['images'])
                                          : product['image'] ?? '';
                                      final productModel = PopularDetails(
                                        id: int.tryParse((product['_id'] ??
                                                    product['id'] ??
                                                    '0')
                                                .toString()) ??
                                            0,
                                        title: name,
                                        price: (product['price'] ?? '0').toString(),
                                        image: image.toString(),
                                        per: product['per']?.toString(),
                                      );
                                      return MobileProductCard(
                                        product: productModel,
                                        showAddButton: true,
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.pushNamed(
                                            context,
                                            '/product-detail/${product['_id'] ?? product['id']}',
                                          );
                                        },
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 0),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(24, 95, 45, 1),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Shop by Category',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            fontFamily: 'Raleway',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 3,
                          width: 60,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(24, 95, 45, 1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap a category to browse products',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontFamily: 'Raleway',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2-column grid of category cards
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final name = category['name']?.toString() ?? 'Category';
                      final displayName = name.isEmpty
                          ? name
                          : name[0].toUpperCase() +
                              (name.length > 1 ? name.substring(1) : '');
                      final image = category['image']?.toString() ?? '';

                      return GestureDetector(
                        onTap: () => _openCategoryBottomSheet(name),
                        child: Container(
                          height: 130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Background image or gradient
                                if (image.isNotEmpty && image.startsWith('http'))
                                  CachedNetworkImage(
                                    imageUrl: image,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _categoryGradientBg(index),
                                  )
                                else
                                  _categoryGradientBg(index),

                                // Bottom gradient overlay
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: 70,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Color.fromRGBO(0, 0, 0, 0.65),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Category name at bottom-left
                                Positioned(
                                  bottom: 10,
                                  left: 12,
                                  right: 8,
                                  child: Text(
                                    displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Raleway',
                                      shadows: [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _categoryGradientBg(int index) {
    final gradients = [
      [const Color.fromRGBO(24, 95, 45, 1), const Color.fromRGBO(40, 140, 70, 1)],
      [const Color(0xFF2196F3), const Color(0xFF21CBF3)],
      [const Color(0xFFFF6B35), const Color(0xFFFFB347)],
      [const Color(0xFF9C27B0), const Color(0xFFE91E63)],
      [const Color(0xFF00897B), const Color(0xFF26C6DA)],
      [const Color(0xFFE53935), const Color(0xFFFF8A65)],
    ];
    final g = gradients[index % gradients.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: g,
        ),
      ),
      child: const Center(
        child: Icon(Icons.category, color: Colors.white54, size: 48),
      ),
    );
  }

  Widget _sortChipSheet(String label, String value, StateSetter setSheetState) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setSheetState(() {
          _sortBy = _sortBy == value ? null : value;
          if (_selectedCategory != null) _loadProductsForCategory(_selectedCategory!);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromRGBO(24, 95, 45, 1).withValues(alpha: 0.15)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color.fromRGBO(24, 95, 45, 1)
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color.fromRGBO(24, 95, 45, 1) : Colors.black87,
          ),
        ),
      ),
    );
  }
}
