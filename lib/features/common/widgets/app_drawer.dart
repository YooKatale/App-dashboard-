import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../wishlist/providers/wishlist_provider.dart';

// ── Theme colors (matching webapp exactly) ────────────────────────────────────
const _kPrimary  = Color(0xFF0B2416);
const _kDark     = Color(0xFF1A5C1A);
const _kAccent   = Color(0xFF2ECC71);
const _kOrange   = Color(0xFFE07820);
const _kRed      = Color(0xFFD32F2F);

// ── Providers for sidebar stats ───────────────────────────────────────────────
final _drawerOrdersCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final token = await AuthService.getToken();
    final userData = await AuthService.getUserData();
    if (token == null) return 0;
    final userId = userData?['_id']?.toString() ?? userData?['id']?.toString() ?? '';
    if (userId.isEmpty) return 0;
    final res = await ApiService.fetchUserOrders(userId, token: token);
    final orders = res['data'] ?? res['orders'] ?? res;
    if (orders is List) return orders.length;
    return 0;
  } catch (_) {
    return 0;
  }
});

final _drawerWalletProvider = FutureProvider.autoDispose<double>((ref) async {
  try {
    final token = await AuthService.getToken();
    if (token == null) return 0;
    final res = await ApiService.fetchCashoutStats(token: token);
    final data = res['data'] ?? res;
    if (data is Map) {
      final bal = data['balance'] ?? data['wallet'] ?? data['totalEarnings'] ?? 0;
      return (bal is num) ? bal.toDouble() : double.tryParse(bal.toString()) ?? 0;
    }
    return 0;
  } catch (_) {
    return 0;
  }
});

// ── Main Drawer widget ────────────────────────────────────────────────────────
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState     = ref.watch(authStateProvider);
    final firstName     = authState.firstName ?? '';
    final lastName      = authState.lastName ?? '';
    final email         = authState.email ?? '';
    final initial       = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'Y';
    final fullName      = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    final isLoggedIn    = authState.isLoggedIn;
    final profilePicUrl = authState.profilePicUrl;

    // Wishlist count
    final wishlistAsync = ref.watch(wishlistProvider);
    final wishlistCount = wishlistAsync.valueOrNull?.length ?? 0;

    // Orders count
    final ordersAsync  = isLoggedIn ? ref.watch(_drawerOrdersCountProvider) : const AsyncValue.data(0);
    final ordersCount  = ordersAsync.valueOrNull ?? 0;

    // Wallet balance
    final walletAsync  = isLoggedIn ? ref.watch(_drawerWalletProvider) : const AsyncValue.data(0.0);
    final walletBal    = walletAsync.valueOrNull ?? 0.0;
    final walletStr    = 'UGX ${walletBal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.84,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          _DrawerHeader(
            profilePicUrl: profilePicUrl,
            fullName: isLoggedIn ? (fullName.isNotEmpty ? fullName : 'Welcome') : 'Guest',
            email: isLoggedIn ? email : '',
            initial: initial,
            onClose: () => Navigator.of(context).pop(),
          ),

          // ── Stats row ────────────────────────────────────────────────────────
          if (isLoggedIn)
            _StatsRow(
              ordersCount: ordersCount,
              wishlistCount: wishlistCount,
              walletStr: walletStr,
            ),

          // ── Scrollable nav ───────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),

                  // "Start Selling Today" CTA
                  _StartSellingBanner(context: context),

                  const SizedBox(height: 4),

                  // SHOP & EXPLORE section
                  _SectionLabel(label: 'SHOP & EXPLORE'),
                  _NavTile(icon: Icons.home_rounded,        label: 'Home',        route: '/home',         context: context),
                  _NavTile(icon: Icons.grid_view_rounded,   label: 'Categories',  route: '/categories',   context: context),
                  _NavTile(icon: Icons.storefront_rounded,  label: 'Marketplace', route: '/marketplace',  context: context, badge: 'NEW', badgeColor: _kDark),
                  _NavTile(icon: Icons.local_offer_rounded, label: 'Promotions',  route: '/rewards',      context: context, badge: 'HOT', badgeColor: _kOrange),
                  _NavTile(icon: Icons.card_giftcard_rounded, label: 'Gift Cards', route: '/gift-cards',  context: context),
                  _NavTile(icon: Icons.stars_rounded,       label: 'Rewards',     route: '/rewards',      context: context),

                  const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 2),

                  // MY ACCOUNT section
                  _SectionLabel(label: 'MY ACCOUNT'),
                  _NavTile(icon: Icons.receipt_long_rounded,       label: 'My Orders',    route: '/orders',        context: context),
                  _NavTile(icon: Icons.favorite_rounded,           label: 'Wishlist',     route: '/wishlist',      context: context),
                  _NavTile(icon: Icons.account_balance_wallet_rounded, label: 'Cashout', route: '/cashout',        context: context),
                  _NavTile(icon: Icons.person_rounded,             label: 'Profile',      route: '/account',       context: context),
                  _NavTile(icon: Icons.calendar_month_rounded,     label: 'Meal Calendar',route: '/meal-calendar', context: context),
                  _NavTile(icon: Icons.grid_view_rounded,          label: 'Subscribe',    route: '/subscription',  context: context),
                  _NavTile(icon: Icons.notifications_rounded,      label: 'Notifications',route: '/notifications', context: context),

                  const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 2),

                  // COMPANY section
                  _SectionLabel(label: 'COMPANY'),
                  _NavTile(icon: Icons.info_rounded,            label: 'About Us',        route: '/about',     context: context),
                  _NavTile(icon: Icons.mail_rounded,            label: 'Contact Us',      route: '/contact',   context: context),
                  _NavTile(icon: Icons.work_rounded,            label: 'Careers',         route: '/careers',   context: context),
                  _NavTile(icon: Icons.campaign_rounded,        label: 'Advertise',       route: '/advertise', context: context),
                  _NavTile(icon: Icons.handshake_rounded,       label: 'Become a Partner',route: '/partner',   context: context),
                  _NavTile(icon: Icons.electric_rickshaw_rounded,label: 'Driver Portal',  route: '/driver-app', context: context),
                  _NavTile(icon: Icons.help_rounded,            label: 'Help & FAQs',     route: '/help',      context: context),

                  const SizedBox(height: 12),

                  // ── Call button ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _CallButton(),
                  ),

                  const SizedBox(height: 10),

                  // ── Sign in / Sign out ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: isLoggedIn
                        ? _LogoutButton(ref: ref, context: context)
                        : _SignInButton(context: context),
                  ),

                  const SizedBox(height: 16),

                  // ── Footer ───────────────────────────────────────────────────
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Text(
                        'YooKatale · fresh produce & groceries\nKampala, Uganda',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFAAAAAA),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final String? profilePicUrl;
  final String fullName;
  final String email;
  final String initial;
  final VoidCallback onClose;

  const _DrawerHeader({
    required this.profilePicUrl,
    required this.fullName,
    required this.email,
    required this.initial,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _kPrimary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 16,
        right: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kAccent.withOpacity(0.5), width: 2),
            ),
            child: ClipOval(
              child: profilePicUrl != null
                  ? CachedNetworkImage(
                      imageUrl: profilePicUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _InitialAvatar(initial: initial),
                    )
                  : _InitialAvatar(initial: initial),
            ),
          ),
          const SizedBox(width: 12),
          // Name & email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Close button
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int ordersCount;
  final int wishlistCount;
  final String walletStr;

  const _StatsRow({
    required this.ordersCount,
    required this.wishlistCount,
    required this.walletStr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F9F7),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          _StatCell(value: ordersCount.toString(), label: 'Orders'),
          _StatDivider(),
          _StatCell(value: wishlistCount.toString(), label: 'Wishlist'),
          _StatDivider(),
          Expanded(
            child: Column(
              children: [
                Text(
                  walletStr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A5C1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Wallet',
                  style: TextStyle(fontSize: 10, color: Color(0xFF888888)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A5C1A))),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: const Color(0xFFDDDDDD));
  }
}

