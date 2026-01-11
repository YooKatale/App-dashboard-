import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/realtime_service.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import 'package:intl/intl.dart';

/// Real-time order tracking screen (like Jumia Foods/Glovo)
/// Shows order status, delivery progress, and live location tracking
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final RealtimeService _realtimeService = RealtimeService();
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _deliveryLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _setupRealtimeListeners();
  }

  Future<void> _loadOrder() async {
    try {
      final userData = await AuthService.getUserData();
      final token = await AuthService.getAuthToken();
      
      final response = await ApiService.fetchOrder(widget.orderId, token: token);
      if (response['status'] == 'Success' || response['data'] != null) {
        setState(() {
          _order = response['data'] ?? response;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading order: $e')),
        );
      }
    }
  }

  void _setupRealtimeListeners() {
    // Listen to order updates in real-time
    _realtimeService.watchOrder(widget.orderId).listen((orderData) {
      if (orderData != null && mounted) {
        setState(() {
          _order = orderData;
        });
      }
    });

    // Listen to delivery location updates
    _realtimeService.watchDeliveryLocation(widget.orderId).listen((location) {
      if (location != null && mounted) {
        setState(() {
          _deliveryLocation = location;
        });
      }
    });
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Order Confirmed';
      case 'preparing':
        return 'Preparing Your Order';
      case 'awaiting_delivery':
        return 'Awaiting Delivery';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      default:
        return 'Processing';
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Icons.shopping_cart;
      case 'confirmed':
        return Icons.check_circle;
      case 'preparing':
        return Icons.restaurant;
      case 'awaiting_delivery':
        return Icons.local_shipping;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.hourglass_empty;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'awaiting_delivery':
        return Colors.amber;
      case 'out_for_delivery':
        return Colors.green;
      case 'delivered':
      case 'completed':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  int _getStatusProgress(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 1;
      case 'confirmed':
        return 2;
      case 'preparing':
        return 3;
      case 'awaiting_delivery':
        return 4;
      case 'out_for_delivery':
        return 5;
      case 'delivered':
      case 'completed':
        return 6;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Tracking'),
          backgroundColor: Colors.green.shade700,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Tracking'),
          backgroundColor: Colors.green.shade700,
        ),
        body: const Center(child: Text('Order not found')),
      );
    }

    final status = _order!['status']?.toString() ?? 'pending';
    final statusProgress = _getStatusProgress(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Your Order'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getStatusText(status),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Order #${widget.orderId.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Progress Timeline
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Progress',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildProgressStep(
                    'Order Placed',
                    Icons.shopping_cart,
                    statusProgress >= 1,
                  ),
                  _buildProgressStep(
                    'Order Confirmed',
                    Icons.check_circle,
                    statusProgress >= 2,
                  ),
                  _buildProgressStep(
                    'Preparing',
                    Icons.restaurant,
                    statusProgress >= 3,
                  ),
                  _buildProgressStep(
                    'Awaiting Delivery',
                    Icons.local_shipping,
                    statusProgress >= 4,
                  ),
                  _buildProgressStep(
                    'Out for Delivery',
                    Icons.delivery_dining,
                    statusProgress >= 5,
                  ),
                  _buildProgressStep(
                    'Delivered',
                    Icons.check_circle_outline,
                    statusProgress >= 6,
                    isLast: true,
                  ),
                ],
              ),
            ),

            // Delivery Map (if location available)
            if (_deliveryLocation != null &&
                _deliveryLocation!['location'] != null)
              Container(
                height: 300,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _deliveryLocation!['location']['lat']?.toDouble() ?? 0.0,
                        _deliveryLocation!['location']['lng']?.toDouble() ?? 0.0,
                      ),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('delivery'),
                        position: LatLng(
                          _deliveryLocation!['location']['lat']?.toDouble() ?? 0.0,
                          _deliveryLocation!['location']['lng']?.toDouble() ?? 0.0,
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                      ),
                    },
                  ),
                ),
              ),

            // Order Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Order ID', widget.orderId.substring(0, 8)),
                  if (_order!['createdAt'] != null)
                    _buildDetailRow(
                      'Order Date',
                      DateFormat('MMM dd, yyyy HH:mm').format(
                        DateTime.parse(_order!['createdAt']),
                      ),
                    ),
                  if (_order!['deliveryAddress'] != null)
                    _buildDetailRow(
                      'Delivery Address',
                      _order!['deliveryAddress']['address1']?.toString() ?? 'N/A',
                    ),
                  if (_order!['total'] != null)
                    _buildDetailRow(
                      'Total Amount',
                      'UGX ${_order!['total'].toString()}',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(
    String title,
    IconData icon,
    bool isCompleted, {
    bool isLast = false,
  }) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.green.shade700 : Colors.grey.shade300,
              ),
              child: Icon(
                icon,
                color: isCompleted ? Colors.white : Colors.grey,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green.shade700 : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              color: isCompleted ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _realtimeService.dispose();
    super.dispose();
  }
}
