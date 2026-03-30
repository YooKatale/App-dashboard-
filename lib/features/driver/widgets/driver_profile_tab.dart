import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../authentication/providers/auth_provider.dart';

const _kBg     = Color(0xFF0A0F14);
const _kCard   = Color(0xFF111820);
const _kBorder = Color(0xFF1E2D3D);
const _kGreen  = Color(0xFF00C853);
const _kText   = Color(0xFFE0E6ED);
const _kMuted  = Color(0xFF8A99AA);
const _kRed    = Color(0xFFD32F2F);

class DriverProfileTab extends ConsumerStatefulWidget {
  const DriverProfileTab({super.key});

  @override
  ConsumerState<DriverProfileTab> createState() => _DriverProfileTabState();
}

class _DriverProfileTabState extends ConsumerState<DriverProfileTab> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      final res = await ApiService.fetchDriverStats(token: token);
      final data = res['data'] is Map ? res['data'] as Map<String, dynamic> : res;
      // Try to get driver profile details
      Map<String, dynamic>? profile;
      try {
        final pRes = await ApiService.fetchUserProfile(token: token);
        profile = pRes['data'] is Map ? pRes['data'] as Map<String, dynamic>
            : pRes['user'] is Map ? pRes['user'] as Map<String, dynamic>
            : null;
      } catch (_) {
        profile = data;
      }
      if (mounted) {
        setState(() { _profile = profile ?? data; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.clearUserData();
    ref.read(authStateProvider.notifier).state = const AuthState.loggedOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/driver', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState    = ref.watch(authStateProvider);
    final firstName    = authState.firstName ?? _profile?['firstname']?.toString() ?? 'Driver';
    final lastName     = authState.lastName ?? _profile?['lastname']?.toString() ?? '';
    final email        = authState.email ?? _profile?['email']?.toString() ?? '';
    final fullName     = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    final initial      = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'D';
    final picUrl       = authState.profilePicUrl ?? _profile?['avatar']?.toString();

    final totalDeliveries = _profile?['totalDeliveries'] ?? _profile?['deliveries'] ?? 0;
    final rating = (_profile?['rating'] is num)
        ? (_profile!['rating'] as num).toStringAsFixed(1)
        : '5.0';
    final acceptanceRate = _profile?['acceptanceRate']?.toString() ?? '98%';

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kGreen))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // ── Profile header ─────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0D1E14), Color(0xFF0A0F14)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Avatar with camera button
                          Stack(
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _kGreen, width: 2.5),
                                ),
                                child: ClipOval(
                                  child: picUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: picUrl,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              _InitialAvatar(initial: initial),
                                        )
                                      : _InitialAvatar(initial: initial),
                                ),
                              ),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  width: 26, height: 26,
                                  decoration: BoxDecoration(
                                    color: _kGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _kBg, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(fullName,
                              style: const TextStyle(
                                  color: _kText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(email,
                              style: const TextStyle(color: _kMuted, fontSize: 13)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Verified Driver',
                                style: TextStyle(
                                    color: _kGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(height: 18),
                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ProfileStat(
                                  label: 'Deliveries',
                                  value: totalDeliveries.toString()),
                              _VSep(),
                              _ProfileStat(
                                  label: 'Rating',
                                  value: rating,
                                  icon: Icons.star_rounded,
                                  iconColor: const Color(0xFFFFCC00)),
                              _VSep(),
                              _ProfileStat(
                                  label: 'Acceptance',
                                  value: acceptanceRate),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Menu items ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _ProfileMenuItem(
                              icon: Icons.person_rounded,
                              label: 'Personal Info',
                              onTap: () {}),
                          _ProfileMenuItem(
                              icon: Icons.directions_bike_rounded,
                              label: 'Vehicle Details',
                              onTap: () {}),
                          _ProfileMenuItem(
                              icon: Icons.description_rounded,
                              label: 'Documents',
                              onTap: () {}),
                          _ProfileMenuItem(
                              icon: Icons.account_balance_rounded,
                              label: 'Payout Method',
                              onTap: () {}),
                          _ProfileMenuItem(
                              icon: Icons.star_rate_rounded,
                              label: 'Ratings & Reviews',
                              onTap: () {}),
                          _ProfileMenuItem(
                              icon: Icons.help_rounded,
                              label: 'Help & Support',
                              onTap: () {
                                Navigator.of(context).pushNamed('/help');
                              }),

                          const SizedBox(height: 16),

                          // Logout
                          GestureDetector(
                            onTap: _logout,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: _kRed.withOpacity(0.5)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout_rounded,
                                      color: _kRed, size: 18),
                                  SizedBox(width: 8),
                                  Text('Logout',
                                      style: TextStyle(
                                          color: _kRed,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          const Text('YooKatale Driver App v2.0',
                              style: TextStyle(color: _kMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  const _ProfileStat({required this.label, required this.value,
      this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (icon != null) ...[
          Icon(icon, color: iconColor ?? _kGreen, size: 14),
          const SizedBox(height: 2),
        ],
        Text(value,
            style: const TextStyle(
                color: _kText, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: _kMuted, fontSize: 10)),
      ],
    );
  }
}

class _VSep extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: _kBorder);
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileMenuItem({
    required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: _kGreen, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: _kText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: _kMuted, size: 14),
          ],
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initial;
  const _InitialAvatar({required this.initial});
  @override
  Widget build(BuildContext context) => Container(
    width: 88, height: 88,
    color: const Color(0xFF1A5E35),
    child: Center(
      child: Text(initial,
          style: const TextStyle(
              color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
    ),
  );
}
