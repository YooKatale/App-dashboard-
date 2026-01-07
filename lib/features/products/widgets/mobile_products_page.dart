import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../home_page/notifiers/product_notifier.dart';
import '../../common/widgets/custom_appbar.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import '../../common/models/products_model.dart';
import 'mobile_product_card.dart';
import 'product_detail_page.dart';

class MobileProductsPage extends ConsumerWidget {
  final String title;
  final String? category;
  final String? searchQuery;

  const MobileProductsPage({
    super.key,
    required this.title,
    this.category,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productProvider = category != null
        ? ref.watch(fruitProvider)
        : ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 1),
      body: productProvider.when(
        data: (products) {
          // Filter products by search query if provided
          List<PopularDetails> filteredProducts = products.popularProducts;
          if (searchQuery != null && searchQuery!.trim().isNotEmpty) {
            final query = searchQuery!.toLowerCase().trim();
            filteredProducts = products.popularProducts.where((product) {
              // Search by title and price
              return product.title.toLowerCase().contains(query) ||
                  product.price.toLowerCase().contains(query);
            }).toList();
          }

          if (filteredProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    searchQuery != null && searchQuery!.trim().isNotEmpty
                        ? Icons.search_off
                        : Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    searchQuery != null && searchQuery!.trim().isNotEmpty
                        ? 'No products found for "$searchQuery"'
                        : 'No products available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontFamily: 'Raleway',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.60, // Adjusted for fixed-height content to prevent overflow
              crossAxisSpacing: 16, // Increased spacing so cards don't touch
              mainAxisSpacing: 16, // Increased spacing so cards don't touch
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return MobileProductCard(
                product: product,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(
                        productId: product.actualId ?? product.id.toString(),
                        product: product,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading products',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontFamily: 'Raleway',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.refresh(category != null ? fruitProvider : productsProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color.fromRGBO(24, 95, 45, 1),
          ),
        ),
      ),
    );
  }
}
