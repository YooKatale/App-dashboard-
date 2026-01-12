import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/api_service.dart';
import '../../products/widgets/mobile_products_page.dart';
import '../../products/widgets/mobile_product_card.dart';
import '../../common/models/products_model.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import '../../common/widgets/custom_appbar.dart';

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
        
        setState(() {
          _categories = categoryMap.values.toList();
          if (_categories.isNotEmpty && _selectedCategory == null) {
            _selectedCategory = _categories[0]['name']?.toString();
            _loadProductsForCategory(_selectedCategory!);
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
        _loadProductsForCategory('Supermarket');
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
        
        // Apply sorting if selected
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(context),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 1),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Left Sidebar - Categories List with Sort Filter
                Container(
                  width: 120,
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      // Categories Heading
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(24, 95, 45, 1),
                        ),
                        child: const Text(
                          'Categories',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Raleway',
                          ),
                        ),
                      ),
                      
                      // Sort by Price Filter
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sort by Price',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _sortBy = _sortBy == 'low-to-high' ? null : 'low-to-high';
                                  if (_selectedCategory != null) {
                                    _loadProductsForCategory(_selectedCategory!);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: _sortBy == 'low-to-high' 
                                      ? const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _sortBy == 'low-to-high'
                                        ? const Color.fromRGBO(24, 95, 45, 1)
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_downward,
                                      size: 14,
                                      color: _sortBy == 'low-to-high'
                                          ? const Color.fromRGBO(24, 95, 45, 1)
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    const Expanded(
                                      child: Text(
                                        'Low to High',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _sortBy = _sortBy == 'high-to-low' ? null : 'high-to-low';
                                  if (_selectedCategory != null) {
                                    _loadProductsForCategory(_selectedCategory!);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: _sortBy == 'high-to-low' 
                                      ? const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _sortBy == 'high-to-low'
                                        ? const Color.fromRGBO(24, 95, 45, 1)
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_upward,
                                      size: 14,
                                      color: _sortBy == 'high-to-low'
                                          ? const Color.fromRGBO(24, 95, 45, 1)
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    const Expanded(
                                      child: Text(
                                        'High to Low',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Categories List
                      Expanded(
                        child: ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final name = category['name']?.toString() ?? 'Category';
                      // Ensure first letter is capitalized
                      final displayName = name.isEmpty 
                          ? name 
                          : name[0].toUpperCase() + (name.length > 1 ? name.substring(1) : '');
                      final isSelected = _selectedCategory?.toLowerCase() == name.toLowerCase();
                      
                      return GestureDetector(
                        onTap: () => _loadProductsForCategory(name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            border: isSelected
                                ? const Border(
                                    left: BorderSide(
                                      color: Color.fromRGBO(24, 95, 45, 1),
                                      width: 3,
                                    ),
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                displayName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color.fromRGBO(24, 95, 45, 1)
                                      : Colors.black87,
                                ),
                                maxLines: 2,
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
                ),
                
                // Right Side - Products Grid
                Expanded(
                  child: Column(
                    children: [
                      // Header with "All Products" button
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedCategory ?? 'Products',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MobileProductsPage(
                                      title: _selectedCategory ?? 'All Products',
                                      category: _selectedCategory?.toLowerCase(),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              label: const Text('All Products'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color.fromRGBO(24, 95, 45, 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Products Grid
                      Expanded(
                        child: _isLoadingProducts
                            ? const Center(child: CircularProgressIndicator())
                            : _products.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
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
                                    padding: const EdgeInsets.all(12),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16, // Increased spacing so cards don't touch
                                      mainAxisSpacing: 16, // Increased spacing so cards don't touch
                                      childAspectRatio: 0.60, // Adjusted for fixed-height content
                                    ),
                                    itemCount: _products.length,
                                    itemBuilder: (context, index) {
                                      final product = _products[index];
                                      final name = product['name']?.toString() ??
                                          product['title']?.toString() ??
                                          'Product';
                                      final image = product['images'] != null
                                          ? (product['images'] is List &&
                                                  (product['images'] as List)
                                                      .isNotEmpty
                                              ? product['images'][0]
                                              : product['images'])
                                          : product['image'] ?? '';
                                      final isNetworkImage = image
                                              .toString()
                                              .startsWith('http://') ||
                                          image.toString().startsWith('https://');

                                      // Use MobileProductCard for consistency
                                      final productModel = PopularDetails(
                                        id: int.tryParse((product['_id'] ?? product['id'] ?? '0').toString()) ?? 0,
                                        title: name,
                                        price: (product['price'] ?? '0').toString(),
                                        image: image.toString(),
                                        per: product['per']?.toString(),
                                      );
                                      
                                      return MobileProductCard(
                                        product: productModel,
                                        showAddButton: true, // Enable Add button on categories page
                                        onTap: () {
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
                ),
              ],
            ),
    );
  }
}
