import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

const _kGreen  = Color(0xFF0D7C3B);
const _kBg     = Color(0xFFF4F5F7);
const _kText   = Color(0xFF111111);
const _kMuted  = Color(0xFF9CA3AF);
const _kBorder = Color(0xFFE5E7EB);
const _kAmber  = Color(0xFFD97706);

class DriverNotificationsPage extends StatefulWidget {
  final String token;
  final String driverId;
  const DriverNotificationsPage({super.key, required this.token, required this.driverId});

  @override
  State<DriverNotificationsPage> createState() => _DriverNotificationsPageState();
}

class _DriverNotificationsPageState extends State<DriverNotificationsPage> {
  bool _loading = true;
  List<_Notif> _notifs = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.token.isEmpty || widget.driverId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final res = await ApiService.fetchDriverDashboard(token: widget.token, driverId: widget.driverId);
      final data = res['data'] as Map? ?? {};
      final notifs = <_Notif>[];

      // Active delivery notification
      final active = data['activeDelivery'];
      if (active is Map) {
        final status = active['status']?.toString() ?? 'assigned';
        notifs.add(_Notif(
          icon: Icons.delivery_dining_rounded,
          iconColor: _kGreen,
          iconBg: const Color(0xFFF0FDF4),
          title: 'Active Delivery',
          body: _statusMessage(status),
          time: _timeAgo(active['updatedAt']?.toString()),
          isNew: true,
        ));
      }

      // Recent deliveries as notifications
      final deliveries = data['recentDeliveries'];
      if (deliveries is List) {
        for (final d in deliveries.take(8)) {
          if (d is! Map) continue;
          final status = d['status']?.toString() ?? '';
          final addr = _extractAddress(d);
          final earning = ((d['driverEarning'] ?? d['earning'] ?? 0) as num).toInt();
          notifs.add(_Notif(
            icon: _statusIcon(status),
            iconColor: _statusColor(status),
            iconBg: _statusBg(status),
            title: _statusLabel(status),
            body: addr.isNotEmpty ? 'Delivered to $addr' : 'Order completed',
            sub: earning > 0 ? '+UGX ${_fmtK(earning)}' : null,
            time: _timeAgo(d['updatedAt']?.toString() ?? d['createdAt']?.toString()),
            isNew: false,
          ));
        }
      }

      // New available orders
      try {
        final ordRes = await ApiService.fetchDriverAvailableOrders(token: widget.token, driverId: widget.driverId);
        final orders = ordRes['data'];
        final orderList = orders is List ? orders : (orders is Map ? (orders['orders'] as List? ?? []) : <dynamic>[]);
        if (orderList.isNotEmpty) {
          notifs.insert(0, _Notif(
            icon: Icons.inbox_rounded,
            iconColor: _kAmber,
            iconBg: const Color(0xFFFFFBEB),
            title: '${orderList.length} new order${orderList.length > 1 ? 's' : ''} nearby',
            body: 'Go online to accept orders in your area',
            time: 'Just now',
            isNew: true,
          ));
        }
      } catch (_) {}

      if (mounted) setState(() { _notifs = notifs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'assigned':   return 'Order assigned — head to pickup location';
      case 'picked_up':  return 'Picked up — on the way to customer';
      case 'in_transit': return 'In transit — delivering to customer';
      case 'delivered':  return 'Delivery completed successfully';
      default: return 'Delivery in progress';
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'delivered': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.local_shipping_rounded;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'delivered': return _kGreen;
      case 'cancelled': return Colors.red;
      default: return _kAmber;
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'delivered': return const Color(0xFFF0FDF4);
      case 'cancelled': return const Color(0xFFFEF2F2);
      default: return const Color(0xFFFFFBEB);
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'delivered': return 'Order Delivered';
      case 'cancelled': return 'Order Cancelled';
      case 'in_transit': return 'In Transit';
      case 'picked_up': return 'Picked Up';
      default: return 'Order Update';
    }
  }

  String _extractAddress(Map d) {
    final addr = d['deliveryAddress'];
    if (addr is Map) return addr['address']?.toString() ?? '';
    return addr?.toString() ?? '';
  }

  String _fmtK(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }

  String _timeAgo(String? iso) {
    if (iso == null || iso.isEmpty) return 'Recently';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return 'Recently'; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _kText),
        ),
        title: const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kText)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: _kBorder)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kText, size: 20),
            onPressed: () { setState(() => _loading = true); _load(); },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2.5))
          : _notifs.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifs.length,
                    itemBuilder: (_, i) => _notifCard(_notifs[i]),
                  ),
                ),
    );
  }

  Widget _notifCard(_Notif n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: n.isNew ? _kGreen.withOpacity(0.3) : _kBorder),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: n.iconBg, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Icon(n.icon, color: n.iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(n.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kText))),
            if (n.isNew) Container(width: 7, height: 7,
                decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle)),
          ]),
          const SizedBox(height: 3),
          Text(n.body, style: const TextStyle(fontSize: 12, color: _kMuted, height: 1.4)),
          if (n.sub != null) ...[
            const SizedBox(height: 3),
            Text(n.sub!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen)),
          ],
          const SizedBox(height: 4),
          Text(n.time, style: const TextStyle(fontSize: 10, color: _kMuted)),
        ])),
      ]),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 64, height: 64,
            decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.notifications_none_rounded, size: 32, color: _kMuted)),
        const SizedBox(height: 16),
        const Text('No notifications yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kText)),
        const SizedBox(height: 6),
        const Text('New orders and delivery updates will appear here',
            style: TextStyle(fontSize: 12, color: _kMuted), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _Notif {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, body, time;
  final String? sub;
  final bool isNew;

  const _Notif({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.title, required this.body, required this.time,
    this.sub, this.isNew = false,
  });
}
