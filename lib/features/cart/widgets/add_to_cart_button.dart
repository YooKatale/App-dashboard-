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
    final authState = ref.read(authStateProvider);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || authState.userId == null) {
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
      final success = await CartService.addToCart(
        userId: authState.userId!,
        productId: widget.productId,
        quantity: widget.quantity,
        token: await user.getIdToken(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.productName} added to cart'),
              action: SnackBarAction(
                label: 'View Cart',
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add to cart')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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

