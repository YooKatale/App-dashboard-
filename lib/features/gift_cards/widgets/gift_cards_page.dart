import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/error_handler_service.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../common/widgets/bottom_navigation_bar.dart';

const _green = Color.fromRGBO(24, 95, 45, 1);

const List<Map<String, dynamic>> _occasions = [
  {'name': 'General Gift', 'emoji': '🎁'},
  {'name': 'Birthday', 'emoji': '🎂'},
  {'name': "Mother's Day", 'emoji': '💐'},
  {'name': "Father's Day", 'emoji': '👔'},
  {'name': 'Valentine\'s Day', 'emoji': '❤️'},
  {'name': 'Christmas', 'emoji': '🎄'},
  {'name': 'Wedding', 'emoji': '💍'},
  {'name': 'Graduation', 'emoji': '🎓'},
  {'name': 'Easter', 'emoji': '🐣'},
  {'name': 'New Year', 'emoji': '🎆'},
  {'name': 'Anniversary', 'emoji': '🌹'},
  {'name': 'Baby Shower', 'emoji': '👶'},
  {'name': 'Thank You', 'emoji': '🙏'},
  {'name': 'Congratulations', 'emoji': '🏆'},
  {'name': 'Get Well Soon', 'emoji': '💊'},
  {'name': 'Just Because', 'emoji': '✨'},
  {'name': 'Housewarming', 'emoji': '🏠'},
  {'name': "Women's Day", 'emoji': '👩'},
  {'name': 'Independence Day', 'emoji': '🇺🇬'},
  {'name': 'Eid', 'emoji': '🌙'},
  {'name': "Teachers' Day", 'emoji': '📚'},
  {'name': 'Friendship Day', 'emoji': '🤝'},
];

const List<int> _presetAmounts = [10000, 20000, 50000, 100000, 200000, 500000];

class GiftCardsPage extends ConsumerStatefulWidget {
  const GiftCardsPage({super.key});

  @override
  ConsumerState<GiftCardsPage> createState() => _GiftCardsPageState();
}

class _GiftCardsPageState extends ConsumerState<GiftCardsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _myVouchers = [];
  List<dynamic> _sentVouchers = [];
  bool _loadingVouchers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVouchers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers() async {
    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) setState(() => _loadingVouchers = false);
      return;
    }
    try {
      final res = await ApiService.fetchMyGiftCards(token: token);
      if (mounted) {
        final data = res['data'] ?? res;
        setState(() {
          _myVouchers = (data['received'] ?? data['vouchers'] ?? data) is List
              ? (data['received'] ?? data['vouchers'] ?? data) as List
              : [];
          _sentVouchers = (data['sent']) is List ? data['sent'] as List : [];
          _loadingVouchers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingVouchers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Gift Cards', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Raleway')),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF185f2d), Color(0xFF2e7d32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 36)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Gift Cards & Vouchers',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Raleway')),
                            const SizedBox(height: 4),
                            Text('Give the gift of fresh food to anyone you love',
                                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Buy a gift card section
            const _BuyGiftCard(),

            // Redeem section
            const _RedeemSection(),

            // My vouchers
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: const Text('My Vouchers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: _green,
                unselectedLabelColor: Colors.grey,
                indicatorColor: _green,
                tabs: const [
                  Tab(text: 'Received'),
                  Tab(text: 'Sent'),
                ],
              ),
            ),
            SizedBox(
              height: 300,
              child: _loadingVouchers
                  ? const Center(child: CircularProgressIndicator(color: _green))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildVoucherList(_myVouchers),
                        _buildVoucherList(_sentVouchers),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherList(List vouchers) {
    if (vouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text('No vouchers yet', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vouchers.length,
      itemBuilder: (_, i) => _VoucherCard(voucher: vouchers[i]),
    );
  }
}

// ─── Buy Gift Card ────────────────────────────────────────────────────────
class _BuyGiftCard extends ConsumerStatefulWidget {
  const _BuyGiftCard();

  @override
  ConsumerState<_BuyGiftCard> createState() => _BuyGiftCardState();
}

class _BuyGiftCardState extends ConsumerState<_BuyGiftCard> {
  final _formKey = GlobalKey<FormState>();
  final _customAmountCtrl = TextEditingController();
  final _recipientNameCtrl = TextEditingController();
  final _recipientEmailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  int? _selectedAmount;
  Map<String, dynamic>? _selectedOccasion;
  bool _sendToSomeone = false;
  bool _isLoading = false;
  String _paymentMethod = 'mobile_money';

  @override
  void dispose() {
    _customAmountCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientEmailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  int get _amount {
    if (_selectedAmount != null) return _selectedAmount!;
    return int.tryParse(_customAmountCtrl.text.replaceAll(',', '')) ?? 0;
  }

  Future<void> _purchase() async {
    if (_selectedOccasion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an occasion'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_amount < 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum amount is UGX 5,000'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_sendToSomeone) {
      if (!_formKey.currentState!.validate()) return;
    }

    final authState = ref.read(authStateProvider);
    if (!authState.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to purchase a gift card'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      final userData = await AuthService.getUserData();
      final res = await ApiService.purchaseGiftCard(
        token: token,
        amount: _amount,
        occasion: _selectedOccasion!['name'] as String,
        sendToSomeone: _sendToSomeone,
        recipientName: _sendToSomeone ? _recipientNameCtrl.text.trim() : null,
        recipientEmail: _sendToSomeone ? _recipientEmailCtrl.text.trim() : null,
        message: _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
        paymentMethod: _paymentMethod,
        userId: userData?['_id']?.toString() ?? authState.userId ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gift card purchase initiated! Check your vouchers.'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(context, message: ErrorHandlerService.getErrorMessage(e));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Buy a Gift Card', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Occasion selector
            const Text('Select Occasion', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _occasions.length,
                itemBuilder: (_, i) {
                  final o = _occasions[i];
                  final selected = _selectedOccasion == o;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedOccasion = o),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? _green : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? _green : Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(o['emoji'] as String, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(o['name'] as String,
                              style: TextStyle(fontSize: 10, color: selected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w500),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Amount
            const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetAmounts.map((a) {
                final selected = _selectedAmount == a;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedAmount = a;
                    _customAmountCtrl.clear();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? _green : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? _green : Colors.grey[300]!),
                    ),
                    child: Text(
                      'UGX ${(a / 1000).toStringAsFixed(0)}K',
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.grey[800],
                        fontWeight: FontWeight.w600, fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customAmountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14),
              onChanged: (_) => setState(() => _selectedAmount = null),
              decoration: InputDecoration(
                labelText: 'Custom Amount (UGX)',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon: const Icon(Icons.attach_money, color: _green, size: 20),
                hintText: 'Min. UGX 5,000',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 1.5)),
              ),
            ),
            const SizedBox(height: 20),

            // Send to someone toggle
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.send, color: _green, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Send to someone else', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('Send as a gift to a friend or family member', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _sendToSomeone,
                    onChanged: (v) => setState(() => _sendToSomeone = v),
                    activeColor: _green,
                  ),
                ],
              ),
            ),

            if (_sendToSomeone) ...[
              const SizedBox(height: 14),
              _tf(_recipientNameCtrl, 'Recipient Name *', Icons.person, required: true),
              const SizedBox(height: 10),
              _tf(_recipientEmailCtrl, 'Recipient Email *', Icons.email, keyboard: TextInputType.emailAddress, required: true),
            ],

            const SizedBox(height: 14),
            TextFormField(
              controller: _messageCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Personal Message (Optional)',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon: const Icon(Icons.message_outlined, color: _green, size: 20),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),

            // Payment method
            const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _paymentMethodTile('mobile_money', Icons.phone_android, 'Mobile Money')),
                const SizedBox(width: 10),
                Expanded(child: _paymentMethodTile('card', Icons.credit_card, 'Card')),
              ],
            ),
            const SizedBox(height: 20),

            // Amount summary
            if (_amount > 0)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _green.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('UGX ${_amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: _green, fontSize: 16)),
                  ],
                ),
              ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _purchase,
                icon: const Icon(Icons.card_giftcard),
                label: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Purchase Gift Card', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tf(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboard, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(icon, color: _green, size: 18),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
    );
  }

  Widget _paymentMethodTile(String value, IconData icon, String label) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _green.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _green : Colors.grey[300]!, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? _green : Colors.grey[700]),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? _green : Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}

