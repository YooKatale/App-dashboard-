import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../../services/auth_service.dart';

const _kDark   = Color(0xFF112D1C);
const _kPrimary = Color(0xFF0B2416);
const _kAccent = Color(0xFF2ECC71);
const _kBg     = Color(0xFFF4F6F4);

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

    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.82,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: _kPrimary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar — shows real profile image if available (like webapp)
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: profilePicUrl == null
                            ? const LinearGradient(
                                colors: [Color(0xFF1A5E35), Color(0xFF27AE60)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        border: Border.all(color: _kAccent.withOpacity(0.4), width: 2),
                      ),
                      child: ClipOval(
                        child: profilePicUrl != null
                            ? CachedNetworkImage(
                                imageUrl: profilePicUrl,
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _DrawerInitialAvatar(initial: initial),
                              )
                            : _DrawerInitialAvatar(initial: initial),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoggedIn ? (fullName.isNotEmpty ? fullName : 'Welcome') : 'Guest',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isLoggedIn && email.isNotEmpty) ...[
                            const SizedBox(height: 3),
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
                  ],
                ),
                const SizedBox(height: 14),
                // YooKatale Pro badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kAccent.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: _kAccent, size: 12),
                      SizedBox(width: 5),
                      Text(
                        'YooKatale Pro',
                        style: TextStyle(color: _kAccent, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Nav items ────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  _DrawerSection(title: 'Main', items: [
                    _DrawerItem(icon: Icons.home_rounded,          label: 'Home',              route: '/home'),
                    _DrawerItem(icon: Icons.grid_view_rounded,     label: 'Subscribe',         route: '/subscription'),
                    _DrawerItem(icon: Icons.shopping_cart_rounded, label: 'Cart',              route: '/cart'),
                    _DrawerItem(icon: Icons.favorite_rounded,      label: 'Wishlist',          route: '/wishlist'),
                    _DrawerItem(icon: Icons.receipt_long_rounded,  label: 'My Orders',         route: '/orders'),
                    _DrawerItem(icon: Icons.calendar_month_rounded,label: 'Meal Calendar',     route: '/meal-calendar'),
                    _DrawerItem(icon: Icons.schedule_rounded,      label: 'Schedule',          route: '/schedule'),
                  ]),

                  _DrawerSection(title: 'Shop', items: [
                    _DrawerItem(icon: Icons.category_rounded,      label: 'All Categories',    route: '/categories'),
                    _DrawerItem(icon: Icons.card_giftcard_rounded, label: 'Gift Cards',        route: '/gift-cards'),
                    _DrawerItem(icon: Icons.stars_rounded,         label: 'Rewards',           route: '/rewards'),
                    _DrawerItem(icon: Icons.account_balance_wallet_rounded, label: 'Cashout',  route: '/cashout'),
                  ]),

                  _DrawerSection(title: 'Account', items: [
                    _DrawerItem(icon: Icons.person_rounded,        label: 'Profile',           route: '/account'),
                    _DrawerItem(icon: Icons.edit_rounded,          label: 'Edit Profile',      route: '/edit-profile'),
                    _DrawerItem(icon: Icons.notifications_rounded, label: 'Notifications',     route: '/notifications'),
                    _DrawerItem(icon: Icons.settings_rounded,      label: 'Settings',          route: '/settings'),
                  ]),

                  _DrawerSection(title: 'Services', items: [
                    _DrawerItem(icon: Icons.electric_rickshaw_rounded, label: 'Driver Dashboard', route: '/driver-dashboard'),
                    _DrawerItem(icon: Icons.handshake_rounded,     label: 'Become a Partner', route: '/partner'),
                    _DrawerItem(icon: Icons.work_rounded,          label: 'Careers',           route: '/careers'),
                    _DrawerItem(icon: Icons.campaign_rounded,      label: 'Advertise',         route: '/advertise'),
                  ]),

                  _DrawerSection(title: 'Info', items: [
                    _DrawerItem(icon: Icons.help_rounded,          label: 'Help & Support',    route: '/help'),
                    _DrawerItem(icon: Icons.quiz_rounded,          label: 'FAQs',              route: '/faqs'),
                    _DrawerItem(icon: Icons.info_rounded,          label: 'About Us',          route: '/about'),
                    _DrawerItem(icon: Icons.mail_rounded,          label: 'Contact Us',        route: '/contact'),
                    _DrawerItem(icon: Icons.lock_rounded,          label: 'Privacy Policy',    route: '/privacy'),
                    _DrawerItem(icon: Icons.description_rounded,   label: 'Terms of Service',  route: '/terms'),
                  ]),

                  const SizedBox(height: 8),

                  // Sign in / Sign out
                  if (!isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/signin');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: _kPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Sign In',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(context);
                          await AuthService.clearUserData();
                          ref.read(authStateProvider.notifier).state = const AuthState.loggedOut();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEEEE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFCCCC)),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.logout_rounded, color: Color(0xFFD32F2F), size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Sign Out',
                                  style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section with title ─────────────────────────────────────────────────────────
class _DrawerSection extends StatelessWidget {
  final String title;
  final List<_DrawerItem> items;
  const _DrawerSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFAAAAAA),
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...items.map((item) => _DrawerNavTile(item: item)),
        const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFEEEEEE)),
      ],
    );
  }
}

// ── Individual drawer tile ─────────────────────────────────────────────────────
class _DrawerItem {
  final IconData icon;
  final String label;
  final String route;
  const _DrawerItem({required this.icon, required this.label, required this.route});
}

class _DrawerNavTile extends StatelessWidget {
  final _DrawerItem item;
  const _DrawerNavTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isActive = currentRoute == item.route;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (currentRoute != item.route) {
          Navigator.pushNamed(context, item.route);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8F5EE) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 20,
              color: isActive ? _kPrimary : const Color(0xFF555555),
            ),
            const SizedBox(width: 14),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? _kPrimary : const Color(0xFF333333),
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: _kAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DrawerInitialAvatar extends StatelessWidget {
  final String initial;
  const _DrawerInitialAvatar({required this.initial});
  @override
  Widget build(BuildContext context) => Container(
    width: 54,
    height: 54,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1A5E35), Color(0xFF27AE60)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
    ),
  );
}
