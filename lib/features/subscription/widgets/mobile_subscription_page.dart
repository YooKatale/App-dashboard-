import 'package:flutter/material.dart';
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

/// PLAN_CONFIG - matches web subscription page (premium, family, business)
const Map<String, Map<String, dynamic>> _planConfig = {
  'premium': {
    'name': 'Premium',
    'tagline': 'SINGLE USER',
    'color': 0xFF7c3aed,
    'gradient': [0xFF4c1d95, 0xFF7c3aed],
    'ctaLabel': 'Subscribe to premium',
    'popular': false,
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
    'features': [
      '2-6 users',
      'Account activation',
      '1 Food test',
      'Diet insights & meal planning',
      'Promotional offers & discounts',
      'Credit line: pay-later model',
      'Unlimited food varieties',
      'Loyalty points',
      'Gas credit',
      'Express delivery 24/7',
    ],
  },
  'business': {
    'name': 'Business',
    'tagline': '10+ EMPLOYEES',
    'color': 0xFF0ea5e9,
    'gradient': [0xFF0c4a6e, 0xFF0ea5e9],
    'ctaLabel': 'Subscribe to business',
    'popular': false,
    'features': [
      '10+ users',
      'Account activation',
      '1 Food test',
      'Employee meal cards',
      'Gym and wellness cards',
      'Diet insights',
      'Promotional offers & discounts',
      'Credit line',
      'Unlimited food varieties',
      'Loyalty points',
      'Gas credit',
      'Express delivery 24/7',
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Subscription Packages'),
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
                        padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromRGBO(24, 95, 45, 1),
                              Color.fromRGBO(40, 140, 70, 1),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Meal Plans',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'Raleway',
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Choose the plan that fits your lifestyle',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.88),
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w500,
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

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              if (isPopular)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFe07820),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('MOST POPULAR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                              Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(gradient[0]),
                                  Color(gradient.length > 1 ? gradient[1] : gradient[0]),
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'Raleway',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'UGX ${_formatPrice(price)}',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'Raleway',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.card_membership,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                            ],
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (description.isNotEmpty) ...[
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                ),
                                  const SizedBox(height: 16),
                                ],
                                
                                if (features.isNotEmpty) ...[
                                const Text(
                                  'Plan Benefits',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...features.map((f) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle, size: 16, color: Color.fromRGBO(24, 95, 45, 1)),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(f, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                                    ],
                                  ),
                                )),
                                const SizedBox(height: 20),
                                ] else if (benefits.isNotEmpty) ...[
                                const Text('Benefits:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(benefits, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                const SizedBox(height: 20),
                                ],
                                
                                // Subscribe Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isSubscribing
                                        ? null
                                        : () => _subscribeToPackage(
                                            package['_id']?.toString() ?? ''),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color.fromRGBO(24, 95, 45, 1),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isSubscribing
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Subscribe Now',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Raleway',
                                            ),
                                          ),
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
