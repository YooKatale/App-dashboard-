import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/error_handler_service.dart';

// ── Exact webapp colors (from partner.module.css) ───────────────────────────
const _kGreen      = Color(0xFF1A6B3A); // --green
const _kGreenLight = Color(0xFF2D9556); // --green-light
const _kGreenPale  = Color(0xFFE8F5EE); // --green-pale
const _kYellow     = Color(0xFFF5C800); // --yellow
const _kOrange     = Color(0xFFF97316); // --orange
const _kOrangePale = Color(0xFFFFF3EC); // --orange-pale
const _kDark       = Color(0xFF0C1A10); // --dark
const _kText       = Color(0xFF243028); // --text
const _kMuted      = Color(0xFF637568); // --muted
const _kBorder     = Color(0xFFE2EDE7); // --border
const _kBg         = Color(0xFFF5F9F6); // --bg

const List<String> _categories = [
  'Fresh Produce', 'Groceries', 'Restaurant', 'Bakery', 'Butchery',
  'Dairy Products', 'Beverages', 'Health Foods', 'Kitchen Supplies',
  'Food Delivery', 'Catering Services', 'Organic Foods', 'Farm Produce',
  'Seafood', 'Spices & Herbs', 'International Cuisine', 'Street Food',
  'Coffee Shop', 'Juice Bar', 'Supermarket', 'Livestock farmer',
  'Fisherman', 'Carbohydrates', 'Protein', 'Fats & Oils', 'Vitamins',
  'Gas', 'Knife Sharpening', 'Breakfast', 'Dairy', 'Vegetables',
  'Juice', 'Meals', 'Root tubers', 'Market', 'Shop', 'Dairy farmer',
  'Poultry farmer', 'Egg supplier', 'Honey supplier', 'Cuisines',
  'Kitchen', 'Supplements', 'Gym', 'Hotel', 'Chef', 'Culinary',
];

const List<Map<String, String>> _vendorFaq = [
  {
    'q': 'How do I register my business on YooKatale?',
    'a': 'Fill out the vendor registration form on this page with your store details including name, address, contact information, and business category. Our team will review and approve your application within 24 hours.',
  },
  {
    'q': 'How long does the registration process take?',
    'a': 'After submitting the form, your account will be reviewed and approved within 24 hours. You\'ll receive an email notification once your application is approved.',
  },
  {
    'q': 'How do I collect my money on YooKatale?',
    'a': 'Payments are processed weekly through bank transfer. You\'ll receive payments every Monday for the previous week\'s sales.',
  },
  {
    'q': 'What categories can I register under?',
    'a': 'We support various categories including Fresh Produce, Groceries, Restaurants, Bakery, Butchery, Dairy Products, Beverages, Health Foods, and many more.',
  },
  {
    'q': 'Is there a registration fee?',
    'a': 'No, registering as a vendor on YooKatale is completely free! You only pay a small commission on successful sales.',
  },
  {
    'q': 'Can I update my store information after registration?',
    'a': 'Yes, you can update your store information, business hours, and other details anytime through your vendor dashboard after your account is approved.',
  },
];

const List<Map<String, String>> _deliveryFaq = [
  {
    'q': 'How do I register to deliver with YooKatale?',
    'a': 'Fill out the delivery form on this page with your personal details and preferred transport method. Our team will review your application and get back to you within 24 hours.',
  },
  {
    'q': 'How long does registration take?',
    'a': 'Within 24 hours your account will be reviewed and approved to start delivering. You\'ll receive an email notification with your login credentials once approved.',
  },
  {
    'q': 'How do I get my earnings?',
    'a': 'Delivery payments are made weekly via bank transfer every Monday. You can track your earnings in real-time through the delivery app dashboard.',
  },
  {
    'q': 'Why should I deliver for YooKatale?',
    'a': 'Earn your way with flexible schedules, competitive rates, and the freedom to work when it suits you. Enjoy weekly reliable payments.',
  },
  {
    'q': 'What transport options are available?',
    'a': 'You can deliver using a bike, motorcycle, or vehicle. If you choose vehicle or motorcycle, you\'ll need to provide your number plate.',
  },
  {
    'q': 'Can I set my own schedule?',
    'a': 'Yes! One of the biggest advantages of delivering with YooKatale is setting your own schedule. Work when it suits you.',
  },
];

class PartnerPage extends StatefulWidget {
  const PartnerPage({super.key});

  @override
  State<PartnerPage> createState() => _PartnerPageState();
}

