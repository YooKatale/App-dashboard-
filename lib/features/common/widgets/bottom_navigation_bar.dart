import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../cart/providers/cart_provider.dart';
import '../../authentication/providers/auth_provider.dart';

// Exact colors from the HTML spec
const _kDark   = Color(0xFF112D1C); // var(--g-dark) - active color
const _kAccent = Color(0xFF2ECC71); // var(--g-bright)
const _kInactive = Color(0xFFAAAAAA); // #aaa
const _kRed    = Color(0xFFE53935); // var(--red)

// ── Wishlist count provider (updated by WishlistPage/service)
final wishlistCountProvider = StateProvider<int>((ref) => 0);

class MobileBottomNavigationBar extends ConsumerStatefulWidget {
  final int currentIndex;
  const MobileBottomNavigationBar({super.key, this.currentIndex = 0});

  @override
  ConsumerState<MobileBottomNavigationBar> createState() =>
      _MobileBottomNavigationBarState();
}

class _MobileBottomNavigationBarState
    extends ConsumerState<MobileBottomNavigationBar> {
  late int _idx;

  @override
  void initState() {
    super.initState();
    _idx = widget.currentIndex;
  }

  void _tap(int index) {
    if (_idx == index) return;
    setState(() => _idx = index);
    switch (index) {
      case 0: Navigator.of(context).pushReplacementNamed('/home');         break;
      case 1: Navigator.of(context).pushReplacementNamed('/subscription'); break;
      case 2: Navigator.of(context).pushReplacementNamed('/cart');         break;
      case 3: Navigator.of(context).pushReplacementNamed('/wishlist');     break;
      case 4: Navigator.of(context).pushReplacementNamed('/account');      break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount      = ref.watch(cartCountProvider);
    final wishlistCount  = ref.watch(wishlistCountProvider);
    final authState      = ref.watch(authStateProvider);
    final firstName      = authState.firstName ?? '';
    final initial        = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'Y';
    final displayName    = firstName.isNotEmpty ? firstName : 'Profile';
    final profilePicUrl  = authState.profilePicUrl;

    return Container(
      height: 68 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x14000000), width: 1)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          children: [
            // ── Home ──
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
              index: 0,
              active: _idx == 0,
              onTap: _tap,
            ),
            // ── Subscribe ── (bar_chart matches webapp AiOutlineBarChart)
            _NavItem(
              icon: Icons.bar_chart_outlined,
              activeIcon: Icons.bar_chart_rounded,
              label: 'Subscribe',
              index: 1,
              active: _idx == 1,
              onTap: _tap,
            ),
            // ── Cart ──
            _NavItem(
              icon: Icons.shopping_cart_outlined,
              activeIcon: Icons.shopping_cart_rounded,
              label: 'Cart',
              index: 2,
              active: _idx == 2,
              onTap: _tap,
              badge: cartCount,
              badgeColor: _kRed,
            ),
            // ── Wishlist ──
            _NavItem(
              icon: Icons.favorite_outline_rounded,
              activeIcon: Icons.favorite_rounded,
              label: 'Wishlist',
              index: 3,
              active: _idx == 3,
              onTap: _tap,
              badge: wishlistCount,
              badgeColor: _kRed,
            ),
            // ── Profile ──
            _ProfileItem(
              index: 4,
              active: _idx == 4,
              initial: initial,
              displayName: displayName,
              profilePicUrl: profilePicUrl,
              onTap: _tap,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Generic nav item ───────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final bool active;
  final void Function(int) onTap;
  final int badge;
  final Color badgeColor;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.active,
    required this.onTap,
    this.badge = 0,
    this.badgeColor = _kRed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  active ? activeIcon : icon,
                  size: 22,
                  color: active ? _kDark : _kInactive,
                ),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? _kDark : _kInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile avatar item ────────────────────────────────────────────────────────
class _ProfileItem extends StatelessWidget {
  final int index;
  final bool active;
  final String initial;
  final String displayName;
  final String? profilePicUrl;
  final void Function(int) onTap;

  const _ProfileItem({
    required this.index,
    required this.active,
    required this.initial,
    required this.displayName,
    required this.onTap,
    this.profilePicUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: profilePicUrl == null
                    ? const LinearGradient(
                        colors: [Color(0xFF1A5E35), Color(0xFF27AE60)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: active ? Border.all(color: _kAccent, width: 2) : null,
              ),
              child: ClipOval(
                child: profilePicUrl != null
                    ? CachedNetworkImage(
                        imageUrl: profilePicUrl!,
                        width: 26,
                        height: 26,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _InitialAvatar(initial: initial),
                      )
                    : _InitialAvatar(initial: initial),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              displayName.length > 8 ? '${displayName.substring(0, 7)}…' : displayName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? _kDark : _kInactive,
              ),
            ),
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
    width: 26,
    height: 26,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1A5E35), Color(0xFF27AE60)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
    ),
  );
}
