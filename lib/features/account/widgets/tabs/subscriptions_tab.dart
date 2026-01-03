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
  List<dynamic> _subscriptions = [];
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
        setState(() {
          _subscriptions = response['data'] is List ? response['data'] : [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _subscriptions = [];
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
            : _subscriptions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.card_membership, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No active subscriptions',
                          style: TextStyle(fontSize: 24, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Navigate to subscription page
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Navigate to subscriptions page')),
                            );
                          },
                          child: const Text('Browse Subscriptions'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadSubscriptions,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _subscriptions.length,
                      itemBuilder: (context, index) {
                        final subscription = _subscriptions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.card_membership, size: 40),
                            title: Text(
                              subscription['package']?['name'] ?? 'Subscription',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Type: ${subscription['package']?['type'] ?? 'N/A'}'),
                                Text(
                                  'Status: ${subscription['status'] ?? 'Active'}',
                                  style: TextStyle(
                                    color: subscription['status'] == 'Active'
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // TODO: Navigate to subscription details
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Subscription details coming soon')),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
  }
}

