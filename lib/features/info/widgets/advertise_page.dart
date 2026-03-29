import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/widgets/bottom_navigation_bar.dart';

const _green = Color.fromRGBO(24, 95, 45, 1);

class AdvertisePage extends StatefulWidget {
  const AdvertisePage({super.key});

  @override
  State<AdvertisePage> createState() => _AdvertisePageState();
}

class _AdvertisePageState extends State<AdvertisePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _bizCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  String _selectedPackage = '';
  bool _sending = false;
  bool _sent = false;

  static const _packages = [
    _AdPackage(
      icon: Icons.bolt_rounded,
      title: 'Starter',
      price: 'UGX 150,000 / mo',
      color: Colors.blue,
      features: ['Banner in app home screen', '10,000+ impressions/month', 'Email support'],
    ),
    _AdPackage(
      icon: Icons.star_rounded,
      title: 'Growth',
      price: 'UGX 400,000 / mo',
      color: Colors.orange,
      features: ['Featured placement on home & search', '50,000+ impressions/month', 'Push notification blast (1×)', 'Weekly analytics report'],
      popular: true,
    ),
    _AdPackage(
      icon: Icons.workspace_premium_rounded,
      title: 'Premium',
      price: 'UGX 900,000 / mo',
      color: _green,
      features: ['All Growth features', '200,000+ impressions/month', 'Push notification blasts (4×)', 'Dedicated account manager', 'Custom campaign design'],
    ),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _bizCtrl.dispose(); _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedPackage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select an advertising package'),
        backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() { _sending = false; _sent = true; });
  }

  void _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Advertise With Us', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Raleway')),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
      body: _sent ? _buildSuccess() : SingleChildScrollView(
        child: Column(
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 14),
                  const Text('Reach Thousands of\nFood Lovers Daily', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Raleway', height: 1.3)),
                  const SizedBox(height: 8),
                  Text('50,000+ active users in Kampala and beyond', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statPill('50K+', 'Active Users'),
                      _statPill('4.8★', 'App Rating'),
                      _statPill('98%', 'Delivery Rate'),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Why advertise
                  const Text('Why Advertise on YooKatale?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...[
                    (Icons.people_alt_rounded, 'Targeted Audience', 'Reach active food buyers in Uganda'),
                    (Icons.trending_up_rounded, 'High Engagement', 'Users open the app 5+ times per week'),
                    (Icons.local_offer_rounded, 'Affordable Rates', 'Packages starting from UGX 150,000/month'),
                    (Icons.analytics_rounded, 'Real Analytics', 'Track impressions, clicks, and conversions'),
                  ].map((e) => _reasonTile(e.$1, e.$2, e.$3)),

                  const SizedBox(height: 24),
                  const Text('Choose a Package', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._packages.map((p) => _packageCard(p)),

                  const SizedBox(height: 24),
                  const Text('Get Started', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _field(_nameCtrl, 'Your Name', Icons.person_outline),
                        const SizedBox(height: 12),
                        _field(_emailCtrl, 'Email Address', Icons.email_outlined, keyboard: TextInputType.emailAddress,
                          validator: (v) => (v?.contains('@') ?? false) ? null : 'Invalid email'),
                        const SizedBox(height: 12),
                        _field(_bizCtrl, 'Business / Brand Name', Icons.business_outlined),
                        const SizedBox(height: 12),
                        _field(_budgetCtrl, 'Monthly Budget (UGX)', Icons.attach_money_rounded, keyboard: TextInputType.number),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _sending ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green, foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _sending
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Submit Inquiry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _green.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.support_agent_rounded, color: _green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Talk to our Ads Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              GestureDetector(
                                onTap: () => _launch('mailto:ads@yookatale.app'),
                                child: const Text('ads@yookatale.app', style: TextStyle(color: _green, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Raleway')),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _reasonTile(IconData icon, String title, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _green, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ])),
        ],
      ),
    );
  }

  Widget _packageCard(_AdPackage p) {
    final selected = _selectedPackage == p.title;
    return GestureDetector(
      onTap: () => setState(() => _selectedPackage = p.title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? p.color.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? p.color : Colors.grey[200]!, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: p.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(p.icon, color: p.color, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (p.popular) ...[
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                          child: const Text('Popular', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold))),
                      ],
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_circle_rounded, color: p.color),
              ],
            ),
            const SizedBox(height: 4),
            Text(p.price, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.color)),
            const SizedBox(height: 10),
            ...p.features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Icon(Icons.check, size: 14, color: p.color),
                const SizedBox(width: 6),
                Text(f, style: const TextStyle(fontSize: 13)),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      validator: validator ?? (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 2)),
        filled: true, fillColor: Colors.white,
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 64)),
            const SizedBox(height: 24),
            const Text('Inquiry Submitted!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Raleway')),
            const SizedBox(height: 12),
            Text('Our ads team will contact you within 1 business day to discuss your campaign.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.6)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdPackage {
  final IconData icon;
  final String title;
  final String price;
  final Color color;
  final List<String> features;
  final bool popular;
  const _AdPackage({required this.icon, required this.title, required this.price, required this.color, required this.features, this.popular = false});
}
