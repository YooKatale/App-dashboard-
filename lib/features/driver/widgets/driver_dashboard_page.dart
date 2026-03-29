import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/error_handler_service.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import '../../authentication/widgets/mobile_sign_in.dart';

const _green = Color.fromRGBO(24, 95, 45, 1);

class DriverDashboardPage extends ConsumerStatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  ConsumerState<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends ConsumerState<DriverDashboardPage>
    with SingleTickerProviderStateMixin {
  bool _isOnline = false;
  bool _isLoading = true;
  bool _isToggling = false;
  Map<String, dynamic>? _stats;
  List<dynamic> _availableOrders = [];
  Map<String, dynamic>? _activeDelivery;
  String? _error;
  Timer? _pollTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MobileSignInPage()),
        );
      }
      return;
    }
    await _loadData();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    if (!_isLoading) setState(() => _error = null);
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final results = await Future.wait([
        ApiService.fetchDriverStats(token: token),
        ApiService.fetchAvailableOrders(token: token),
        ApiService.fetchActiveDelivery(token: token),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0]['data'] as Map<String, dynamic>? ?? results[0];
          _isOnline = _stats?['isOnline'] == true || _stats?['online'] == true;
          final ordersData = results[1]['data'] ?? results[1]['orders'] ?? results[1];
          _availableOrders = ordersData is List ? ordersData : [];
          final activeData = results[2]['data'];
          _activeDelivery = activeData is Map ? activeData as Map<String, dynamic> : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandlerService.getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleAvailability() async {
    setState(() => _isToggling = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      await ApiService.toggleDriverAvailability(token: token, isOnline: !_isOnline);
      setState(() => _isOnline = !_isOnline);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isOnline ? 'You are now online' : 'You are now offline'),
          backgroundColor: _isOnline ? Colors.green : Colors.grey,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(context,
            message: ErrorHandlerService.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      await ApiService.acceptDeliveryOrder(token: token, orderId: orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order accepted!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(context,
            message: ErrorHandlerService.getErrorMessage(e));
      }
    }
  }

  Future<void> _updateDeliveryStatus(String orderId, String status) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      await ApiService.updateDeliveryStatus(token: token, orderId: orderId, status: status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to ${status.replaceAll('_', ' ')}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(context,
            message: ErrorHandlerService.getErrorMessage(e));
      }
    }
  }

  String _formatCurrency(dynamic amount) {
    final n = (amount is num) ? amount.toDouble() : double.tryParse(amount?.toString() ?? '0') ?? 0;
    return 'UGX ${n.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Driver Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Raleway')),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _isToggling
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : GestureDetector(
                    onTap: _toggleAvailability,
                    child: Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isOnline ? Colors.greenAccent : Colors.grey[300],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isOnline ? 'Online' : 'Offline',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Orders'),
            Tab(text: 'Earnings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDashboard(),
                    _buildOrders(),
                    _buildEarnings(),
                  ],
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
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final todayDeliveries = _stats?['todayDeliveries'] ?? _stats?['deliveriesToday'] ?? 0;
    final weeklyEarnings = _stats?['weeklyEarnings'] ?? _stats?['earnings'] ?? 0;
    final rating = _stats?['rating'] ?? _stats?['averageRating'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _green,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isOnline
                      ? [const Color(0xFF185f2d), const Color(0xFF2e7d32)]
                      : [Colors.grey[600]!, Colors.grey[700]!],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isOnline ? Icons.two_wheeler : Icons.pause_circle_outline,
                      color: Colors.white, size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isOnline ? 'You\'re Online' : 'You\'re Offline',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isOnline ? 'Ready to receive delivery orders' : 'Tap to go online',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOnline,
                    onChanged: _isToggling ? null : (_) => _toggleAvailability(),
                    activeColor: Colors.white,
                    activeTrackColor: Colors.greenAccent,
                    inactiveTrackColor: Colors.grey[400],
                    inactiveThumbColor: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats grid
            const Text('Today\'s Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard(Icons.delivery_dining, 'Deliveries', todayDeliveries.toString(), Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(Icons.account_balance_wallet, 'Weekly', _formatCurrency(weeklyEarnings), _green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(Icons.star_rounded, 'Rating',
                    '${rating is double ? rating.toStringAsFixed(1) : rating}/5', Colors.amber[700]!)),
              ],
            ),
            const SizedBox(height: 24),

            // Active delivery
            if (_activeDelivery != null) ...[
              const Text('Active Delivery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              _buildActiveDeliveryCard(),
              const SizedBox(height: 24),
            ],

            // Quick actions
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    Icons.list_alt, 'Available Orders',
                    '${_availableOrders.length} waiting',
                    Colors.orange,
                    () => _tabController.animateTo(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    Icons.bar_chart, 'My Earnings',
                    'View details',
                    Colors.purple,
                    () => _tabController.animateTo(2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveDeliveryCard() {
    final order = _activeDelivery!;
    final orderId = order['_id']?.toString() ?? order['orderId']?.toString() ?? '';
    final status = order['status']?.toString() ?? 'pending';
    final address = order['deliveryAddress']?.toString() ?? order['address']?.toString() ?? 'N/A';
    final amount = order['totalAmount'] ?? order['amount'] ?? 0;

    Color statusColor;
    String statusLabel;
    String nextStatus;
    String nextStatusLabel;

    switch (status) {
      case 'assigned':
        statusColor = Colors.blue;
        statusLabel = 'Assigned';
        nextStatus = 'picked_up';
        nextStatusLabel = 'Mark Picked Up';
        break;
      case 'picked_up':
        statusColor = Colors.orange;
        statusLabel = 'Picked Up';
        nextStatus = 'in_transit';
        nextStatusLabel = 'Start Transit';
        break;
      case 'in_transit':
        statusColor = Colors.purple;
        statusLabel = 'In Transit';
        nextStatus = 'delivered';
        nextStatusLabel = 'Mark Delivered';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status;
        nextStatus = '';
        nextStatusLabel = '';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #${orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(address, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.attach_money, color: _green, size: 16),
              const SizedBox(width: 6),
              Text(_formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          if (nextStatus.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _updateDeliveryStatus(orderId, nextStatus),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(nextStatusLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrders() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _green,
      child: _availableOrders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    _isOnline ? 'No orders available right now' : 'Go online to see available orders',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (!_isOnline)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ElevatedButton(
                        onPressed: _toggleAvailability,
                        style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
                        child: const Text('Go Online'),
                      ),
                    ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availableOrders.length,
              itemBuilder: (_, i) => _buildOrderCard(_availableOrders[i]),
            ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final o = order is Map ? order as Map<String, dynamic> : <String, dynamic>{};
    final orderId = o['_id']?.toString() ?? o['orderId']?.toString() ?? '';
    final address = o['deliveryAddress']?.toString() ?? o['address']?.toString() ?? 'N/A';
    final amount = o['totalAmount'] ?? o['amount'] ?? 0;
    final distance = o['distance']?.toString();
    final items = o['items'];
    final itemCount = items is List ? items.length : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (distance != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
                    child: Text('$distance km', style: TextStyle(color: Colors.blue[700], fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(address, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: _green, size: 16),
                const SizedBox(width: 6),
                Text('$itemCount item${itemCount != 1 ? 's' : ''}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                const Spacer(),
                Text(_formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: _green)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _acceptOrder(orderId),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Accept Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnings() {
    final totalEarnings = _stats?['totalEarnings'] ?? _stats?['earnings'] ?? 0;
    final weeklyEarnings = _stats?['weeklyEarnings'] ?? 0;
    final todayEarnings = _stats?['todayEarnings'] ?? 0;
    final totalDeliveries = _stats?['totalDeliveries'] ?? 0;
    final completionRate = _stats?['completionRate'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _green,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF185f2d), Color(0xFF2e7d32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(totalEarnings),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildEarningRow('Today', _formatCurrency(todayEarnings), Icons.today, Colors.blue),
            _buildEarningRow('This Week', _formatCurrency(weeklyEarnings), Icons.date_range, Colors.orange),
            _buildEarningRow('Total Deliveries', '$totalDeliveries', Icons.delivery_dining, _green),
            _buildEarningRow(
              'Completion Rate',
              '${completionRate is double ? completionRate.toStringAsFixed(1) : completionRate}%',
              Icons.check_circle_outline,
              Colors.purple,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Earnings are paid out weekly to your registered mobile money account.',
                      style: TextStyle(color: Colors.blue[800], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningRow(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
