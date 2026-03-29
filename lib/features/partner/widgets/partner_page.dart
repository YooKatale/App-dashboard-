import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/error_handler_service.dart';
import '../../common/widgets/bottom_navigation_bar.dart';

const _green = Color.fromRGBO(24, 95, 45, 1);

const List<String> _businessCategories = [
  'Fruits & Vegetables', 'Meat & Poultry', 'Dairy & Eggs', 'Grains & Flour',
  'Beverages & Juices', 'Snacks & Confectionery', 'Bakery & Pastries',
  'Seafood', 'Spices & Condiments', 'Organic Foods', 'Baby Foods',
  'Health & Wellness Foods', 'Frozen Foods', 'Canned & Packaged Foods',
  'Cooking Oils', 'Sugar & Sweeteners', 'Pasta & Noodles', 'Nuts & Seeds',
  'Coffee & Tea', 'Alcoholic Beverages', 'Soft Drinks', 'Water & Sports Drinks',
  'Ethnic & Specialty Foods', 'Halal Foods', 'Kosher Foods', 'Vegan Foods',
  'Restaurant & Catering', 'Fast Food', 'Street Food', 'Home Cooked Meals',
  'Meal Prep Services', 'Breakfast & Brunch', 'Desserts & Ice Cream',
  'Smoothies & Health Drinks', 'Farm Direct', 'Wholesale', 'Other',
];

class PartnerPage extends ConsumerStatefulWidget {
  const PartnerPage({super.key});

  @override
  ConsumerState<PartnerPage> createState() => _PartnerPageState();
}

class _PartnerPageState extends ConsumerState<PartnerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Become a Partner',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Raleway')),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: 'Vendor'),
            Tab(icon: Icon(Icons.two_wheeler), text: 'Delivery Driver'),
          ],
        ),
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _VendorForm(),
          _DriverForm(),
        ],
      ),
    );
  }
}

// ─── Vendor Registration Form ─────────────────────────────────────────────
class _VendorForm extends ConsumerStatefulWidget {
  const _VendorForm();

  @override
  ConsumerState<_VendorForm> createState() => _VendorFormState();
}