class _PartnerPageState extends State<PartnerPage> with SingleTickerProviderStateMixin {
  int _tab = 0; // 0 = Vendor, 1 = Delivery

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kDark,
        elevation: 0,
        title: const Text('Partner with YooKatale',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kDark)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero ──────────────────────────────────────────────────────
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  // Pulsing badge
                  _PulsingBadge(),
                  const SizedBox(height: 14),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 34, fontWeight: FontWeight.w800, color: _kDark, height: 1.05),
                      children: [
                        const TextSpan(text: 'Partner with\n'),
                        TextSpan(text: 'Yoo', style: TextStyle(color: _kYellow)),
                        TextSpan(text: 'Katale', style: TextStyle(color: _kGreenLight)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join vendors and delivery partners. Grow your business\nwith Uganda\'s freshest online marketplace.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: _kMuted, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Stats row ─────────────────────────────────────────────────
            Row(
              children: [
                _StatCard(num: '45,290', label: 'Users',   color: _kGreen),
                const SizedBox(width: 8),
                _StatCard(num: '4K',     label: 'Drivers', color: _kOrange),
                const SizedBox(width: 8),
                _StatCard(num: '3.5K',   label: 'Stores',  color: const Color(0xFFC49F00)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Tab switcher ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  _TabBtn(
                    icon: Icons.store_mall_directory_outlined,
                    label: 'Vendor',
                    active: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  _TabBtn(
                    icon: Icons.pedal_bike_outlined,
                    label: 'Delivery Partner',
                    active: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                    activeColor: _kOrange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Panel ─────────────────────────────────────────────────────
            if (_tab == 0) const _VendorPanel() else const _DeliveryPanel(),
          ],
        ),
      ),
    );
  }
}

// ── Pulsing badge ────────────────────────────────────────────────────────────
class _PulsingBadge extends StatefulWidget {
  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _kGreenPale,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFB8DFC8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _kGreenLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kGreenLight.withOpacity(_anim.value * 0.5),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          const Text(
            'NOW ACCEPTING PARTNERS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _kGreen,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String num;
  final String label;
  final Color color;
  const _StatCard({required this.num, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text(num, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: _kMuted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Tab button ───────────────────────────────────────────────────────────────
class _TabBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color activeColor;
  const _TabBtn({required this.icon, required this.label, required this.active,
      required this.onTap, this.activeColor = _kGreen});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(color: activeColor.withOpacity(0.28), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : _kMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : _kMuted,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Vendor panel ─────────────────────────────────────────────────────────────
class _VendorPanel extends StatefulWidget {
  const _VendorPanel();

  @override
  State<_VendorPanel> createState() => _VendorPanelState();
}

class _VendorPanelState extends State<_VendorPanel> {
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  String? _category;
  bool _vegan   = false;
  bool _terms   = false;
  bool _loading = false;
  bool _success = false;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _addressCtrl.dispose(); _emailCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final e = <String, String>{};
    if (_nameCtrl.text.trim().isEmpty)    e['name']     = 'Store name is required';
    if (_addressCtrl.text.trim().isEmpty) e['address']  = 'Address is required';
    if (_phoneCtrl.text.trim().isEmpty)   e['phone']    = 'Phone number is required';
    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@'))
                                          e['email']    = 'Enter a valid email address';
    if (_category == null)                e['category'] = 'Please select a category';
    setState(() => _errors = e);
    return e.isEmpty;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    if (!_terms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms and conditions'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final token = await AuthService.getToken();
      await ApiService.registerVendor(
        token: token,
        storeName: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        category: _category!,
        isVegan: _vegan,
      );
      if (mounted) setState(() { _success = true; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandlerService.getErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Steps indicator
        _StepsIndicator(currentStep: 2),
        const SizedBox(height: 14),

        // Perks grid
        _buildPerksGrid(),
        const SizedBox(height: 14),

        // Orange divider
        Container(
          height: 3,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kOrange, _kYellow]),
            borderRadius: BorderRadius.circular(100),
          ),
          margin: const EdgeInsets.only(bottom: 14),
        ),

        // Form card
        _buildFormCard(),
        const SizedBox(height: 20),

        // FAQ
        const Text('FREQUENTLY ASKED',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kMuted, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        _FaqCard(items: _vendorFaq),
      ],
    );
  }

  Widget _buildPerksGrid() {
    return Column(
      children: [
        // Featured perk (full width, dark green)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F3D20), Color(0xFF1A6B3A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Onboarding',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    SizedBox(height: 3),
                    Text('Get approved and start selling within 24 hours.',
                        style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _PerkCard(
                icon: Icons.bar_chart_rounded,
                title: 'Vendor Dashboard',
                desc: 'Manage orders and inventory in real-time.',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PerkCard(
                icon: Icons.credit_card_rounded,
                title: 'Weekly Payouts',
                desc: 'Reliable weekly payments via bank or Mobile Money.',
                isOrange: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: _kGreenPale, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.store_mall_directory_outlined, color: _kGreen, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Store Registration',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kDark)),
                    Text('Fill in your store details below.',
                        style: TextStyle(fontSize: 11, color: _kMuted)),
                  ],
                ),
              ],
            ),
          ),

          if (_success)
            _buildSuccess()
          else
            _buildForm(),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 68, height: 68,
            decoration: const BoxDecoration(color: _kGreenPale, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 32, color: _kGreen),
          ),
          const SizedBox(height: 14),
          const Text('Application Submitted! 🎉',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kDark)),
          const SizedBox(height: 8),
          const Text(
            'Your vendor application has been received.\nWe\'ll review it within 24 hours.',
            style: TextStyle(fontSize: 13, color: _kMuted, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Name + Phone (row)
          Row(
            children: [
              Expanded(
                child: _VField(
                  ctrl: _nameCtrl, label: 'STORE NAME *',
                  hint: 'e.g. Mama\'s Kitchen',
                  error: _errors['name'],
                  onChanged: (_) { if (_errors['name'] != null) setState(() => _errors.remove('name')); },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _VField(
                  ctrl: _phoneCtrl, label: 'PHONE *',
                  hint: '+256 7XX XXX XXX',
                  keyboardType: TextInputType.phone,
                  error: _errors['phone'],
                  onChanged: (_) { if (_errors['phone'] != null) setState(() => _errors.remove('phone')); },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _VField(
            ctrl: _addressCtrl, label: 'STORE ADDRESS *',
            hint: 'e.g. Plot 6, Kampala Road, Kampala',
            error: _errors['address'],
            onChanged: (_) { if (_errors['address'] != null) setState(() => _errors.remove('address')); },
          ),
          const SizedBox(height: 12),

          _VField(
            ctrl: _emailCtrl, label: 'EMAIL ADDRESS *',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            error: _errors['email'],
            onChanged: (_) { if (_errors['email'] != null) setState(() => _errors.remove('email')); },
          ),
          const SizedBox(height: 12),

          // Category dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('BUSINESS CATEGORY *',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kText, letterSpacing: 0.4)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _errors['category'] != null ? Colors.red : _kBorder, width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    hint: const Text('Select your category',
                        style: TextStyle(fontSize: 13, color: Color(0xFFAABCB2))),
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    borderRadius: BorderRadius.circular(10),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kMuted),
                    items: _categories.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: const TextStyle(fontSize: 13, color: _kText)),
                    )).toList(),
                    onChanged: (v) => setState(() {
                      _category = v;
                      _errors.remove('category');
                    }),
                  ),
                ),
              ),
              if (_errors['category'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_errors['category']!,
                      style: const TextStyle(fontSize: 11, color: Colors.red)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Brief description
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('BRIEF DESCRIPTION',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kText, letterSpacing: 0.4)),
              const SizedBox(height: 6),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 13, color: _kText),
                decoration: InputDecoration(
                  hintText: 'Tell customers what you sell and what makes your store special...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFAABCB2)),
                  filled: true, fillColor: _kBg,
                  contentPadding: const EdgeInsets.all(13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _kBorder, width: 1.5)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _kBorder, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kGreenLight, width: 1.5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Vegan toggle
          _ToggleRow(
            icon: Icons.eco_outlined,
            title: 'Vegetarian / Vegan options',
            subtitle: 'We offer plant-based or vegetarian products.',
            value: _vegan,
            onChanged: (v) => setState(() => _vegan = v),
          ),

          // Terms toggle
          _ToggleRow(
            icon: Icons.verified_outlined,
            title: 'I agree to the Terms & Conditions',
            subtitle: 'YooKatale vendor agreement applies.',
            value: _terms,
            onChanged: (v) => setState(() => _terms = v),
            accentColor: _kOrange,
          ),
          const SizedBox(height: 14),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Application',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Delivery panel ────────────────────────────────────────────────────────────
class _DeliveryPanel extends StatefulWidget {
  const _DeliveryPanel();

  @override
  State<_DeliveryPanel> createState() => _DeliveryPanelState();
}

class _DeliveryPanelState extends State<_DeliveryPanel> {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _locCtrl   = TextEditingController();
  final _plateCtrl = TextEditingController();
  String _transport = 'bike';
  bool _terms   = false;
  bool _loading = false;
  bool _success = false;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _emailCtrl.dispose(); _locCtrl.dispose(); _plateCtrl.dispose();
    super.dispose();
  }

  bool _needsPlate() => _transport != 'bike';

  bool _validate() {
    final e = <String, String>{};
    if (_nameCtrl.text.trim().isEmpty)  e['name']  = 'Full name is required';
    if (_phoneCtrl.text.trim().isEmpty) e['phone'] = 'Phone number is required';
    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@'))
                                        e['email'] = 'Enter a valid email address';
    if (_needsPlate() && _plateCtrl.text.trim().isEmpty)
                                        e['plate'] = 'Number plate is required';
    setState(() => _errors = e);
    return e.isEmpty;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    if (!_terms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms and conditions'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final token = await AuthService.getToken();
      await ApiService.registerDeliveryDriver(
        token: token,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        location: _locCtrl.text.trim().isEmpty ? null : _locCtrl.text.trim(),
        vehicleType: _transport,
        numberPlate: _needsPlate() && _plateCtrl.text.trim().isNotEmpty ? _plateCtrl.text.trim() : null,
      );
      if (mounted) setState(() { _success = true; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandlerService.getErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Featured delivery perk (orange)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C2D00), Color(0xFFC2440A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Earn on Every Delivery',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    SizedBox(height: 3),
                    Text('Flexible hours, competitive rates, weekly payments.',
                        style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _PerkCard(icon: Icons.schedule_rounded, title: 'Flexible Hours', desc: 'Work when it suits you.')),
            const SizedBox(width: 8),
            Expanded(child: _PerkCard(icon: Icons.payments_outlined, title: 'Weekly Pay', desc: 'Paid every Monday.', isOrange: true)),
          ],
        ),
        const SizedBox(height: 14),

        // Form card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(color: _kOrangePale, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.pedal_bike_outlined, color: _kOrange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delivery Partner Registration',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kDark)),
                        Text('Fill in your details to get started.',
                            style: TextStyle(fontSize: 11, color: _kMuted)),
                      ],
                    ),
                  ],
                ),
              ),

              if (_success)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 68, height: 68,
                        decoration: BoxDecoration(color: _kOrangePale, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, size: 32, color: _kOrange),
                      ),
                      const SizedBox(height: 14),
                      const Text('Application Submitted! 🎉',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kDark)),
                      const SizedBox(height: 8),
                      const Text(
                        'Your delivery application has been received.\nWe\'ll review it within 24 hours.',
                        style: TextStyle(fontSize: 13, color: _kMuted, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _VField(ctrl: _nameCtrl, label: 'FULL NAME *', hint: 'e.g. Ssali Robert',
                              error: _errors['name'],
                              onChanged: (_) { if (_errors['name'] != null) setState(() => _errors.remove('name')); }),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _VField(ctrl: _phoneCtrl, label: 'PHONE *', hint: '+256 7XX XXX XXX',
                              keyboardType: TextInputType.phone,
                              error: _errors['phone'],
                              onChanged: (_) { if (_errors['phone'] != null) setState(() => _errors.remove('phone')); }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _VField(ctrl: _emailCtrl, label: 'EMAIL *', hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        error: _errors['email'],
                        onChanged: (_) { if (_errors['email'] != null) setState(() => _errors.remove('email')); }),
                      const SizedBox(height: 12),
                      _VField(ctrl: _locCtrl, label: 'LOCATION (optional)', hint: 'e.g. Kampala, Nakawa'),
                      const SizedBox(height: 12),

                      // Transport selector
                      const Text('TRANSPORT TYPE *',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kText, letterSpacing: 0.4)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _TransportBtn(label: 'Bike',       value: 'bike',     icon: Icons.pedal_bike_outlined,     selected: _transport == 'bike',     onTap: () => setState(() => _transport = 'bike')),
                          _TransportBtn(label: 'Motorcycle', value: 'motorcycle', icon: Icons.two_wheeler_rounded,   selected: _transport == 'motorcycle', onTap: () => setState(() => _transport = 'motorcycle')),
                          _TransportBtn(label: 'Car',        value: 'car',      icon: Icons.directions_car_outlined,  selected: _transport == 'car',       onTap: () => setState(() => _transport = 'car')),
                          _TransportBtn(label: 'Pickup',     value: 'pickup',   icon: Icons.local_shipping_outlined,  selected: _transport == 'pickup',    onTap: () => setState(() => _transport = 'pickup')),
                          _TransportBtn(label: 'Van',        value: 'van',      icon: Icons.airport_shuttle_outlined, selected: _transport == 'van',       onTap: () => setState(() => _transport = 'van')),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Number plate (conditional)
                      if (_needsPlate()) ...[
                        _VField(ctrl: _plateCtrl, label: 'NUMBER PLATE *', hint: 'e.g. UAA 123B',
                          error: _errors['plate'],
                          onChanged: (_) { if (_errors['plate'] != null) setState(() => _errors.remove('plate')); }),
                        const SizedBox(height: 12),
                      ],

                      _ToggleRow(
                        icon: Icons.verified_outlined,
                        title: 'I agree to the Terms & Conditions',
                        subtitle: 'YooKatale delivery partner agreement applies.',
                        value: _terms,
                        onChanged: (v) => setState(() => _terms = v),
                        accentColor: _kOrange,
                      ),
                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Submit Application',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // FAQ
        const Text('FREQUENTLY ASKED',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kMuted, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        _FaqCard(items: _deliveryFaq),
      ],
    );
  }
}

