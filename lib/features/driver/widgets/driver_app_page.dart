import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../services/api_service.dart';
import '../../../services/driver_auth_service.dart';
import 'driver_home_tab.dart';
import 'driver_delivery_tab.dart';
import 'driver_earnings_tab.dart';
import 'driver_profile_tab.dart';
import 'driver_notifications_page.dart';

// ── Theme constants (light — matches webapp) ─────────────────────────────
const kDrvBg      = Color(0xFFF4F5F7);
const kDrvWhite   = Colors.white;
const kDrvGreen   = Color(0xFF0D7C3B);
const kDrvText    = Color(0xFF111111);
const kDrvMuted   = Color(0xFF6B7280);
const kDrvBorder  = Color(0xFFE5E7EB);
const kDrvAmber   = Color(0xFF92400E);
const kDrvAmberBg = Color(0xFFFEF3C7);

class DriverAppPage extends StatefulWidget {
  const DriverAppPage({super.key});

  @override
  State<DriverAppPage> createState() => _DriverAppPageState();
}

class _DriverAppPageState extends State<DriverAppPage> {
  int _idx           = 0;
  bool _isOnline     = false;
  bool _toggling     = false;
  bool _hasActive    = false;
  String _driverName = '';
  String _driverAvatar = '';
  String _driverId   = '';
  String _token      = '';

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final token  = await DriverAuthService.getToken();
    final id     = await DriverAuthService.getDriverId();
    final driver = await DriverAuthService.getDriverData();
    if (!mounted) return;
    // Redirect to driver login if no session
    if (token == null || token.isEmpty || id == null || id.isEmpty) {
      Navigator.of(context).pushReplacementNamed('/driver');
      return;
    }
    setState(() {
      _token       = token;
      _driverId    = id;
      _driverName  = driver?['name']?.toString() ?? driver?['fullName']?.toString() ?? '';
      _driverAvatar = driver?['profileImage']?.toString() ?? driver?['profilePicture']?.toString() ?? '';
    });
    _fetchDashboardForHeader(token, id);
    _registerFcmToken(token, id);
  }

  Future<void> _registerFcmToken(String token, String driverId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, sound: true, badge: true);
      final fcmToken = await messaging.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await ApiService.updateDriverFcmToken(token: token, driverId: driverId, fcmToken: fcmToken);
      }
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (!mounted) return;
        final notif = message.notification;
        if (notif != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(notif.title ?? 'YooKatale Driver', style: const TextStyle(fontWeight: FontWeight.w700)),
              if (notif.body != null) Text(notif.body!, style: const TextStyle(fontSize: 12)),
            ]),
            backgroundColor: kDrvGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ));
          // Refresh header state
          _fetchDashboardForHeader(token, driverId);
        }
      });
    } catch (_) {} // FCM not available in all environments
  }

  Future<void> _fetchDashboardForHeader(String token, String id) async {
    try {
      final res = await ApiService.fetchDriverDashboard(token: token, driverId: id);
      if (!mounted) return;
      final data = res['data'];
      if (data is Map) {
        final drv = data['driver'];
        setState(() {
          _isOnline  = drv?['isAvailable'] == true || drv?['isAvailable']?.toString() == 'true';
          _hasActive = data['activeDelivery'] != null;
          // refresh avatar from live data
          final pic = drv?['profileImage']?.toString() ?? drv?['profilePicture']?.toString() ?? drv?['avatar']?.toString() ?? '';
          if (pic.isNotEmpty) _driverAvatar = pic;
          final name = drv?['name']?.toString() ?? drv?['fullName']?.toString() ?? '';
          if (name.isNotEmpty) _driverName = name;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleOnline() async {
    if (_driverId.isEmpty || _token.isEmpty || _toggling) return;
    setState(() => _toggling = true);
    try {
      final res = await ApiService.toggleDriverAvailabilityById(
          token: _token, driverId: _driverId);
      if (res['status'] == 'Success') {
        setState(() => _isOnline = res['data']?['isAvailable'] == true);
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _toggling = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDrvBg,
      appBar: _buildTopBar(),
      body: IndexedStack(
        index: _idx,
        children: [
          DriverHomeTab(onSwitchToDelivery: () => _setTab(1)),
          const DriverDeliveryTab(),
          const DriverEarningsTab(),
          const DriverProfileTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildTopBar() {
    return AppBar(
      backgroundColor: kDrvWhite,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 14,
      title: Row(children: [
        // Logo + brand
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(7)),
          clipBehavior: Clip.antiAlias,
          child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
        ),
        const SizedBox(width: 6),
        const Text('Yookatale',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kDrvText)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: kDrvAmberBg,
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Text('DRIVER',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                  color: kDrvAmber, letterSpacing: 0.3)),
        ),
      ]),
      actions: [
        // Online/Offline toggle
        GestureDetector(
          onTap: _toggleOnline,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _isOnline ? kDrvGreen : kDrvMuted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 5, height: 5,
                decoration: BoxDecoration(
                  color: _isOnline ? const Color(0xFF86EFAC) : const Color(0xFFD1D5DB),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _toggling ? '...' : (_isOnline ? 'Online' : 'Offline'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        // Notification bell
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => DriverNotificationsPage(token: _token, driverId: _driverId),
          )),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kDrvBorder),
            ),
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 16, color: kDrvText),
                if (_hasActive)
                  Positioned(
                    top: -2, right: -2,
                    child: Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(color: kDrvGreen, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Avatar
        GestureDetector(
          onTap: () => setState(() => _idx = 3),
          child: Container(
            margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: kDrvText,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: _driverAvatar.isNotEmpty
                ? Image.network(_driverAvatar, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initials())
                : _initials(),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: kDrvBorder),
      ),
    );
  }

  Widget _initials() {
    final parts = _driverName.split(' ');
    final ini = parts.map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join('').substring(0, parts.length > 1 ? 2 : 1);
    return Center(child: Text(ini.isEmpty ? 'D' : ini,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10)));
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: kDrvWhite,
        border: Border(top: BorderSide(color: kDrvBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavItem(icon: Icons.grid_view_rounded,      label: 'Home',     idx: 0, cur: _idx, onTap: _setTab),
              _NavItem(icon: Icons.delivery_dining_rounded, label: 'Delivery', idx: 1, cur: _idx, onTap: _setTab,
                  badge: _hasActive),
              _NavItem(icon: Icons.account_balance_wallet_outlined, label: 'Earnings', idx: 2, cur: _idx, onTap: _setTab),
              _NavItem(icon: Icons.person_outline_rounded, label: 'Profile',  idx: 3, cur: _idx, onTap: _setTab),
            ],
          ),
        ),
      ),
    );
  }

  void _setTab(int i) => setState(() => _idx = i);
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int idx, cur;
  final void Function(int) onTap;
  final bool badge;

  const _NavItem({
    required this.icon, required this.label,
    required this.idx, required this.cur, required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = idx == cur;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(idx),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(icon, size: 22,
                color: active ? kDrvGreen : kDrvMuted),
            if (badge)
              Positioned(
                top: -2, right: -4,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: kDrvGreen, shape: BoxShape.circle),
                ),
              ),
          ]),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? kDrvGreen : kDrvMuted)),
        ]),
      ),
    );
  }
}