class _VendorFormState extends ConsumerState<_VendorForm> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _category;
  bool _isVegetarian = false;
  bool _isVegan = false;
  bool _isLoading = false;
  bool _success = false;
  final Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a business category'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() { _isLoading = true; _fieldErrors.clear(); });
    try {
      final token = await AuthService.getToken();
      await ApiService.registerVendor(
        token: token,
        storeName: _storeNameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        category: _category!,
        isVegetarian: _isVegetarian,
        isVegan: _isVegan,
      );
      if (mounted) setState(() { _success = true; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(context, message: ErrorHandlerService.getErrorMessage(e));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _buildSuccess('Vendor');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(
              Icons.storefront,
              'Sell on YooKatale',
              'Register your store and reach thousands of customers. Your application will be reviewed within 24 hours.',
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Store Information'),
            const SizedBox(height: 12),
            _buildField(_storeNameCtrl, 'Store Name *', Icons.store, validator: _required),
            const SizedBox(height: 14),
            _buildField(_addressCtrl, 'Store Address *', Icons.location_on, validator: _required),
            const SizedBox(height: 14),
            _buildField(_phoneCtrl, 'Phone Number *', Icons.phone,
                keyboard: TextInputType.phone, validator: _required),
            const SizedBox(height: 14),
            _buildField(_emailCtrl, 'Business Email *', Icons.email,
                keyboard: TextInputType.emailAddress, validator: _emailValidator),
            const SizedBox(height: 14),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _category,
              decoration: _inputDecor('Business Category *', Icons.category),
              hint: const Text('Select category'),
              isExpanded: true,
              items: _businessCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Food Type'),
            const SizedBox(height: 10),
            _buildToggleRow(
              'Vegetarian Options',
              'We serve vegetarian food',
              Icons.eco,
              Colors.green,
              _isVegetarian,
              (v) => setState(() => _isVegetarian = v),
            ),
            const SizedBox(height: 8),
            _buildToggleRow(
              'Vegan Options',
              'We serve vegan food',
              Icons.spa,
              Colors.teal,
              _isVegan,
              (v) => setState(() => _isVegan = v),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Register as Vendor',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
            _buildFAQSection('Vendor FAQs', [
              _FAQ('How long does approval take?', 'Your application is reviewed within 24 hours by our team.'),
              _FAQ('What commission does YooKatale take?', 'We charge a competitive commission per successful sale.'),
              _FAQ('How do I get paid?', 'Earnings are sent directly to your mobile money account weekly.'),
              _FAQ('Can I manage my own pricing?', 'Yes, you have full control over your product prices.'),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Delivery Driver Registration Form ───────────────────────────────────
class _DriverForm extends ConsumerStatefulWidget {
  const _DriverForm();

  @override
  ConsumerState<_DriverForm> createState() => _DriverFormState();
}

class _DriverFormState extends ConsumerState<_DriverForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  String? _vehicleType;
  bool _hasPermit = false;
  bool _isLoading = false;
  bool _success = false;

  final List<Map<String, dynamic>> _vehicles = [
    {'value': 'bike', 'label': 'Motorcycle', 'icon': Icons.two_wheeler},
    {'value': 'bicycle', 'label': 'Bicycle', 'icon': Icons.pedal_bike},
    {'value': 'car', 'label': 'Car', 'icon': Icons.directions_car},
    {'value': 'pickup', 'label': 'Pickup Truck', 'icon': Icons.local_shipping},
    {'value': 'van', 'label': 'Van', 'icon': Icons.airport_shuttle},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _locationCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  bool get _needsPlate => ['bike', 'car', 'pickup', 'van'].contains(_vehicleType);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehicleType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your vehicle type'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      await ApiService.registerDeliveryDriver(
        token: token,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        vehicleType: _vehicleType!,
        numberPlate: _needsPlate ? _plateCtrl.text.trim() : null,
        hasPermit: _hasPermit,
      );
      if (mounted) setState(() { _success = true; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(context, message: ErrorHandlerService.getErrorMessage(e));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _buildSuccess('Delivery Driver');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(
              Icons.delivery_dining,
              'Deliver with YooKatale',
              'Join our delivery team and earn money on your own schedule. Flexible hours, competitive pay.',
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Personal Details'),
            const SizedBox(height: 12),
            _buildField(_nameCtrl, 'Full Name *', Icons.person, validator: _required),
            const SizedBox(height: 14),
            _buildField(_phoneCtrl, 'Phone Number *', Icons.phone,
                keyboard: TextInputType.phone, validator: _required),
            const SizedBox(height: 14),
            _buildField(_emailCtrl, 'Email *', Icons.email,
                keyboard: TextInputType.emailAddress, validator: _emailValidator),
            const SizedBox(height: 14),
            _buildField(_locationCtrl, 'Location (Optional)', Icons.location_on),
            const SizedBox(height: 20),

            _buildSectionTitle('Vehicle Details'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _vehicles.map((v) {
                final selected = _vehicleType == v['value'];
                return GestureDetector(
                  onTap: () => setState(() => _vehicleType = v['value'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? _green : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? _green : Colors.grey[300]!, width: 1.5),
                      boxShadow: selected ? [BoxShadow(color: _green.withOpacity(0.2), blurRadius: 8)] : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(v['icon'] as IconData, size: 18, color: selected ? Colors.white : Colors.grey[700]),
                        const SizedBox(width: 6),
                        Text(v['label'] as String,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.grey[700],
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 13,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_needsPlate) ...[
              const SizedBox(height: 14),
              _buildField(_plateCtrl, 'Number Plate *', Icons.badge,
                  validator: _needsPlate ? _required : null),
            ],
            const SizedBox(height: 16),
            _buildToggleRow(
              'Valid Driving Permit',
              'I have a valid driving permit',
              Icons.verified,
              Colors.blue,
              _hasPermit,
              (v) => setState(() => _hasPermit = v),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Register as Driver',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
            _buildFAQSection('Driver FAQs', [
              _FAQ('How do I earn money?', 'You earn per delivery. The more deliveries you complete, the more you earn.'),
              _FAQ('When do I get paid?', 'Earnings are transferred to your mobile money account weekly.'),
              _FAQ('Do I need insurance?', 'We recommend having personal vehicle insurance.'),
              _FAQ('What areas can I deliver in?', 'You can deliver across all areas we serve in Uganda.'),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────

Widget _buildSuccess(String role) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: _green, size: 64),
          ),
          const SizedBox(height: 24),
          Text(
            'Application Submitted!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Raleway'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your $role application has been received. Our team will review it within 24 hours and contact you via email.',
            style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text('Review within 24 hours', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildHeaderCard(IconData icon, String title, String subtitle) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF185f2d), Color(0xFF2e7d32)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Raleway')),
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85), height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildSectionTitle(String title) {
  return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87));
}

Widget _buildField(TextEditingController ctrl, String label, IconData icon, {
  TextInputType? keyboard, String? Function(String?)? validator, bool readOnly = false, VoidCallback? onTap,
}) {
  return TextFormField(
    controller: ctrl,
    keyboardType: keyboard,
    readOnly: readOnly,
    onTap: onTap,
    style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 15),
    decoration: _inputDecor(label, icon),
    validator: validator,
  );
}

InputDecoration _inputDecor(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
    prefixIcon: Icon(icon, color: _green, size: 20),
    filled: true,
    fillColor: Colors.grey[50],
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
  );
}

Widget _buildToggleRow(String title, String subtitle, IconData icon, Color color, bool value, ValueChanged<bool> onChanged) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: _green),
      ],
    ),
  );
}

class _FAQ {
  final String q, a;
  const _FAQ(this.q, this.a);
}

Widget _buildFAQSection(String title, List<_FAQ> faqs) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle(title),
      const SizedBox(height: 12),
      ...faqs.map((faq) => _FAQTile(faq: faq)),
    ],
  );
}

class _FAQTile extends StatefulWidget {
  final _FAQ faq;
  const _FAQTile({required this.faq});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _open ? _green.withOpacity(0.3) : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.faq.q, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            trailing: Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: _green),
            onTap: () => setState(() => _open = !_open),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(widget.faq.a, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
            ),
        ],
      ),
    );
  }
}

String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null;

String? _emailValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email is required';
  if (!v.contains('@')) return 'Enter a valid email';
  return null;
}
