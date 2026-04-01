import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/api_service.dart';
import '../../../services/driver_auth_service.dart';
import '../../../services/error_handler_service.dart';

const _kBg     = Color(0xFFF4F5F7);
const _kGreen  = Color(0xFF0D7C3B);
const _kText   = Color(0xFF111111);
const _kMuted  = Color(0xFF9CA3AF);
const _kBorder = Color(0xFFE5E7EB);
const _kOrange = Color(0xFFD97706);

class DriverDeliveryTab extends StatefulWidget {
  const DriverDeliveryTab({super.key});

  @override
  State<DriverDeliveryTab> createState() => _DriverDeliveryTabState();
}

class _DriverDeliveryTabState extends State<DriverDeliveryTab> {
  Map<String, dynamic>? _activeDelivery;
  bool _loading = true;
  bool _updatingStatus = false;
  Timer? _timer;
  GoogleMapController? _mapCtrl;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  double? _minsToPickup;
  double? _minsToDelivery;
  LatLng? _driverPos;

  String _token = '';
  String _driverId = '';

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    _token    = await DriverAuthService.getToken() ?? '';
    _driverId = await DriverAuthService.getDriverId() ?? '';
    await _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      if (_token.isEmpty) return;

      Map<String, dynamic>? deliveryData;
      if (_driverId.isNotEmpty) {
        try {
          final dash = await ApiService.fetchDriverDashboard(token: _token, driverId: _driverId);
          final data = dash['data'];
          if (data is Map && data['activeDelivery'] is Map) {
            deliveryData = Map<String, dynamic>.from(data['activeDelivery'] as Map);
          }
        } catch (_) {}
      }
      if (deliveryData == null) {
        final res = await ApiService.fetchActiveDelivery(token: _token);
        final data = res['data'];
        if (data is Map) deliveryData = Map<String, dynamic>.from(data as Map);
      }

