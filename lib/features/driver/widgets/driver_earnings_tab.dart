import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/driver_auth_service.dart';

const _kGreen  = Color(0xFF0D7C3B);
const _kBg     = Color(0xFFF4F5F7);
const _kText   = Color(0xFF111111);
const _kMuted  = Color(0xFF9CA3AF);
const _kBorder = Color(0xFFF3F4F6);
const _kAmber  = Color(0xFFD97706);

class DriverEarningsTab extends StatefulWidget {
  const DriverEarningsTab({super.key});

  @override
  State<DriverEarningsTab> createState() => _DriverEarningsTabState();
}

class _DriverEarningsTabState extends State<DriverEarningsTab> {
  bool _loading = true;
  Map<String, dynamic> _dash = {};
  String _period = 'week';
  String _token = '', _driverId = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _token    = await DriverAuthService.getToken() ?? '';
    _driverId = await DriverAuthService.getDriverId() ?? '';
    await _load();
  }

  Future<void> _load() async {
    if (_token.isEmpty || _driverId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final res = await ApiService.fetchDriverDashboard(token: _token, driverId: _driverId);
      if (mounted) setState(() {
        _dash    = (res['data'] is Map ? res['data'] as Map<String, dynamic> : {});
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;
    return n.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  List<BarChartGroupData> _buildBars() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final chartData = List<double>.filled(7, 0);
    final weeklyBreakdown = _dash['weeklyBreakdown'];
    if (weeklyBreakdown is List) {
      for (final item in weeklyBreakdown) {
        final idx = days.indexOf(item['day']?.toString() ?? '');
        if (idx >= 0) chartData[idx] = ((item['earnings'] ?? 0) as num).toDouble();
      }
    }
    final todayIdx = DateTime.now().weekday - 1;
    return List.generate(7, (i) => BarChartGroupData(
      x: i,
      barRods: [BarChartRodData(
        toY: chartData[i],
        color: i == todayIdx ? _kGreen : _kGreen.withOpacity(0.25),
        width: 16,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      )],
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2.5));

    final driver         = (_dash['driver'] as Map?) ?? <String, dynamic>{};
    final totalEarnings  = (_dash['totalEarnings'] ?? driver['totalEarnings'] ?? 0);
    final weekEarnings   = (_dash['weekEarnings'] ?? 0);
    final pendingPayout  = (_dash['pendingPayout'] ?? 0);
    final todayDeliveries = (_dash['todayDeliveries'] ?? 0);
    final totalDeliveries = (driver['totalDeliveries'] ?? 0);
    final acceptanceRate  = (driver['acceptanceRate'] ?? _dash['driver']?['acceptanceRate'] ?? 100);
    final recentDeliveries = (_dash['recentDeliveries'] is List ? _dash['recentDeliveries'] as List : []);
    final payoutHistory    = (_dash['payoutHistory'] is List ? _dash['payoutHistory'] as List : []);

    final bars = _buildBars();
    final maxY = bars.isEmpty ? 100000.0
        : (bars.map((b) => b.barRods.first.toY).reduce((a, b) => a > b ? a : b) * 1.2).clamp(1.0, double.infinity);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return RefreshIndicator(
      onRefresh: _load,
      color: _kGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Dark earnings header (matches webapp) ─────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Earnings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                // Period toggle
                Row(children: ['week', 'month'].map((p) => GestureDetector(
                  onTap: () => setState(() => _period = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _period == p ? Colors.white.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(p == 'week' ? 'Week' : 'Month',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: _period == p ? Colors.white : const Color(0xFF6B7280))),
                  ),
                )).toList()),
              ]),
              const SizedBox(height: 14),
              Text('UGX ${_fmt(totalEarnings)}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 2),
              const Text('Total earnings', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _earningsChip(
                  Icons.trending_up_rounded, const Color(0xFF22C55E),
                  'This Week', 'UGX ${_fmt(weekEarnings)}',
                )),
                const SizedBox(width: 8),
                Expanded(child: _earningsChip(
                  Icons.access_time_rounded, _kAmber,
                  'Pending', 'UGX ${_fmt(pendingPayout)}',
                  valueColor: _kAmber,
                )),
              ]),
            ]),
          ),

          // ── 3-stat row ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              _miniStat('$todayDeliveries', 'Today', _kGreen),
              const SizedBox(width: 6),
              _miniStat('$totalDeliveries', 'Total Trips', _kText),
              const SizedBox(width: 6),
              _miniStat('$acceptanceRate%', 'Acceptance',
                  (acceptanceRate is num && (acceptanceRate as num) >= 80) ? _kGreen : _kAmber),
            ]),
          ),

          // ── Weekly chart ───────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Weekly Overview',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kText)),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: BarChart(BarChartData(
                  maxY: maxY,
                  barGroups: bars,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, reservedSize: 20,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(days[v.toInt().clamp(0, 6)],
                            style: const TextStyle(fontSize: 9, color: _kMuted)),
                      ),
                    )),
                  ),
                )),
              ),
            ]),
          ),

          // ── Payout request button ──────────────────────────────────────
          if ((pendingPayout as num) > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                  label: Text('Request Payout — UGX ${_fmt(pendingPayout)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ),

          // ── Payout history ─────────────────────────────────────────────
          if (payoutHistory.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Payout History',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kText)),
            ),
            ...payoutHistory.map((p) => _payoutRow(p)),
          ],

          // ── Recent deliveries ──────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Recent Deliveries',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kText)),
          ),
          if (recentDeliveries.isEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: Column(children: [
                const Icon(Icons.monetization_on_outlined, size: 28, color: Color(0xFFD1D5DB)),
                const SizedBox(height: 8),
                const Text('No deliveries yet',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kText)),
                const SizedBox(height: 2),
                const Text('Complete deliveries to see your history',
                    style: TextStyle(fontSize: 11, color: _kMuted), textAlign: TextAlign.center),
              ]),
            )
          else
            ...recentDeliveries.map((d) => _deliveryRow(d)),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _earningsChip(IconData icon, Color iconColor, String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
            color: valueColor ?? Colors.white)),
      ]),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 9, color: _kMuted, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _payoutRow(dynamic p) {
    final pm = p is Map ? p as Map<String, dynamic> : <String, dynamic>{};
    String dateLabel = '';
    final paidAt = pm['paidAt']?.toString() ?? '';
    if (paidAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(paidAt);
        final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        dateLabel = '${months[dt.month-1]} ${dt.day}, ${dt.year}';
      } catch (_) {}
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder)),
        child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: const Icon(Icons.account_balance_wallet_outlined, size: 14, color: _kGreen)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pm['note']?.toString() ?? 'Payout',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kText)),
            if (dateLabel.isNotEmpty)
              Text(dateLabel, style: const TextStyle(fontSize: 10, color: _kMuted)),
          ])),
          Text('UGX ${_fmt(pm['amount'] ?? 0)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen)),
        ]),
      ),
    );
  }

  Widget _deliveryRow(dynamic d) {
    final dm = d is Map ? d as Map<String, dynamic> : <String, dynamic>{};
    final order = dm['orderId'] is Map ? dm['orderId'] as Map<String, dynamic> : <String, dynamic>{};
    final addr = order['deliveryAddress'] is Map
        ? (order['deliveryAddress'] as Map)['address']?.toString() ?? (order['deliveryAddress'] as Map)['address1']?.toString() ?? ''
        : order['deliveryAddress']?.toString() ?? '';
    final earning = ((dm['commissionAmount'] ?? dm['estimatedEarning'] ?? dm['driverEarning'] ?? 0) as num).toInt();
    final status = dm['status']?.toString() ?? '';
    final isDelivered = status == 'delivered';
    String dateLabel = '';
    final dt = dm['deliveredAt']?.toString() ?? dm['createdAt']?.toString() ?? '';
    if (dt.isNotEmpty) {
      try {
        final d2 = DateTime.parse(dt);
        final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        dateLabel = '${months[d2.month-1]} ${d2.day}';
      } catch (_) {}
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder)),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: isDelivered ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(isDelivered ? Icons.check_circle_outline_rounded : Icons.access_time_rounded,
                size: 14, color: isDelivered ? _kGreen : _kAmber),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              order['customerName']?.toString() ??
                  (order['vendorId'] is Map ? (order['vendorId'] as Map)['businessName']?.toString() ?? 'Delivery' : 'Delivery'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kText),
              overflow: TextOverflow.ellipsis,
            ),
            if (addr.isNotEmpty)
              Text(addr, style: const TextStyle(fontSize: 10, color: _kMuted), overflow: TextOverflow.ellipsis),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('+UGX ${_fmt(earning)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen)),
            if (dateLabel.isNotEmpty)
              Text(dateLabel, style: const TextStyle(fontSize: 9, color: _kMuted)),
          ]),
        ]),
      ),
    );
  }
}
