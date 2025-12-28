import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../common/models/products_model.dart';
import '../services/product_service.dart';

// Fetch products from API (syncs with backend)
final productsProvider = FutureProvider.autoDispose<Products>((ref) async {
  return await ProductService.fetchProductsFromApi();
});

// Fetch fruits from API (using category filter)
final fruitProvider = FutureProvider.autoDispose<Products>(
  (ref) async => await ProductService.fetchProductsByCategory('fruits'),
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
