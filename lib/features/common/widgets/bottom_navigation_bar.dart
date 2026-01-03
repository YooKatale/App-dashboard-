import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../app.dart';
import '../../cart/widgets/cart_page.dart';
import '../../account/widgets/mobile_account_page.dart';
import '../../categories/widgets/mobile_categories_page.dart';
import '../../subscription/widgets/mobile_subscription_page.dart';
import '../../cart/providers/cart_provider.dart';

class MobileBottomNavigationBar extends ConsumerStatefulWidget {
  final int currentIndex;
  
  const MobileBottomNavigationBar({
    super.key,
    this.currentIndex = 0,
  });

  @override
  ConsumerState<MobileBottomNavigationBar> createState() => _MobileBottomNavigationBarState();
}

class _MobileBottomNavigationBarState extends ConsumerState<MobileBottomNavigationBar> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;
    
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/categories');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/cart');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/subscription');
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed('/account');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                isActive: _currentIndex == 0,
              ),
              _buildNavItem(
                icon: Icons.category_rounded,
                label: 'Categories',
                index: 1,
                isActive: _currentIndex == 1,
              ),
              _buildNavItem(
                icon: Icons.shopping_cart_rounded,
                label: 'Cart',
                index: 2,
                isActive: _currentIndex == 2,
                badgeCount: ref.watch(cartCountProvider),
              ),
              _buildNavItem(
                icon: Icons.card_giftcard_rounded,
                label: 'Subscriptions',
                index: 3,
                isActive: _currentIndex == 3,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Account',
                index: 4,
                isActive: _currentIndex == 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    int badgeCount = 0,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isActive
                        ? const Color.fromRGBO(24, 95, 45, 1)
                        : Colors.grey[600],
                    size: 22,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? const Color.fromRGBO(24, 95, 45, 1)
                        : Colors.grey[600],
                    fontFamily: 'Raleway',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
