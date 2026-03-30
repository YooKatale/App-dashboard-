import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';
import '../../payment/widgets/flutter_wave.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import '../../schedule/widgets/meal_calendar_page.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../authentication/providers/redirect_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../cart/providers/cart_provider.dart';

/// PLAN_CONFIG - mirrors webapp PLAN_CONFIG exactly
const Map<String, Map<String, dynamic>> _planConfig = {
  'premium': {
    'name': 'Premium',
    'tagline': 'SINGLE USER',
    'color': 0xFF7c3aed,
    'gradient': [0xFF4c1d95, 0xFF7c3aed],
    'ctaLabel': 'Subscribe to premium',
    'popular': false,
    'originalPrice': 'UGX 40,000',
    'saveAmt': 'SAVE 10,000',
    'currentPrice': 'UGX 30,000',
    'discount': '25% OFF',
    'stars': 4.5,
    'reviews': 128,
    'features': [
      'Premium Membership Fee',
      '1 Premium Food Test',
      '24 - 45 mins Delivery',
      'Cashless Shopping',
      'Same Day Delivery',
      '12 months Membership',
      '24/7 Customer Support',
    ],
  },
  'family': {
    'name': 'Family',
    'tagline': '2-6 FAMILY MEMBERS',
    'color': 0xFFe07820,
    'gradient': [0xFF92400e, 0xFFe07820],
    'ctaLabel': 'Subscribe to family',
    'popular': true,
    'originalPrice': 'UGX 100,000',
    'saveAmt': 'SAVE 30,000',
    'currentPrice': 'UGX 90,000',
    'discount': '25% OFF',
    'stars': 4.5,
    'reviews': 128,
    'features': [
      '2-6 users',
      'Account activation',
      '1 Food test',
      'Diet insights: Personalized nutrition advice and meal planning tips.',
      'Promotional offers & discounts: Exclusive deals for the entire family.',
      'Credit line: A flexible micro-credit option, pay-later model.',
      'Unlimited food varieties in different quantities.',
      'Loyalty points: Redeem cash for loyalty points.',
      'Gas credit: Access to gas refills.',
      'Express delivery 24/7: Priority delivery service.',
    ],
  },
  'business': {
    'name': 'Business',
    'tagline': '10+ EMPLOYEES',
    'color': 0xFF0ea5e9,
    'gradient': [0xFF0c4a6e, 0xFF0ea5e9],
    'ctaLabel': 'Subscribe to business',
    'popular': false,
    'originalPrice': 'UGX 240,000',
    'saveAmt': 'SAVE 60,000',
    'currentPrice': 'UGX 180,000',
    'discount': '25% OFF',
    'stars': 4.5,
    'reviews': 128,
    'features': [
      '10+ users',
      'Account activation',
      '1 Food test',
      'Employee meal cards: Ensure your team is well-nourished.',
      'Gym and wellness cards: Promote wellness with gym memberships.',
      'Diet insights: Personalized nutrition advice.',
      'Promotional offers & discounts: Exclusive access to deals.',
      'Credit line: Flexible micro-credit for businesses.',
      'Unlimited food varieties in different quantities.',
      'Loyalty points: Redeem cash for long-term savings.',
      'Gas credit: Access to gas refills for business operations.',
      'Express delivery 24/7: Fast priority delivery at any time.',
    ],
  },
};

class MobileSubscriptionPage extends ConsumerStatefulWidget {
  const MobileSubscriptionPage({super.key});

  @override
  ConsumerState<MobileSubscriptionPage> createState() =>
      _MobileSubscriptionPageState();
}