// ─── Redeem section ────────────────────────────────────────────────────────
class _RedeemSection extends ConsumerStatefulWidget {
  const _RedeemSection();

  @override
  ConsumerState<_RedeemSection> createState() => _RedeemSectionState();
}

class _RedeemSectionState extends ConsumerState<_RedeemSection> {
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a voucher code'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      await ApiService.redeemGiftCard(token: token, code: code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gift card redeemed!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
        _codeCtrl.clear();
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(context, message: ErrorHandlerService.getErrorMessage(e));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _codeCtrl,
              style: const TextStyle(fontSize: 14, letterSpacing: 1),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Redeem a Gift Card Code',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                prefixIcon: const Icon(Icons.qr_code, color: _green, size: 20),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _green, width: 1.5), borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _isLoading ? null : _redeem,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Redeem'),
          ),
        ],
      ),
    );
  }
}

// ─── Voucher Card ──────────────────────────────────────────────────────────
class _VoucherCard extends StatelessWidget {
  final dynamic voucher;
  const _VoucherCard({required this.voucher});

  @override
  Widget build(BuildContext context) {
    final v = voucher is Map ? voucher as Map<String, dynamic> : <String, dynamic>{};
    final occasion = v['occasion']?.toString() ?? 'Gift';
    final code = v['code']?.toString() ?? '';
    final amount = v['amount'] ?? 0;
    final balance = v['remainingBalance'] ?? v['balance'] ?? amount;
    final status = v['status']?.toString() ?? 'active';
    final message = v['message']?.toString() ?? '';
    final expiry = v['expiresAt']?.toString().split('T').first ?? '';

    final emoji = _occasions.firstWhere(
      (o) => (o['name'] as String).toLowerCase() == occasion.toLowerCase(),
      orElse: () => {'emoji': '🎁'},
    )['emoji'] as String;

    Color statusColor;
    switch (status) {
      case 'used': statusColor = Colors.grey; break;
      case 'expired': statusColor = Colors.red; break;
      case 'partially_used': statusColor = Colors.orange; break;
      default: statusColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(occasion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('UGX ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                        style: const TextStyle(color: _green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status == 'partially_used' ? 'Partial' : status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (code.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied!'), behavior: SnackBarBehavior.floating),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(code, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14)),
                    const Spacer(),
                    const Icon(Icons.copy, size: 16, color: _green),
                    const SizedBox(width: 4),
                    const Text('Copy', style: TextStyle(color: _green, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"$message"', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600], fontSize: 13)),
          ],
          if (expiry.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('Expires: $expiry', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
