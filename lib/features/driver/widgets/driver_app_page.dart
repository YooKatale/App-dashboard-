import 'package:flutter/material.dart';
import 'driver_home_tab.dart';
import 'driver_delivery_tab.dart';
import 'driver_earnings_tab.dart';
import 'driver_profile_tab.dart';

const _kBg      = Color(0xFF0A0F14);
const _kGreen   = Color(0xFF00C853);
const _kCard    = Color(0xFF111820);
const _kBorder  = Color(0xFF1E2D3D);
const _kMuted   = Color(0xFF8A99AA);
const _kText    = Color(0xFFE0E6ED);

class DriverAppPage extends StatefulWidget {
  const DriverAppPage({super.key});

  @override
  State<DriverAppPage> createState() => _DriverAppPageState();
}

class _DriverAppPageState extends State<DriverAppPage> {
  int _currentIndex = 0;

  static const _tabs = [
    DriverHomeTab(),
    DriverDeliveryTab(),
    DriverEarningsTab(),
    DriverProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _kCard,
          border: Border(top: BorderSide(color: _kBorder, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TabItem(icon: Icons.home_rounded,       label: 'Home',     index: 0, current: _currentIndex, onTap: _setTab),
                _TabItem(icon: Icons.delivery_dining_rounded, label: 'Delivery', index: 1, current: _currentIndex, onTap: _setTab),
                _TabItem(icon: Icons.bar_chart_rounded,  label: 'Earnings', index: 2, current: _currentIndex, onTap: _setTab),
                _TabItem(icon: Icons.person_rounded,     label: 'Profile',  index: 3, current: _currentIndex, onTap: _setTab),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setTab(int i) => setState(() => _currentIndex = i);
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? _kGreen.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: active ? _kGreen : _kMuted, size: 22),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? _kGreen : _kMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
