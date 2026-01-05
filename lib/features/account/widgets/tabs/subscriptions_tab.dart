import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/api_service.dart';
import '../../../authentication/providers/auth_provider.dart';

class SubscriptionsTab extends ConsumerStatefulWidget {
  const SubscriptionsTab({super.key});

  @override
  ConsumerState<SubscriptionsTab> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends ConsumerState<SubscriptionsTab> {
  List<dynamic> _completedSubscriptions = [];
  List<dynamic> _pendingSubscriptions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = ref.read(authStateProvider);
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || authState.userId == null) {
        setState(() {
          _error = 'Please login to view subscriptions';
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.fetchUserSubscriptions(
        authState.userId!,
        token: await user.getIdToken(),
      );

      if (response['status'] == 'Success' && response['data'] != null) {
        final allSubscriptions = response['data'] is List ? response['data'] : [];
        
        // Separate completed and pending subscriptions based on payment status
        final completed = <dynamic>[];
        final pending = <dynamic>[];
        
        for (var sub in allSubscriptions) {
          final paymentStatus = sub['payment']?['status']?.toString().toLowerCase() ?? 
                               sub['status']?.toString().toLowerCase() ?? 
                               'pending';
          final orderStatus = sub['order']?['status']?.toString().toLowerCase() ?? 
                             sub['orderStatus']?.toString().toLowerCase() ?? 
                             'pending';
          
          // Check if payment is completed
          if (paymentStatus == 'completed' || 
              paymentStatus == 'paid' || 
              paymentStatus == 'success' ||
              orderStatus == 'completed' ||
              orderStatus == 'paid') {
            completed.add(sub);
          } else {
            // Pending payment
            pending.add(sub);
          }
        }
        
        setState(() {
          _completedSubscriptions = completed;
          _pendingSubscriptions = pending;
          _isLoading = false;
        });
      } else {
        setState(() {
          _completedSubscriptions = [];
          _pendingSubscriptions = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load subscriptions: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadSubscriptions,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : _completedSubscriptions.isEmpty && _pendingSubscriptions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.card_membership,
                              size: 64,
                              color: Color.fromRGBO(24, 95, 45, 1),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No Subscriptions Yet',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Browse our subscription packages',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/subscription');
                            },
                            icon: const Icon(Icons.explore),
                            label: const Text('Browse Subscriptions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSubscriptions,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Pending Payments Section
                          if (_pendingSubscriptions.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.pending_actions,
                                    color: Colors.orange,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Pending Payments',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._pendingSubscriptions.map((subscription) => _buildPendingSubscriptionCard(subscription, context)),
                            const SizedBox(height: 32),
                          ],
                          
                          // Completed Subscriptions Section
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(24, 95, 45, 1).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline,
                                  color: Color.fromRGBO(24, 95, 45, 1),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Active Subscriptions',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_completedSubscriptions.isEmpty)
                            Card(
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[200]!, width: 1),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No active subscriptions',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Complete a payment to activate your subscription',
                                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ..._completedSubscriptions.map((subscription) => _buildCompletedSubscriptionCard(subscription, context)),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildPendingSubscriptionCard(dynamic subscription, BuildContext context) {
    final packageName = subscription['package']?['name'] ?? 
                       subscription['packageName'] ?? 
                       'Subscription';
    final orderId = subscription['order']?['_id']?.toString() ?? 
                   subscription['orderId']?.toString() ?? 
                   subscription['_id']?.toString();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.pending, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packageName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Payment Pending',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Complete payment to activate your subscription',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: orderId != null
                    ? () {
                        Navigator.pushNamed(context, '/payment/$orderId');
                      }
                    : () {
                        Navigator.pushNamed(context, '/subscription');
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Complete Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedSubscriptionCard(dynamic subscription, BuildContext context) {
    final packageName = subscription['package']?['name'] ?? 
                       subscription['packageName'] ?? 
                       'Subscription';
    final packageType = subscription['package']?['type'] ?? 
                       subscription['packageType'] ?? 
                       'N/A';
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription details coming soon')),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color.fromRGBO(24, 95, 45, 1),
                      const Color.fromRGBO(24, 95, 45, 1).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_membership,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      packageName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.category, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          packageType,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

