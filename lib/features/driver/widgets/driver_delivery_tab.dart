import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/error_handler_service.dart';

const _kBg     = Color(0xFF0A0F14);
const _kCard   = Color(0xFF111820);
const _kBorder = Color(0xFF1E2D3D);
const _kGreen  = Color(0xFF00C853);
const _kText   = Color(0xFFE0E6ED);
const _kMuted  = Color(0xFF8A99AA);
const _kOrange = Color(0xFFE07820);

class DriverDeliveryTab extends StatefulWidget {
  const DriverDeliveryTab({super.key});

  @override
  State<DriverDeliveryTab> createState() => _DriverDeliveryTabState();
}

class _DriverDeliveryTabState extends State<DriverDeliveryTab> {
  Map<String, dynamic>? _activeDelivery;
  bool _loading = true;
  String? _error;
  Timer? _timer;
  GoogleMapController? _mapCtrl;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // ETA tracking
  double? _minsToPickup;
  double? _minsToDelivery;
  LatLng? _driverPos;

  @override
  void initState() {
    super.initState();
    _load();
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
      final token = await AuthService.getToken();
      if (token == null) return;
      final res = await ApiService.fetchActiveDelivery(token: token);
      final data = res['data'];
      if (mounted) {
        setState(() {
          _activeDelivery = data is Map ? data as Map<String, dynamic> : null;
          _loading = false;
          if (_activeDelivery != null) _buildMapData();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = ErrorHandlerService.getErrorMessage(e);
        });
      }
    }
  }

  void _buildMapData() {
    final d = _activeDelivery!;
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    // Driver location
    final driverLat = _toDouble(d['driverLat'] ?? d['driver']?['lat']);
    final driverLng = _toDouble(d['driverLng'] ?? d['driver']?['lng']);
    if (driverLat != null && driverLng != null) {
      _driverPos = LatLng(driverLat, driverLng);
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _driverPos!,
        infoWindow: const InfoWindow(title: 'Driver'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    // Pickup location
    final pickupLat = _toDouble(d['pickupLat'] ?? d['pickup']?['lat']);
    final pickupLng = _toDouble(d['pickupLng'] ?? d['pickup']?['lng']);
    if (pickupLat != null && pickupLng != null) {
      final pickupPos = LatLng(pickupLat, pickupLng);
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: pickupPos,
        infoWindow: const InfoWindow(title: 'Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
      if (_driverPos != null) {
        final distKm = _haversine(_driverPos!, pickupPos);
        _minsToPickup = (distKm / 30) * 60; // assume 30km/h avg speed
        polylines.add(Polyline(
          polylineId: const PolylineId('to_pickup'),
          points: [_driverPos!, pickupPos],
          color: _kOrange,
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ));
      }
    }

    // Delivery location
    final delivLat = _toDouble(d['deliveryLat'] ?? d['delivery']?['lat']);
    final delivLng = _toDouble(d['deliveryLng'] ?? d['delivery']?['lng']);
    if (delivLat != null && delivLng != null) {
      final delivPos = LatLng(delivLat, delivLng);
      markers.add(Marker(
        markerId: const MarkerId('delivery'),
        position: delivPos,
        infoWindow: InfoWindow(
            title: 'Deliver to',
            snippet: d['deliveryAddress']?.toString() ?? ''),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
      if (pickupLat != null && pickupLng != null) {
        final pickupPos = LatLng(pickupLat, pickupLng);
        final distKm = _haversine(pickupPos, delivPos);
        _minsToDelivery = (distKm / 30) * 60;
        polylines.add(Polyline(
          polylineId: const PolylineId('to_delivery'),
          points: [pickupPos, delivPos],
          color: _kGreen,
          width: 3,
        ));
      }
    }

    _markers = markers;
    _polylines = polylines;

    // Update camera if we have a driver position
    if (_driverPos != null && _mapCtrl != null) {
      _mapCtrl!.animateCamera(
        CameraUpdate.newLatLngZoom(_driverPos!, 14),
      );
    }
  }

  double _haversine(LatLng a, LatLng b) {
    const R = 6371.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(a.latitude)) *
            math.cos(_deg2rad(b.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
    return R * c;
  }

  double _deg2rad(double deg) => deg * math.pi / 180;

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Future<void> _updateStatus(String orderId, String status) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      await ApiService.updateDeliveryStatus(
          token: token, orderId: orderId, status: status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to ${status.replaceAll('_', ' ')}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kGreen))
            : _activeDelivery == null
                ? _buildEmpty()
                : _buildActiveDelivery(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: _kCard,
                shape: BoxShape.circle,
                border: Border.all(color: _kBorder, width: 2),
              ),
              child: const Icon(Icons.delivery_dining_rounded,
                  color: _kMuted, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('No Active Delivery',
                style: TextStyle(color: _kText, fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Accept an order from the Home tab to start a delivery',
              style: TextStyle(color: _kMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kGreen.withOpacity(0.4)),
                ),
                child: const Text('Refresh',
                    style: TextStyle(color: _kGreen, fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveDelivery() {
    final d = _activeDelivery!;
    final orderId = d['_id']?.toString() ?? d['id']?.toString() ?? '';
    final status = d['status']?.toString() ?? 'pending';
    final address = d['deliveryAddress']?.toString() ?? 'N/A';
    final items = d['items'] as List? ?? [];
    final customerName = d['customer']?['firstname']?.toString()
        ?? d['customerName']?.toString() ?? 'Customer';
    final customerPhone = d['customer']?['phone']?.toString()
        ?? d['customerPhone']?.toString() ?? '';
    final total = d['totalPrice'] ?? d['total'] ?? 0;

    final hasMap = _driverPos != null ||
        (_toDouble(d['pickupLat'] ?? d['pickup']?['lat']) != null);

    return Column(
      children: [
        // ── Map ──────────────────────────────────────────────────────────────
        SizedBox(
          height: hasMap ? 260 : 0,
          child: hasMap
              ? Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _driverPos ??
                            const LatLng(0.3136, 32.5811), // Kampala default
                        zoom: 14,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      onMapCreated: (ctrl) {
                        _mapCtrl = ctrl;
                        if (_driverPos != null) {
                          ctrl.animateCamera(
                              CameraUpdate.newLatLngZoom(_driverPos!, 14));
                        }
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      mapType: MapType.normal,
                    ),
                    // ETA overlays
                    if (_minsToPickup != null || _minsToDelivery != null)
                      Positioned(
                        bottom: 12, left: 12, right: 12,
                        child: Row(
                          children: [
                            if (_minsToPickup != null)
                              _EtaChip(
                                label: 'To pickup',
                                mins: _minsToPickup!,
                                color: _kOrange,
                              ),
                            if (_minsToPickup != null && _minsToDelivery != null)
                              const SizedBox(width: 8),
                            if (_minsToDelivery != null)
                              _EtaChip(
                                label: 'To delivery',
                                mins: _minsToDelivery!,
                                color: _kGreen,
                              ),
                          ],
                        ),
                      ),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        // ── Delivery details ──────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _statusColor(status).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: _statusColor(status)),
                      ),
                      const SizedBox(width: 8),
                      Text(_statusLabel(status),
                          style: TextStyle(
                              color: _statusColor(status),
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Customer info
                _InfoRow(icon: Icons.person_rounded,
                    label: 'Customer', value: customerName),
                if (customerPhone.isNotEmpty)
                  _InfoRow(icon: Icons.phone_rounded,
                      label: 'Phone', value: customerPhone),
                _InfoRow(icon: Icons.location_on_rounded,
                    label: 'Deliver to', value: address),
                _InfoRow(icon: Icons.shopping_bag_rounded,
                    label: 'Items', value: '${items.length} items'),
                _InfoRow(icon: Icons.payments_rounded,
                    label: 'Total', value: 'UGX ${total.toString()}'),

                const SizedBox(height: 20),

                // Action buttons
                _buildActionButtons(orderId, status),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String orderId, String status) {
    if (status == 'assigned' || status == 'pending') {
      return _ActionBtn(
        label: 'Mark as Picked Up',
        color: _kOrange,
        onTap: () => _updateStatus(orderId, 'picked_up'),
      );
    } else if (status == 'picked_up') {
      return _ActionBtn(
        label: 'Mark as Delivered',
        color: _kGreen,
        onTap: () => _updateStatus(orderId, 'delivered'),
      );
    } else if (status == 'delivered') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kGreen.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: _kGreen, size: 20),
            SizedBox(width: 8),
            Text('Delivery Complete!',
                style: TextStyle(
                    color: _kGreen, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'assigned':  return _kOrange;
      case 'picked_up': return Colors.blueAccent;
      case 'delivered': return _kGreen;
      default:          return _kMuted;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'assigned':  return 'Assigned';
      case 'picked_up': return 'Picked Up';
      case 'delivered': return 'Delivered';
      default:          return s.replaceAll('_', ' ').toUpperCase();
    }
  }
}

class _EtaChip extends StatelessWidget {
  final String label;
  final double mins;
  final Color color;
  const _EtaChip({required this.label, required this.mins, required this.color});

  @override
  Widget build(BuildContext context) {
    final m = mins.round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, color: color, size: 14),
          const SizedBox(width: 5),
          Text('$label: ${m}m',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _kMuted, size: 16),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(color: _kMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: _kText, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ),
      ),
    );
  }
}
