import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../services/error_handler_service.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import '../../authentication/widgets/mobile_sign_in.dart';
import '../../notifications/providers/notification_provider.dart';

class CashoutPage extends ConsumerStatefulWidget {
  const CashoutPage({super.key});

  @override
  ConsumerState<CashoutPage> createState() => _CashoutPageState();
}

class _CashoutPageState extends ConsumerState<CashoutPage> {
  Map<String, dynamic>? _stats;
  List<dynamic> _payoutMethods = [];
  List<dynamic> _withdrawals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await AuthService.getToken();
      final userData = await AuthService.getUserData();
      final authState = ref.read(authStateProvider);
      final userId = authState.userId ?? userData?['_id']?.toString();
      if (token == null || userId == null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MobileSignInPage()),
          );
        }
        return;
      }
      final statsRes = await ApiService.fetchCashoutStats(token: token);
      final methodsRes = await ApiService.fetchPayoutMethods(token: token);
      final withdrawalsRes = await ApiService.fetchWithdrawals(token: token);
      if (mounted) {
        setState(() {
          _stats = statsRes['data'] as Map<String, dynamic>? ?? statsRes;
          _payoutMethods = (methodsRes['data'] ?? methodsRes['payoutMethods']) is List
              ? (methodsRes['data'] ?? methodsRes['payoutMethods']) as List
              : [];
          _withdrawals = (withdrawalsRes['data'] ?? withdrawalsRes['withdrawals']) is List
              ? (withdrawalsRes['data'] ?? withdrawalsRes['withdrawals']) as List
              : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandlerService.getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(dynamic amount) {
    final n = (amount is num) ? amount.toDouble() : double.tryParse(amount?.toString() ?? '0') ?? 0;
    return 'UGX ${n.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    final notificationCount = ref.watch(notificationCountProvider);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Cashout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0B2416),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0B2416), width: 1.5),
                    ),
                    child: Text(
                      notificationCount > 9 ? '9+' : '$notificationCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBalanceCard(),
                        const SizedBox(height: 24),
                        _buildPayoutMethods(),
                        const SizedBox(height: 24),
                        _buildWithdrawals(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = _stats?['balance'] ?? _stats?['availableBalance'] ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(24, 95, 45, 1),
            Color.fromRGBO(24, 95, 45, 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(24, 95, 45, 1).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(balance),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showWithdrawDialog(),
              icon: const Icon(Icons.account_balance_wallet, color: Color.fromRGBO(24, 95, 45, 1)),
              label: const Text('Withdraw', style: TextStyle(color: Color.fromRGBO(24, 95, 45, 1), fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payout Methods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),
        if (_payoutMethods.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.payment, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('No payout methods added', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text('Add MTN or Airtel mobile money to withdraw', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          )
        else
          ..._payoutMethods.map((m) {
            final method = m is Map ? m : {};
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.phone_android, color: const Color.fromRGBO(24, 95, 45, 1)),
                title: Text(method['type']?.toString() ?? 'Mobile Money'),
                subtitle: Text(method['phoneNumber']?.toString() ?? method['accountNumber']?.toString() ?? ''),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildWithdrawals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Withdrawals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),
        if (_withdrawals.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text('No withdrawals yet', style: TextStyle(color: Colors.grey[600])),
          )
        else
          ..._withdrawals.take(5).map((w) {
            final item = w is Map ? w : {};
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(
                  item['status'] == 'completed' ? Icons.check_circle : Icons.pending,
                  color: item['status'] == 'completed' ? Colors.green : Colors.orange,
                ),
                title: Text(_formatCurrency(item['amount'] ?? 0)),
                subtitle: Text(item['createdAt']?.toString().split('T').first ?? ''),
              ),
            );
          }),
      ],
    );
  }

  void _showWithdrawDialog() {
    final balance = (_stats?['balance'] ?? _stats?['availableBalance']) as num? ?? 0;
    final balanceNum = balance is int ? balance.toDouble() : (balance as double? ?? 0.0);

    final amountCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String network = 'MTN';
    bool withdrawing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Withdraw Funds', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(24, 95, 45, 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Color.fromRGBO(24, 95, 45, 1), size: 20),
                    const SizedBox(width: 8),
                    Text('Available: ${_formatCurrency(balanceNum)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color.fromRGBO(24, 95, 45, 1))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Network selector
              const Text('Network', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final n in ['MTN', 'Airtel'])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: n == 'MTN' ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => setModalState(() => network = n),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: network == n ? const Color.fromRGBO(24, 95, 45, 1) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: network == n ? const Color.fromRGBO(24, 95, 45, 1) : Colors.grey[300]!),
                            ),
                            child: Center(
                              child: Text(n,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: network == n ? Colors.white : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Mobile Money Number',
                  prefixIcon: const Icon(Icons.phone, color: Color.fromRGBO(24, 95, 45, 1), size: 20),
                  hintText: '+256 7XX XXX XXX',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color.fromRGBO(24, 95, 45, 1), width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Amount (UGX)',
                  prefixIcon: const Icon(Icons.attach_money, color: Color.fromRGBO(24, 95, 45, 1), size: 20),
                  hintText: 'Enter amount to withdraw',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color.fromRGBO(24, 95, 45, 1), width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: withdrawing ? null : () async {
                    final phone = phoneCtrl.text.trim();
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (phone.isEmpty || amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
                      );
                      return;
                    }
                    if (amount > balanceNum) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Amount exceeds available balance'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                      );
                      return;
                    }
                    setModalState(() => withdrawing = true);
                    try {
                      final token = await AuthService.getToken();
                      if (token != null) {
                        await ApiService.withdrawFunds(token: token, amount: amount, payoutMethodId: null);
                      }
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Withdrawal request submitted!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                        );
                        _loadData();
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ErrorHandlerService.getErrorMessage(e)), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                        );
                        setModalState(() => withdrawing = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: withdrawing
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirm Withdrawal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
