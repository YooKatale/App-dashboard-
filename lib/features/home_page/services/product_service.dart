import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';
import '../../../services/api_service.dart';
import '../../common/models/products_model.dart';

class ProductService {
  // Fetch products from API (preferred method)
  static Future<Products> fetchProductsFromApi() async {
    try {
      log('Fetching products from API...');
      final response = await ApiService.fetchProducts();
      
      if (response['status'] == 'Success' && response['data'] != null) {
        // Transform API response to match Products model
        final data = response['data'];
        List<dynamic> productList = [];
        
        // Handle both array and object formats
        if (data is List) {
          productList = data;
        } else if (data is Map && data.containsKey('products')) {
          productList = data['products'] as List;
        } else {
          productList = [data];
        }
        
        final products = productList
            .map((product) {
              // Handle different image formats (array or string)
              String imageUrl = '';
              if (product['images'] != null) {
                if (product['images'] is List && (product['images'] as List).isNotEmpty) {
                  imageUrl = product['images'][0]?.toString() ?? '';
                } else if (product['images'] is String) {
                  imageUrl = product['images'];
                }
              }
              
              return PopularDetails(
                id: product['_id']?.toString().hashCode ?? 
                    product['id']?.toString().hashCode ?? 
                    DateTime.now().millisecondsSinceEpoch,
                image: imageUrl.isEmpty 
                    ? (product['image']?.toString() ?? '') 
                    : imageUrl,
                title: product['name']?.toString() ?? 'Product',
                price: product['price']?.toString() ?? '0',
                per: product['unit']?.toString() ?? '',
                actualId: product['_id']?.toString() ?? product['id']?.toString(), // Store actual _id for API calls
              );
            })
            .toList();
        
        return Products(popularProducts: products);
      } else {
        throw Exception('Invalid API response format');
      }
    } catch (e) {
      log('Error fetching from API: $e, falling back to JSON');
      // Fallback to local JSON if API fails
      try {
        return await fetchProducts(url: 'assets/popular_products.json');
      } catch (jsonError) {
        log('Error loading fallback JSON: $jsonError');
        // Return empty products if both fail
        return Products(popularProducts: []);
      }
    }
  }

  // Fetch products from local JSON (fallback)
  static Future<Products> fetchProducts({String? url}) async {
    log('Url: $url');
    final jsonString = await rootBundle.loadString(url!);
    final data = jsonDecode(jsonString);
    return Products.fromJson(data);
  }

  // Fetch products by category from API
  static Future<Products> fetchProductsByCategory(String category) async {
    try {
      log('Fetching products by category: $category');
      final response = await ApiService.fetchProductsByCategory(category);
      
      if (response['status'] == 'Success' && response['data'] != null) {
        final data = response['data'];
        List<dynamic> productList = [];
        
        if (data is List) {
          productList = data;
        } else if (data is Map && data.containsKey('products')) {
          productList = data['products'] as List;
        } else {
          productList = [data];
        }
        
        final products = productList
            .map((product) {
              String imageUrl = '';
              if (product['images'] != null) {
                if (product['images'] is List && (product['images'] as List).isNotEmpty) {
                  imageUrl = product['images'][0]?.toString() ?? '';
                } else if (product['images'] is String) {
                  imageUrl = product['images'];
                }
              }
              
              return PopularDetails(
                id: product['_id']?.toString().hashCode ?? 
                    product['id']?.toString().hashCode ?? 
                    DateTime.now().millisecondsSinceEpoch,
                image: imageUrl.isEmpty 
                    ? (product['image']?.toString() ?? '') 
                    : imageUrl,
                title: product['name']?.toString() ?? 'Product',
                price: product['price']?.toString() ?? '0',
                per: product['unit']?.toString() ?? '',
                actualId: product['_id']?.toString() ?? product['id']?.toString(), // Store actual _id for API calls
              );
            })
            .toList();
        
        return Products(popularProducts: products);
      } else {
        throw Exception('Invalid API response format');
      }
    } catch (e) {
      log('Error fetching category products: $e');
      // Fallback to JSON for fruits
      if (category.toLowerCase() == 'fruits') {
        try {
          return await fetchProducts(url: 'assets/fruit_products.json');
        } catch (jsonError) {
          log('Error loading fallback JSON: $jsonError');
          return Products(popularProducts: []);
        }
      }
      rethrow;
    }
  }

  /// Fetch products filtered by budget (low/middle/high).
  /// Backend /products/filter may not support budget; we filter client-side by price.
  static Future<Products> fetchProductsFiltered(String budget) async {
    final all = await fetchProductsFromApi();
    if (budget.isEmpty) return all;
    // Price ranges (UGX): low < 10000, middle 10000-50000, high > 50000
    final filtered = all.popularProducts.where((p) {
      final price = double.tryParse(p.price) ?? 0;
      switch (budget.toLowerCase()) {
        case 'low': return price < 10000;
        case 'middle': return price >= 10000 && price <= 50000;
        case 'high': return price > 50000;
        default: return true;
      }
    }).toList();
    return Products(popularProducts: filtered);
  }

  /// Fetch categories from API
  static Future<List<Map<String, dynamic>>> fetchCategoriesFromApi() async {
    try {
      final response = await ApiService.fetchCategories();
      if (response['success'] == true && response['categories'] != null) {
        final cats = response['categories'] as List;
        return cats.map((c) => c is Map ? Map<String, dynamic>.from(c as Map) : <String, dynamic>{}).toList();
      }
      return [];
    } catch (e) {
      log('Error fetching categories: $e');
      return [];
    }
  }
}
