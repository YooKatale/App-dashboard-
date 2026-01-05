import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../cart/services/cart_service.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>>? cartItems;
  final double? total;

  const CheckoutPage({
    super.key,
    this.cartItems,
    this.total,
  });

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _specialRequestsController = TextEditingController();
  String _paymentMethod = 'flutterwave';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _processCheckout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter delivery address')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authStateProvider);
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || authState.userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to checkout')),
          );
        }
        return;
      }

      // Fetch cart items
      final cartItems = await CartService.fetchCart(
        authState.userId!,
        token: await user.getIdToken(),
      );

      if (cartItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your cart is empty')),
          );
        }
        return;
      }

      final total = CartService.calculateTotal(cartItems);
      final deliveryFee = 1000.0; // Delivery fee like webapp
      final orderTotal = total + deliveryFee;

      // Get user data for checkout
      final userData = await AuthService.getUserData();
      if (userData == null) {
        throw Exception('User data not found. Please login again.');
      }

      // Generate receipt ID like webapp
      final now = DateTime.now();
      final receiptId = 'R${now.year}${now.month}${now.day}-${now.millisecondsSinceEpoch % 1000}';
      final orderDate = '${now.toDateString()}, ${now.toLocalTimeString()}';

      // Prepare cart data for API (match webapp format)
      final cartsData = cartItems.map((item) => {
        'productId': item.productId,
        'quantity': item.quantity,
        'price': item.price,
        'name': item.productName,
      }).toList();

      // Create order via API (match webapp createCartCheckout)
      final response = await ApiService.createCartCheckout(
        user: userData,
        customerName: '${userData['firstname'] ?? ''} ${userData['lastname'] ?? ''}'.trim(),
        carts: cartsData,
        order: {
          'orderTotal': orderTotal,
          'deliveryAddress': _addressController.text.trim(),
          'specialRequests': _specialRequestsController.text.trim(),
          'payment': {'paymentMethod': '', 'transactionId': ''},
          'orderDate': orderDate,
          'receiptId': receiptId,
        },
        token: await user.getIdToken(),
      );

      // Extract order ID from response (match webapp: res.data.data.Order)
      String? orderId;
      if (response['data'] != null && response['data'] is Map) {
        final data = response['data'] as Map<String, dynamic>;
        orderId = data['Order']?.toString() ?? data['orderId']?.toString();
      }

      if (orderId == null) {
        throw Exception('Failed to create order. Please try again.');
      }

      // Redirect to webapp payment page (match webapp: router.push(`/payment/${orderId}`))
      final paymentUrl = 'https://www.yookatale.app/payment/$orderId';
      final uri = Uri.parse(paymentUrl);

      // Store redirect route if user needs to login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_payment_url', paymentUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          Navigator.of(context).pop(); // Go back to cart
        }
      } else {
        throw Exception('Could not open payment page. Please try again.');
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

  String _formatCurrency(double amount) {
    return 'UGX ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color.fromRGBO(24, 95, 45, 1),
                      const Color.fromRGBO(24, 95, 45, 1).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Delivery Information',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: const TextStyle(color: Colors.black87),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color.fromRGBO(24, 95, 45, 1), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.black),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: const TextStyle(color: Colors.black87),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color.fromRGBO(24, 95, 45, 1), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        style: const TextStyle(color: Colors.black),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Delivery Address *',
                          labelStyle: const TextStyle(color: Colors.black87),
                          hintText: 'Enter your delivery address',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color.fromRGBO(24, 95, 45, 1), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter delivery address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _specialRequestsController,
                        style: const TextStyle(color: Colors.black),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Special Requests (Optional)',
                          labelStyle: const TextStyle(color: Colors.black87),
                          hintText: 'Any special instructions for delivery',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color.fromRGBO(24, 95, 45, 1), width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color.fromRGBO(24, 95, 45, 1),
                      const Color.fromRGBO(24, 95, 45, 1).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('FlutterWave', style: TextStyle(color: Colors.black)),
                      value: 'flutterwave',
                      groupValue: _paymentMethod,
                      activeColor: const Color.fromRGBO(24, 95, 45, 1),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _paymentMethod = value);
                        }
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Stripe', style: TextStyle(color: Colors.black)),
                      value: 'stripe',
                      groupValue: _paymentMethod,
                      activeColor: const Color.fromRGBO(24, 95, 45, 1),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _paymentMethod = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FutureBuilder<double>(
                    future: _getTotal(),
                    builder: (context, snapshot) {
                      final total = snapshot.data ?? 0.0;
                      final deliveryFee = 1000.0;
                      final orderTotal = total + deliveryFee;
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal:',
                                style: TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                              Text(
                                _formatCurrency(total),
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Delivery Fee:',
                                style: TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                              Text(
                                _formatCurrency(deliveryFee),
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                _formatCurrency(orderTotal),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(24, 95, 45, 1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  title: _isLoading ? 'Processing...' : 'Proceed to Payment',
                  onPressed: _isLoading ? null : _processCheckout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<double> _getTotal() async {
    try {
      final authState = ref.read(authStateProvider);
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || authState.userId == null) {
        return widget.total ?? 0.0;
      }

      final cartItems = await CartService.fetchCart(
        authState.userId!,
        token: await user.getIdToken(),
      );

      return CartService.calculateTotal(cartItems);
    } catch (e) {
      return widget.total ?? 0.0;
    }
  }
}
