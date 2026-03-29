import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../services/error_handler_service.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../common/widgets/bottom_navigation_bar.dart';

const _green = Color.fromRGBO(24, 95, 45, 1);

class RewardsPage extends ConsumerStatefulWidget {
  const RewardsPage({super.key});

  @override
  ConsumerState<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends ConsumerState<RewardsPage> {
  List<dynamic> _rewards = [];
  List<dynamic> _myRewards = [];
  Map<String, dynamic>? _referralData;
  int _myPoints = 0;
  bool _isLoading = true;
  String? _error;

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
      final rewardsRes = await ApiService.fetchRewards();
      if (token != null) {
        try {
          final myRes = await ApiService.fetchMyRewards(token: token);
          _myRewards = (myRes['data'] ?? myRes['rewards']) is List
              ? (myRes['data'] ?? myRes['rewards']) as List : [];
          // Extract points balance
          final statsRes = await ApiService.fetchCashoutStats(token: token);
          final stats = statsRes['data'] ?? statsRes;
          _myPoints = ((stats['loyaltyPoints'] ?? stats['points'] ?? 0) as num).toInt();
        } catch (_) {
          _myRewards = [];
        }
        try {
          final refRes = await ApiService.fetchReferralData(token: token);
          _referralData = refRes['data'] as Map<String, dynamic>?;
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _rewards = (rewardsRes['data'] ?? rewardsRes['rewards']) is List
              ? (rewardsRes['data'] ?? rewardsRes['rewards']) as List : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = ErrorHandlerService.getErrorMessage(e); _isLoading = false; });
      }
    }
  }

  Future<void> _redeemReward(String rewardId, int pointsRequired) async {
    if (_myPoints < pointsRequired) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('You need $pointsRequired points. You have $_myPoints.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final token = await AuthService.getToken();
    if (token == null) {
      Navigator.pushNamed(context, '/signin');
      return;
    }
    try {
      await ApiService.redeemReward(token: token, rewardId: rewardId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Reward redeemed!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating,
        ));
        _loadData();
      }
    } catch (e) {
      if (mounted) ErrorHandlerService.showErrorSnackBar(context, message: ErrorHandlerService.getErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Rewards & Loyalty', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Raleway')),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: _green,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPointsBanner(),
                        if (_referralData != null) _buildReferralCard(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: const Text('Available Rewards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        if (_rewards.isEmpty)
                          _buildEmptyRewards()
                        else
                          ..._rewards.map((r) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildRewardCard(r, isOwned: false),
                          )),
                        if (_myRewards.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                            child: const Text('My Redeemed Rewards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          ..._myRewards.map((r) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildRewardCard(r, isOwned: true),
                          )),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsBanner() {
    return Container(
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Loyalty Points', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    _myPoints.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Raleway'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Earn points on every order. Redeem them for discounts, cashback, and more.',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _pointsPill(Icons.shopping_bag, 'Shop to earn'),
              const SizedBox(width: 8),
              _pointsPill(Icons.people, 'Refer friends'),
              const SizedBox(width: 8),
              _pointsPill(Icons.redeem, 'Redeem anytime'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pointsPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildReferralCard() {
    final ref = _referralData!;
    final totalEarnings = ref['totalEarnings'] ?? ref['earnings'] ?? 0;
    final peopleReferred = ref['totalReferrals'] ?? ref['referrals'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text('Referral Earnings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _refStat(
                'UGX ${totalEarnings.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                'Total Earned', Icons.attach_money, Colors.green,
              )),
              Expanded(child: _refStat('$peopleReferred', 'Referred', Icons.people, Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _refStat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEmptyRewards() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No rewards available yet', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          const SizedBox(height: 6),
          Text('Keep shopping to unlock new rewards!', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildRewardCard(dynamic reward, {required bool isOwned}) {
    final r = reward is Map ? reward as Map<String, dynamic> : <String, dynamic>{};
    final title = r['title']?.toString() ?? 'Reward';
    final description = r['description']?.toString() ?? '';
    final points = ((r['points'] ?? r['pointsRequired'] ?? 0) as num).toInt();
    final rewardId = r['_id']?.toString() ?? r['id']?.toString();
    final type = r['type']?.toString() ?? '';
    final value = r['value']?.toString() ?? '';

    Color typeColor;
    String typeLabel;
    switch (type) {
      case 'discount': typeColor = Colors.purple; typeLabel = 'Discount'; break;
      case 'cashback': typeColor = Colors.green; typeLabel = 'Cashback'; break;
      case 'gift': typeColor = Colors.orange; typeLabel = 'Gift'; break;
      default: typeColor = _green; typeLabel = type.isEmpty ? 'Reward' : type;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: _green, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    if (value.isNotEmpty)
                      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _green)),
                    if (description.isNotEmpty)
                      Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (!isOwned && points > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 3),
                          Text('$points pts required',
                              style: TextStyle(
                                fontSize: 12,
                                color: _myPoints >= points ? _green : Colors.red,
                                fontWeight: FontWeight.w500,
                              )),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isOwned && rewardId != null)
                ElevatedButton(
                  onPressed: () => _redeemReward(rewardId, points),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _myPoints >= points ? _green : Colors.grey[300],
                    foregroundColor: _myPoints >= points ? Colors.white : Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Redeem', style: TextStyle(fontSize: 13)),
                )
              else if (isOwned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600], size: 14),
                      const SizedBox(width: 4),
                      const Text('Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
