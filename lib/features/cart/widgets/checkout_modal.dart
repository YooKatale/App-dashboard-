import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../services/error_handler_service.dart';
import '../models/cart_model.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../common/widgets/location_search_picker.dart';

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

class _CheckoutModalState extends ConsumerState<CheckoutModal>
    with SingleTickerProviderStateMixin {
  static const _primaryGreen = Color(0xFF185F2D);
  static const _secondaryGreen = Color(0xFF1F793A);

  int _step = 0; // 0 = Delivery, 1 = Review & Payment

  // Delivery method
  String _deliveryMethod = 'standard'; // standard | express | scheduled

  // Address
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  double? _selectedLatitude;
  double? _selectedLongitude;
  LatLng? _selectedLocation;

  // Special requests
  bool _peeledFood = false;
  bool _ecoPackaging = false;
  final _specialRequestsController = TextEditingController();

  // Receipt data
  String _currentDateTime = '';
  String _receiptId = '';
  String _orderId = '';

  // Loading / progress animation
  bool _isLoading = false;
  double _paymentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _generateReceiptData();
  }

  void _generateReceiptData() {
    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch;
    final rand = ts % 10000;
    setState(() {
      _currentDateTime = DateFormat('EEE, MMM dd, yyyy — hh:mm a').format(now);
      _receiptId = 'RCP-$ts-$rand';
      _orderId = 'ORD-$ts-$rand';
    });
  }

  @override
  void dispose() {
    _address1Controller.dispose();
    _address2Controller.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  double get _deliveryFeeDisplay {
    switch (_deliveryMethod) {
      case 'express':
        return 7500;
      case 'scheduled':
        return 4500;
      default:
        return 3500;
    }
  }

  double get _deliveryFeeBackend => 1000.0;

  String get _estimatedDelivery {
    final now = DateTime.now();
    if (_deliveryMethod == 'express') {
      final eta = now.add(const Duration(minutes: 45));
      return 'Today by ${DateFormat('hh:mm a').format(eta)}';
    }
    if (_deliveryMethod == 'scheduled') {
      return 'Scheduled — choose at payment';
    }
    final eta = now.add(const Duration(days: 1));
    return 'Tomorrow by ${DateFormat('hh:mm a').format(eta)}';
  }

  void _handleContinue() {
    if (_address1Controller.text.trim().isEmpty &&
        _address2Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a delivery address'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _handleProceedToPayment() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _paymentProgress = 0.0;
    });

    // Animate progress 0→80% while API call runs
    _animateProgress(0.8);

    try {
      final authState = ref.read(authStateProvider);
      final userData = await AuthService.getUserData();
      final token = await AuthService.getToken();

      String? userId;
      if (authState.isLoggedIn && authState.userId != null) {
        userId = authState.userId;
      } else if (userData != null) {
        userId = userData['_id']?.toString() ?? userData['id']?.toString();
      }

      if (userId == null || userData == null) {
        throw Exception('Please login to checkout');
      }

      final deliveryAddress = {
        'address1': _address1Controller.text.trim(),
        'address2': _address2Controller.text.trim(),
        if (_selectedLatitude != null && _selectedLongitude != null) ...{
          'latitude': _selectedLatitude,
          'longitude': _selectedLongitude,
        },
      };

      final specialRequests = {
        'peeledFood': _peeledFood,
        'ecoPackaging': _ecoPackaging,
        'moreInfo': _specialRequestsController.text.trim(),
      };

      final orderTotal = widget.cartTotal + _deliveryFeeBackend;

      final cartsData = widget.cartItems
          .map((item) => {
                '_id': item.productId,
                'cartId': item.cartId,
                'productId': item.productId,
                'quantity': item.quantity,
                'price': item.price,
                'name': item.name,
                'images': item.image.isNotEmpty ? [item.image] : [],
              } as Map<String, dynamic>)
          .toList();

      final response = await ApiService.createCartCheckout(
        user: userData,
        customerName:
            '${userData['firstname'] ?? ''} ${userData['lastname'] ?? ''}'
                .trim(),
        carts: cartsData,
        order: {
          'orderTotal': orderTotal,
          'deliveryAddress': deliveryAddress,
          'specialRequests': specialRequests,
          'payment': {'paymentMethod': '', 'transactionId': ''},
          'orderDate': _currentDateTime,
          'receiptId': _receiptId,
          'deliveryMethod': _deliveryMethod,
        },
        token: token,
      );

      // Extract order ID
      String? backendOrderId;
      if (response['data'] != null && response['data'] is Map) {
        final data = response['data'] as Map<String, dynamic>;
        if (data['data'] != null && data['data'] is Map) {
          final nested = data['data'] as Map<String, dynamic>;
          backendOrderId = nested['Order']?.toString() ??
              nested['orderId']?.toString() ??
              nested['_id']?.toString();
        }
        backendOrderId ??= data['Order']?.toString() ??
            data['orderId']?.toString() ??
            data['_id']?.toString();
      }
      backendOrderId ??= response['Order']?.toString();

      if (backendOrderId == null || backendOrderId.isEmpty) {
        if (kDebugMode) print('Checkout response: $response');
        throw Exception(
            'Failed to create order: No order ID received. Please try again.');
      }

      // Finish animation to 100%
      _animateProgress(1.0);
      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      final paymentUrl = 'https://www.yookatale.app/payment/$backendOrderId';
      final uri = Uri.parse(paymentUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.payment, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
                child: Text('Redirecting to payment page...',
                    style: TextStyle(fontSize: 14))),
          ]),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }

      if (!mounted) return;

      if (!launched) {
        setState(() => _isLoading = false);
        ErrorHandlerService.showErrorDialog(
          context,
          title: 'Unable to Open Payment Page',
          message:
              'We couldn\'t open the payment page. Please visit:\n\n$paymentUrl',
          showSupportOptions: true,
        );
        return;
      }

      Navigator.of(context).pop();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                    child: Text(
                        'Payment page opened. Complete payment to finish.',
                        style: TextStyle(fontSize: 14))),
              ]),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/home', (route) => false);
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandlerService.showErrorSnackBar(
          context,
          message:
              'Failed to checkout: ${ErrorHandlerService.getErrorMessage(e)}',
        );
      }
    }
  }

  void _animateProgress(double target) {
    Future.doWhile(() async {
      if (!mounted) return false;
      if (_paymentProgress >= target) return false;
      setState(() {
        _paymentProgress =
            (_paymentProgress + 0.02).clamp(0.0, target);
      });
      await Future.delayed(const Duration(milliseconds: 30));
      return _paymentProgress < target;
    });
  }

  String _fmt(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},');
    return 'UGX $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 760),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header gradient
            _buildHeader(),
            // Step progress
            _buildStepProgress(),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child:
                    _step == 0 ? _buildStepOne() : _buildStepTwo(),
              ),
            ),
            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryGreen, _secondaryGreen],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Your Purchase',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Secure checkout powered by YooKatale',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: Colors.white, size: 24),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepProgress() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      child: Row(
        children: [
          _StepCircle(
              number: 1,
              label: 'Delivery',
              isActive: _step >= 0,
              isDone: _step > 0),
          Expanded(
            child: Container(
              height: 2,
              color: _step > 0 ? _primaryGreen : Colors.grey[300],
            ),
          ),
          _StepCircle(
              number: 2,
              label: 'Review',
              isActive: _step >= 1,
              isDone: false),
          Expanded(
            child: Container(
              height: 2,
              color: Colors.grey[300],
            ),
          ),
          _StepCircle(
              number: 3,
              label: 'Payment',
              isActive: false,
              isDone: false),
        ],
      ),
    );
  }

  Widget _buildStepOne() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Delivery method
        _SectionTitle(title: 'Delivery Method'),
        const SizedBox(height: 10),
        _buildDeliveryOption(
          key: 'standard',
          icon: Icons.inventory_2_rounded,
          title: 'Standard Delivery',
          subtitle: '1-2 days',
          price: 'UGX 3,500',
        ),
        const SizedBox(height: 8),
        _buildDeliveryOption(
          key: 'express',
          icon: Icons.directions_car_rounded,
          title: 'Express Delivery',
          subtitle: 'Same day',
          price: 'UGX 7,500',
        ),
        const SizedBox(height: 8),
        _buildDeliveryOption(
          key: 'scheduled',
          icon: Icons.calendar_today_rounded,
          title: 'Scheduled Delivery',
          subtitle: 'Choose date',
          price: 'UGX 4,500',
        ),
        const SizedBox(height: 20),

        // Delivery address
        _SectionTitle(title: 'Delivery Address'),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context)
                  .push<Map<String, dynamic>>(MaterialPageRoute(
                builder: (context) => LocationSearchPicker(
                  onLocationSelected: (locationData) {
                    Navigator.of(context).pop(locationData);
                  },
                  initialAddress: _address1Controller.text,
                  required: false,
                ),
              ));
              if (result != null && mounted) {
                setState(() {
                  _address1Controller.text =
                      result['address'] ?? result['address1'] ?? '';
                  _selectedLatitude =
                      result['lat'] as double? ?? result['latitude'] as double?;
                  _selectedLongitude =
                      result['lng'] as double? ?? result['longitude'] as double?;
                  if (_selectedLatitude != null &&
                      _selectedLongitude != null) {
                    _selectedLocation =
                        LatLng(_selectedLatitude!, _selectedLongitude!);
                  }
                });
                if (_address1Controller.text.trim().isNotEmpty) {
                  setState(() => _step = 1);
                }
              }
            },
            icon: const Icon(Icons.my_location_rounded, size: 18),
            label: const Text('Use My Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _styledField(
          controller: _address1Controller,
          label: 'Address Line 1',
          hint: 'Street, area or landmark',
          icon: Icons.location_on_rounded,
          suffix: _selectedLatitude != null
              ? const Icon(Icons.check_circle,
                  color: Color(0xFF2ECC71), size: 20)
              : null,
        ),
        const SizedBox(height: 10),
        _styledField(
          controller: _address2Controller,
          label: 'Address Line 2 (optional)',
          hint: 'Apartment, building, floor',
          icon: Icons.home_rounded,
        ),
        const SizedBox(height: 20),

        // Special requests
        _SectionTitle(title: 'Special Requests'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              CheckboxListTile(
                value: _peeledFood,
                activeColor: _primaryGreen,
                title: const Text('Peel Food',
                    style: TextStyle(fontSize: 14)),
                onChanged: (v) => setState(() => _peeledFood = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                dense: true,
              ),
              const Divider(height: 1, indent: 12, endIndent: 12),
              CheckboxListTile(
                value: _ecoPackaging,
                activeColor: _primaryGreen,
                title: const Text('Eco-Friendly Packaging',
                    style: TextStyle(fontSize: 14)),
                onChanged: (v) =>
                    setState(() => _ecoPackaging = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                dense: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _styledField(
          controller: _specialRequestsController,
          label: 'Additional instructions (optional)',
          hint: 'Any other notes for the delivery team',
          icon: Icons.notes_rounded,
          maxLines: 3,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDeliveryOption({
    required String key,
    required IconData icon,
    required String title,
    required String subtitle,
    required String price,
  }) {
    final isSelected = _deliveryMethod == key;
    return GestureDetector(
      onTap: () => setState(() => _deliveryMethod = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryGreen : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryGreen.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? _primaryGreen.withValues(alpha: 0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: isSelected ? _primaryGreen : Colors.grey[500],
                  size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isSelected ? _primaryGreen : Colors.black87)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Text(price,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? _primaryGreen : Colors.black87)),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _primaryGreen : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? _primaryGreen : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTwo() {
    final subtotal = widget.cartTotal;
    final total = subtotal + _deliveryFeeDisplay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Receipt card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Receipt header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryGreen, _secondaryGreen],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/logo1.webp',
                      width: 36,
                      height: 36,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.shopping_cart,
                          color: Colors.white,
                          size: 36),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('YooKatale',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text('Order Receipt',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              // Receipt IDs
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _ReceiptRow(
                        label: 'Receipt ID',
                        value: _receiptId,
                        valueStyle: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.black87)),
                    const SizedBox(height: 4),
                    _ReceiptRow(
                        label: 'Order ID',
                        value: _orderId,
                        valueStyle: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.black87)),
                    const SizedBox(height: 4),
                    _ReceiptRow(label: 'Date', value: _currentDateTime),
                    const Divider(height: 20),

                    // Customer name
                    FutureBuilder<Map<String, dynamic>?>(
                      future: AuthService.getUserData(),
                      builder: (_, snap) {
                        final name =
                            '${snap.data?['firstname'] ?? ''} ${snap.data?['lastname'] ?? ''}'
                                .trim();
                        return _ReceiptRow(
                            label: 'Customer',
                            value: name.isEmpty ? '—' : name);
                      },
                    ),
                    const Divider(height: 20),

                    // Items
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Items',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black54)),
                    ),
                    const SizedBox(height: 8),
                    ...widget.cartItems.map((item) {
                      final itemTotal =
                          (double.tryParse(item.price) ?? 0.0) * item.quantity;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.name} × ${item.quantity}',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black87),
                              ),
                            ),
                            Text(
                              _fmt(itemTotal),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryGreen),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 20),

                    // Totals
                    _ReceiptRow(
                        label: 'Subtotal', value: _fmt(subtotal)),
                    const SizedBox(height: 6),
                    _ReceiptRow(
                      label:
                          'Delivery (${_deliveryMethod[0].toUpperCase()}${_deliveryMethod.substring(1)})',
                      value: _fmt(_deliveryFeeDisplay),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text(_fmt(total),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: _primaryGreen)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // ETA
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF185F2D).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 16, color: _primaryGreen),
                          const SizedBox(width: 8),
                          Text('Estimated delivery: $_estimatedDelivery',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: _primaryGreen,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Trust badges
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _TrustBadge(
                  icon: Icons.lock_rounded, label: 'Secure\nCheckout'),
              _TrustBadge(
                  icon: Icons.local_shipping_rounded,
                  label: 'Fast\nDelivery'),
              _TrustBadge(
                  icon: Icons.headset_mic_rounded,
                  label: '24/7\nSupport'),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: _step == 0
          ? _GradientButton(
              label: 'Continue to Review',
              onPressed: _isLoading ? null : _handleContinue,
              icon: Icons.arrow_forward_rounded,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _paymentProgress,
                      backgroundColor: Colors.grey[200],
                      color: _primaryGreen,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _paymentProgress < 0.5
                        ? 'Creating your order…'
                        : _paymentProgress < 0.9
                            ? 'Almost there…'
                            : 'Redirecting to payment…',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _step = 0),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryGreen,
                        side: const BorderSide(color: _primaryGreen),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GradientButton(
                        label: _isLoading
                            ? 'Processing…'
                            : 'Proceed to Payment',
                        onPressed:
                            _isLoading ? null : _handleProceedToPayment,
                        icon: Icons.payment_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _styledField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 13, color: Colors.black54),
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
        prefixIcon: Icon(icon, size: 18, color: _primaryGreen),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: _primaryGreen, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ── Supporting widgets ──────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepCircle({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  static const _green = Color(0xFF185F2D);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? _green : Colors.grey[300],
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text(
                    '$number',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? _green : Colors.grey[500],
            fontWeight:
                isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: valueStyle ??
                const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF185F2D).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF185F2D)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const _GradientButton({
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              gradient: onPressed == null
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF185F2D), Color(0xFF1F793A)],
                    ),
              color: onPressed == null ? Colors.grey[300] : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: onPressed == null
                        ? Colors.grey[600]
                        : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                if (icon != null && onPressed != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: Colors.white, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
