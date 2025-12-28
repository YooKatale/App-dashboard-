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
}
