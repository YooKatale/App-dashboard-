import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../cart/services/cart_service.dart';
import '../../common/widgets/custom_button.dart';
import '../../payment/widgets/flutter_wave.dart';
import '../../common/widgets/bottom_navigation_bar.dart';

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

      // Create order data (TODO: send to API)
      // final orderData = {
      //   'userId': authState.userId,
      //   'items': cartItems
      //       .map((item) => {
      //             'productId': item.productId,
      //             'quantity': item.quantity,
      //             'price': item.price,
      //           })
      //       .toList(),
      //   'deliveryAddress': _addressController.text.trim(),
      //   'specialRequests': _specialRequestsController.text.trim(),
      //   'orderTotal': total,
      //   'paymentMethod': _paymentMethod,
      // };

      // TODO: Create order via API
      // For now, navigate to payment
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlutterWavePayment(
              orderId: DateTime.now().millisecondsSinceEpoch.toString(),
              amount: total,
            ),
          ),
        );
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
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
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
                decoration: const InputDecoration(
                  labelText: 'Delivery Address *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your delivery address',
                ),
                maxLines: 3,
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
                decoration: const InputDecoration(
                  labelText: 'Special Requests (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Any special instructions for delivery',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              RadioListTile<String>(
                title: const Text('FlutterWave'),
                value: 'flutterwave',
                groupValue: _paymentMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _paymentMethod = value);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Stripe'),
                value: 'stripe',
                groupValue: _paymentMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _paymentMethod = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      FutureBuilder<double>(
                        future: _getTotal(),
                        builder: (context, snapshot) {
                          final total = snapshot.data ?? 0.0;
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Subtotal:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    _formatCurrency(total),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total:',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(total),
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
                    ],
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
