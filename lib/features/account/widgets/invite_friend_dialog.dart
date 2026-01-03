import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';

class InviteFriendDialog extends StatefulWidget {
  final String userId;

  const InviteFriendDialog({
    super.key,
    required this.userId,
  });

  @override
  State<InviteFriendDialog> createState() => _InviteFriendDialogState();
}

class _InviteFriendDialogState extends State<InviteFriendDialog> {
  String? _referralCode;
  String? _referralUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReferralInfo();
  }

  Future<void> _loadReferralInfo() async {
    try {
      final userData = await AuthService.getUserData();
      final token = await AuthService.getToken();
      final userId = userData?['_id']?.toString() ?? widget.userId;
      
      // Try to fetch/create referral code from backend
      try {
        // Generate referral code from user ID (like webapp)
        final hash = userId.substring(0, 8).toUpperCase();
        _referralCode = hash;
        _referralUrl = 'https://yookatale.app/signup?ref=$_referralCode';
        
        // Optionally save to backend
        // await ApiService.createReferralCode(userId: userId, referralCode: _referralCode, token: token);
      } catch (e) {
        // Fallback to simple generation
        _referralCode = userId.length >= 8 
            ? userId.substring(0, 8).toUpperCase() 
            : userId.toUpperCase();
        _referralUrl = 'https://yookatale.app/signup?ref=$_referralCode';
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareReferral() async {
    if (_referralUrl == null) return;

    // Use same message format as webapp
    final message = '''Hey, I am using YooKatale. Forget about cooking or going to the market. Enjoy a variety of customizable meals for breakfast, lunch & supper at discounted prices with access to credit, never miss a meal by using our premium, family & business subscription plans with friends and family!:: https://www.yookatale.app

Sign up for free today & invite friends & loved ones $_referralUrl

Earn 20,000UGX to 50,000UGX & other Gifts for every member you invite.

Use my referral code: $_referralCode

www.yookatale.app/subscription''';

    await Share.share(
      message,
      subject: 'Join Yookatale - Fresh Groceries Delivered',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      size: 40,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  const Text(
                    'Invite Friends',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Raleway',
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    'Share your referral code and earn rewards when friends sign up!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Referral Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(24, 95, 45, 1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color.fromRGBO(24, 95, 45, 1),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Your Referral Code',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _referralCode ?? 'Loading...',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(24, 95, 45, 1),
                            fontFamily: 'Raleway',
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _copyToClipboard(_referralCode ?? ''),
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy Code'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Share Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _shareReferral,
                      icon: const Icon(Icons.share, size: 20),
                      label: const Text(
                        'Share Referral Link',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Raleway',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Info Text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You earn rewards when your friends sign up using your code!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Close Button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
      ),
    );
  }
}
