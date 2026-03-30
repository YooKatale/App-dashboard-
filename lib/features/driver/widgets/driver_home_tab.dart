import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/error_handler_service.dart';
import '../../authentication/providers/auth_provider.dart';

const _kBg     = Color(0xFF0A0F14);
const _kCard   = Color(0xFF111820);
const _kBorder = Color(0xFF1E2D3D);
const _kGreen  = Color(0xFF00C853);
const _kGreenDim = Color(0xFF1A5C1A);
const _kText   = Color(0xFFE0E6ED);
const _kMuted  = Color(0xFF8A99AA);
const _kOrange = Color(0xFFE07820);

class DriverHomeTab extends ConsumerStatefulWidget {
  const DriverHomeTab({super.key});

  @override
  ConsumerState<DriverHomeTab> createState() => _DriverHomeTabState();
}

class _DriverHomeTabState extends ConsumerState<DriverHomeTab> {
  bool _isOnline  = false;
  bool _toggling  = false;
  bool _loading   = true;
  String? _error;
  Map<String, dynamic>? _stats;
  List<dynamic> _orders = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      final results = await Future.wait([
        ApiService.fetchDriverStats(token: token),
        ApiService.fetchAvailableOrders(token: token),
      ]);
      if (mounted) {
        final statsRaw = results[0];
        final stats = statsRaw['data'] is Map
            ? statsRaw['data'] as Map<String, dynamic>
            : statsRaw;
        final ordersRaw = results[1];
        final orders = ordersRaw['data'] ?? ordersRaw['orders'] ?? ordersRaw;
        setState(() {
          _stats   = stats;
          _isOnline = stats['isOnline'] == true || stats['online'] == true;
          _orders   = orders is List ? orders : [];
          _loading  = false;
          _error    = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = ErrorHandlerService.getErrorMessage(e); });
    }
  }

  Future<void> _toggle() async {
    setState(() => _toggling = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      await ApiService.toggleDriverAvailability(token: token, isOnline: !_isOnline);
      setState(() => _isOnline = !_isOnline);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ErrorHandlerService.getErrorMessage(e)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _accept(String orderId) async {
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
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ErrorHandlerService.getErrorMessage(e)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  String _fmt(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;
    return 'UGX ${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final authState  = ref.watch(authStateProvider);
    final firstName  = authState.firstName ?? 'Driver';
    final now        = DateTime.now();
    final greeting   = now.hour < 12 ? 'Good morning' : now.hour < 17 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kGreen))
            : RefreshIndicator(
                color: _kGreen,
                backgroundColor: _kCard,
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top bar ──────────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0D1E14), Color(0xFF0A0F14)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$greeting,',
                                          style: const TextStyle(
                                              color: _kMuted, fontSize: 13)),
                                      Text(firstName,
                                          style: const TextStyle(
                                              color: _kText,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                ),
                                // Online/offline toggle
                                GestureDetector(
                                  onTap: _toggling ? null : _toggle,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _isOnline
                                          ? _kGreen.withOpacity(0.15)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _isOnline ? _kGreen : Colors.grey,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: _toggling
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: _kGreen))
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 8, height: 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: _isOnline
                                                      ? _kGreen
                                                      : Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _isOnline ? 'Online' : 'Offline',
                                                style: TextStyle(
                                                  color: _isOnline
                                                      ? _kGreen
                                                      : Colors.grey,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Stats row
                            Row(
                              children: [
                                _StatCard(
                                  label: 'Deliveries',
                                  value: (_stats?['totalDeliveries'] ??
                                      _stats?['deliveries'] ??
                                      _stats?['completed'] ?? 0).toString(),
                                  icon: Icons.delivery_dining_rounded,
                                ),
                                const SizedBox(width: 10),
                                _StatCard(
                                  label: "Today's Earnings",
                                  value: _fmt(_stats?['todayEarnings'] ??
                                      _stats?['today'] ?? 0),
                                  icon: Icons.payments_rounded,
                                ),
                                const SizedBox(width: 10),
                                _StatCard(
                                  label: 'Rating',
                                  value: (_stats?['rating'] ?? 5.0).toStringAsFixed(1),
                                  icon: Icons.star_rounded,
                                  iconColor: const Color(0xFFFFCC00),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Available Orders ─────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Row(
                          children: [
                            const Text('Available Orders',
                                style: TextStyle(
                                    color: _kText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            if (_orders.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _kOrange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _orders.length.toString(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                          ],
                        ),
                      ),

                      if (!_isOnline)
                        _OfflineBanner()
                      else if (_orders.isEmpty)
                        _EmptyOrders()
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _orders.length,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemBuilder: (_, i) => _OrderCard(
                            order: _orders[i] as Map<String, dynamic>,
                            onAccept: _accept,
                            formatCurrency: _fmt,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor = _kGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: _kText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: _kMuted, fontSize: 9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.wifi_off_rounded, color: _kMuted, size: 40),
          SizedBox(height: 10),
          Text("You're Offline",
              style: TextStyle(color: _kText, fontSize: 16, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Go online to start receiving orders',
              style: TextStyle(color: _kMuted, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, color: _kMuted, size: 44),
          SizedBox(height: 10),
          Text('No available orders',
              style: TextStyle(color: _kText, fontSize: 16, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('New orders will appear here when available',
              style: TextStyle(color: _kMuted, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final Future<void> Function(String) onAccept;
  final String Function(dynamic) formatCurrency;

  const _OrderCard({
    required this.order,
    required this.onAccept,
    required this.formatCurrency,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _accepting = false;

  @override
  Widget build(BuildContext context) {
    final order   = widget.order;
    final orderId = order['_id']?.toString() ?? order['id']?.toString() ?? '';
    final items   = order['items'] as List? ?? [];
    final total   = order['totalPrice'] ?? order['total'] ?? order['amount'] ?? 0;
    final address = order['deliveryAddress']?.toString() ??
        order['address']?.toString() ?? 'N/A';
    final distance = order['distance']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shopping_bag_rounded,
                    color: _kGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId}',
                        style: const TextStyle(
                            color: _kText,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    Text('${items.length} item${items.length != 1 ? 's' : ''}',
                        style: const TextStyle(color: _kMuted, fontSize: 11)),
                  ],
                ),
              ),
              Text(widget.formatCurrency(total),
                  style: const TextStyle(
                      color: _kGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: _kOrange, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(address,
                    style: const TextStyle(color: _kMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (distance.isNotEmpty)
                Text(distance,
                    style: const TextStyle(color: _kMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {/* decline */},
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Decline',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _accepting ? null : () async {
                    setState(() => _accepting = true);
                    await widget.onAccept(orderId);
                    if (mounted) setState(() => _accepting = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C853), Color(0xFF1A8E3E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: _accepting
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Accept Order',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
