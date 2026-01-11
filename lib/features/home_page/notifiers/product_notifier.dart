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
  (ref) async => await ProductService.fetchProductsByCategory('grains and flour'),
);

final meatProvider = FutureProvider.autoDispose<Products>(
  (ref) async => await ProductService.fetchProductsByCategory('meat'),
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
