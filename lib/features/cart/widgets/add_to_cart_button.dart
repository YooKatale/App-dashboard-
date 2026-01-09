import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/cart_service.dart';
import '../../authentication/providers/auth_provider.dart';

class AddToCartButton extends ConsumerStatefulWidget {
  final String productId;
  final String productName;
  final int quantity;
  final Widget? child;

  const AddToCartButton({
    super.key,
    required this.productId,
    required this.productName,
    this.quantity = 1,
    this.child,
  });

  @override
  ConsumerState<AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends ConsumerState<AddToCartButton> {
  bool _isLoading = false;

  Future<void> _addToCart() async {
    // Use AuthService (like webapp) instead of Firebase
    final userData = await AuthService.getUserData();
    final token = await AuthService.getToken();
    final authState = ref.read(authStateProvider);

    // Check auth state first, then stored data
    String? userId;
    if (authState.isLoggedIn && authState.userId != null) {
      userId = authState.userId;
    } else if (userData != null && userData.isNotEmpty) {
      userId = userData['_id']?.toString() ?? userData['id']?.toString();
      if (userId != null) {
        // Sync auth state
        ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
          userId: userId,
          email: userData['email']?.toString(),
          firstName: userData['firstname']?.toString(),
          lastName: userData['lastname']?.toString(),
        );
      }
    }

    if (userId == null || token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to add items to cart')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // EXACT WEBAPP LOGIC: Always ensure quantity is at least 1
      final quantityToAdd = widget.quantity > 0 ? widget.quantity : 1;
      
      final result = await CartService.addToCart(
        userId: userId,
        productId: widget.productId,
        quantity: quantityToAdd,
        token: token,
      );
      
      // Update cart count after adding (even if already in cart, refresh to show current state)
      try {
        final cartItems = await CartService.fetchCart(userId, token: token);
        ref.read(cartCountProvider.notifier).state = cartItems.length;
      } catch (e) {
        // Ignore count update errors
      }
      
      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.productName} added to cart'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'View Cart',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Handle "already in cart" case gracefully
          if (result['alreadyInCart'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product is already in your cart. You can update quantity from the cart page.'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']?.toString() ?? 'Failed to add to cart'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        
        // EXACT WEBAPP LOGIC: Handle errors gracefully
        if (errorMessage.contains('Product already added to cart') || 
            errorMessage.contains('already added')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product is already in your cart. You can update quantity from the cart page.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (errorMessage.contains('not found') || 
                   errorMessage.contains('Resource not found')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product not found. Please try again or contact support.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child != null) {
      return InkWell(
        onTap: _isLoading ? null : _addToCart,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : widget.child,
      );
    }

    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _addToCart,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.shopping_cart),
      label: const Text('Add to Cart'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
      ),
    );
  }
}

