import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/driver_auth_service.dart';
import '../../../services/error_handler_service.dart';

const _kGreen  = Color(0xFF0D7C3B);
const _kBg     = Color(0xFFF4F5F7);
const _kText   = Color(0xFF111111);
const _kMuted  = Color(0xFF9CA3AF);
const _kBorder = Color(0xFFF3F4F6);
const _kAmber  = Color(0xFFD97706);

class DriverHomeTab extends StatefulWidget {
  final VoidCallback? onSwitchToDelivery;
  const DriverHomeTab({super.key, this.onSwitchToDelivery});

  @override
  State<DriverHomeTab> createState() => _DriverHomeTabState();
}

class _DriverHomeTabState extends State<DriverHomeTab> {
  bool _loading   = true;
  bool _isOnline  = false;
  bool _toggling  = false;
  bool _accepting = false;
  String? _acceptingId;

  Map<String, dynamic>? _dashData;
  List<dynamic> _availableOrders = [];
  String _driverName = '';
  String _token      = '';
  String _driverId   = '';

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final token = await DriverAuthService.getToken();
    final id    = await DriverAuthService.getDriverId();
    final data  = await DriverAuthService.getDriverData();
    if (!mounted) return;
    _token      = token ?? '';
    _driverId   = id ?? '';
    _driverName = data?['name']?.toString() ?? data?['fullName']?.toString() ?? 'Driver';
    await _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) => _load());
  }

  Future<void> _load() async {
    if (_token.isEmpty || _driverId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final results = await Future.wait([
        ApiService.fetchDriverDashboard(token: _token, driverId: _driverId),
        ApiService.fetchDriverAvailableOrders(token: _token, driverId: _driverId),
      ]);
      if (!mounted) return;
      final dash = results[0];
      final ordRes = results[1];
      final dashData = dash['data'] is Map ? dash['data'] as Map<String, dynamic> : <String, dynamic>{};
      // Robust orders parsing — handles List, Map wrapper, and alternative keys
      final ordersRaw = ordRes['data'] ?? ordRes['orders'];
      List<dynamic> parsedOrders = [];
      if (ordersRaw is List) {
        parsedOrders = ordersRaw;
      } else if (ordersRaw is Map) {
        final inner = ordersRaw['orders'] ?? ordersRaw['data'] ?? ordersRaw['results'];
        if (inner is List) parsedOrders = inner;
      }
      final drv = dashData['driver'];
      setState(() {
        _dashData        = dashData;
        _isOnline        = drv?['isAvailable'] == true || drv?['isAvailable']?.toString() == 'true';
        _availableOrders = parsedOrders;
        _loading         = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle() async {
    if (_driverId.isEmpty || _toggling) return;
    setState(() => _toggling = true);
    try {
      final res = await ApiService.toggleDriverAvailabilityById(
          token: _token, driverId: _driverId);
      if (res['status'] == 'Success') {
        setState(() => _isOnline = res['data']?['isAvailable'] == true);
        _showToast(_isOnline ? 'You\'re online!' : 'You\'re offline');
      }
    } catch (e) {
      _showToast(ErrorHandlerService.getErrorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _accept(String orderId) async {
    if (_accepting) return;
    setState(() { _accepting = true; _acceptingId = orderId; });
    try {
      final res = await ApiService.acceptDriverOrder(
          token: _token, orderId: orderId, driverId: _driverId);
      if (res['status'] == 'Success') {
        _showToast('Order accepted! Navigate to pickup.');
        await _load();
      } else {
        _showToast(res['message']?.toString() ?? 'Failed to accept order', error: true);
      }
    } catch (e) {
      _showToast(ErrorHandlerService.getErrorMessage(e), error: true);
    } finally {
      if (mounted) setState(() { _accepting = false; _acceptingId = null; });
    }
  }

  void _showToast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red[700] : _kGreen,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _fmtK(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2.5),
      );
    }

    final driver        = (_dashData?['driver'] as Map?) ?? <String, dynamic>{};
    final activeDelivery = _dashData?['activeDelivery'];
    final todayTrips    = _dashData?['todayDeliveries'] ?? driver['todayDeliveries'] ?? 0;
    final weekEarnings  = _dashData?['weekEarnings'] ?? 0;
    final rating        = (driver['averageRating'] ?? 0.0) is num
        ? (driver['averageRating'] ?? 0.0) as num : 0;
    final ratingCount   = driver['ratingCount'] ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      color: _kGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_greeting(), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(_driverName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
              ]),
            ),

            // Stats grid — matches webapp 3-col
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                _statCard(
                  icon: Icons.inventory_2_outlined, iconBg: const Color(0xFFF0FDF4), iconColor: _kGreen,
                  value: '$todayTrips', unit: 'trips · Today',
                ),
                const SizedBox(width: 6),
                _statCard(
                  icon: Icons.trending_up_rounded, iconBg: const Color(0xFFFFFBEB), iconColor: _kAmber,
                  value: '${_fmtK(weekEarnings)}', unit: 'UGX · Week',
                ),
                const SizedBox(width: 6),
                _statCard(
                  icon: Icons.star_rounded, iconBg: const Color(0xFFFEFCE8), iconColor: _kAmber,
                  value: rating.toStringAsFixed(1), unit: '$ratingCount reviews',
                  starIcon: true,
                ),
              ]),
            ),

            // Active delivery banner — dark button like webapp
            if (activeDelivery != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: widget.onSwitchToDelivery,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kText,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Active Delivery',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text(
                          _extractAddress(activeDelivery),
                          style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x1F0D7C3B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _statusShort(activeDelivery['status']?.toString() ?? ''),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kGreen),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF6B7280), size: 16),
                    ]),
                  ),
                ),
              ),
            ],

            // Nearby orders header
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Nearby Orders',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kText)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Text('${_availableOrders.length}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kGreen)),
                ),
              ]),
            ),

            // Orders list or empty state
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _isOnline
                  ? _availableOrders.isEmpty
                      ? _emptyState(Icons.inventory_2_outlined, 'No orders right now', 'Stay online')
                      : Column(children: _availableOrders.map((o) => _orderCard(o)).toList())
                  : _emptyState(Icons.bolt_rounded, "You're offline", 'Go online to receive orders'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({required IconData icon, required Color iconBg, required Color iconColor,
    required String value, required String unit, bool starIcon = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(6)),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kText, height: 1)),
          Text(unit, style: const TextStyle(fontSize: 9, color: _kMuted, height: 1.4)),
        ]),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 28, color: const Color(0xFFD1D5DB)),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kText)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 11, color: _kMuted)),
      ]),
    );
  }

  Widget _orderCard(dynamic order) {
    final o  = order is Map ? order as Map<String, dynamic> : <String, dynamic>{};
    final id = o['_id']?.toString() ?? '';
    final shortId = id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
    final vendor = o['vendorId'] is Map ? o['vendorId'] as Map : <String, dynamic>{};
    final vendorName = vendor['businessName']?.toString() ?? vendor['name']?.toString() ?? 'Vendor';
    final addr = _extractAddress(o);
    final total = ((o['orderTotal'] ?? o['total'] ?? 0) as num).toInt();
    final earning = ((o['estimatedEarning'] ?? o['driverEarning'] ?? 0) as num).toInt();
    final items = (o['items'] ?? o['products']) is List ? (o['items'] ?? o['products']) as List : [];
    final isAccepting = _acceptingId == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Order #$shortId',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kText)),
            const SizedBox(height: 2),
            Text(vendorName, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(6),
            ),
            child: Text('+UGX ${_fmtK(earning)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kGreen)),
          ),
        ]),
        if (addr.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 12, color: _kMuted),
            const SizedBox(width: 4),
            Expanded(child: Text(addr, style: const TextStyle(fontSize: 11, color: _kMuted), overflow: TextOverflow.ellipsis)),
          ]),
        ],
        if (items.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('${items.length} item${items.length != 1 ? 's' : ''} · UGX ${_fmtK(total)}',
              style: const TextStyle(fontSize: 11, color: _kMuted)),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 38,
          child: ElevatedButton(
            onPressed: isAccepting ? null : () => _accept(id),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: isAccepting
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Accept Order', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  String _extractAddress(dynamic delivery) {
    if (delivery == null) return '';
    final addr = delivery['deliveryAddress'];
    if (addr is Map) return addr['address']?.toString() ?? addr['address1']?.toString() ?? '';
    return addr?.toString() ?? '';
  }

  String _statusShort(String s) {
    switch (s) {
      case 'assigned':    return 'Assigned';
      case 'picked_up':   return 'Picked Up';
      case 'in_transit':  return 'In Transit';
      case 'delivered':   return 'Delivered';
      default:            return s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : 'Active';
    }
  }
}
