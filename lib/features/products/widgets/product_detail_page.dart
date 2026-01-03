import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../common/models/products_model.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import '../../cart/providers/cart_provider.dart';
import '../../cart/services/cart_service.dart';
import 'product_rating_widget.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;
  final PopularDetails product;

  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.product,
  });

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  Map<String, dynamic>? _productDetails;
  bool _isLoading = true;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      final response = await ApiService.fetchProductById(widget.productId);
      if (response['status'] == 'Success' && response['data'] != null) {
        setState(() {
          _productDetails = response['data'] as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addToCart() async {
    try {
      final userData = await AuthService.getUserData();
      final token = await AuthService.getToken();
      
      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to add items to cart'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final userId = userData['_id']?.toString() ?? userData['id']?.toString();
      
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User ID not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await ApiService.addToCart(
        userId: userId,
        productId: widget.productId,
        quantity: _quantity,
        token: token,
      );

      if (mounted) {
        // EXACT WEBAPP LOGIC: Check response.data?.message or response.status
        // Webapp shows success if res.data?.message exists
        if (response['status'] == 'Success' || response['message'] != null) {
          // Refresh cart count
          _refreshCartCount(userId, token);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']?.toString() ?? 'Product added to cart successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']?.toString() ?? 'Failed to add to cart'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        
        // EXACT WEBAPP LOGIC: Handle "Product already added to cart" gracefully
        // Webapp shows error but doesn't crash - we should handle it gracefully too
        if (errorMessage.contains('Product already added to cart') || 
            errorMessage.contains('already added')) {
          // Product is already in cart - show friendly message and update cart count
          _refreshCartCount(userId, token);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product is already in your cart. You can update quantity from the cart page.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (errorMessage.contains('not found') || 
                   errorMessage.contains('Resource not found')) {
          // Product or user not found - show helpful message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product not found. Please try again or contact support.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          // Other errors - show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNetworkImage = widget.product.image.startsWith('http://') || 
                          widget.product.image.startsWith('https://');

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 1),
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: isNetworkImage
                  ? CachedNetworkImage(
                      imageUrl: widget.product.image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Image.asset(
                      widget.product.image.startsWith('assets/')
                          ? widget.product.image
                          : 'assets/${widget.product.image}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
            ),
            backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
            foregroundColor: Colors.white,
          ),
          
          // Product Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Title
                  Text(
                    widget.product.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Raleway',
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Price
                  Row(
                    children: [
                      Text(
                        'UGX ${widget.product.price}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(24, 95, 45, 1),
                          fontFamily: 'Raleway',
                        ),
                      ),
                      if (widget.product.per != null && widget.product.per!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '/ ${widget.product.per}',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Quantity Selector
                  Row(
                    children: [
                      const Text(
                        'Quantity:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Raleway',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                            ),
                            Container(
                              width: 50,
                              alignment: Alignment.center,
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() => _quantity++);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Product Description (if available)
                  if (_productDetails != null && _productDetails!['description'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Raleway',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _productDetails!['description'].toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  
                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _addToCart,
                      icon: const Icon(Icons.shopping_cart, size: 24),
                      label: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Raleway',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Ratings & Reviews
                  ProductRatingsWidget(productId: widget.productId),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _refreshCartCount(String userId, String? token) async {
    try {
      final cartItems = await CartService.fetchCart(userId, token: token);
      ref.read(cartCountProvider.notifier).state = cartItems.length;
    } catch (e) {
      // Silently fail - cart count will update on next cart page load
    }
  }
}
