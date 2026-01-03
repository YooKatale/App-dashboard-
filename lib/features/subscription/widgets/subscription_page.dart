import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../common/widgets/custom_button.dart';
import '../../payment/widgets/flutter_wave.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  List<dynamic> _packages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use AuthService token (like webapp and cart)
      final token = await AuthService.getToken();
      final user = FirebaseAuth.instance.currentUser;
      // Try Firebase token first, fallback to AuthService token
      final authToken = await user?.getIdToken() ?? token;
      
      final response = await ApiService.fetchSubscriptionPackages(
        token: authToken,
      );

      if (response['status'] == 'Success' && response['data'] != null) {
        setState(() {
          _packages = response['data'] is List ? response['data'] : [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _packages = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load subscription packages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _subscribeToPackage(String packageId) async {
    try {
      // EXACT WEBAPP LOGIC: const { userInfo } = useSelector((state) => state.auth)
      // Webapp checks: if (!userInfo || userInfo == {} || userInfo == "") then redirect
      final userData = await AuthService.getUserData();
      final token = await AuthService.getToken();
      final authState = ref.read(authStateProvider);
      final user = FirebaseAuth.instance.currentUser;

      // Check if user is logged in (EXACT webapp check: userInfo?._id)
      String? userId;
      
      // First check auth state provider (most reliable)
      if (authState.isLoggedIn && authState.userId != null) {
        userId = authState.userId;
      }
      
      // If not in auth state, check stored user data (EXACT webapp check)
      if (userId == null && userData != null && userData.isNotEmpty) {
        final id = userData['_id']?.toString() ?? userData['id']?.toString();
        if (id != null && id.isNotEmpty) {
          userId = id;
          // Sync auth state with stored data
          ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
            userId: userId,
            email: userData['email']?.toString(),
            firstName: userData['firstname']?.toString(),
            lastName: userData['lastname']?.toString(),
          );
        }
      }

      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to subscribe')),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushNamed(context, '/signin');
            }
          });
        }
        return;
      }

      // Use Firebase token if available, otherwise use AuthService token
      final authToken = await user?.getIdToken() ?? token ?? userData?['token']?.toString();

      final response = await ApiService.createSubscription(
        userId: userId,
        packageId: packageId,
        token: authToken,
      );

      if (response['status'] == 'Success' && response['data'] != null) {
        final orderId = response['data']['Order']?.toString();
        if (orderId != null && mounted) {
          // Navigate to payment page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlutterWavePayment(orderId: orderId),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    response['message'] ?? 'Failed to create subscription')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatCurrency(dynamic amount) {
    final amt = amount is num
        ? amount.toDouble()
        : double.tryParse(amount.toString()) ?? 0.0;
    return 'UGX ${amt.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPackages,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _packages.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.card_membership,
                              size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No subscription packages available',
                            style: TextStyle(fontSize: 24, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Subscribe to our payment plan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                  fontSize: 18, color: Colors.black87),
                              children: [
                                TextSpan(text: 'Get '),
                                TextSpan(
                                  text: '25%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromRGBO(24, 95, 45, 1),
                                  ),
                                ),
                                TextSpan(text: ' subscription discount'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              childAspectRatio: 2.5,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _packages.length,
                            itemBuilder: (context, index) {
                              final package = _packages[index];
                              return _SubscriptionCard(
                                package: package,
                                onSubscribe: () => _subscribeToPackage(
                                    package['_id']?.toString() ?? ''),
                                formatCurrency: _formatCurrency,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final VoidCallback onSubscribe;
  final String Function(dynamic) formatCurrency;

  const _SubscriptionCard({
    required this.package,
    required this.onSubscribe,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package['name']?.toString() ?? 'Subscription Package',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        package['type']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatCurrency(package['price'] ?? 0),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(24, 95, 45, 1),
                  ),
                ),
              ],
            ),
            if (package['description'] != null) ...[
              const SizedBox(height: 12),
              Text(
                package['description'].toString(),
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
            if (package['features'] != null && package['features'] is List) ...[
              const SizedBox(height: 12),
              ...(package['features'] as List).map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 16, color: Color.fromRGBO(24, 95, 45, 1)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature.toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                title: 'Subscribe',
                onPressed: onSubscribe,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
