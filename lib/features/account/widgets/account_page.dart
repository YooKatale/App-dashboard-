import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../features/authentication/providers/auth_provider.dart';
import 'tabs/general_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/subscriptions_tab.dart';
import 'tabs/settings_tab.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  String _activeTab = 'general';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = FirebaseAuth.instance.currentUser;

    if (!authState.isLoggedIn || user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
          backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please login to view your account'),
        ),
      );
    }

    // Get user info from auth state or Firebase
    final userName = user.displayName ?? 'User';
    final userEmail = user.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // User Profile Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(51),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color.fromRGBO(24, 95, 45, 1),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Color.fromRGBO(24, 95, 45, 1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tabs and Content
          Expanded(
            child: Row(
              children: [
                // Sidebar Navigation
                Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(
                      right: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: ListView(
                    children: [
                      _TabButton(
                        icon: Icons.person_outline,
                        label: 'General',
                        isActive: _activeTab == 'general',
                        onTap: () => setState(() => _activeTab = 'general'),
                      ),
                      _TabButton(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Orders',
                        isActive: _activeTab == 'orders',
                        onTap: () => setState(() => _activeTab = 'orders'),
                      ),
                      _TabButton(
                        icon: Icons.card_membership,
                        label: 'Subscriptions',
                        isActive: _activeTab == 'subscriptions',
                        onTap: () =>
                            setState(() => _activeTab = 'subscriptions'),
                      ),
                      _TabButton(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        isActive: _activeTab == 'settings',
                        onTap: () => setState(() => _activeTab = 'settings'),
                      ),
                    ],
                  ),
                ),
                // Content Area
                Expanded(
                  child: _activeTab == 'general'
                      ? const GeneralTab()
                      : _activeTab == 'orders'
                          ? const OrdersTab()
                          : _activeTab == 'subscriptions'
                              ? const SubscriptionsTab()
                              : const SettingsTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        color:
            isActive ? const Color.fromRGBO(24, 95, 45, 1) : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.black87,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