// ── Steps indicator ──────────────────────────────────────────────────────────
class _StepsIndicator extends StatelessWidget {
  final int currentStep;
  const _StepsIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'label': 'Choose'},
      {'label': 'Register'},
      {'label': 'Go Live'},
    ];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(height: 2, color: _kBorder),
          );
        }
        final idx = i ~/ 2;
        final done    = idx < currentStep - 1;
        final current = idx == currentStep - 1;
        return Column(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? _kGreen : current ? _kYellow : Colors.white,
                border: Border.all(
                  color: done ? _kGreen : current ? _kYellow : _kBorder,
                  width: 2,
                ),
                boxShadow: current
                    ? [BoxShadow(color: _kYellow.withOpacity(0.35), blurRadius: 8, spreadRadius: 2)]
                    : null,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : Text('${idx + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: current ? _kDark : _kMuted,
                        )),
              ),
            ),
            const SizedBox(height: 4),
            Text(steps[idx]['label']!,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: (done || current) ? _kText : _kMuted,
                  letterSpacing: 0.4,
                )),
          ],
        );
      }),
    );
  }
}

// ── Perk card ────────────────────────────────────────────────────────────────
class _PerkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final bool isOrange;
  const _PerkCard({required this.icon, required this.title, required this.desc, this.isOrange = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOrange ? _kOrangePale : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isOrange ? const Color(0xFFFFD0B0) : _kBorder, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: isOrange ? Colors.orange.withOpacity(0.12) : _kGreenPale,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isOrange ? _kOrange : _kGreen, size: 18),
          ),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: isOrange ? const Color(0xFFB8420A) : _kDark,
              )),
          const SizedBox(height: 3),
          Text(desc, style: const TextStyle(fontSize: 11, color: _kMuted, height: 1.4)),
        ],
      ),
    );
  }
}

