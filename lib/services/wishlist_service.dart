/// Wishlist service - syncs with web wishlistSlice (localStorage).
/// Backend has NO wishlist API; both web and mobile use local storage.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const String _wishlistKey = 'yookatale-wishlist';

class WishlistService {
  /// Load wishlist items from local storage
  static Future<List<Map<String, dynamic>>> loadWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_wishlistKey);
      if (raw == null) return [];
      final parsed = json.decode(raw);
      if (parsed is! List) return [];
      return parsed
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Save wishlist items to local storage
  static Future<void> _saveWishlist(List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_wishlistKey, json.encode(items));
    } catch (_) {}
  }

  /// Add product to wishlist (matches web: { productId, product })
  static Future<void> addToWishlist(String productId, Map<String, dynamic>? product) async {
    final items = await loadWishlist();
    if (items.any((i) => (i['productId'] ?? i['product_id']) == productId)) return;
    items.add({'productId': productId, 'product': product});
    await _saveWishlist(items);
  }

  /// Remove product from wishlist
  static Future<void> removeFromWishlist(String productId) async {
    final items = await loadWishlist();
    items.removeWhere((i) => (i['productId'] ?? i['product_id']) == productId);
    await _saveWishlist(items);
  }

  /// Toggle product in wishlist
  static Future<bool> toggleWishlist(String productId, Map<String, dynamic>? product) async {
    final items = await loadWishlist();
    final idx = items.indexWhere((i) => (i['productId'] ?? i['product_id']) == productId);
    if (idx >= 0) {
      items.removeAt(idx);
      await _saveWishlist(items);
      return false;
    } else {
      items.add({'productId': productId, 'product': product});
      await _saveWishlist(items);
      return true;
    }
  }

  /// Check if product is in wishlist
  static Future<bool> isInWishlist(String productId) async {
    final items = await loadWishlist();
    return items.any((i) => (i['productId'] ?? i['product_id']) == productId);
  }
}
