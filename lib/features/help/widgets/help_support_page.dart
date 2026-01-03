import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/widgets/bottom_navigation_bar.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          // Contact Support Section
          _HelpSection(
            title: 'Contact Support',
            children: [
              _HelpTile(
                icon: Icons.phone,
                title: 'Call Us',
                subtitle: '+256 700 000 000',
                onTap: () async {
                  final uri = Uri.parse('tel:+256700000000');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              _HelpTile(
                icon: Icons.email,
                title: 'Email Us',
                subtitle: 'support@yookatale.com',
                onTap: () async {
                  final uri = Uri.parse('mailto:support@yookatale.com');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              _HelpTile(
                icon: Icons.chat_bubble_outline,
                title: 'Live Chat',
                subtitle: 'Available 24/7',
                onTap: () {
                  // Open live chat
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
                  _showFAQDialog(
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
                  _showFAQDialog(
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
                  _showFAQDialog(
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
                  _showFAQDialog(
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
                  _showFAQDialog(
                    context,
                    'How do subscriptions work?',
                    'Subscribe to a meal plan and get 3 meals per day delivered to your door. You can view the weekly meal calendar and customize your preferences.',
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Account & Settings
          _HelpSection(
            title: 'Account & Settings',
            children: [
              _HelpTile(
                icon: Icons.person_outline,
                title: 'How do I update my profile?',
                subtitle: 'Manage your account information',
                onTap: () {
                  Navigator.pushNamed(context, '/account');
                },
              ),
              _HelpTile(
                icon: Icons.location_on_outlined,
                title: 'How do I change my delivery address?',
                subtitle: 'Update your location',
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
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
                  _showAboutDialog(context);
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

  void _showFAQDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About YooKatale'),
        content: const Text(
          'YooKatale - Your Digital Mobile Food Market\n\n'
          'Version 1.0.0\n\n'
          'YooKatale is your trusted grocery delivery partner, bringing fresh products and meal subscriptions right to your door.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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
