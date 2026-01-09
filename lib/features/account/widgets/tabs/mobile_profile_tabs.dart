import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../services/api_service.dart';
import '../../../../services/auth_service.dart';
import '../../../receipt/widgets/receipt_page.dart';

// Orders Tab - EXACTLY SYNCHRONIZED WITH WEBAPP
class MobileOrdersTab extends ConsumerStatefulWidget {
  const MobileOrdersTab({super.key});

  @override
  ConsumerState<MobileOrdersTab> createState() => _MobileOrdersTabState();
}

class _MobileOrdersTabState extends ConsumerState<MobileOrdersTab> {
  List<dynamic> _allOrders = [];
  List<dynamic> _completedOrders = [];
  bool _isLoading = true;
  String _selectedTab = 'active'; // 'active' or 'completed' - EXACT WEBAPP LOGIC

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userData = await AuthService.getUserData();
      final token = await AuthService.getToken();
      final userId = userData?['_id']?.toString() ?? userData?['id']?.toString();
      
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // Use the same endpoint as webapp: /products/orders/:userId
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/products/orders/$userId'),
        headers: ApiService.getHeaders(token: token),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'Success' && data['data'] != null) {
          // Webapp returns { AllOrders: [], CompletedOrders: [] } - EXACT WEBAPP FORMAT
          final ordersData = data['data'];
          final allOrders = ordersData['AllOrders'] ?? [];
          final completedOrders = ordersData['CompletedOrders'] ?? [];
          
          setState(() {
            // Store both arrays separately (like webapp)
            _allOrders = allOrders;
            _completedOrders = completedOrders;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_allOrders.isEmpty && _completedOrders.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No orders yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Tab buttons - EXACT WEBAPP UI
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTabButton(
                              'Active Orders',
                              _selectedTab == 'active',
                              () {
                                setState(() => _selectedTab = 'active');
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTabButton(
                              'Completed Orders',
                              _selectedTab == 'completed',
                              () {
                                setState(() => _selectedTab = 'completed');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Orders list - EXACT WEBAPP LOGIC
                    Expanded(
                      child: _selectedTab == 'active'
                          ? _buildActiveOrdersList()
                          : _buildCompletedOrdersList(),
                    ),
                  ],
                ),
    );
  }

  // Tab button widget - matches webapp styling
  Widget _buildTabButton(String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color.fromRGBO(24, 95, 45, 1) : Colors.transparent,
          border: Border.all(
            color: const Color.fromRGBO(24, 95, 45, 1),
            width: 1.7,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // Active Orders List - EXACT WEBAPP LOGIC: AllOrders where status !== "completed"
  Widget _buildActiveOrdersList() {
    // Filter: order?.status !== "completed" (EXACT WEBAPP LOGIC)
    final activeOrders = _allOrders.where((order) {
      final orderData = order['order'] ?? order;
      final status = orderData['status']?.toString().toLowerCase() ?? '';
      return status != 'completed';
    }).toList();

    if (activeOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Text(
            "You don't have active orders",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeOrders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(activeOrders[index]);
      },
    );
  }

  // Completed Orders List - EXACT WEBAPP LOGIC: Use CompletedOrders array
  Widget _buildCompletedOrdersList() {
    if (_completedOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Text(
            "You don't have completed orders",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completedOrders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(_completedOrders[index]);
      },
    );
  }

  // Order Card - Professional UI with black text on white background
  Widget _buildOrderCard(dynamic order) {
    final orderData = order['order'] ?? order;
    final orderId = order['_id']?.toString() ?? orderData['_id']?.toString() ?? 'N/A';
    final total = orderData['orderTotal'] ?? orderData['total'] ?? 0;
    final status = orderData['status']?.toString() ?? 'pending';
    final paymentMethod = orderData['payment']?['paymentMethod']?.toString() ?? 
                        orderData['paymentMethod']?.toString() ?? '__';
    final productItems = order['productItems']?.toString() ?? 
                       order['products']?.length?.toString() ?? '__';
    final deliveryAddress = orderData['deliveryAddress'];
    final specialRequest = orderData['specialRequest'] ?? orderData['specialRequests'];
    final createdAt = order['createdAt'] ?? orderData['createdAt'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Order ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ID',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        orderId.length > 20 ? '${orderId.substring(0, 20)}...' : orderId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // Order Details
            _buildOrderDetailRow('Products', productItems),
            _buildOrderDetailRow('Payment Method', paymentMethod),
            _buildOrderDetailRow('Order Total', 'UGX ${_formatCurrency(total)}'),
            // Delivery Address
            if (deliveryAddress != null) ...[
              if (deliveryAddress is Map && deliveryAddress['address1'] != null && deliveryAddress['address1'] != '')
                _buildOrderDetailRow('Delivery Address 1', deliveryAddress['address1']),
              if (deliveryAddress is Map && deliveryAddress['address2'] != null && deliveryAddress['address2'] != '')
                _buildOrderDetailRow('Delivery Address 2', deliveryAddress['address2']),
            ],
            // Special Requests
            if (specialRequest != null) ...[
              if (specialRequest is Map && specialRequest['peeledFood'] != null)
                _buildOrderDetailRow('Peel Food', specialRequest['peeledFood'].toString()),
              if (specialRequest is Map && specialRequest['moreInfo'] != null)
                _buildOrderDetailRow('Other Requests', specialRequest['moreInfo']),
            ],
            // Date
            if (createdAt != null) ...[
              const SizedBox(height: 8),
              _buildOrderDetailRow('Date', _formatDate(createdAt)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _formatCurrency(dynamic amount) {
    final amountValue = amount is num ? amount : double.tryParse(amount.toString()) ?? 0;
    return amountValue.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatDate(dynamic date) {
    try {
      if (date is String) {
        final parsed = DateTime.parse(date);
        final now = DateTime.now();
        final difference = now.difference(parsed);
        
        if (difference.inDays == 0) {
          if (difference.inHours == 0) {
            if (difference.inMinutes == 0) {
              return 'Just now';
            }
            return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
          }
          return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
        } else if (difference.inDays == 1) {
          return 'Yesterday';
        } else if (difference.inDays < 7) {
          return '${difference.inDays} days ago';
        } else {
          return '${parsed.day}/${parsed.month}/${parsed.year}';
        }
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }
}

// Subscriptions Tab
class MobileSubscriptionsTab extends ConsumerStatefulWidget {
  const MobileSubscriptionsTab({super.key});

  @override
  ConsumerState<MobileSubscriptionsTab> createState() =>
      _MobileSubscriptionsTabState();
}

class _MobileSubscriptionsTabState
    extends ConsumerState<MobileSubscriptionsTab> {
  List<dynamic> _subscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    try {
      final userData = await AuthService.getUserData();
      final token = await AuthService.getToken();
      final userId = userData?['_id']?.toString() ?? userData?['id']?.toString();
      
      if (userId != null) {
        final response = await ApiService.fetchUserSubscriptions(userId, token: token);
        if (response['status'] == 'Success' && response['data'] != null) {
          setState(() {
            _subscriptions = response['data'] is List 
                ? response['data'] as List 
                : [response['data']];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subscriptions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_membership,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No active subscriptions',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/subscription');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Browse Subscriptions'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subscriptions.length,
                  itemBuilder: (context, index) {
                    final subscription = _subscriptions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.card_membership,
                            color: Color.fromRGBO(24, 95, 45, 1)),
                        title: Text(
                          subscription['packageName']?.toString() ?? 'Subscription',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Status: ${subscription['status'] ?? 'Active'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Show subscription details
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
