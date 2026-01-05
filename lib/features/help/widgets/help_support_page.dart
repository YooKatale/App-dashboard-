import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import '../../../widgets/support_contact_widget.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../../services/auth_service.dart';

class HelpSupportPage extends ConsumerWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.isLoggedIn;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Raleway',
          ),
        ),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contact Support Section - Always show
          const SupportContactWidget(),
          const SizedBox(height: 24),
          
          _HelpSection(
            title: 'Contact Support',
            children: [
              _HelpTile(
                icon: Icons.chat,
                title: 'WhatsApp Support',
                subtitle: '+256786118137',
                onTap: () async {
                  final uri = Uri.parse('https://wa.me/256786118137');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              _HelpTile(
                icon: Icons.email,
                title: 'Email Support',
                subtitle: 'info@yookatale.app',
                onTap: () async {
                  final uri = Uri.parse('mailto:info@yookatale.app?subject=Support Request');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Frequently Asked Questions
          _HelpSection(
            title: 'Frequently Asked Questions',
            children: [
              _HelpTile(
                icon: Icons.shopping_bag_outlined,
                title: 'How do I place an order?',
                subtitle: 'Learn how to order products',
                onTap: () {
                  HelpSupportPage._showFAQDialog(
                    context,
                    'How do I place an order?',
                    '1. Browse products and add items to your cart\n2. Review your cart and proceed to checkout\n3. Enter your delivery address\n4. Choose payment method\n5. Confirm your order',
                  );
                },
              ),
              _HelpTile(
                icon: Icons.local_shipping,
                title: 'What are the delivery charges?',
                subtitle: 'Learn about delivery fees',
                onTap: () {
                  HelpSupportPage._showFAQDialog(
                    context,
                    'What are the delivery charges?',
                    'Free delivery within 3km distance. Extra charges: 950 UGX per additional kilometer.',
                  );
                },
              ),
              _HelpTile(
                icon: Icons.payment,
                title: 'What payment methods do you accept?',
                subtitle: 'Available payment options',
                onTap: () {
                  HelpSupportPage._showFAQDialog(
                    context,
                    'What payment methods do you accept?',
                    'We accept mobile money, credit/debit cards, and cash on delivery.',
                  );
                },
              ),
              _HelpTile(
                icon: Icons.refresh,
                title: 'Can I cancel my order?',
                subtitle: 'Order cancellation policy',
                onTap: () {
                  HelpSupportPage._showFAQDialog(
                    context,
                    'Can I cancel my order?',
                    'You can cancel your order within 30 minutes of placing it. After that, please contact support.',
                  );
                },
              ),
              _HelpTile(
                icon: Icons.card_membership,
                title: 'How do subscriptions work?',
                subtitle: 'Learn about meal subscriptions',
                onTap: () {
                  HelpSupportPage._showFAQDialog(
                    context,
                    'How do subscriptions work?',
                    'Subscribe to a meal plan and get 3 meals per day delivered to your door. You can view the weekly meal calendar and customize your preferences.',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Account & Settings - Show same content whether logged in or not
          _HelpSection(
            title: 'Account & Settings',
            children: [
              _HelpTile(
                icon: Icons.person_outline,
                title: 'How do I update my profile?',
                subtitle: 'Manage your account information',
                onTap: () {
                  if (isLoggedIn) {
                    Navigator.pushNamed(context, '/account');
                  } else {
                    Navigator.pushNamed(context, '/signin');
                  }
                },
              ),
              _HelpTile(
                icon: Icons.location_on_outlined,
                title: 'How do I change my delivery address?',
                subtitle: 'Update your location',
                onTap: () {
                  if (isLoggedIn) {
                    Navigator.pushNamed(context, '/settings');
                  } else {
                    Navigator.pushNamed(context, '/signin');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // About
          _HelpSection(
            title: 'About',
            children: [
              _HelpTile(
                icon: Icons.info_outline,
                title: 'About YooKatale',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  showAboutDialog(context, isLoggedIn);
                },
              ),
              _HelpTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                onTap: () {
                  // Open privacy policy
                },
              ),
              _HelpTile(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                subtitle: 'Read our terms',
                onTap: () {
                  // Open terms
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _showFAQDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showAboutDialog(BuildContext context, bool isLoggedIn) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(24, 95, 45, 1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Color.fromRGBO(24, 95, 45, 1),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'About YooKatale',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Content
              const Text(
                'YooKatale - Your Digital Mobile Food Market',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'YooKatale is your trusted grocery delivery partner, bringing fresh products and meal subscriptions right to your door.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // WhatsApp Button (if logged in)
              if (isLoggedIn) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final uri = Uri.parse('https://wa.me/256786118137');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.chat, color: Colors.white),
                    label: const Text(
                      'Contact via WhatsApp',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Close Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color.fromRGBO(24, 95, 45, 1),
                    side: const BorderSide(color: Color.fromRGBO(24, 95, 45, 1)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _HelpSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _HelpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromRGBO(24, 95, 45, 1)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
