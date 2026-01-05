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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSubscriptions,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _completedSubscriptions.isEmpty && _pendingSubscriptions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.card_membership, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No subscriptions',
                          style: TextStyle(fontSize: 24, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/subscription');
                          },
                          child: const Text('Browse Subscriptions'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadSubscriptions,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Pending Payments Section
                        if (_pendingSubscriptions.isNotEmpty) ...[
                          const Text(
                            'Pending Payments',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._pendingSubscriptions.map((subscription) => _buildPendingSubscriptionCard(subscription, context)),
                          const SizedBox(height: 24),
                        ],
                        
                        // Completed Subscriptions Section
                        const Text(
                          'Active Subscriptions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_completedSubscriptions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No active subscriptions. Complete a payment to activate your subscription.',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ..._completedSubscriptions.map((subscription) => _buildCompletedSubscriptionCard(subscription, context)),
                      ],
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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.card_membership,
            color: Color.fromRGBO(24, 95, 45, 1),
            size: 28,
          ),
        ),
        title: Text(
          packageName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Type: $packageType'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          // TODO: Navigate to subscription details
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription details coming soon')),
          );
        },
      ),
    );
  }
}

