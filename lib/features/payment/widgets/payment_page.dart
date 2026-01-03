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

  // Professional Payment Method Card Widget
  Widget _buildPaymentMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() => _paymentMethod = value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color.fromRGBO(24, 95, 45, 1)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color.fromRGBO(24, 95, 45, 1)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? const Color.fromRGBO(24, 95, 45, 1)
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color.fromRGBO(24, 95, 45, 1),
                size: 24,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey[400],
                size: 24,
              ),
          ],
        ),
      ),
    );
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
                          // Amount to be paid - Professional Design
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.1),
                                  const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(24, 95, 45, 1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.payment,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Amount to be paid',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _formatCurrency(
                                    _order!['total']?.toDouble() ?? widget.amount ?? 0.0,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(24, 95, 45, 1),
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Apply Coupon Section - Professional UI
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.local_offer,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Apply Coupon',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          decoration: InputDecoration(
                                            hintText: 'Enter coupon code',
                                            prefixIcon: const Icon(Icons.confirmation_number),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: BorderSide(color: Colors.grey[300]!),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(
                                                color: Color.fromRGBO(24, 95, 45, 1),
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                          ),
                                          onChanged: (value) {
                                            setState(() => _couponCode = value);
                                          },
                                          controller: TextEditingController(text: _couponCode),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: _isValidatingCoupon ? null : _validateCoupon,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          elevation: 2,
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
                                            : const Text(
                                                'Apply',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Payment Method Selection - Professional UI with Icons
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select payment option',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Payment Method Cards
                              _buildPaymentMethodCard(
                                icon: Icons.phone_android,
                                title: 'Mobile Money',
                                subtitle: 'MTN, Airtel, and more',
                                value: 'mobileMoney',
                                isSelected: _paymentMethod == 'mobileMoney',
                              ),
                              const SizedBox(height: 12),
                              _buildPaymentMethodCard(
                                icon: Icons.credit_card,
                                title: 'Debit/Credit Card',
                                subtitle: 'Visa, Mastercard, and more',
                                value: 'card',
                                isSelected: _paymentMethod == 'card',
                              ),
                              const SizedBox(height: 12),
                              _buildPaymentMethodCard(
                                icon: Icons.local_shipping,
                                title: 'Cash on Delivery',
                                subtitle: 'Pay when you receive',
                                value: 'cash_on_delivery',
                                isSelected: _paymentMethod == 'cash_on_delivery',
                              ),
                            ],
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
