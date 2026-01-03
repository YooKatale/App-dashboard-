import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../services/api_service.dart';
import '../../../../services/auth_service.dart';

// Orders Tab
class MobileOrdersTab extends ConsumerStatefulWidget {
  const MobileOrdersTab({super.key});

  @override
  ConsumerState<MobileOrdersTab> createState() => _MobileOrdersTabState();
}

class _MobileOrdersTabState extends ConsumerState<MobileOrdersTab> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

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
          // Webapp returns { AllOrders: [], CompletedOrders: [] }
          final ordersData = data['data'];
          final allOrders = ordersData['AllOrders'] ?? [];
          final completedOrders = ordersData['CompletedOrders'] ?? [];
          
          setState(() {
            _orders = allOrders; // Show all orders
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
        title: const Text('My Orders'),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
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
              : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Color.fromRGBO(24, 95, 45, 1),
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(text: 'Active Orders'),
                          Tab(text: 'Completed Orders'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildOrdersList(_orders.where((o) {
                              final status = o['order']?['status']?.toString().toLowerCase() ?? 
                                           o['status']?.toString().toLowerCase() ?? '';
                              return status != 'completed' && status != 'delivered';
                            }).toList()),
                            _buildOrdersList(_orders.where((o) {
                              final status = o['order']?['status']?.toString().toLowerCase() ?? 
                                           o['status']?.toString().toLowerCase() ?? '';
                              return status == 'completed' || status == 'delivered';
                            }).toList()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildOrdersList(List<dynamic> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final orderData = order['order'] ?? order;
        final orderId = order['_id']?.toString() ?? orderData['_id']?.toString() ?? 'N/A';
        final total = orderData['orderTotal'] ?? orderData['total'] ?? 0;
        final status = orderData['status']?.toString() ?? 'pending';
        final paymentMethod = orderData['payment']?['paymentMethod']?.toString() ?? 
                            orderData['paymentMethod']?.toString() ?? 'N/A';
        final productItems = order['productItems']?.toString() ?? 
                           order['products']?.length?.toString() ?? '0';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Order ID: ${orderId.length > 12 ? orderId.substring(0, 12) : orderId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildOrderDetailRow('Products', productItems),
                _buildOrderDetailRow('Payment Method', paymentMethod),
                _buildOrderDetailRow('Total', 'UGX ${_formatCurrency(total)}'),
                if (orderData['deliveryAddress'] != null)
                  _buildOrderDetailRow(
                    'Address',
                    orderData['deliveryAddress'] is Map
                        ? orderData['deliveryAddress']['address1']?.toString() ?? 'N/A'
                        : orderData['deliveryAddress'].toString(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildOrderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
