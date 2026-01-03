import 'dart:developer';
import '../../../services/api_service.dart';
import '../models/cart_model.dart';

class CartService {
  // Fetch user's cart
  static Future<List<CartItem>> fetchCart(String userId, {String? token}) async {
    try {
      log('Fetching cart for user: $userId');
      final response = await ApiService.fetchCart(userId, token: token);
      
      if (response['status'] == 'Success' && response['data'] != null) {
        final data = response['data'];
        List<CartItem> cartItems = [];
        
        // Handle cart items and products
        final cartItemsData = data['CartItems'] as List<dynamic>? ?? [];
        final productsData = data['CartProductsItems'] as List<dynamic>? ?? [];
        
        // Combine cart items with product details
        for (var cartItem in cartItemsData) {
          final productId = cartItem['productId']?.toString();
          final product = productsData.firstWhere(
            (p) => p['_id']?.toString() == productId,
            orElse: () => <String, dynamic>{},
          );
          
          if (product.isNotEmpty) {
            cartItems.add(CartItem.fromJson({
              ...cartItem,
              'cartId': cartItem['_id'],
              ...product,
            }));
          }
        }
        
        return cartItems;
      } else {
        return [];
      }
    } catch (e) {
      log('Error fetching cart: $e');
      return [];
    }
  }

  // Add item to cart
  // Returns Map with 'success' boolean and optional 'message' and 'error'
  static Future<Map<String, dynamic>> addToCart({
    required String userId,
    required String productId,
    required int quantity,
    String? token,
  }) async {
    try {
      log('Adding to cart: productId=$productId, quantity=$quantity');
      final response = await ApiService.addToCart(
        userId: userId,
        productId: productId,
        quantity: quantity,
        token: token,
      );
      
      // EXACT WEBAPP LOGIC: Check response.status or response.message
      if (response['status'] == 'Success' || response['message'] != null) {
        return {
          'success': true,
          'message': response['message']?.toString() ?? 'Product added to cart',
        };
      }
      
      return {
        'success': false,
        'message': response['message']?.toString() ?? 'Failed to add to cart',
      };
    } catch (e) {
      log('Error adding to cart: $e');
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Handle specific error cases
      if (errorMessage.contains('Product already added to cart') || 
          errorMessage.contains('already added')) {
        return {
          'success': false,
          'message': 'Product already added to cart',
          'alreadyInCart': true,
        };
      }
      
      return {
        'success': false,
        'message': errorMessage,
        'error': errorMessage,
      };
    }
  }

  // Update cart item quantity
  static Future<bool> updateCartItem({
    required String cartId,
    required int quantity,
    String? token,
  }) async {
    try {
      log('Updating cart item: cartId=$cartId, quantity=$quantity');
      final response = await ApiService.updateCartItem(
        cartId: cartId,
        quantity: quantity,
        token: token,
      );
      
      return response['status'] == 'Success';
    } catch (e) {
      log('Error updating cart item: $e');
      return false;
    }
  }

  // Delete cart item
  static Future<bool> deleteCartItem(String cartId, {String? token}) async {
    try {
      log('Deleting cart item: cartId=$cartId');
      final response = await ApiService.deleteCartItem(cartId, token: token);
      
      return response['status'] == 'Success';
    } catch (e) {
      log('Error deleting cart item: $e');
      return false;
    }
  }

  // Calculate cart total
  static double calculateTotal(List<CartItem> cartItems) {
    return cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
}

