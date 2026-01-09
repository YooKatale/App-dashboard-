import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../services/error_handler_service.dart';
import '../../../features/common/widgets/custom_button.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../authentication/providers/redirect_provider.dart';
import '../providers/cart_provider.dart';
import 'checkout_modal.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Don't auto-reload cart here - it causes quantity to reset after update
    // Only reload when explicitly needed (e.g., after adding new items)
  }

  Future<void> _loadCart() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // EXACT WEBAPP LOGIC: const { userInfo } = useSelector((state) => state.auth)
      // Webapp checks: if (!userInfo || userInfo == {} || userInfo == "") then redirect
      // Webapp uses: fetchCart(userInfo?._id)
      final userData = await AuthService.getUserData();
      final token = await AuthService.getToken();
      final authState = ref.read(authStateProvider);

      // Check if user is logged in (EXACT webapp check: userInfo?._id)
      String? userId;
      
      // First check auth state provider (most reliable)
      if (authState.isLoggedIn && authState.userId != null) {
        userId = authState.userId;
      }
      
      // If not in auth state, check stored user data (EXACT webapp check: if (!userInfo || userInfo == {} || userInfo == ""))
      if (userId == null && userData != null && userData.isNotEmpty) {
        // Ensure we have a valid _id or id (like webapp checks userInfo?._id)
        final id = userData['_id']?.toString() ?? userData['id']?.toString();
        if (id != null && id.isNotEmpty) {
          userId = id;
          // Sync auth state with stored data
          ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
            userId: userId,
            email: userData['email']?.toString(),
            firstName: userData['firstname']?.toString(),
            lastName: userData['lastname']?.toString(),
          );
        }
      }
      
      // If we have userId, try to fetch cart (EXACT webapp: fetchCart(userInfo?._id))
      // EXACT WEBAPP LOGIC: Webapp doesn't always require token for cart fetch
      if (userId != null) {
        // Use token from parameter or try to get from userData
        String? authToken = token;
        if (authToken == null && userData != null) {
          authToken = userData['token']?.toString();
        }
        
        // Try to fetch cart - try with token first, then without if it fails
        try {
          final cartItems = await CartService.fetchCart(
            userId,
            token: authToken, // Token is optional
          );

          if (mounted) {
            setState(() {
              _cartItems = cartItems;
              _isLoading = false;
            });
          }
          
          // Update cart count provider (EXACT WEBAPP LOGIC: sync cart count)
          ref.read(cartCountProvider.notifier).state = cartItems.length;
          return;
        } catch (e) {
          // If fetch fails with token, try without token (some endpoints work without it)
          if (authToken != null) {
            try {
              final cartItems = await CartService.fetchCart(
                userId,
                token: null, // Try without token
              );

              if (mounted) {
                setState(() {
                  _cartItems = cartItems;
                  _isLoading = false;
                });
              }
              
              ref.read(cartCountProvider.notifier).state = cartItems.length;
              return;
            } catch (e2) {
              // Both attempts failed - show empty cart
              if (mounted) {
                setState(() {
                  _cartItems = [];
                  _isLoading = false;
                });
              }
              ref.read(cartCountProvider.notifier).state = 0;
              return;
            }
          } else {
            // No token and fetch failed - show empty cart
            if (mounted) {
              setState(() {
                _cartItems = [];
                _isLoading = false;
              });
            }
            ref.read(cartCountProvider.notifier).state = 0;
            return;
          }
        }
      }

      // Not logged in (EXACT webapp: if (!userInfo || userInfo == {} || userInfo == ""))
      // Only redirect if truly not logged in
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      if (mounted) {
        // Remember where user was trying to go
        ref.read(redirectRouteProvider.notifier).state = '/cart';
        Navigator.of(context).pushReplacementNamed('/signin');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load cart: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity < 1) {
      // If quantity is 0 or less, delete the item instead
      await _deleteItem(item);
      return;
    }

    // Ensure cartId is valid - FIX: Always validate cartId
    if (item.cartId.isEmpty || item.cartId == '') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cart ID is required. Please refresh your cart.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      // Reload cart to get proper IDs
      _loadCart();
      return;
    }

    // Store original quantity to revert if update fails
    final originalQuantity = item.quantity;

    try {
      // Check if user is logged in using auth state (more reliable)
      final authState = ref.read(authStateProvider);
      final userData = await AuthService.getUserData();
      final token = await AuthService.getToken();
      
      // Check if user is logged in (EXACT webapp check: userInfo?._id)
      String? userId;
      
      // First check auth state provider (most reliable)
      if (authState.isLoggedIn && authState.userId != null) {
        userId = authState.userId;
      }
      
      // If not in auth state, check stored user data
      if (userId == null && userData != null && userData.isNotEmpty) {
        final id = userData['_id']?.toString() ?? userData['id']?.toString();
        if (id != null && id.isNotEmpty) {
          userId = id;
        }
      }
      
      // Ensure user is logged in
      if (userId == null) {
        throw Exception('Please log in to update cart');
      }

      // Try to get token, but it's optional for some endpoints
      String? authToken = token;
      if (authToken == null && userData != null) {
        authToken = userData['token']?.toString();
      }

      // Match webapp logic - include userId in update request
      try {
        // Show loading indicator
        if (mounted) {
          // Update UI optimistically for better UX
          setState(() {
            final index = _cartItems.indexWhere((i) => i.cartId == item.cartId);
            if (index != -1) {
              _cartItems[index] = item.copyWith(quantity: newQuantity);
            }
          });
        }
        
        // FIX: Ensure cartId is always passed correctly
        final success = await CartService.updateCartItem(
          cartId: item.cartId, // This should always be valid now
          quantity: newQuantity,
          userId: userId, // Include userId like webapp
          token: authToken, // Token is optional for some endpoints
        );

        if (success) {
          // Update was successful - keep the optimistic update
          // DO NOT reload cart here - it causes quantity to reset to old value
          // The optimistic update already shows the correct quantity in UI
          
          // Update cart count provider
          ref.read(cartCountProvider.notifier).state = _cartItems.length;
          
          // Recalculate total after successful update
          if (mounted) {
            setState(() {
              // Total will be recalculated in build method
              // Quantity is already updated optimistically above - don't reload!
            });
          }
          
          // Show brief success feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Quantity updated to $newQuantity'),
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.green,
              ),
            );
          }
          
          // IMPORTANT: Don't call _loadCart() here - it will reset the quantity!
          // The server has the updated quantity, and our local state matches it
        } else {
          // Update failed - revert to original quantity
          if (mounted) {
            setState(() {
              final index = _cartItems.indexWhere((i) => i.cartId == item.cartId);
              if (index != -1) {
                _cartItems[index] = item.copyWith(quantity: originalQuantity);
              }
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update quantity. Please try again.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (apiError) {
        // Handle API errors specifically
        // Revert optimistic update on error
        if (mounted) {
          setState(() {
            final index = _cartItems.indexWhere((i) => i.cartId == item.cartId);
            if (index != -1) {
              _cartItems[index] = item.copyWith(quantity: originalQuantity);
            }
          });
          
          // Use ErrorHandlerService for user-friendly error messages
          final errorMessage = ErrorHandlerService.getErrorMessage(apiError);
          ErrorHandlerService.showErrorSnackBar(
            context,
            message: 'Failed to update quantity. $errorMessage',
          );
        }
        return; // Exit early to avoid double error handling
      }
    } catch (e) {
      // Handle general errors
      // No need to revert - we didn't update optimistically
      
      if (mounted) {
        // Use ErrorHandlerService for user-friendly error messages
        final errorMessage = ErrorHandlerService.getErrorMessage(e);
        ErrorHandlerService.showErrorSnackBar(
          context,
          message: 'Failed to update quantity. $errorMessage',
        );
      }
    }
  }

  Future<void> _deleteItem(CartItem item) async {
    try {
      final token = await AuthService.getToken();
      final success = await CartService.deleteCartItem(
        item.cartId,
        token: token,
      );

      if (success) {
        _loadCart();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item removed from cart')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove item')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  double _calculateTotal() {
    return CartService.calculateTotal(_cartItems);
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return 'UGX $formatted';
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state and cart count in build method (like webapp watches Redux state)
    final authState = ref.watch(authStateProvider);
    final cartCount = ref.watch(cartCountProvider);
    
    // Reload cart if:
    // 1. Auth state changed to logged in
    // 2. Cart count changed (item was added)
    if (authState.isLoggedIn) {
      if (cartCount > 0 && _cartItems.isEmpty && !_isLoading) {
        // Cart count shows items but cart page is empty - reload
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadCart();
          }
        });
      } else if (cartCount != _cartItems.length && !_isLoading) {
        // Cart count doesn't match items - reload
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadCart();
          }
        });
      }
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 2),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCart,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart_outlined,
                              size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Your cart is empty',
                            style: TextStyle(fontSize: 24, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to home/categories to add products (no auth check needed)
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/home',
                                (route) => false,
                              );
                            },
                            child: const Text('Add Products'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _cartItems.length,
                            itemBuilder: (context, index) {
                              final item = _cartItems[index];
                              return _CartItemCard(
                                item: item,
                                onQuantityChanged: (newQuantity) =>
                                    _updateQuantity(item, newQuantity),
                                onDelete: () => _deleteItem(item),
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withAlpha(77),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, -3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Cart Items:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_cartItems.length}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.grey),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Cart SubTotal:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(_calculateTotal()),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromRGBO(24, 95, 45, 1),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: CustomButton(
                                  title: 'Checkout',
                                  onPressed: () async {
                                    // Check if user is logged in
                                    final authState = ref.read(authStateProvider);
                                    final userData = await AuthService.getUserData();
                                    
                                    String? userId;
                                    if (authState.isLoggedIn && authState.userId != null) {
                                      userId = authState.userId;
                                    } else if (userData != null && userData.isNotEmpty) {
                                      userId = userData['_id']?.toString() ?? userData['id']?.toString();
                                    }
                                    
                                    if (userId == null || userData == null) {
                                      // User not logged in - redirect to sign in
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please login to checkout'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        Navigator.of(context).pushReplacementNamed('/signin');
                                      }
                                      return;
                                    }
                                    
                                    // Show checkout modal - EXACT WEBAPP FLOW
                                    if (mounted) {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => CheckoutModal(
                                          cartItems: _cartItems,
                                          cartTotal: _calculateTotal(),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _CartItemCard extends StatefulWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onDelete;

  const _CartItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onDelete,
  });

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard> {
  late TextEditingController _quantityController;
  
  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '${widget.item.quantity}');
  }
  
  @override
  void didUpdateWidget(_CartItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller when item changes (but only if different)
    if (oldWidget.item.quantity != widget.item.quantity) {
      _quantityController.text = '${widget.item.quantity}';
    }
  }
  
  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return 'UGX $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final onQuantityChanged = widget.onQuantityChanged;
    final onDelete = widget.onDelete;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image - Improved
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: item.image.isNotEmpty
                    ? Image.network(
                        item.image,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, color: Colors.grey),
                          );
                        },
                      )
                    : const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 16),
            // Product Details - Fixed to prevent overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'UGX ${item.price}${item.unit != null ? ' / ${item.unit}' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Quantity Controls - Improved UI
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                                onTap: item.quantity > 1
                                    ? () => onQuantityChanged(item.quantity - 1)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Icon(
                                    Icons.remove,
                                    size: 20,
                                    color: item.quantity > 1
                                        ? const Color.fromRGBO(24, 95, 45, 1)
                                        : Colors.grey[400],
                                  ),
                                ),
                              ),
                            ),
                            // Editable quantity text field - allows typing numbers
                            Container(
                              width: 60,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.symmetric(
                                  vertical: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              child: TextField(
                                controller: _quantityController,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                onSubmitted: (value) {
                                  final newQuantity = int.tryParse(value);
                                  if (newQuantity != null && newQuantity > 0 && newQuantity != item.quantity) {
                                    onQuantityChanged(newQuantity);
                                  } else {
                                    // Reset to original if invalid
                                    _quantityController.text = '${item.quantity}';
                                  }
                                },
                                onChanged: (value) {
                                  // Allow typing, validate on submit
                                },
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                                onTap: () => onQuantityChanged(item.quantity + 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: const Icon(
                                    Icons.add,
                                    size: 20,
                                    color: Color.fromRGBO(24, 95, 45, 1),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatCurrency(item.totalPrice),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(24, 95, 45, 1),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'UGX ${item.price}${item.unit != null ? ' / ${item.unit}' : ''} each',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Delete Button - Improved
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.white,
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Remove Item',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        'Are you sure you want to remove "${item.name}" from your cart?',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Remove',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