// ── Toggle row ───────────────────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accentColor;
  const _ToggleRow({required this.icon, required this.title, required this.subtitle,
      required this.value, required this.onChanged, this.accentColor = _kGreen});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: accentColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, color: _kText, fontWeight: FontWeight.w500)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: _kMuted)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 24,
              decoration: BoxDecoration(
                color: value ? accentColor : _kBorder,
                borderRadius: BorderRadius.circular(100),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transport button ─────────────────────────────────────────────────────────
class _TransportBtn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TransportBtn({required this.label, required this.value, required this.icon,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _kOrangePale : _kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _kOrange : _kBorder,
            width: selected ? 1.5 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? _kOrange : _kMuted),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? _kOrange : _kMuted,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Field widget ─────────────────────────────────────────────────────────────
class _VField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? error;
  final ValueChanged<String>? onChanged;
  const _VField({required this.ctrl, required this.label, required this.hint,
      this.keyboardType, this.error, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kText, letterSpacing: 0.4)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: _kText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFAABCB2)),
            filled: true, fillColor: _kBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            errorText: error,
            errorStyle: const TextStyle(fontSize: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _kBorder, width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: error != null ? Colors.red : _kBorder, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kGreenLight, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

// ── FAQ card ─────────────────────────────────────────────────────────────────
class _FaqCard extends StatefulWidget {
  final List<Map<String, String>> items;
  const _FaqCard({required this.items});

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  int? _open;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: List.generate(widget.items.length, (i) {
          final open = _open == i;
          return Column(
            children: [
              if (i > 0) Divider(height: 1, color: _kBorder),
              GestureDetector(
                onTap: () => setState(() => _open = open ? null : i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(widget.items[i]['q']!,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kText, height: 1.4)),
                      ),
                      const SizedBox(width: 12),
                      AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: _kMuted),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                child: open
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                        child: Text(widget.items[i]['a']!,
                            style: const TextStyle(fontSize: 13, color: _kMuted, height: 1.6)),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }),
      ),
    );
  }
}
