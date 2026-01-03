import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../common/widgets/custom_button.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import 'flutter_wave.dart';

// EXACT WEBAPP LOGIC: Payment page matches webapp structure
class PaymentPage extends ConsumerStatefulWidget {
  final String orderId;
  final double? amount;

  const PaymentPage({
    super.key,
    required this.orderId,
    this.amount,
  });

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  bool _isProcessing = false;
  String _paymentMethod = '';
  String _couponCode = '';
  bool _isValidatingCoupon = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // EXACT WEBAPP LOGIC: fetchOrder(params.id)
      final response = await ApiService.fetchOrder(widget.orderId);

      if (response['status'] == 'Success' || response['status'] == 'success') {
        // Check if order is already paid (webapp checks res.data?.status)
        if (response['data']?['status'] != null && 
            response['data']['status'].toString().isNotEmpty &&
            response['data']['status'] != 'pending') {
          // Order already processed - redirect to home
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
          }
          return;
        }

        setState(() {
          _order = response['data'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      } else {
        throw Exception(response['message']?.toString() ?? 'Failed to fetch order');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error ?? 'Unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _validateCoupon() async {
    if (_couponCode.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a coupon code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isValidatingCoupon = true);

    try {
      final response = await ApiService.validateCoupon(
        couponCode: _couponCode.trim(),
        orderId: widget.orderId,
      );

      if (response['status'] == 'Success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coupon Applied'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _couponCode = '');
        // Reload order to get updated total
        _loadOrder();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']?.toString() ?? 'Invalid coupon code'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isValidatingCoupon = false);
    }
  }

  Future<void> _handlePayment() async {
    if (_paymentMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userData = await AuthService.getUserData();
      final token = await AuthService.getToken();
      final authState = ref.read(authStateProvider);

      // EXACT WEBAPP LOGIC: Handle different payment methods
      if (_paymentMethod == 'cash_on_delivery') {
        // Update order with cash on delivery
        final response = await ApiService.updateOrder(
          orderId: widget.orderId,
          paymentData: {
            'payment': {'paymentMethod': _paymentMethod},
            'order': widget.orderId,
            'schema': 'schedule',
            'user': userData,
          },
          token: token,
        );

        if (response['status'] == 'Success' || response['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order successfully placed for Cash on Delivery.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
          }
        }
      } else if (_paymentMethod == 'payLater') {
        // Update order with pay later
        final response = await ApiService.updateOrder(
          orderId: widget.orderId,
          paymentData: {
            'payment': {'paymentMethod': _paymentMethod},
            'order': widget.orderId,
            'schema': 'schedule',
            'user': userData,
          },
          token: token,
        );

        if (response['status'] == 'Success' || response['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order successfully placed for pay later'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
          }
        }
      } else {
        // For card/mobile money - show Flutterwave payment
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlutterWavePayment(
                orderId: widget.orderId,
                amount: _order?['total']?.toDouble() ?? widget.amount ?? 0.0,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrder,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _order == null
                  ? const Center(child: Text('Order not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Amount to be paid
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Amount to be paid',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatCurrency(
                                    _order!['total']?.toDouble() ?? widget.amount ?? 0.0,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(24, 95, 45, 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Apply Coupon Section
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Apply Coupon',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          decoration: const InputDecoration(
                                            hintText: 'Enter coupon code',
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setState(() => _couponCode = value);
                                          },
                                          controller: TextEditingController(text: _couponCode),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: _isValidatingCoupon ? null : _validateCoupon,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                        ),
                                        child: _isValidatingCoupon
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : const Text('Apply'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Payment Method Selection
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Select payment option',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _paymentMethod.isEmpty ? null : _paymentMethod,
                                    decoration: const InputDecoration(
                                      labelText: 'Payment Method',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'mobileMoney',
                                        child: Text('Mobile Money'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'card',
                                        child: Text('Debit/Credit Card'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'cash_on_delivery',
                                        child: Text('Cash on Delivery'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _paymentMethod = value);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Make Payment Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : _handlePayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Make Payment',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
