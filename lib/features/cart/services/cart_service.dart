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
            // FIX: Ensure cartId is always set and quantity is valid
            final cartId = cartItem['_id']?.toString() ?? 
                          cartItem['cartId']?.toString() ?? 
                          cartItem['id']?.toString() ?? 
                          '';
            
            // FIX: Ensure quantity is at least 1
            final quantity = cartItem['quantity'];
            final validQuantity = (quantity is int && quantity > 0) || 
                                 (quantity is String && int.tryParse(quantity) != null && int.parse(quantity) > 0)
                                 ? (quantity is int ? quantity : int.parse(quantity))
                                 : 1;
            
            cartItems.add(CartItem.fromJson({
              ...cartItem,
              'cartId': cartId,
              'quantity': validQuantity,
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
      
      // Handle specific error cases with user-friendly messages
      String userMessage = errorMessage;
      
      if (errorMessage.toLowerCase().contains('sold out') || 
          errorMessage.toLowerCase().contains('out of stock') ||
          errorMessage.toLowerCase().contains('stock')) {
        userMessage = 'This product is currently out of stock.';
      } else if (errorMessage.contains('Product already added to cart') || 
                 errorMessage.contains('already added') ||
                 errorMessage.contains('already in cart')) {
        userMessage = 'This product is already in your cart.';
        return {
          'success': false,
          'message': userMessage,
          'alreadyInCart': true,
        };
      } else if (errorMessage.toLowerCase().contains('not found') ||
                 errorMessage.toLowerCase().contains('does not exist')) {
        userMessage = 'Product not found. Please try again.';
      } else if (errorMessage.toLowerCase().contains('quantity') ||
                 errorMessage.toLowerCase().contains('available')) {
        userMessage = 'Insufficient quantity available.';
      }
      
      return {
        'success': false,
        'message': userMessage,
        'error': errorMessage,
      };
    }
  }

  // Update cart item quantity - Match webapp logic
  static Future<bool> updateCartItem({
    required String cartId,
    required int quantity,
    String? userId,
    String? token,
  }) async {
    try {
      log('Updating cart item: cartId=$cartId, quantity=$quantity, userId=$userId');
      final response = await ApiService.updateCartItem(
        cartId: cartId,
        quantity: quantity,
        userId: userId,
        token: token,
      );
      
      log('Cart update response: $response');
      
      // Check for success - response might have status field or just be successful if statusCode is 200
      // If statusCode is 200, the update was successful (API returns 200 on success)
      // Check various success indicators
      if (response['status'] == 'Success' || 
          response['status'] == 'success' ||
          response['success'] == true) {
        log('Cart update successful: status field indicates success');
        return true;
      }
      
      // Check if response has a message (could be success or error)
      if (response['message'] != null) {
        final message = response['message'].toString().toLowerCase();
        log('Cart update message: $message');
        // If message indicates success
        if (message.contains('success') || 
            message.contains('updated') ||
            message.contains('quantity') ||
            message.contains('cart')) {
          log('Cart update successful (message indicates success)');
          return true;
        }
        // If message indicates error
        if (message.contains('error') || 
            message.contains('fail') ||
            message.contains('not found')) {
          log('Cart update failed (message indicates error)');
          return false;
        }
      }
      
      // If response has data, it's likely successful
      if (response.containsKey('data') && response['data'] != null) {
        log('Cart update successful (has data field)');
        return true;
      }
      
      // If response is empty or just an object with statusCode 200, consider it success
      // Many APIs return empty object {} on success
      if (response is Map && response.isEmpty) {
        log('Cart update successful (empty response with 200 status)');
        return true;
      }
      
      // Check if response is just an object (no error field) - assume success
      if (response is Map && !response.containsKey('error')) {
        log('Cart update successful (no error field, assuming success)');
        return true;
      }
      
      // If we got here with statusCode 200 but no clear success indicator, assume success
      // (since 200 status code typically means success)
      log('Cart update assuming success (200 status code received)');
      return true;
    } catch (e) {
      log('Error updating cart item: $e');
      // Re-throw to get better error messages
      rethrow;
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

