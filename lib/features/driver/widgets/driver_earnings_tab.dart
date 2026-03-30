import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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

class DriverEarningsTab extends StatefulWidget {
  const DriverEarningsTab({super.key});

  @override
  State<DriverEarningsTab> createState() => _DriverEarningsTabState();
}

class _DriverEarningsTabState extends State<DriverEarningsTab> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _stats;
  List<dynamic> _payouts = [];
  String _period = 'Week';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      final res = await ApiService.fetchDriverStats(token: token);
      final data = res['data'] is Map
          ? res['data'] as Map<String, dynamic>
          : res;
      // Try to get payout history
      List<dynamic> payouts = [];
      try {
        final pRes = await ApiService.fetchCashoutHistory(token: token);
        final pData = pRes['data'] ?? pRes['payouts'] ?? pRes;
        if (pData is List) payouts = pData;
      } catch (_) {}
      if (mounted) {
        setState(() {
          _stats   = data;
          _payouts = payouts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error   = ErrorHandlerService.getErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  String _fmt(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0;
    if (n >= 1000000) {
      return 'UGX ${(n / 1000000).toStringAsFixed(1)}M';
    } else if (n >= 1000) {
      return 'UGX ${(n / 1000).toStringAsFixed(0)}K';
    }
    return 'UGX ${n.toStringAsFixed(0)}';
  }

  // Build weekly bar chart data from stats
  List<BarChartGroupData> _buildBars() {
    final weeklyData = _stats?['weeklyEarnings'] as List? ??
        _stats?['weekly'] as List? ?? [];
    if (weeklyData.isEmpty) {
      // Demo data pattern
      final demo = [12000.0, 45000.0, 28000.0, 65000.0, 42000.0, 80000.0, 55000.0];
      return List.generate(7, (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: demo[i],
            color: i == DateTime.now().weekday - 1 ? _kGreen : _kGreen.withOpacity(0.3),
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }
    return List.generate(
      weeklyData.length.clamp(0, 7),
      (i) {
        final v = weeklyData[i];
        final amount = v is num ? v.toDouble()
            : double.tryParse(v?['amount']?.toString() ?? v?.toString() ?? '0') ?? 0;
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: i == DateTime.now().weekday - 1 ? _kGreen : _kGreen.withOpacity(0.3),
              width: 18,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kGreen)),
      );
    }

    final totalEarnings = _stats?['totalEarnings'] ?? _stats?['total'] ?? 0;
    final weekEarnings  = _stats?['weekEarnings'] ?? _stats?['week'] ?? 0;
    final monthEarnings = _stats?['monthEarnings'] ?? _stats?['month'] ?? 0;
    final displayEarnings = _period == 'Week' ? weekEarnings : monthEarnings;
    final totalDeliveries = _stats?['totalDeliveries'] ?? _stats?['deliveries'] ?? 0;
    final rating = _stats?['rating'] ?? 5.0;

    final bars = _buildBars();
    final maxY = bars.isEmpty ? 100000.0
        : bars.map((b) => b.barRods.first.toY).reduce((a, b) => a > b ? a : b) * 1.2;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _kGreen,
          backgroundColor: _kCard,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Dark header ───────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0A1A0F), Color(0xFF0A0F14)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Earnings',
                          style: TextStyle(color: _kMuted, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(_fmt(totalEarnings),
                          style: const TextStyle(
                              color: _kText,
                              fontSize: 30,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text('Total lifetime earnings',
                          style: TextStyle(color: _kMuted, fontSize: 12)),
                      const SizedBox(height: 18),
                      // Stats row
                      Row(
                        children: [
                          _EarnStat(label: 'Deliveries',
                              value: totalDeliveries.toString()),
                          _EarnStat(label: 'Rating',
                              value: (rating is num ? rating : 5).toStringAsFixed(1),
                              icon: Icons.star_rounded,
                              iconColor: const Color(0xFFFFCC00)),
                          _EarnStat(label: 'This month',
                              value: _fmt(monthEarnings)),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Period toggle ─────────────────────────────────────
                      Row(
                        children: [
                          const Text('Earnings History',
                              style: TextStyle(
                                  color: _kText,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          const Spacer(),
                          _PeriodToggle(
                            selected: _period,
                            onSelect: (p) => setState(() => _period = p),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_fmt(displayEarnings),
                          style: const TextStyle(
                              color: _kGreen,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      Text('${_period == 'Week' ? 'This week' : 'This month'}',
                          style: const TextStyle(color: _kMuted, fontSize: 11)),

                      const SizedBox(height: 18),

                      // ── Bar chart ─────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                        decoration: BoxDecoration(
                          color: _kCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Weekly Earnings',
                                style: TextStyle(
                                    color: _kText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 160,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: maxY,
                                  barGroups: bars,
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (_) => FlLine(
                                      color: _kBorder,
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (v, _) {
                                          const days = ['M','T','W','T','F','S','S'];
                                          final i = v.toInt();
                                          if (i < 0 || i >= days.length) {
                                            return const SizedBox.shrink();
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(days[i],
                                                style: const TextStyle(
                                                    color: _kMuted, fontSize: 11)),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ── Payout History ────────────────────────────────────
                      const Text('Payout History',
                          style: TextStyle(
                              color: _kText,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),

                      if (_payouts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _kCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kBorder),
                          ),
                          child: const Center(
                            child: Text('No payouts yet',
                                style: TextStyle(color: _kMuted, fontSize: 13)),
                          ),
                        )
                      else
                        ..._payouts.take(5).map((p) {
                          final pMap = p as Map<String, dynamic>? ?? {};
                          return _PayoutTile(payout: pMap, fmt: _fmt);
                        }),
                    ],
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

class _EarnStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  const _EarnStat({required this.label, required this.value,
      this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Icon(icon, color: iconColor ?? _kGreen, size: 14)
            else
              const SizedBox(height: 14),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: const TextStyle(color: _kMuted, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  const _PeriodToggle({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: ['Week', 'Month'].map((p) {
          final active = p == selected;
          return GestureDetector(
            onTap: () => onSelect(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? _kGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(p,
                  style: TextStyle(
                      color: active ? Colors.white : _kMuted,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PayoutTile extends StatelessWidget {
  final Map<String, dynamic> payout;
  final String Function(dynamic) fmt;
  const _PayoutTile({required this.payout, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final amount = payout['amount'] ?? payout['total'] ?? 0;
    final date   = payout['createdAt']?.toString().substring(0, 10) ??
        payout['date']?.toString() ?? '';
    final method = payout['method']?.toString() ?? payout['type']?.toString() ?? 'Payout';
    final status = payout['status']?.toString() ?? 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments_rounded, color: _kGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(method, style: const TextStyle(
                    color: _kText, fontSize: 13, fontWeight: FontWeight.w600)),
                if (date.isNotEmpty)
                  Text(date, style: const TextStyle(color: _kMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmt(amount),
                  style: const TextStyle(
                      color: _kGreen, fontSize: 13, fontWeight: FontWeight.w700)),
              Text(status,
                  style: TextStyle(
                      color: status == 'completed' ? _kGreen : _kMuted,
                      fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
