import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';
import '../../../services/auth_service.dart';
import '../../../features/common/widgets/custom_button.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../authentication/providers/redirect_provider.dart';
import '../providers/cart_provider.dart';

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
    // Reload cart when page becomes visible (e.g., after adding items)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadCart();
      }
    });
  }

  Future<void> _loadCart() async {
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
      // Even if token is null, try to fetch - token might be in userData
      if (userId != null) {
        // Use token from parameter or try to get from userData
        String? authToken = token;
        if (authToken == null && userData != null) {
          authToken = userData['token']?.toString();
        }
        
        // If we have a token, fetch cart
        if (authToken != null) {
          try {
            final cartItems = await CartService.fetchCart(
              userId,
              token: authToken,
            );

            setState(() {
              _cartItems = cartItems;
              _isLoading = false;
            });
            
            // Update cart count provider (EXACT WEBAPP LOGIC: sync cart count)
            ref.read(cartCountProvider.notifier).state = cartItems.length;
            return;
          } catch (e) {
            // If fetch fails, show empty cart instead of redirecting
            setState(() {
              _cartItems = [];
              _isLoading = false;
            });
            // Update cart count to 0 when cart is empty
          ref.read(cartCountProvider.notifier).state = 0;
            return;
          }
        } else {
          // No token but user is logged in - show empty cart
          setState(() {
            _cartItems = [];
            _isLoading = false;
          });
          // Update cart count to 0 when cart is empty
          ref.read(cartCountProvider.notifier).state = 0;
          return;
        }
      }

      // Not logged in (EXACT webapp: if (!userInfo || userInfo == {} || userInfo == ""))
      // Only redirect if truly not logged in
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        // Remember where user was trying to go
        ref.read(redirectRouteProvider.notifier).state = '/cart';
        Navigator.of(context).pushReplacementNamed('/signin');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load cart: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity < 1) return;

    try {
      final token = await AuthService.getToken();
      final success = await CartService.updateCartItem(
        cartId: item.cartId,
        quantity: newQuantity,
        token: token,
      );

      if (success) {
        _loadCart();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update quantity')),
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
    return 'UGX ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
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
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
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
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_cartItems.length}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
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
                                      color: Colors.black87,
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
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/checkout',
                                      arguments: {
                                        'total': _calculateTotal(),
                                        'cartItems': _cartItems,
                                      },
                                    );
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

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onDelete;

  const _CartItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.image.isNotEmpty
                    ? item.image
                    : 'https://via.placeholder.com/80',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'UGX ${item.price}${item.unit != null ? ' / ${item.unit}' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Quantity Controls
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: item.quantity > 1
                            ? () => onQuantityChanged(item.quantity - 1)
                            : null,
                        color: const Color.fromRGBO(24, 95, 45, 1),
                      ),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => onQuantityChanged(item.quantity + 1),
                        color: const Color.fromRGBO(24, 95, 45, 1),
                      ),
                      const Spacer(),
                      Text(
                        _formatCurrency(item.totalPrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(24, 95, 45, 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Remove Item'),
                    content: Text('Remove ${item.name} from cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                        child: const Text('Remove',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return 'UGX ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }
}
