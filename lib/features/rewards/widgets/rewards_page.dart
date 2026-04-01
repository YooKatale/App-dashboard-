import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../services/error_handler_service.dart';
import '../../common/widgets/bottom_navigation_bar.dart';

const _kGreen   = Color(0xFF185F2D);
const _kGreen2  = Color(0xFF2E7D32);
const _kBg      = Color(0xFFF5F9F6);

class RewardsPage extends ConsumerStatefulWidget {
  const RewardsPage({super.key});

  @override
  ConsumerState<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends ConsumerState<RewardsPage> {
  List<dynamic> _rewards    = [];
  List<dynamic> _myRewards  = [];
  Map<String, dynamic>? _referralData;
  Map<String, dynamic>? _referralRewards;
  int  _myPoints  = 0;
  bool _isLoading = true;
  String? _error;

  // Redeem modal state
  Map<String, dynamic>? _selectedReward;
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = await AuthService.getToken();
      final rewardsRes = await ApiService.fetchRewards(token: token);
      if (token != null) {
        try {
          final myRes = await ApiService.fetchMyRewards(token: token);
          _myRewards = (myRes['data'] ?? myRes['rewards']) is List
              ? (myRes['data'] ?? myRes['rewards']) as List : [];
          final statsRes = await ApiService.fetchCashoutStats(token: token);
          final stats = statsRes['data'] ?? statsRes;
          _myPoints = ((stats['loyaltyPoints'] ?? stats['loyalty'] ?? stats['points'] ?? 0) as num).toInt();
        } catch (_) { _myRewards = []; }
        try {
          final refRes = await ApiService.fetchReferralData(token: token);
          _referralData = (refRes['data'] ?? refRes) is Map
              ? Map<String, dynamic>.from((refRes['data'] ?? refRes) as Map) : null;
        } catch (_) {}
        try {
          final rrRes = await ApiService.fetchReferralRewards(token: token);
          _referralRewards = (rrRes['data'] ?? rrRes) is Map
              ? Map<String, dynamic>.from((rrRes['data'] ?? rrRes) as Map) : null;
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _rewards = (rewardsRes['data'] ?? rewardsRes['rewards']) is List
              ? (rewardsRes['data'] ?? rewardsRes['rewards']) as List : [];
          _isLoading = false;
        });
      }
    } catch (_) {
      // Show empty state rather than error screen
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _openRedeemModal(Map<String, dynamic> reward) {
    setState(() => _selectedReward = reward);
    showDialog(context: context, builder: (_) => _buildRedeemDialog());
  }

  Widget _buildRedeemDialog() {
    final r = _selectedReward!;
    final points = ((r['pointsRequired'] ?? r['points'] ?? 0) as num).toInt();
    final canAfford = _myPoints >= points;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Confirm Redemption', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r['title']?.toString() ?? 'Reward', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if ((r['description']?.toString() ?? '').isNotEmpty)
            Text(r['description'].toString(), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text('Cost: $points points', style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          Text('Your balance: $_myPoints points', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          if (!canAfford) ...[
            const SizedBox(height: 8),
            const Text('Insufficient points!', style: TextStyle(color: Colors.red, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () { Navigator.pop(context); setState(() => _selectedReward = null); },
          child: const Text('Cancel'),
        ),
        StatefulBuilder(builder: (_, setSt) => ElevatedButton(
          onPressed: (!canAfford || _redeeming) ? null : () async {
            setSt(() => _redeeming = true);
            final token = await AuthService.getToken();
            if (token == null) { setSt(() => _redeeming = false); return; }
            try {
              await ApiService.redeemReward(token: token, rewardId: r['_id']?.toString() ?? '');
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Reward redeemed!'), backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ));
                _loadData();
              }
            } catch (e) {
              if (mounted) ErrorHandlerService.showErrorSnackBar(context, message: ErrorHandlerService.getErrorMessage(e));
            } finally {
              if (mounted) setSt(() => _redeeming = false);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: _redeeming
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Redeem'),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Rewards & Loyalty',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Raleway')),
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : _error != null ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _kGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    if (_referralData != null) ...[
                      _sectionTitle('Referral Earnings'),
                      _buildReferralStats(),
                      _buildProgressCard(),
                      if (_referralPeopleList.isNotEmpty) _buildPeopleReferred(),
                    ],
                    if (_referralRewards != null && (_referralRewards!['rewards'] is List) && (_referralRewards!['rewards'] as List).isNotEmpty) ...[
                      _sectionTitle('First-Purchase Bonuses'),
                      _buildFirstPurchaseBonuses(),
                    ],
                    if (_myRewards.isNotEmpty) ...[
                      _sectionTitle('My Redeemed Rewards'),
                      _buildMyRewards(),
                    ],
                    _sectionTitle('Available Rewards'),
                    _buildAvailableRewards(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  List<dynamic> get _referralPeopleList {
    final rd = _referralData!;
    return (rd['referredUsers'] ?? rd['referrals'] ?? rd['referred'] ?? []) is List
        ? (rd['referredUsers'] ?? rd['referrals'] ?? rd['referred']) as List
        : [];
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
    child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
  );

  Widget _buildError() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.card_giftcard, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white)),
      ]),
    ));
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kGreen, _kGreen2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            const Text('Rewards', style: TextStyle(color: Colors.white, fontSize: 26,
                fontWeight: FontWeight.w800, fontFamily: 'Raleway')),
          ]),
          const SizedBox(height: 10),
          const Text('Redeem your loyalty points for exclusive rewards and discounts.',
              style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 6),
              Text('${_myPoints.toString()} Points Available',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),
        ],
      ),
    );
  }

  // 3-card referral stats grid
  Widget _buildReferralStats() {
    final rd = _referralData!;
    final totalEarnings = ((rd['totalEarnings'] ?? rd['earnings'] ?? 0) as num).toInt();
    final totalReferred = ((rd['totalReferred'] ?? rd['totalReferrals'] ?? rd['referrals'] ?? 0) as num).toInt();
    final rewardPerReferral = ((rd['rewardPerReferral'] ?? 1) as num).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(child: _statCard(
          icon: Icons.attach_money_rounded,
          iconColor: Colors.green[600]!,
          iconBg: const Color(0xFFE8F5E9),
          label: 'Total Earned',
          value: 'UGX ${_fmt(totalEarnings)}',
          borderColor: const Color(0xFFA5D6A7),
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          icon: Icons.people_rounded,
          iconColor: Colors.blue[600]!,
          iconBg: const Color(0xFFE3F2FD),
          label: 'People Referred',
          value: '$totalReferred',
          borderColor: const Color(0xFF90CAF9),
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          icon: Icons.star_rounded,
          iconColor: Colors.purple[600]!,
          iconBg: const Color(0xFFF3E5F5),
          label: 'Per Referral',
          value: '$rewardPerReferral pt',
          borderColor: const Color(0xFFCE93D8),
        )),
      ]),
    );
  }

  Widget _statCard({required IconData icon, required Color iconColor, required Color iconBg,
    required String label, required String value, required Color borderColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 18),
          alignment: Alignment.center,
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: iconColor),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // Target progress card
  Widget _buildProgressCard() {
    final rd = _referralData!;
    const referralTargetCash = 50000;
    final cashEquiv = ((rd['rewardPerReferralCashEquivalent'] ?? rd['cashEquivalent'] ?? 2000) as num).toDouble();
    final totalReferred = ((rd['totalReferred'] ?? rd['totalReferrals'] ?? 0) as num).toInt();
    final referralsNeeded = cashEquiv > 0 ? (referralTargetCash / cashEquiv).ceil() : 25;
    final progress = (totalReferred / referralsNeeded).clamp(0.0, 1.0);
    final progressCount = totalReferred.clamp(0, referralsNeeded);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF80CBC4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Target Progress', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(20)),
              child: Text('$progressCount/$referralsNeeded referrals',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF00695C), fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            'Invite $referralsNeeded+ people to reach UGX ${_fmt(referralTargetCash)} at UGX ${_fmt(cashEquiv.toInt())} per point (cashout unlock at 25 signups).',
            style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress, minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(Color(0xFF009688)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildPeopleReferred() {
    final people = _referralPeopleList;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('People you referred', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          ...people.take(10).map((person) {
            final p = person is Map ? person as Map<String, dynamic> : <String, dynamic>{};
            final first = p['firstname']?.toString() ?? '';
            final last = p['lastname']?.toString() ?? '';
            final name = [first, last].where((s) => s.isNotEmpty).join(' ').trim();
            final displayName = name.isEmpty ? 'YooKatale User' : name;
            final email = p['email']?.toString() ?? '';
            final joinDate = p['joinedAt']?.toString() ?? p['createdAt']?.toString() ?? '';
            final initials = '${first.isNotEmpty ? first[0].toUpperCase() : 'Y'}${last.isNotEmpty ? last[0].toUpperCase() : 'U'}';
            String dateLabel = '';
            if (joinDate.isNotEmpty) {
              try {
                final dt = DateTime.parse(joinDate);
                final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                dateLabel = '${months[dt.month-1]} ${dt.day}, ${dt.year}';
              } catch (_) {}
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  if (email.isNotEmpty) Text(email, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Joined', style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                  ),
                  if (dateLabel.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 2),
                      child: Text(dateLabel, style: TextStyle(fontSize: 10, color: Colors.grey[400]))),
                ]),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  Widget _buildFirstPurchaseBonuses() {
    final rr = _referralRewards!;
    final rewards = (rr['rewards']) as List? ?? [];
    final totalCash = ((rr['totalCash'] ?? 0) as num).toInt();
    final totalGiftCards = ((rr['totalGiftCards'] ?? 0) as num).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 2-card summary
        Row(children: [
          Expanded(child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA5D6A7)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: const Icon(Icons.attach_money_rounded, color: Color(0xFF388E3C), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Cash Bonuses', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                Text('UGX ${_fmt(totalCash)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF388E3C))),
              ])),
            ]),
          )),
          const SizedBox(width: 10),
          Expanded(child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFF176)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: const Color(0xFFFFFDE7), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFF9A825), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Gift Cards', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                Text('UGX ${_fmt(totalGiftCards)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFF9A825))),
              ])),
            ]),
          )),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Rewards from friends' first purchases",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 12),
            ...rewards.take(10).map((reward) {
              final rw = reward is Map ? reward as Map<String, dynamic> : <String, dynamic>{};
              final person = rw['referredUser'] is Map
                  ? rw['referredUser'] as Map<String, dynamic> : <String, dynamic>{};
              final first = person['firstname']?.toString() ?? '';
              final last = person['lastname']?.toString() ?? '';
              final name = [first, last].where((s) => s.isNotEmpty).join(' ').trim();
              final displayName = name.isEmpty ? 'YooKatale User' : name;
              final initials = '${first.isNotEmpty ? first[0].toUpperCase() : 'Y'}${last.isNotEmpty ? last[0].toUpperCase() : 'U'}';
              final dateStr = rw['createdAt']?.toString() ?? '';
              String dateLabel = '';
              if (dateStr.isNotEmpty) {
                try {
                  final dt = DateTime.parse(dateStr);
                  final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                  dateLabel = '${months[dt.month-1]} ${dt.day}, ${dt.year}';
                } catch (_) {}
              }
              final cashAmount = ((rw['cashAmount'] ?? 0) as num).toInt();
              final giftCard = rw['giftCard'] is Map ? rw['giftCard'] as Map<String, dynamic> : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.orange[400], borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$displayName made a purchase!',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      if (dateLabel.isNotEmpty)
                        Text(dateLabel, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    ]),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, children: [
                    if (cashAmount > 0)
                      _bonusBadge('+UGX ${_fmt(cashAmount)} cash', Colors.green),
                    if (giftCard != null)
                      _bonusBadge(
                          'Gift Card: ${giftCard['code'] ?? ''} (UGX ${_fmt((giftCard['amount'] ?? 0) as int)})',
                          Colors.amber[700]!),
                  ]),
                ]),
              );
            }),
          ]),
        ),
      ]),
    );
  }

  Widget _bonusBadge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );

  Widget _buildMyRewards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _myRewards.map((ur) {
          final r = ur is Map ? ur as Map<String, dynamic> : <String, dynamic>{};
          final title = r['reward'] is Map
              ? (r['reward'] as Map)['title']?.toString() ?? 'Reward'
              : r['title']?.toString() ?? 'Reward';
          final code = r['code']?.toString() ?? '';
          final status = r['status']?.toString() ?? 'active';
          final date = r['createdAt']?.toString() ?? '';
          String dateLabel = '';
          if (date.isNotEmpty) {
            try {
              final dt = DateTime.parse(date);
              dateLabel = 'Redeemed ${dt.month}/${dt.day}/${dt.year}';
            } catch (_) {}
          }
          Color statusColor;
          String statusLabel;
          switch (status) {
            case 'used': statusColor = Colors.grey; statusLabel = 'Used'; break;
            case 'expired': statusColor = Colors.red; statusLabel = 'Expired'; break;
            default: statusColor = Colors.green; statusLabel = 'Active';
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: status == 'active' ? const Color(0xFFA5D6A7) : Colors.grey[200]!),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ]),
              if (code.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Code:', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'monospace')),
                  ]),
                ),
              ],
              if (dateLabel.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 6),
                  child: Text(dateLabel, style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvailableRewards() {
    if (_rewards.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!)),
        child: Column(children: [
          const Text('⭐', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No rewards available yet', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          const SizedBox(height: 6),
          Text('Keep shopping to unlock new rewards!', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _rewards.map((r) {
          final rw = r is Map ? r as Map<String, dynamic> : <String, dynamic>{};
          final title = rw['title']?.toString() ?? 'Reward';
          final description = rw['description']?.toString() ?? '';
          final points = ((rw['pointsRequired'] ?? rw['points'] ?? 0) as num).toInt();
          final rewardId = rw['_id']?.toString() ?? rw['id']?.toString();
          final type = rw['type']?.toString() ?? '';
          final value = ((rw['value'] ?? 0) as num).toDouble();
          final canAfford = _myPoints >= points;

          Color typeColor;
          String typeLabel;
          switch (type) {
            case 'discount': typeColor = Colors.purple; typeLabel = 'DISCOUNT'; break;
            case 'cashback': typeColor = Colors.green; typeLabel = 'CASHBACK'; break;
            case 'gift': typeColor = Colors.orange; typeLabel = 'GIFT'; break;
            case 'free_delivery': typeColor = Colors.blue; typeLabel = 'FREE DELIVERY'; break;
            default: typeColor = _kGreen; typeLabel = type.isEmpty ? 'REWARD' : type.replaceAll('_', ' ').toUpperCase();
          }

          String valueStr = '';
          if (value > 0) {
            switch (type) {
              case 'discount': valueStr = '${value.toStringAsFixed(0)}% OFF'; break;
              case 'cashback': valueStr = 'UGX ${_fmt(value.toInt())} Cashback'; break;
              default: valueStr = 'Value: ${_fmt(value.toInt())}';
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
            ),
            child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: _kGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: const Icon(Icons.card_giftcard_rounded, color: _kGreen, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (type.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(typeLabel, style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.w600)),
                  ),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                if (valueStr.isNotEmpty)
                  Text(valueStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kGreen)),
                if (description.isNotEmpty)
                  Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                Row(children: [
                  const Icon(Icons.star, color: Colors.amber, size: 13),
                  const SizedBox(width: 3),
                  Text('$points pts',
                    style: TextStyle(fontSize: 12,
                      color: canAfford ? _kGreen : Colors.red,
                      fontWeight: FontWeight.w500)),
                ]),
              ])),
              const SizedBox(width: 10),
              if (rewardId != null)
                ElevatedButton(
                  onPressed: canAfford ? () => _openRedeemModal(rw) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford ? _kGreen : Colors.grey[300],
                    foregroundColor: canAfford ? Colors.white : Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(canAfford ? 'Redeem' : 'Need\n$points pts',
                      style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
