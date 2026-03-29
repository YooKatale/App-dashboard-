import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/widgets/bottom_navigation_bar.dart';

const _green = Color.fromRGBO(24, 95, 45, 1);

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('About YooKatale', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Raleway')),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF185f2d), Color(0xFF2e7d32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.local_grocery_store, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text('YooKatale', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Raleway')),
                  const SizedBox(height: 8),
                  Text('Fresh Food. Delivered Fast.', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9))),
                  const SizedBox(height: 4),
                  Text('Version 2.0.0', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Our Mission', Icons.flag,
                    'YooKatale is Uganda\'s leading fresh food delivery platform, connecting customers with local farmers, vendors, and food suppliers. We make it easy to get fresh, quality food delivered to your doorstep quickly and affordably.',
                  ),
                  _buildSection('What We Offer', Icons.star,
                    'From fresh fruits and vegetables to grains, meat, dairy, and specialty foods — YooKatale offers thousands of products sourced directly from trusted local suppliers across Uganda.',
                  ),
                  _buildSection('Our Story', Icons.history,
                    'Founded in Uganda, YooKatale started with a simple vision: make fresh, quality food accessible to every household. Today we serve thousands of families across Kampala and beyond, with same-day delivery and flexible subscription meal plans.',
                  ),

                  const SizedBox(height: 8),
                  const Text('Key Features', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  ...[
                    ('🚀', 'Same-Day Delivery', 'Get fresh food delivered within 24-45 minutes'),
                    ('📦', 'Subscription Plans', 'Weekly meal plans starting from UGX 50,000'),
                    ('⭐', 'Loyalty Rewards', 'Earn points on every purchase and redeem for discounts'),
                    ('💳', 'Cashless Payments', 'Pay securely via mobile money or card'),
                    ('🌱', 'Local Sourcing', 'Supporting Ugandan farmers and food businesses'),
                    ('📱', 'Real-time Tracking', 'Track your order from checkout to doorstep'),
                  ].map((f) => _buildFeatureTile(f.$1, f.$2, f.$3)),

                  const SizedBox(height: 24),
                  const Text('Connect With Us', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildLinkTile(Icons.language, 'Website', 'www.yookatale.app', 'https://www.yookatale.app'),
                  _buildLinkTile(Icons.email, 'Email', 'info@yookatale.app', 'mailto:info@yookatale.app'),
                  _buildLinkTile(Icons.phone, 'Phone', '+256 786 118 137', 'tel:+256786118137'),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _green, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(String emoji, String title, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(IconData icon, String label, String value, String url) {
    return Builder(
      builder: (ctx) => GestureDetector(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(icon, color: _green, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _green)),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, size: 16, color: _green),
            ],
          ),
        ),
      ),
    );
  }
}