class _MobileSubscriptionPageState
    extends ConsumerState<MobileSubscriptionPage> {
  List<dynamic> _packages = [];
  bool _isLoading = true;
  bool _isSubscribing = false;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final token = await AuthService.getToken();
      final response = await ApiService.fetchSubscriptionPackages(token: token);
      
      if (response['status'] == 'Success' && response['data'] != null) {
        final data = response['data'];
        if (mounted) {
          setState(() {
            _packages = data is List ? data : [data];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _subscribeToPackage(String packageId) async {
    // EXACT WEBAPP LOGIC: const { userInfo } = useSelector((state) => state.auth)
    // Webapp checks: if (!userInfo || userInfo == {} || userInfo == "") then redirect
    // Webapp uses: createSubscription({ user: userInfo._id, packageId: ID })
    var userData = await AuthService.getUserData();
    final token = await AuthService.getToken();
    
    // EXACT webapp check: if (!userInfo || userInfo == {} || userInfo == "")
    String? userId;
    
    if (userData != null && userData.isNotEmpty) {
      // Ensure we have a valid _id or id (like webapp checks userInfo?._id)
      final id = userData['_id']?.toString() ?? userData['id']?.toString();
      if (id != null && id.isNotEmpty) {
        userId = id;
      }
    }
    
    // If no userId from stored data, check auth state
    if (userId == null) {
      final authState = ref.read(authStateProvider);
      if (authState.isLoggedIn && authState.userId != null) {
        userId = authState.userId;
      }
    }
    
    // Not logged in (EXACT webapp: if (!userInfo || userInfo == {} || userInfo == ""))
    // But check auth state first - if logged in, use that
    if (userId == null) {
      final authState = ref.read(authStateProvider);
      if (authState.isLoggedIn && authState.userId != null) {
        userId = authState.userId;
        // Sync with stored data
        if (userData == null) {
          final storedData = await AuthService.getUserData();
          if (storedData != null) {
            userData = storedData;
          }
        }
      } else {
        // Truly not logged in
        if (mounted) {
          // Save the package ID for auto-subscribe after login
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_subscription_package', packageId);
          
          // Remember where user was trying to go
          ref.read(redirectRouteProvider.notifier).state = '/subscription';
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to subscribe'),
              backgroundColor: Colors.orange,
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushNamed(context, '/signin');
            }
          });
        }
        return;
      }
    }
    
    // EXACT WEBAPP LOGIC: Backend subscription endpoint doesn't require token
    // Webapp sends: { user: userInfo._id, packageId: ID } - no token needed
    // Token is optional - try to get it but don't block subscription
    String? finalToken = token;
    if (finalToken == null) {
      finalToken = await AuthService.getToken();
    }
    // Token is optional for subscription endpoint
    
    // Update auth state if not already set (sync with stored data)
    final authState = ref.read(authStateProvider);
    if (!authState.isLoggedIn && userData != null) {
      ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
        userId: userId,
        email: userData['email']?.toString(),
        firstName: userData['firstname']?.toString(),
        lastName: userData['lastname']?.toString(),
      );
    }

    setState(() => _isSubscribing = true);

    try {
      // EXACT WEBAPP LOGIC: Backend expects { user: userId, packageId: packageId }
      // Token is optional - subscription endpoint doesn't require authentication
      final response = await ApiService.createSubscription(
        userId: userId!,
        packageId: packageId,
        token: finalToken, // Optional - pass if available
      );

      if (response['status'] == 'Success') {
        // Redirect to webapp for payment (as requested)
        final orderId = response['data']?['Order']?.toString() ?? 
                       response['data']?['_id']?.toString() ??
                       response['data']?['orderId']?.toString();
        
        if (orderId != null && mounted) {
          // Save payment URL for redirect after login if needed
          final prefs = await SharedPreferences.getInstance();
          final webappUrl = 'https://yookatale.app/payment/$orderId';
          await prefs.setString('pending_payment_url', webappUrl);
          
          final uri = Uri.parse(webappUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Redirecting to webapp to complete payment...'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Fallback to in-app payment
            Navigator.pushNamed(
              context,
              '/payment/$orderId',
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription created but payment redirect failed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubscribing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state in build method (like webapp watches Redux state)
    final authState = ref.watch(authStateProvider);
    final notificationCount = ref.watch(notificationCountProvider);

    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _SubTopBar(
          cartCount: cartCount,
          notificationCount: notificationCount,
        ),
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 1),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _packages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_membership,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No subscription packages available',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero gradient header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0B2416), Color(0xFF185f2d)],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Meal Plans',
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Raleway', height: 1.1),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Choose the plan that fits your lifestyle',
                              style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.85), fontFamily: 'Raleway', fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 16),
                            // 25% OFF announcement banner
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('25% OFF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.greenAccent)),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text('Limited time offer on all plans', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Subscription Packages (First)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Subscription Packages',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _packages.length,
                        itemBuilder: (context, index) {
                    final package = _packages[index];
                    final type = (package['type'] ?? '').toString().toLowerCase();
                    final config = _planConfig[type] ?? _planConfig['premium']!;
                    final name = package['name']?.toString() ?? config['name'] ?? 'Subscription';
                    final price = package['price']?.toString() ?? '0';
                    final description = package['description']?.toString() ?? '';
                    final details = package['details'];
                    final features = details is List && (details as List).isNotEmpty
                        ? (details as List).map((e) => e.toString()).toList()
                        : (config['features'] as List?)?.map((e) => e.toString()).toList() ?? [];
                    final benefits = package['benefits']?.toString() ?? '';
                    final gradient = config['gradient'] as List<int>? ?? [0xFF185f2d, 0xFF185f2d];
                    final isPopular = config['popular'] == true;

                    final accentColor = Color(config['color'] as int);
                    final originalPrice = config['originalPrice']?.toString() ?? '';
                    final saveAmt = config['saveAmt']?.toString() ?? '';
                    final currentPrice = config['currentPrice']?.toString() ?? 'UGX ${_formatPrice(price)}';
                    final discount = config['discount']?.toString() ?? '25% OFF';
                    final stars = (config['stars'] as num? ?? 4.5).toDouble();
                    final reviews = (config['reviews'] as num? ?? 0).toInt();
                    final tagline = config['tagline']?.toString() ?? '';
                    final ctaLabel = config['ctaLabel']?.toString() ?? 'Subscribe Now';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: isPopular ? Border.all(color: accentColor, width: 2) : null,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.12),
                            spreadRadius: 1,
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Card header (gradient) ──────────────────────────
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(gradient[0]), Color(gradient.length > 1 ? gradient[1] : gradient[0])],
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: icon + MOST POPULAR + 25% OFF
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        type == 'premium' ? Icons.favorite_rounded
                                            : type == 'family' ? Icons.group_rounded
                                            : Icons.trending_up_rounded,
                                        color: Colors.white, size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Discount pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.22),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(discount,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.4)),
                                    ),
                                    const Spacer(),
                                    if (isPopular)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFe07820),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text('MOST POPULAR',
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // Plan name + tagline pill
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Raleway')),
                                    const SizedBox(width: 8),
                                    if (tagline.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(tagline,
                                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.5)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Pricing rows
                                if (originalPrice.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Text(
                                        originalPrice,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.6),
                                          decoration: TextDecoration.lineThrough,
                                          decorationColor: Colors.white54,
                                        ),
                                      ),
                                      if (saveAmt.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.greenAccent.withOpacity(0.25),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(saveAmt,
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.greenAccent)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  currentPrice,
                                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Raleway'),
                                ),
                                const SizedBox(height: 12),
                                // Star rating
                                Row(
                                  children: [
                                    ...List.generate(5, (i) {
                                      final filled = i < stars.floor();
                                      final half = !filled && i < stars;
                                      return Icon(
                                        half ? Icons.star_half_rounded : (filled ? Icons.star_rounded : Icons.star_outline_rounded),
                                        color: Colors.amber,
                                        size: 16,
                                      );
                                    }),
                                    const SizedBox(width: 6),
                                    Text('$stars', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 4),
                                    Text('($reviews reviews)', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ── Features + CTA ──────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (features.isNotEmpty) ...[
                                  const Text('PLAN BENEFITS',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF888888), letterSpacing: 1.2)),
                                  const SizedBox(height: 12),
                                  ...features.map((f) {
                                    // Strip leading bullet/dash
                                    final text = f.replaceFirst(RegExp(r'^[•\-]\s*'), '').trim();
                                    if (text.isEmpty || RegExp(r'^benefits?\s*:?\s*$', caseSensitive: false).hasMatch(text)) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.check_circle_rounded, size: 16, color: accentColor),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4))),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 20),
                                ] else if (description.isNotEmpty) ...[
                                  Text(description, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                                  const SizedBox(height: 20),
                                ],

                                // CTA
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isSubscribing
                                        ? null
                                        : () => _subscribeToPackage(package['_id']?.toString() ?? ''),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: accentColor.withOpacity(0.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 0,
                                    ),
                                    child: _isSubscribing
                                        ? const SizedBox(height: 22, width: 22,
                                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                        : Text(ctaLabel,
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Raleway')),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                      
                      const SizedBox(height: 24),
                      
                      // Meal Subscription & Weekly Calendar Section (Below packages)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Color.fromRGBO(24, 95, 45, 1),
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Meal Subscription & Weekly Calendar',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Choose your meals, view pricing, and see the weekly meal calendar for each plan.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MealCalendarPage(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.calendar_view_week),
                                label: const Text('View Meal Calendar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.local_shipping, 
                                        color: Colors.blue[700], size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Free Delivery:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 28),
                                    child: Text(
                                      'Within 3km distance.\nExtra: 950 UGX per additional kilometer.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String text, [Color? textColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color.fromRGBO(24, 95, 45, 1)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: textColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(String price) {
    try {
      final numPrice = double.parse(price);
      return numPrice.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } catch (e) {
      return price;
    }
  }
}

// ── Subscription top bar — matches homepage style ─────────────────────────────
class _SubTopBar extends StatelessWidget {
  final int cartCount;
  final int notificationCount;

  const _SubTopBar({required this.cartCount, required this.notificationCount});

  static const _kPrimary = Color(0xFF0B2416);
  static const _kAccent  = Color(0xFF2ECC71);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kPrimary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        bottom: 8,
        left: 12,
        right: 12,
      ),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 8),

          // Title / search tap area
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/search'),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.45), size: 15),
                    const SizedBox(width: 8),
                    Text(
                      'Search products…',
                      style: GoogleFonts.inter(color: Colors.white.withOpacity(0.55), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Notifications
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/notifications'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                ),
              ),
              if (notificationCount > 0)
                Positioned(
                  top: -3, right: -3,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kPrimary, width: 1.5),
                    ),
                    child: Text(notificationCount > 9 ? '9+' : '$notificationCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),

          // Cart
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/cart'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                ),
              ),
              if (cartCount > 0)
                Positioned(
                  top: -3, right: -3,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: _kAccent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kPrimary, width: 1.5),
                    ),
                    child: Text(cartCount > 9 ? '9+' : '$cartCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
