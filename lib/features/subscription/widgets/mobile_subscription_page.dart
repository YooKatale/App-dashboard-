import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../payment/widgets/flutter_wave.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import '../../schedule/widgets/meal_calendar_page.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../authentication/providers/redirect_provider.dart';
import 'food_algae_box.dart';

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
        setState(() {
          _packages = data is List ? data : [data];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _subscribeToPackage(String packageId) async {
    // Always check stored user data first (like webapp checks localStorage)
    var userData = await AuthService.getUserData();
    var token = await AuthService.getToken();
    
    String? userId;
    
    // If we have data, use it
    if (userData != null && token != null) {
      userId = userData['_id']?.toString() ?? userData['id']?.toString();
      
      // Update auth state if we have user data but auth state is not set
      final authState = ref.read(authStateProvider);
      if (userId != null && !authState.isLoggedIn) {
        ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
          userId: userId,
          email: userData['email']?.toString(),
          firstName: userData['firstname']?.toString(),
          lastName: userData['lastname']?.toString(),
        );
      }
    } else {
      // Fallback: Check auth state and try to get token
      final authState = ref.read(authStateProvider);
      if (authState.isLoggedIn && authState.userId != null) {
        userId = authState.userId;
        token = await AuthService.getToken();
      }
    }
    
    // Final check - if still no data, redirect to login
    if (userId == null || token == null) {
      // Double check one more time
      userData = await AuthService.getUserData();
      token = await AuthService.getToken();
      
      if (userData != null && token != null) {
        userId = userData['_id']?.toString() ?? userData['id']?.toString();
        // Update auth state
        if (userId != null) {
          ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
            userId: userId,
            email: userData['email']?.toString(),
            firstName: userData['firstname']?.toString(),
            lastName: userData['lastname']?.toString(),
          );
        }
      } else {
        // Really not logged in, redirect
        if (mounted) {
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

    setState(() => _isSubscribing = true);

    try {
      final response = await ApiService.createSubscription(
        userId: userId!,
        packageId: packageId,
        token: token,
      );

      if (response['status'] == 'Success') {
        // Navigate to payment page
        final orderId = response['data']?['Order']?.toString() ?? 
                       response['data']?['_id']?.toString() ??
                       response['data']?['orderId']?.toString();
        final packagePrice = response['data']?['price']?.toString() ??
                            response['data']?['packagePrice']?.toString();
        final amount = packagePrice != null ? double.tryParse(packagePrice) ?? 0.0 : 0.0;
        
        if (orderId != null && mounted) {
          Navigator.pushNamed(
            context,
            '/payment/$orderId',
            arguments: {'amount': amount},
          );
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
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Subscription Packages'),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 3),
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
                    final name = package['name']?.toString() ?? 'Subscription';
                    final price = package['price']?.toString() ?? '0';
                    final description = package['description']?.toString() ?? '';
                    final benefits = package['benefits']?.toString() ?? '';

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
                          // Header
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(24, 95, 45, 1),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Raleway',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'UGX $price',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Raleway',
                                  ),
                                ),
                              ],
                            ),
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
                                
                                if (benefits.isNotEmpty) ...[
                                  const Text(
                                    'Benefits:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    benefits,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                
                                // Package Details
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Package Details:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDetailRow(Icons.restaurant, '3 meals per day', Colors.black87),
                                      _buildDetailRow(Icons.local_grocery_store, 'Fresh ingredients', Colors.black87),
                                      _buildDetailRow(Icons.delivery_dining, 'Free delivery: Within 3km distance. Extra: 950 UGX per additional kilometer.', Colors.black87),
                                      _buildDetailRow(Icons.calendar_today, 'Weekly meal calendar', Colors.black87),
                                      _buildDetailRow(Icons.support_agent, '24/7 Support', Colors.black87),
                                      _buildDetailRow(Icons.security, 'Safe, instant and secured', Colors.black87),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
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
                      
                      // Food Algae Box
                      FutureBuilder<Map<String, dynamic>?>(
                        future: AuthService.getUserData(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            final userId = snapshot.data!['_id']?.toString() ?? 
                                          snapshot.data!['id']?.toString();
                            return FoodAlgaeBox(
                              userId: userId,
                              planType: _packages.isNotEmpty 
                                  ? _packages[0]['name']?.toString() 
                                  : null,
                            );
                          }
                          return const SizedBox.shrink();
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
}
