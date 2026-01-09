import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../common/models/products_model.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/error_handler_service.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import '../../cart/providers/cart_provider.dart';
import '../../cart/services/cart_service.dart';
import 'product_ratings_widget.dart';

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
        if (mounted) {
          ErrorHandlerService.showErrorSnackBar(
            context,
            message: response['message']?.toString() ?? 'Product not found. Please try again.',
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final errorMessage = ErrorHandlerService.getErrorMessage(e);
        ErrorHandlerService.showErrorSnackBar(
          context,
          message: 'Failed to load product. $errorMessage',
        );
      }
    }
  }

  Future<void> _addToCart() async {
    try {
      final userData = await AuthService.getUserData();
      final token = await AuthService.getToken();
      
      if (userData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to add items to cart'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final userId = userData['_id']?.toString() ?? userData['id']?.toString();
      
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User ID not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Use productId from loaded product details if available, otherwise use widget.productId
      // Match webapp logic: webapp uses ProductData._id directly
      String? actualProductId;
      
      // First try to get from loaded product details (most reliable)
      if (_productDetails != null && _productDetails!.isNotEmpty) {
        actualProductId = _productDetails!['_id']?.toString() ?? 
                         _productDetails!['id']?.toString();
      }
      
      // Try to get from widget.product.actualId (for homepage products)
      if ((actualProductId == null || actualProductId.isEmpty) && widget.product.actualId != null) {
        actualProductId = widget.product.actualId;
      }
      
      // Fallback to widget.productId if product details not loaded yet
      if (actualProductId == null || actualProductId.isEmpty) {
        actualProductId = widget.productId;
      }
      
      // Last resort: try to get from widget.product.id (hash code - not ideal but better than nothing)
      if ((actualProductId == null || actualProductId.isEmpty) && widget.product.id != null) {
        // Don't use hash code - it won't work with backend
        // Instead, try to fetch product by name or wait for product details to load
      }

      if (actualProductId == null || actualProductId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product ID not found. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // EXACT WEBAPP LOGIC: Ensure quantity is at least 1
      final quantityToAdd = _quantity > 0 ? _quantity : 1;
      
      final response = await ApiService.addToCart(
        userId: userId,
        productId: actualProductId,
        quantity: quantityToAdd,
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
          // Check for specific error messages in response
          final message = response['message']?.toString() ?? 'Failed to add to cart';
          Color backgroundColor = Colors.orange;
          
          if (message.toLowerCase().contains('sold out') || 
              message.toLowerCase().contains('out of stock')) {
            backgroundColor = Colors.red;
          } else if (message.toLowerCase().contains('already') ||
                     message.toLowerCase().contains('in cart')) {
            backgroundColor = Colors.orange;
            // Refresh cart count if already in cart
            _refreshCartCount(userId, token);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: backgroundColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = ErrorHandlerService.getErrorMessage(e);
        
        // Handle specific error cases with appropriate messages
        String userMessage = errorMessage;
        Color backgroundColor = Colors.red;
        
        if (errorMessage.toLowerCase().contains('sold out') || 
            errorMessage.toLowerCase().contains('out of stock') ||
            errorMessage.toLowerCase().contains('stock')) {
          userMessage = 'This product is currently out of stock.';
          backgroundColor = Colors.red;
        } else if (errorMessage.contains('Product already added to cart') || 
                   errorMessage.contains('already added') ||
                   errorMessage.contains('already in cart')) {
          userMessage = 'This product is already in your cart.';
          backgroundColor = Colors.orange;
          // Product is already in cart - show friendly message and update cart count
          final userData = await AuthService.getUserData();
          final token = await AuthService.getToken();
          final userId = userData?['_id']?.toString() ?? userData?['id']?.toString();
          if (userId != null) {
            _refreshCartCount(userId, token);
          }
        } else if (errorMessage.toLowerCase().contains('not found') ||
                   errorMessage.toLowerCase().contains('does not exist')) {
          userMessage = 'Product not found. Please try again.';
        } else if (errorMessage.toLowerCase().contains('quantity') ||
                   errorMessage.toLowerCase().contains('available')) {
          userMessage = 'Insufficient quantity available.';
        } else {
          userMessage = 'Failed to add to cart. $errorMessage';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 3),
          ),
        );
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
                  
                  // Quantity Selector - Improved UI
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Raleway',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color.fromRGBO(24, 95, 45, 1),
                            width: 2,
                          ),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Decrease Button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (_quantity > 1) {
                                    setState(() => _quantity--);
                                  }
                                },
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.remove,
                                    color: _quantity > 1
                                        ? const Color.fromRGBO(24, 95, 45, 1)
                                        : Colors.grey[400],
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            // Quantity Display
                            Container(
                              width: 60,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.symmetric(
                                  vertical: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontFamily: 'Raleway',
                                ),
                              ),
                            ),
                            // Increase Button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() => _quantity++);
                                },
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(
                                    Icons.add,
                                    color: Color.fromRGBO(24, 95, 45, 1),
                                    size: 24,
                                  ),
                                ),
                              ),
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
                  
                  // Ratings & Reviews Section
                  ProductRatingsWidget(
                    productId: widget.productId,
                  ),
                  
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