// ── Start Selling CTA ─────────────────────────────────────────────────────────
class _StartSellingBanner extends StatelessWidget {
  final BuildContext context;
  const _StartSellingBanner({required this.context});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed('/partner');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE07820), Color(0xFFFF9944)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Start Selling Today',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFFAAAAAA),
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ── Nav tile ──────────────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final BuildContext context;
  final String? badge;
  final Color? badgeColor;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.route,
    required this.context,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext ctx) {
    final currentRoute = ModalRoute.of(ctx)?.settings.name;
    final isActive = currentRoute == route;
    return GestureDetector(
      onTap: () {
        Navigator.of(ctx).pop();
        if (currentRoute != route) {
          Navigator.of(ctx).pushNamed(route);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8F5EE) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19,
                color: isActive ? _kDark : const Color(0xFF555555)),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? _kDark : const Color(0xFF333333),
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? _kDark,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (isActive && badge == null)
              Container(
                width: 4, height: 4,
                decoration: const BoxDecoration(color: _kAccent, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Call button ───────────────────────────────────────────────────────────────
class _CallButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('tel:+256786118137');
        if (await canLaunchUrl(uri)) launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5EE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kAccent.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_rounded, color: Color(0xFF1A5C1A), size: 18),
            SizedBox(width: 8),
            Text(
              'Call +256 786 118137',
              style: TextStyle(
                color: Color(0xFF1A5C1A),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logout button ─────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final WidgetRef ref;
  final BuildContext context;
  const _LogoutButton({required this.ref, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: () async {
        Navigator.of(ctx).pop();
        await AuthService.clearUserData();
        ref.read(authStateProvider.notifier).state = const AuthState.loggedOut();
        if (ctx.mounted) {
          Navigator.of(ctx).pushNamedAndRemoveUntil('/', (_) => false);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kRed.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: _kRed, size: 18),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                color: _kRed,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sign in button ────────────────────────────────────────────────────────────
class _SignInButton extends StatelessWidget {
  final BuildContext context;
  const _SignInButton({required this.context});

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: () {
        Navigator.of(ctx).pop();
        Navigator.of(ctx).pushNamed('/signin');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text(
            'Sign In',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Initial avatar ────────────────────────────────────────────────────────────
class _InitialAvatar extends StatelessWidget {
  final String initial;
  const _InitialAvatar({required this.initial});
  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1A5E35), Color(0xFF27AE60)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(initial,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
    ),
  );
}
