import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/error_handler_service.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import '../screens/order_tracking_screen.dart';

const _green = Color.fromRGBO(24, 95, 45, 1);

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> with SingleTickerProviderStateMixin {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  static const _tabs = ['All', 'Active', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final authState = ref.read(authStateProvider);
      final token = await AuthService.getToken();
      if (authState.userId == null || token == null) {
        if (mounted) setState(() { _error = 'Please sign in to view your orders'; _isLoading = false; });
        return;
      }
      final response = await ApiService.fetchUserOrders(authState.userId!, token: token);
      if (mounted) {
        setState(() {
          _orders = (response['data'] ?? response['orders']) is List
              ? (response['data'] ?? response['orders']) as List
              : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = ErrorHandlerService.getErrorMessage(e); _isLoading = false; });
    }
  }

  List<dynamic> _filtered(String tab) {
    if (tab == 'All') return _orders;
    final statuses = {
      'Active': ['pending', 'confirmed', 'preparing', 'awaiting_delivery', 'out_for_delivery'],
      'Completed': ['delivered', 'completed'],
      'Cancelled': ['cancelled'],
    }[tab] ?? [];
    return _orders.where((o) => statuses.contains((o['status'] ?? '').toString().toLowerCase())).toList();
  }

  String _formatCurrency(dynamic amount) {
    final amt = amount is num ? amount.toDouble() : double.tryParse(amount.toString()) ?? 0.0;
    return 'UGX ${amt.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString());
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Raleway')),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadOrders),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: _tabs.map((t) => _buildOrderList(_filtered(t), t)).toList(),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _error!.contains('sign in')
                  ? () => Navigator.pushNamed(context, '/signin')
                  : _loadOrders,
              icon: Icon(_error!.contains('sign in') ? Icons.login : Icons.refresh),
              label: Text(_error!.contains('sign in') ? 'Sign In' : 'Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders, String tab) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📦', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              tab == 'All' ? 'No orders yet' : 'No $tab orders',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              tab == 'All' ? 'Start shopping and your orders will appear here.' : 'Nothing to show here.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (tab == 'All') ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/home'),
                style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
                child: const Text('Start Shopping'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: _green,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, i) => _buildOrderCard(orders[i]),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final o = order is Map ? order as Map<String, dynamic> : <String, dynamic>{};
    final orderId = o['_id']?.toString() ?? o['id']?.toString() ?? '';
    final shortId = orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();
    final status = o['status']?.toString() ?? 'pending';
    final total = _formatCurrency(o['orderTotal'] ?? o['total'] ?? 0);
    final date = _formatDate(o['createdAt']);
    final items = (o['items'] ?? o['products']) is List ? (o['items'] ?? o['products']) as List : [];
    final isActive = ['pending', 'confirmed', 'preparing', 'awaiting_delivery', 'out_for_delivery'].contains(status.toLowerCase());
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _green.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.receipt_long_rounded, color: _green, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #$shortId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                        if (date.isNotEmpty)
                          Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

            // Items preview
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: items.take(2).map<Widget>((item) {
                    final name = item['name']?.toString() ?? item['title']?.toString() ?? 'Item';
                    final qty = item['quantity']?.toString() ?? '1';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: _green),
                          const SizedBox(width: 8),
                          Expanded(child: Text('$name × $qty', style: TextStyle(fontSize: 13, color: Colors.grey[700]), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (items.length > 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('+${items.length - 2} more items', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ),
              ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Divider(height: 1, color: Colors.grey[200]),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      Text(total, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _green)),
                    ],
                  ),
                  const Spacer(),
                  if (isActive && orderId.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)),
                      ),
                      icon: const Icon(Icons.location_on_rounded, size: 16),
                      label: const Text('Track', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    )
                  else
                    OutlinedButton(
                      onPressed: () => _showOrderDetails(o),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _green, side: const BorderSide(color: _green),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Details', style: TextStyle(fontSize: 13)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> o) {
    final orderId = o['_id']?.toString() ?? o['id']?.toString() ?? '';
    final shortId = orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();
    final status = o['status']?.toString() ?? 'pending';
    final items = (o['items'] ?? o['products']) is List ? (o['items'] ?? o['products']) as List : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text('Order Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text(_statusLabel(status), style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _detailRow('Order ID', '#$shortId'),
                    _detailRow('Date', _formatDate(o['createdAt'])),
                    _detailRow('Total', _formatCurrency(o['orderTotal'] ?? o['total'] ?? 0)),
                    if (o['deliveryAddress'] != null)
                      _detailRow('Address', o['deliveryAddress']['address1']?.toString() ?? ''),
                    const SizedBox(height: 16),
                    if (items.isNotEmpty) ...[
                      const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 10),
                      ...items.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          const Icon(Icons.shopping_basket_outlined, color: _green, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(item['name']?.toString() ?? item['title']?.toString() ?? 'Item',
                            style: const TextStyle(fontSize: 14))),
                          Text('×${item['quantity'] ?? 1}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          const SizedBox(width: 8),
                          Text(_formatCurrency(item['price'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ]),
                      )),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'preparing': return Colors.purple;
      case 'awaiting_delivery': return Colors.amber[700]!;
      case 'out_for_delivery': return _green;
      case 'delivered': case 'completed': return Colors.green[700]!;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'preparing': return 'Preparing';
      case 'awaiting_delivery': return 'Ready';
      case 'out_for_delivery': return 'On the Way';
      case 'delivered': return 'Delivered';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }
}
