import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../services/error_handler_service.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import '../../authentication/widgets/mobile_sign_in.dart';
import '../../notifications/providers/notification_provider.dart';

// ── Webapp colors ───────────────────────────────────────────────────────────
const _kGreenDark  = Color(0xFF0A1F0A);
const _kGreen1     = Color(0xFF1A5C1A);
const _kGreen2     = Color(0xFF2D8C2D);
const _kBlue1      = Color(0xFF075985);
const _kBlue2      = Color(0xFF0284C7);
const _kOrange1    = Color(0xFF9A3412);
const _kOrange2    = Color(0xFFEA580C);
const _kPurple1    = Color(0xFF6D28D9);
const _kPurple2    = Color(0xFF7C3AED);
const _kBg         = Color(0xFFF2F6F2);
const _kPrimary    = Color(0xFF185F2D);

String _fmt(dynamic n) {
  final v = n is num ? n.toDouble() : double.tryParse(n?.toString() ?? '0') ?? 0;
  return 'UGX ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

class CashoutPage extends ConsumerStatefulWidget {
  const CashoutPage({super.key});

  @override
  ConsumerState<CashoutPage> createState() => _CashoutPageState();
}

class _CashoutPageState extends ConsumerState<CashoutPage> {
  Map<String, dynamic>? _stats;
  List<dynamic> _payoutMethods = [];
  List<dynamic> _withdrawals   = [];
  Map<String, dynamic>? _referralData;
  List<dynamic> _referralRewards = [];
  bool _isLoading = true;
  String? _error;
  bool _balVisible = true;
  bool _copied     = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final token    = await AuthService.getToken();
      final authState = ref.read(authStateProvider);
      final userId   = authState.userId;
      if (token == null || userId == null) {
        if (mounted) Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MobileSignInPage()),
        );
        return;
      }

      // Load all in parallel
      final results = await Future.wait([
        ApiService.fetchCashoutStats(token: token).catchError((_) => <String, dynamic>{}),
        ApiService.fetchPayoutMethods(token: token).catchError((_) => <String, dynamic>{}),
        ApiService.fetchWithdrawals(token: token).catchError((_) => <String, dynamic>{}),
        ApiService.fetchReferralData(token: token).catchError((_) => <String, dynamic>{}),
        ApiService.fetchReferralRewards(token: token).catchError((_) => <String, dynamic>{}),
      ]);

      if (mounted) {
        final statsRaw    = results[0] as Map<String, dynamic>;
        final methodsRaw  = results[1] as Map<String, dynamic>;
        final withdrawRaw = results[2] as Map<String, dynamic>;
        final refRaw      = results[3] as Map<String, dynamic>;
        final refRewards  = results[4] as Map<String, dynamic>;

        setState(() {
          _stats          = (statsRaw['data'] ?? statsRaw) as Map<String, dynamic>?;
          _payoutMethods  = _asList(methodsRaw['data'] ?? methodsRaw['payoutMethods']);
          _withdrawals    = _asList(withdrawRaw['data'] ?? withdrawRaw['withdrawals']);
          _referralData   = (refRaw['data'] ?? refRaw) as Map<String, dynamic>?;
          _referralRewards = _asList((refRewards['data'] ?? refRewards)['rewards'] ?? refRewards['data']);
          _isLoading      = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = ErrorHandlerService.getErrorMessage(e); _isLoading = false; });
    }
  }

  List<dynamic> _asList(dynamic v) => v is List ? v : [];

  String get _referralLink {
    final link = _referralData?['referralLink']?.toString();
    if (link != null && link.isNotEmpty) return link;
    final userId = ref.read(authStateProvider).userId ?? '';
    return 'https://yookatale.app/signup?ref=${userId.substring(0, userId.length > 8 ? 8 : userId.length)}';
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _referralLink));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral link copied!'), backgroundColor: _kGreen2, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifCount = ref.watch(notificationCountProvider);
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kGreenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Cashout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          Stack(clipBehavior: Clip.none, children: [
            IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => Navigator.pushNamed(context, '/notifications')),
            if (notifCount > 0)
              Positioned(right: 8, top: 8, child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: _kGreenDark, width: 1.5)),
                child: Text(notifCount > 9 ? '9+' : '$notifCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
              )),
          ]),
        ],
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: _kPrimary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(children: [
                      _buildStatsGrid(),
                      _buildQuickLinks(),
                      _buildReferralSection(),
                      _buildGamesBanner(),
                      _buildPeopleReferred(),
                      _buildReferralRewards(),
                      _buildPayoutMethods(),
                      _buildWithdrawalHistory(),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
    );
  }

  // ── Stats grid ─────────────────────────────────────────────────────────────
  Widget _buildStatsGrid() {
    final cash    = _stats?['cash'] ?? _stats?['balance'] ?? _stats?['availableBalance'] ?? 0;
    final invites = _stats?['invites'] ?? _stats?['totalReferrals'] ?? 0;
    final points  = _stats?['loyalty'] ?? _stats?['points'] ?? _stats?['loyaltyPoints'] ?? 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kGreenDark, _kGreen1, _kGreen2],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(children: [
        // Cash earned card (full width)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kGreen1, _kGreen2], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                const Text('Cash Earned', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
              const SizedBox(height: 6),
              Text(_balVisible ? _fmt(cash) : '••••••',
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
            ])),
            GestureDetector(
              onTap: () => setState(() => _balVisible = !_balVisible),
              child: Icon(_balVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white60, size: 20),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _showWithdrawSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: const Text('Withdraw', style: TextStyle(color: _kGreen1, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          // Invites card
          Expanded(child: _MiniStatCard(
            gradient: const LinearGradient(colors: [_kBlue1, _kBlue2]),
            icon: Icons.people_outline_rounded,
            label: 'Total Invites',
            value: invites.toString(),
          )),
          const SizedBox(width: 10),
          // Points card
          Expanded(child: _MiniStatCard(
            gradient: const LinearGradient(colors: [_kOrange1, _kOrange2]),
            icon: Icons.stars_rounded,
            label: 'Referral Points',
            value: points.toString(),
          )),
        ]),
      ]),
    );
  }

  // ── Quick links ────────────────────────────────────────────────────────────
  Widget _buildQuickLinks() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        Expanded(child: _QuickCard(
          icon: Icons.star_rounded,
          color: _kGreen2,
          label: 'Rewards',
          sub: 'Redeem your points',
          onTap: () => Navigator.pushNamed(context, '/rewards'),
        )),
        const SizedBox(width: 12),
        Expanded(child: _QuickCard(
          icon: Icons.card_giftcard_rounded,
          color: _kOrange2,
          label: 'Gift Cards',
          sub: 'Send & receive vouchers',
          onTap: () => Navigator.pushNamed(context, '/gift-cards'),
        )),
      ]),
    );
  }

  // ── Referral invite section ────────────────────────────────────────────────
  Widget _buildReferralSection() {
    final totalReferred = _referralData?['totalReferred'] ?? _referralData?['totalReferrals'] ?? 0;
    final rewardPerRef  = _referralData?['rewardPerReferralCashEquivalent'] ?? 2000;
    final minSignups    = _stats?['minSignupsForCashout'] ?? 25;
    final cashEarned    = _referralData?['totalEarnings'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: _kGreen2.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.share_rounded, color: _kGreen2, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Invite a Friend', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
              Text('Earn UGX 2,000 per verified signup', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ]),
        ),
        // Stats row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _RefStat(label: 'Referred', value: totalReferred.toString()),
            _RefStat(label: 'Per Signup', value: _fmt(rewardPerRef)),
            _RefStat(label: 'Min. for cash', value: '$minSignups signups'),
            _RefStat(label: 'Cash Earned', value: _fmt(cashEarned)),
          ]),
        ),
        const SizedBox(height: 12),
        // Link
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(children: [
              Expanded(
                child: Text(_referralLink, style: const TextStyle(fontSize: 12, color: Colors.black54), overflow: TextOverflow.ellipsis),
              ),
              GestureDetector(
                onTap: _copyLink,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _copied ? _kGreen2 : _kGreen1, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(_copied ? 'Copied!' : 'Copy', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Games coming soon ─────────────────────────────────────────────────────
  Widget _buildGamesBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_kPurple1, _kPurple2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Games & Challenges', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          SizedBox(height: 2),
          Text('Earn bonus points playing mini-games — Coming soon!', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
          child: const Text('Soon', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  // ── People you referred ────────────────────────────────────────────────────
  Widget _buildPeopleReferred() {
    final referred = _asList(_referralData?['referrals'] ?? _referralData?['referred']);
    if (referred.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            const Icon(Icons.people_rounded, color: _kGreen2, size: 18),
            const SizedBox(width: 8),
            Text('People You Referred (${referred.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
          ]),
        ),
        const Divider(height: 1),
        ...referred.take(5).map((r) {
          final p = r is Map ? r as Map<String, dynamic> : <String, dynamic>{};
          final name  = p['name']?.toString() ?? p['fullname']?.toString() ?? 'User';
          final email = p['email']?.toString() ?? '';
          final date  = p['createdAt']?.toString().split('T').first ?? '';
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: _kGreen2.withOpacity(0.12),
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: _kGreen2, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(email, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            trailing: date.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _kGreen2.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(date, style: const TextStyle(fontSize: 10, color: _kGreen2, fontWeight: FontWeight.w600)),
                  )
                : null,
          );
        }),
      ]),
    );
  }

  // ── Referral rewards ───────────────────────────────────────────────────────
  Widget _buildReferralRewards() {
    if (_referralRewards.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            const Icon(Icons.card_giftcard_rounded, color: _kOrange2, size: 18),
            const SizedBox(width: 8),
            const Text('First-Purchase Referral Rewards', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
          ]),
        ),
        const Divider(height: 1),
        ..._referralRewards.take(5).map((r) {
          final reward = r is Map ? r as Map<String, dynamic> : <String, dynamic>{};
          final name   = reward['name']?.toString() ?? 'User';
          final amount = reward['cashBonus'] ?? reward['amount'] ?? 0;
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: _kOrange2.withOpacity(0.1),
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: _kOrange2, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _kOrange2.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(_fmt(amount), style: const TextStyle(fontSize: 11, color: _kOrange2, fontWeight: FontWeight.w700)),
            ),
          );
        }),
      ]),
    );
  }

  // ── Payout methods ─────────────────────────────────────────────────────────
  Widget _buildPayoutMethods() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            const Expanded(child: Text('Payout Methods', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87))),
            GestureDetector(
              onTap: _showAddMethodSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded, color: _kPrimary, size: 14),
                  SizedBox(width: 4),
                  Text('Add', style: TextStyle(color: _kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
        ),
        const Divider(height: 1),
        if (_payoutMethods.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Icon(Icons.smartphone_rounded, size: 36, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text('No payout methods added', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              const SizedBox(height: 4),
              Text('Add MTN or Airtel Mobile Money to withdraw', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ]),
          )
        else
          ..._payoutMethods.map((m) {
            final method = m is Map ? m as Map<String, dynamic> : <String, dynamic>{};
            final type   = method['type']?.toString() ?? 'mobile_money';
            final prov   = method['provider']?.toString() ?? method['network']?.toString() ?? '';
            final phone  = method['phone']?.toString() ?? method['phoneNumber']?.toString() ?? '';
            final isDef  = method['isDefault'] == true;
            return ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: prov.toLowerCase().contains('mtn') ? const Color(0xFFFFF3E0) : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.phone_android_rounded,
                    color: prov.toLowerCase().contains('mtn') ? const Color(0xFFFFA000) : _kBlue2, size: 20),
              ),
              title: Text('$prov${type == 'card' ? ' Card' : ' Mobile Money'}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text(phone, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              trailing: isDef
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _kGreen2.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: const Text('Default', style: TextStyle(color: _kGreen2, fontSize: 10, fontWeight: FontWeight.w700)),
                    )
                  : null,
            );
          }),
      ]),
    );
  }

  // ── Withdrawal history ────────────────────────────────────────────────────
  Widget _buildWithdrawalHistory() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text('Withdrawal History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
        ),
        const Divider(height: 1),
        if (_withdrawals.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Icon(Icons.receipt_long_outlined, color: Colors.grey[300], size: 28),
              const SizedBox(width: 12),
              Text('No withdrawals yet', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ]),
          )
        else
          ..._withdrawals.take(10).map((w) {
            final item   = w is Map ? w as Map<String, dynamic> : <String, dynamic>{};
            final status = item['status']?.toString() ?? 'pending';
            final date   = item['createdAt']?.toString().split('T').first ?? '';
            final isOk   = status == 'completed' || status == 'approved';
            return ListTile(
              dense: true,
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isOk ? _kGreen2.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(isOk ? Icons.check_circle_outline_rounded : Icons.pending_outlined,
                    color: isOk ? _kGreen2 : Colors.orange, size: 18),
              ),
              title: Text(_fmt(item['amount'] ?? 0), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text('$status · $date', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            );
          }),
      ]),
    );
  }

  Widget _buildError() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white), child: const Text('Retry')),
      ]),
    ));
  }

  // ── Withdraw bottom sheet ─────────────────────────────────────────────────
  void _showWithdrawSheet() {
    final cash      = _stats?['cash'] ?? _stats?['balance'] ?? _stats?['availableBalance'] ?? 0;
    final amountCtrl = TextEditingController();
    final phoneCtrl  = TextEditingController();
    String network   = 'MTN';
    bool busy        = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Withdraw Funds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ]),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _kGreen1.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.account_balance_wallet_outlined, color: _kGreen1, size: 18),
                const SizedBox(width: 8),
                Text('Available: ${_fmt(cash)}', style: const TextStyle(color: _kGreen1, fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 14),
            const Text('Network', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            Row(children: ['MTN', 'Airtel'].map((n) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: n == 'MTN' ? 8 : 0),
                child: GestureDetector(
                  onTap: () => set(() => network = n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: network == n ? _kPrimary : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: network == n ? _kPrimary : Colors.grey.shade300),
                    ),
                    child: Center(child: Text(n, style: TextStyle(fontWeight: FontWeight.w600, color: network == n ? Colors.white : Colors.grey[700]))),
                  ),
                ),
              ),
            )).toList()),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile Money Number', hintText: '+256 7XX XXX XXX',
                prefixIcon: const Icon(Icons.phone_outlined, color: _kPrimary, size: 20),
                filled: true, fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: _kPrimary, width: 1.5)),
              )),
            const SizedBox(height: 10),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (UGX)', hintText: 'Minimum UGX 5,000',
                prefixIcon: const Icon(Icons.payments_outlined, color: _kPrimary, size: 20),
                filled: true, fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: _kPrimary, width: 1.5)),
              )),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: busy ? null : () async {
                  final phone = phoneCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                  if (phone.isEmpty || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.orange));
                    return;
                  }
                  if (amount < 5000) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum withdrawal is UGX 5,000'), backgroundColor: Colors.orange));
                    return;
                  }
                  set(() => busy = true);
                  try {
                    final token = await AuthService.getToken();
                    if (token != null) await ApiService.withdrawFunds(token: token, amount: amount, payoutMethodId: null);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted!'), backgroundColor: _kGreen2));
                      _loadData();
                    }
                  } catch (e) {
                    set(() => busy = false);
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandlerService.getErrorMessage(e)), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Withdraw Funds', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  // ── Add payout method sheet ───────────────────────────────────────────────
  void _showAddMethodSheet() {
    String type    = 'mobile_money';
    String network = 'MTN';
    final phoneCtrl = TextEditingController();
    bool busy = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Add Payout Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 8),
            Row(children: ['MTN', 'Airtel'].map((n) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: n == 'MTN' ? 8 : 0),
                child: GestureDetector(
                  onTap: () => set(() => network = n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: network == n ? _kPrimary : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: network == n ? _kPrimary : Colors.grey.shade300),
                    ),
                    child: Center(child: Text(n, style: TextStyle(fontWeight: FontWeight.w600, color: network == n ? Colors.white : Colors.grey[700]))),
                  ),
                ),
              ),
            )).toList()),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile Money Number', hintText: '+256 7XX XXX XXX',
                prefixIcon: const Icon(Icons.phone_outlined, color: _kPrimary),
                filled: true, fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: _kPrimary, width: 1.5)),
              )),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: busy ? null : () async {
                  final phone = phoneCtrl.text.trim();
                  if (phone.isEmpty) return;
                  set(() => busy = true);
                  try {
                    final token = await AuthService.getToken();
                    if (token != null) {
                      await ApiService.addPayoutMethod(token: token, type: type, provider: network, phone: phone);
                    }
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout method added!'), backgroundColor: _kGreen2));
                      _loadData();
                    }
                  } catch (e) {
                    set(() => busy = false);
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandlerService.getErrorMessage(e)), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add Method', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────
class _MiniStatCard extends StatelessWidget {
  final LinearGradient gradient;
  final IconData icon;
  final String label;
  final String value;
  const _MiniStatCard({required this.gradient, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String sub;
  final VoidCallback onTap;
  const _QuickCard({required this.icon, required this.color, required this.label, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
            Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 18),
        ]),
      ),
    );
  }
}

class _RefStat extends StatelessWidget {
  final String label;
  final String value;
  const _RefStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black87)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ]),
    ));
  }
}
