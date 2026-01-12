import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../common/models/products_model.dart';
import '../services/product_service.dart';

// Fetch products from API (syncs with backend) - Used for Latest Products
final productsProvider = FutureProvider.autoDispose<Products>((ref) async {
  return await ProductService.fetchProductsFromApi();
});

// Fetch popular products from API - Same as productsProvider but can be customized later
final popularProductsProvider = FutureProvider.autoDispose<Products>((ref) async {
  return await ProductService.fetchProductsFromApi();
});

// Fetch fruits from API (using category filter)
final fruitProvider = FutureProvider.autoDispose<Products>(
  (ref) async => await ProductService.fetchProductsByCategory('fruits'),
);

// Fetch all categories for mobile app (like webapp)
final vegetablesProvider = FutureProvider.autoDispose<Products>(
  (ref) async => await ProductService.fetchProductsByCategory('vegetables'),
);

final grainsProvider = FutureProvider.autoDispose<Products>(
  (ref) async {
    // Try multiple category name variations (case-insensitive matching on backend)
    final variations = [
      'grains & flour',      // Most common format
      'Grains & Flour',      // Capitalized
      'grains and flour',    // With "and"
      'Grains and Flour',    // Capitalized with "and"
      'grain & flour',       // Singular grain
      'grains',              // Just grains
      'Grains',              // Capitalized
      'flour',               // Just flour
      'Flour',               // Capitalized
    ];
    
    for (final category in variations) {
      try {
        final result = await ProductService.fetchProductsByCategory(category);
        // Check if we got products
        if (result.popularProducts.isNotEmpty) {
          return result;
        }
      } catch (e) {
        // Try next variation
        continue;
      }
    }
    
    // If all variations fail, return empty products
    return Products(popularProducts: []);
  },
);

final meatProvider = FutureProvider.autoDispose<Products>(
  (ref) async {
    // Try multiple category name variations
    final variations = [
      'meat',      // Singular
      'Meat',      // Capitalized
      'meats',     // Plural
      'Meats',     // Capitalized plural
    ];
    
    for (final category in variations) {
      try {
        final result = await ProductService.fetchProductsByCategory(category);
        // Check if we got products
        if (result.popularProducts.isNotEmpty) {
          return result;
        }
      } catch (e) {
        // Try next variation
        continue;
      }
    }
    
    // If all variations fail, return empty products
    return Products(popularProducts: []);
  },
);

final dairyProvider = FutureProvider.autoDispose<Products>(
  (ref) async => await ProductService.fetchProductsByCategory('dairy'),
);

final rootProvider = FutureProvider.autoDispose<Products>(
  (ref) async => await ProductService.fetchProductsByCategory('root'),
);

final juiceProvider = FutureProvider.autoDispose<Products>(
  (ref) async => await ProductService.fetchProductsByCategory('juice'),
);

// Fetch categories - keep using local JSON for category list
final categoriesProvider = FutureProvider.autoDispose<Products>(
  (ref) async =>
      await ProductService.fetchProducts(url: 'assets/categories.json'),
);

// Fetch desktop popular products from API
final desktopPopular = FutureProvider.autoDispose<Products>(
  (ref) async => await ProductService.fetchProductsFromApi(),
);
