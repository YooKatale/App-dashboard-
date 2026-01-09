import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../services/error_handler_service.dart';
import '../services/cart_service.dart';
import '../models/cart_model.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../common/widgets/custom_button.dart';

class CheckoutModal extends ConsumerStatefulWidget {
  final List<CartItem> cartItems;
  final double cartTotal;

  const CheckoutModal({
    super.key,
    required this.cartItems,
    required this.cartTotal,
  });

  @override
  ConsumerState<CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends ConsumerState<CheckoutModal> {
  int _currentTab = 0;
  
  // Tab One Data (Delivery Address)
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _specialRequestsController = TextEditingController();
  bool _peeledFood = false;
  
  // Tab Two Data (Receipt)
  String _currentDateTime = '';
  String _receiptId = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateReceiptData();
  }

  void _generateReceiptData() {
    final now = DateTime.now();
    final date = now.toDateString();
    final time = now.toLocaleTimeString();
    setState(() {
      _currentDateTime = '$date, $time';
      final randomNum = DateTime.now().millisecondsSinceEpoch % 1000;
      _receiptId = 'R${now.year}${now.month}${now.day}-$randomNum';
    });
  }

  @override
  void dispose() {
    _address1Controller.dispose();
    _address2Controller.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  void _handleTabOneContinue() {
    // Validate delivery address - EXACT WEBAPP LOGIC
    if (_address1Controller.text.trim().isEmpty && 
        _address2Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Move to tab 2 (receipt)
    setState(() {
      _currentTab = 1;
    });
  }

  Future<void> _handleProceedToPayment() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user is logged in
      final authState = ref.read(authStateProvider);
      final userData = await AuthService.getUserData();
      final token = await AuthService.getToken();
      
      String? userId;
      if (authState.isLoggedIn && authState.userId != null) {
        userId = authState.userId;
      } else if (userData != null && userData.isNotEmpty) {
        userId = userData['_id']?.toString() ?? userData['id']?.toString();
      }
      
      if (userId == null || userData == null) {
        throw Exception('Please login to checkout');
      }

      // Prepare delivery address - EXACT WEBAPP FORMAT
      final deliveryAddress = {
        'address1': _address1Controller.text.trim(),
        'address2': _address2Controller.text.trim(),
      };

      // Prepare special requests - EXACT WEBAPP FORMAT
      final specialRequests = {
        'peeledFood': _peeledFood,
        'moreInfo': _specialRequestsController.text.trim(),
      };

      // Calculate totals - EXACT WEBAPP LOGIC (delivery fee is 3500 in webapp, but 1000 in mobile - use 1000 for consistency)
      final deliveryFee = 1000.0;
      final orderTotal = widget.cartTotal + deliveryFee;

      // Prepare cart data - EXACT WEBAPP FORMAT
      final cartsData = widget.cartItems.map((item) => {
        '_id': item.productId,
        'cartId': item.cartId,
        'productId': item.productId,
        'quantity': item.quantity,
        'price': item.price,
        'name': item.name,
        'images': item.image.isNotEmpty ? [item.image] : [],
      } as Map<String, dynamic>).toList();

      // Create order via API - EXACT WEBAPP LOGIC
      final response = await ApiService.createCartCheckout(
        user: userData,
        customerName: '${userData['firstname'] ?? ''} ${userData['lastname'] ?? ''}'.trim(),
        carts: cartsData,
        order: {
          'orderTotal': orderTotal,
          'deliveryAddress': deliveryAddress,
          'specialRequests': specialRequests,
          'payment': {'paymentMethod': '', 'transactionId': ''},
          'orderDate': _currentDateTime,
          'receiptId': _receiptId,
        },
        token: token,
      );

      // Extract order ID - EXACT WEBAPP LOGIC
      String? orderId;
      if (response['data'] != null && response['data'] is Map) {
        final data = response['data'] as Map<String, dynamic>;
        orderId = data['Order']?.toString() ?? data['orderId']?.toString();
      }

      if (orderId == null) {
        throw Exception('Failed to create order');
      }

      if (!mounted) return;

      // Close modal first
      Navigator.of(context).pop();

      // Redirect to webapp payment page - EXACT WEBAPP URL
      final paymentUrl = 'https://www.yookatale.app/payment/$orderId';
      final uri = Uri.parse(paymentUrl);

      // Show redirect message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Redirecting to payment page...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Try to launch URL
      bool launched = false;
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        if (kDebugMode) {
          print('External launch failed: $e');
        }
      }

      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        } catch (e) {
          if (kDebugMode) {
            print('Platform default launch failed: $e');
          }
        }
      }

      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
          );
        } catch (e) {
          if (kDebugMode) {
            print('In-app browser launch failed: $e');
          }
        }
      }

      if (mounted) {
        if (launched) {
          // Navigate back to home after redirect
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
              );
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Could not open browser automatically.'),
                  const SizedBox(height: 4),
                  SelectableText(
                    paymentUrl,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 10),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ErrorHandlerService.showErrorSnackBar(
          context,
          message: 'Failed to checkout: ${ErrorHandlerService.getErrorMessage(e)}',
        );
      }
    }
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(24, 95, 45, 1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Checkout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _currentTab == 0 ? _buildTabOne() : _buildTabTwo(),
              ),
            ),
            // Footer buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  if (_currentTab == 1)
                    Expanded(
                      child: CustomButton(
                        title: 'Back',
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _currentTab = 0;
                                });
                              },
                      ),
                    ),
                  if (_currentTab == 1) const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      title: _currentTab == 0
                          ? 'Continue to Checkout'
                          : (_isLoading ? 'Processing...' : 'Proceed to Payment'),
                      onPressed: _isLoading
                          ? null
                          : (_currentTab == 0
                              ? _handleTabOneContinue
                              : _handleProceedToPayment),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabOne() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _address1Controller,
          decoration: const InputDecoration(
            labelText: 'Address 1',
            hintText: 'Delivery address',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _address2Controller,
          decoration: const InputDecoration(
            labelText: 'Address 2',
            hintText: 'Delivery address',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        const Text(
          'Choose where applicable',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Peel Food'),
          value: _peeledFood,
          onChanged: (value) {
            setState(() {
              _peeledFood = value ?? false;
            });
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _specialRequestsController,
          decoration: const InputDecoration(
            labelText: 'Any other information',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTabTwo() {
    // EXACT WEBAPP LOGIC: Display 3500 for delivery but use 1000 for calculation
    final deliveryFeeForDisplay = 3500.0;
    final deliveryFeeForCalculation = 1000.0;
    final orderTotal = widget.cartTotal + deliveryFeeForCalculation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Receipt Header
        Row(
          children: [
            Image.asset(
              'assets/logo1.webp',
              width: 50,
              height: 50,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.shopping_cart, size: 50);
              },
            ),
            const SizedBox(width: 12),
            const Text(
              'Yookatale',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Authorized By: Seconds Tech Limited\nP.O. Box 74940, Clock Tower, Kampala, Naguru (U)',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Checkout summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, dynamic>?>(
          future: AuthService.getUserData(),
          builder: (context, snapshot) {
            final userData = snapshot.data;
            return Text(
              'Customer Name: ${userData?['firstname'] ?? ''} ${userData?['lastname'] ?? ''}',
              style: const TextStyle(fontSize: 14),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Date and Time: $_currentDateTime',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        // Products List
        const Text(
          'Products',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.cartItems.map((item) {
          final itemTotal = (double.tryParse(item.price) ?? 0.0) * item.quantity;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product: ${item.name}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Quantity: ${item.quantity}'),
                    Text('Total: ${_formatCurrency(itemTotal)}'),
                  ],
                ),
                const Divider(),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        // Delivery Address
        const Text(
          'Delivery Addresses',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text('Address 1: ${_address1Controller.text.trim().isEmpty ? "__" : _address1Controller.text.trim()}'),
        const SizedBox(height: 4),
        Text('Address 2: ${_address2Controller.text.trim().isEmpty ? "__" : _address2Controller.text.trim()}'),
        const SizedBox(height: 16),
        // Special Requests
        const Text(
          'Special Requests',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text('Peel Food: ${_peeledFood ? "Yes" : "No"}'),
        if (_specialRequestsController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('More Information: ${_specialRequestsController.text.trim()}'),
        ],
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        // Totals
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Delivery Cost:'),
            Text(_formatCurrency(deliveryFeeForDisplay)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Cart SubTotal:'),
            Text(_formatCurrency(widget.cartTotal)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cart Total:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatCurrency(orderTotal),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Receipt Number: $_receiptId',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
