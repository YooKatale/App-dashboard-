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
import '../../../services/error_handler_service.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    try {
      // Load user data from AuthService (matches webapp)
      final userData = await AuthService.getUserData();
      if (userData != null) {
        // Pre-fill name
        final firstName = userData['firstname']?.toString() ?? '';
        final lastName = userData['lastname']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();
        if (fullName.isNotEmpty) {
          _nameController.text = fullName;
        }
        
        // Pre-fill phone
        final phone = userData['phone']?.toString() ?? 
                     userData['phoneNumber']?.toString() ?? '';
        if (phone.isNotEmpty) {
          _phoneController.text = phone;
        }
        
        // Pre-fill delivery address if available
        final address = userData['address']?.toString() ?? 
                       userData['deliveryAddress']?.toString() ?? '';
        if (address.isNotEmpty) {
          _addressController.text = address;
        }
      } else {
        // Fallback to Firebase user if AuthService doesn't have data
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _nameController.text = user.displayName ?? '';
          _phoneController.text = user.phoneNumber ?? '';
        }
      }
    } catch (e) {
      // Silently fail - user can still enter manually
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _nameController.text = user.displayName ?? '';
        _phoneController.text = user.phoneNumber ?? '';
      }
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
      // Check if user is logged in using AuthService (matches webapp logic)
      final userData = await AuthService.getUserData();
      final token = await AuthService.getToken();
      final authState = ref.read(authStateProvider);
      
      String? userId;
      if (authState.isLoggedIn && authState.userId != null) {
        userId = authState.userId;
      } else if (userData != null && userData.isNotEmpty) {
        userId = userData['_id']?.toString() ?? userData['id']?.toString();
      }

      // If user is logged in, proceed with checkout and redirect to webapp
      if (userId != null && userData != null) {
        // User is logged in - proceed with checkout
      } else {
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

      // Fetch cart items
      final cartItems = await CartService.fetchCart(
        userId!,
        token: token,
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

      // userData already fetched above

      // Generate receipt ID like webapp
      final now = DateTime.now();
      final receiptId = 'R${now.year}${now.month}${now.day}-${now.millisecondsSinceEpoch % 1000}';
      final orderDate = '${now.toString().split(' ')[0]}, ${now.toString().split(' ')[1]}';

      // Prepare cart data for API (match webapp format)
      final cartsData = cartItems.map((item) => {
        'productId': item.productId,
        'quantity': item.quantity,
        'price': item.price,
        'name': item.name,
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
        token: token,
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

      // Store redirect route if user needs to login (for future use)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_payment_url', paymentUrl);

      // Always try to launch URL - don't check canLaunchUrl first as it may fail incorrectly
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (mounted) {
          if (launched) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Redirecting to payment page...'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            // Go back to cart after a short delay
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                Navigator.of(context).pop(); // Go back to cart
              }
            });
          } else {
            // If launch failed, show error but don't throw
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please open this link in your browser: $paymentUrl'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        // If launch fails, show the URL to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please open this link to complete payment: $paymentUrl'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 10),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = ErrorHandlerService.getErrorMessage(e);
        ErrorHandlerService.showErrorSnackBar(
          context,
          message: 'Checkout failed. $errorMessage',
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
      // Check if user is logged in using AuthService
      final userData = await AuthService.getUserData();
      final token = await AuthService.getToken();
      final authState = ref.read(authStateProvider);
      
      String? userId;
      if (authState.isLoggedIn && authState.userId != null) {
        userId = authState.userId;
      } else if (userData != null && userData.isNotEmpty) {
        userId = userData['_id']?.toString() ?? userData['id']?.toString();
      }

      if (userId == null) {
        return widget.total ?? 0.0;
      }

      final cartItems = await CartService.fetchCart(
        userId,
        token: token,
      );

      return CartService.calculateTotal(cartItems);
    } catch (e) {
      return widget.total ?? 0.0;
    }
  }
}