      // Real GPS
      try {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
              .timeout(const Duration(seconds: 5));
          if (mounted) _driverPos = LatLng(pos.latitude, pos.longitude);
          if (deliveryData != null && _token.isNotEmpty) {
            final delivId = deliveryData['_id']?.toString() ?? deliveryData['id']?.toString() ?? '';
            final status  = deliveryData['status']?.toString() ?? 'in_transit';
            if (delivId.isNotEmpty) {
              ApiService.updateDriverDeliveryStatus(
                token: _token, deliveryId: delivId, status: status,
                lat: pos.latitude, lng: pos.longitude);
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _activeDelivery = deliveryData;
          _loading = false;
          if (_activeDelivery != null) _buildMapData();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _buildMapData() {
    final d = _activeDelivery!;
    final markers   = <Marker>{};
    final polylines = <Polyline>{};

    // Driver position — prefer real GPS
    final driverLat = _driverPos?.latitude  ?? _toDouble(d['driverLat'] ?? d['driver']?['lat']);
    final driverLng = _driverPos?.longitude ?? _toDouble(d['driverLng'] ?? d['driver']?['lng']);
    if (driverLat != null && driverLng != null) {
      _driverPos = LatLng(driverLat, driverLng);
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _driverPos!,
        infoWindow: const InfoWindow(title: 'You'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    // Pickup
    final pickupLat = _toDouble(d['pickupLat'] ?? d['pickup']?['lat'] ?? d['vendor']?['lat']);
    final pickupLng = _toDouble(d['pickupLng'] ?? d['pickup']?['lng'] ?? d['vendor']?['lng']);
    LatLng? pickupPos;
    if (pickupLat != null && pickupLng != null) {
      pickupPos = LatLng(pickupLat, pickupLng);
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: pickupPos,
        infoWindow: InfoWindow(title: _vendorName(d)),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
      if (_driverPos != null) {
        final dist = _haversine(_driverPos!, pickupPos);
        _minsToPickup = (dist / 30) * 60;
        polylines.add(Polyline(
          polylineId: const PolylineId('to_pickup'),
          points: [_driverPos!, pickupPos],
          color: _kOrange, width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ));
      }
    }

    // Delivery / customer location
    final delivLat = _toDouble(d['deliveryLat'] ?? d['delivery']?['lat']
        ?? d['deliveryAddress']?['lat'] ?? d['customer']?['lat']);
    final delivLng = _toDouble(d['deliveryLng'] ?? d['delivery']?['lng']
        ?? d['deliveryAddress']?['lng'] ?? d['customer']?['lng']);
    if (delivLat != null && delivLng != null) {
      final delivPos = LatLng(delivLat, delivLng);
      markers.add(Marker(
        markerId: const MarkerId('delivery'),
        position: delivPos,
        infoWindow: InfoWindow(title: _customerName(d), snippet: 'Customer'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
      if (pickupPos != null) {
        final dist = _haversine(pickupPos, delivPos);
        _minsToDelivery = (dist / 30) * 60;
        polylines.add(Polyline(
          polylineId: const PolylineId('to_delivery'),
          points: [pickupPos, delivPos],
          color: _kGreen, width: 4,
        ));
      }
    }

    _markers   = markers;
    _polylines = polylines;

    if (_driverPos != null && _mapCtrl != null) {
      _mapCtrl!.animateCamera(CameraUpdate.newLatLngZoom(_driverPos!, 14));
    }
  }

  Future<void> _updateStatus(String deliveryId, String newStatus) async {
    if (_updatingStatus) return;
    setState(() => _updatingStatus = true);
    try {
      await ApiService.updateDriverDeliveryStatus(
        token: _token, deliveryId: deliveryId, status: newStatus,
        lat: _driverPos?.latitude, lng: _driverPos?.longitude,
      );
      if (mounted) {
        _showSnack('Status: ${newStatus.replaceAll('_', ' ')}');
        await _load();
      }
    } catch (e) {
      if (mounted) _showSnack(ErrorHandlerService.getErrorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  void _callCustomer(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red[700] : _kGreen,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _customerName(Map d) {
    final c = d['customer'] as Map? ?? d['customerId'] as Map? ?? <String, dynamic>{};
    final first = c['firstname']?.toString() ?? c['firstName']?.toString() ?? '';
    final last  = c['lastname']?.toString()  ?? c['lastName']?.toString()  ?? '';
    final full  = [first, last].where((s) => s.isNotEmpty).join(' ');
    return full.isNotEmpty ? full : d['customerName']?.toString() ?? 'Customer';
  }

  String _customerPhone(Map d) =>
      (d['customer'] as Map?)?['phone']?.toString() ??
      (d['customer'] as Map?)?['phoneNumber']?.toString() ??
      d['customerPhone']?.toString() ?? '';

  String _customerPic(Map d) =>
      (d['customer'] as Map?)?['profileImage']?.toString() ??
      (d['customer'] as Map?)?['avatar']?.toString() ?? '';

  String _vendorName(Map d) {
    final v = d['vendorId'] as Map? ?? d['vendor'] as Map? ?? <String, dynamic>{};
    return v['businessName']?.toString() ?? v['name']?.toString() ?? 'Restaurant';
  }

  String _deliveryAddress(Map d) {
    final addr = d['deliveryAddress'];
    if (addr is Map) return addr['address']?.toString() ?? addr['address1']?.toString() ?? '';
    return addr?.toString() ?? '';
  }

  int _orderTotal(Map d) => ((d['totalPrice'] ?? d['total'] ?? d['orderTotal'] ?? 0) as num).toInt();
  int _earning(Map d)    => ((d['driverEarning'] ?? d['earning'] ?? d['estimatedEarning'] ?? 0) as num).toInt();

  String _fmtK(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  double _haversine(LatLng a, LatLng b) {
    const R = 6371.0;
    final dLat = _deg2rad(b.latitude  - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(a.latitude)) * math.cos(_deg2rad(b.latitude)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }

  double _deg2rad(double d) => d * math.pi / 180;
  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Color _stepColor(String current, String step) {
    const order = ['assigned', 'picked_up', 'in_transit', 'delivered'];
    final ci = order.indexOf(current);
    final si = order.indexOf(step);
    if (ci < 0) return _kBorder;
    return si <= ci ? _kGreen : _kBorder;
  }

  Color _statusBadgeColor(String s) {
    switch (s) {
      case 'assigned':   return _kOrange;
      case 'picked_up':  return Colors.blue;
      case 'in_transit': return Colors.indigo;
      case 'delivered':  return _kGreen;
      default:           return _kMuted;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'assigned':   return 'Assigned';
      case 'picked_up':  return 'Picked Up';
      case 'in_transit': return 'In Transit';
      case 'delivered':  return 'Delivered';
      default:           return s.replaceAll('_', ' ').toUpperCase();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2.5));
    }
    if (_activeDelivery == null) return _buildEmpty();
    return _buildDeliveryScreen();
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              border: Border.all(color: _kBorder, width: 2),
            ),
            child: const Icon(Icons.delivery_dining_rounded, color: _kMuted, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('No Active Delivery', style: TextStyle(color: _kText, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Accept an order from Home to start a delivery',
              style: TextStyle(color: _kMuted, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kGreen.withOpacity(0.4)),
              ),
              child: const Text('Refresh', style: TextStyle(color: _kGreen, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildDeliveryScreen() {
    final d        = _activeDelivery!;
    final status   = d['status']?.toString() ?? 'assigned';
    final orderId  = d['_id']?.toString() ?? d['id']?.toString() ?? '';
    final cName    = _customerName(d);
    final cPhone   = _customerPhone(d);
    final cPic     = _customerPic(d);
    final vendor   = _vendorName(d);
    final addr     = _deliveryAddress(d);
    final total    = _orderTotal(d);
    final earning  = _earning(d);
    final hasMap   = _driverPos != null || _toDouble(d['pickupLat'] ?? d['pickup']?['lat']) != null;
    final cInitial = cName.isNotEmpty ? cName[0].toUpperCase() : 'C';

    final screenH = MediaQuery.of(context).size.height;
    final mapH    = hasMap ? screenH * 0.52 : 0.0;

    return Column(children: [
      // ── MAP ─────────────────────────────────────────────────────────────────
      if (hasMap)
        SizedBox(
          height: mapH,
          child: Stack(children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _driverPos ?? const LatLng(0.3136, 32.5811),
                zoom: 14,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (c) {
                _mapCtrl = c;
                if (_driverPos != null) c.animateCamera(CameraUpdate.newLatLngZoom(_driverPos!, 14));
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              compassEnabled: false,
            ),
            // Back button
            Positioned(
              top: 12, left: 12,
              child: GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _kText),
                ),
              ),
            ),
            // Status badge top right
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _statusBadgeColor(status),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
                ),
                child: Text(_statusLabel(status),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
            // ETA chips
            if (_minsToPickup != null || _minsToDelivery != null)
              Positioned(
                bottom: 12, left: 12, right: 12,
                child: Row(children: [
                  if (_minsToPickup != null)
                    _etaChip('To pickup', _minsToPickup!, _kOrange),
                  if (_minsToPickup != null && _minsToDelivery != null)
                    const SizedBox(width: 8),
                  if (_minsToDelivery != null)
                    _etaChip('To delivery', _minsToDelivery!, _kGreen),
                ]),
              ),
            // Zoom button
            Positioned(
              bottom: 12, right: 12,
              child: GestureDetector(
                onTap: () {
                  if (_driverPos != null && _mapCtrl != null) {
                    _mapCtrl!.animateCamera(CameraUpdate.newLatLngZoom(_driverPos!, 14));
                  }
                },
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6)],
                    border: Border.all(color: _kGreen, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.my_location_rounded, color: _kGreen, size: 18),
                ),
              ),
            ),
          ]),
        ),

      // ── BOTTOM PANEL ────────────────────────────────────────────────────────
      Expanded(
        child: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2)),
                  ),
                ),

                // Customer row
                Row(children: [
                  // Avatar
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _kGreen, shape: BoxShape.circle,
                      border: Border.all(color: _kGreen, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: cPic.isNotEmpty
                        ? Image.network(cPic, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(child: Text(cInitial,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))))
                        : Center(child: Text(cInitial,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(cName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kText)),
                    Text(addr.isNotEmpty ? addr : 'Customer location',
                        style: const TextStyle(fontSize: 12, color: _kMuted), overflow: TextOverflow.ellipsis),
                  ])),
                  // Call button
                  if (cPhone.isNotEmpty)
                    GestureDetector(
                      onTap: () => _callCustomer(cPhone),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4), shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFD1FAE5)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.call_rounded, color: _kGreen, size: 18),
                      ),
                    ),
                ]),

                const SizedBox(height: 16),

                // Progress stepper
                _buildStepper(status),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 14),

                // FROM / ORDER / EARNING row
                Row(children: [
                  Expanded(child: _infoCol('FROM', vendor)),
                  Container(width: 1, height: 36, color: _kBorder),
                  Expanded(child: _infoCol('ORDER', 'UGX ${_fmtK(total)}')),
                  Container(width: 1, height: 36, color: _kBorder),
                  Expanded(child: _infoCol('EARNING', 'UGX ${_fmtK(earning)}',
                      valueColor: _kGreen)),
                ]),

                const SizedBox(height: 20),

                // Action button
                if (orderId.isNotEmpty) _buildActionBtn(orderId, status),

                // Phone number display
                if (cPhone.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _callCustomer(cPhone),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kGreen.withOpacity(0.4)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.call_rounded, color: _kGreen, size: 16),
                        const SizedBox(width: 8),
                        Text(cPhone, style: const TextStyle(color: _kGreen, fontWeight: FontWeight.w700, fontSize: 14)),
                      ]),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildStepper(String status) {
    const steps = ['assigned', 'picked_up', 'in_transit', 'delivered'];
    const labels = ['Assigned', 'Picked Up', 'In Transit', 'Delivered'];
    final ci = steps.indexOf(status).clamp(0, steps.length - 1);

    return Column(children: [
      // Progress line
      Row(children: List.generate(steps.length, (i) {
        final done = i <= ci;
        return Expanded(child: Row(children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: done ? _kGreen : _kBorder,
              shape: BoxShape.circle,
              border: Border.all(color: done ? _kGreen : _kBorder, width: 2),
            ),
          ),
          if (i < steps.length - 1)
            Expanded(child: Container(
              height: 2,
              color: i < ci ? _kGreen : _kBorder,
            )),
        ]));
      })),
      const SizedBox(height: 6),
      // Labels
      Row(children: List.generate(steps.length, (i) {
        final active = i == ci;
        final done   = i < ci;
        return Expanded(child: Text(
          labels[i],
          style: TextStyle(
            fontSize: 9,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: done || active ? _kGreen : _kMuted,
          ),
          textAlign: i == 0 ? TextAlign.start : (i == steps.length - 1 ? TextAlign.end : TextAlign.center),
        ));
      })),
    ]);
  }

  Widget _buildActionBtn(String orderId, String status) {
    String label;
    String nextStatus;
    bool isDone = false;

    switch (status) {
      case 'assigned':
      case 'pending':
        label = 'Order Collected';
        nextStatus = 'picked_up';
        break;
      case 'picked_up':
        label = 'Mark In Transit';
        nextStatus = 'in_transit';
        break;
      case 'in_transit':
        label = 'Mark Delivered';
        nextStatus = 'delivered';
        break;
      default:
        label = 'Delivery Complete';
        nextStatus = 'delivered';
        isDone = true;
    }

    if (isDone) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD1FAE5)),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_rounded, color: _kGreen, size: 22),
          SizedBox(width: 8),
          Text('Delivery Complete!',
              style: TextStyle(color: _kGreen, fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
      );
    }

    return GestureDetector(
      onTap: _updatingStatus ? null : () => _updateStatus(orderId, nextStatus),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D7C3B), Color(0xFF16A34A)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: _updatingStatus
            ? const Center(child: SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              ]),
      ),
    );
  }

  Widget _etaChip(String label, double mins, Color color) {
    final m = mins.round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.access_time_rounded, color: color, size: 13),
        const SizedBox(width: 4),
        Text('$label: ${m}m', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _infoCol(String label, String value, {Color? valueColor}) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _kMuted, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
          color: valueColor ?? _kText), overflow: TextOverflow.ellipsis),
    ]);
  }
}
