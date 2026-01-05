import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Service to schedule and send persuasive notifications
class NotificationSchedulerService {
  static Timer? _checkTimer;
  static const String _lastProductCheckKey = 'last_product_check';
  static const String _lastActiveKey = 'last_active_time';
  static const String _persuasiveNotificationSentKey = 'persuasive_notification_sent';

  /// Start checking for new products and inactive users
  static void startPeriodicChecks() {
    // Check every 6 hours
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(hours: 6), (_) {
      _checkForNewProducts();
      _checkForInactiveUsers();
    });

    // Initial check after 1 hour
    Future.delayed(const Duration(hours: 1), () {
      _checkForNewProducts();
      _checkForInactiveUsers();
    });
  }

  /// Stop periodic checks
  static void stopPeriodicChecks() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Check for new products and notify users
  static Future<void> _checkForNewProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getString(_lastProductCheckKey);
      final now = DateTime.now();

      // Check if we've checked recently (within last hour)
      if (lastCheck != null) {
        final lastCheckTime = DateTime.parse(lastCheck);
        if (now.difference(lastCheckTime).inHours < 1) {
          return; // Too soon to check again
        }
      }

      // Fetch products
      final response = await ApiService.fetchProducts();
      if (response['status'] == 'Success' && response['data'] != null) {
        final products = response['data'] is List ? response['data'] : [];
        
        // Get user's last seen products (stored locally)
        final lastSeenProductIds = prefs.getStringList('last_seen_product_ids') ?? [];
        final currentProductIds = products
            .map((p) => p['_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();

        // Find new products
        final newProducts = products.where((p) {
          final id = p['_id']?.toString() ?? '';
          return id.isNotEmpty && !lastSeenProductIds.contains(id);
        }).toList();

        if (newProducts.isNotEmpty && newProducts.length <= 10) {
          // Notify about new products
          final productNames = newProducts
              .map((p) => p['name']?.toString() ?? 'Product')
              .toList();
          
          await NotificationService.notifyNewProducts(
            productCount: newProducts.length,
            productNames: productNames,
          );

          // Update last seen products
          await prefs.setStringList('last_seen_product_ids', currentProductIds);
        }

        // Update last check time
        await prefs.setString(_lastProductCheckKey, now.toIso8601String());
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Check for inactive users and send persuasive notifications
  static Future<void> _checkForInactiveUsers() async {
    try {
      final userData = await AuthService.getUserData();
      if (userData == null) return;

      final prefs = await SharedPreferences.getInstance();
      final lastActive = prefs.getString(_lastActiveKey);
      final lastPersuasiveSent = prefs.getString(_persuasiveNotificationSentKey);
      final now = DateTime.now();

      // Update last active time
      await prefs.setString(_lastActiveKey, now.toIso8601String());

      // Check if user has been inactive for more than 3 days
      if (lastActive != null) {
        final lastActiveTime = DateTime.parse(lastActive);
        final daysInactive = now.difference(lastActiveTime).inDays;

        // Only send persuasive notification if:
        // 1. User has been inactive for 3+ days
        // 2. We haven't sent one in the last 7 days
        if (daysInactive >= 3) {
          bool shouldSend = true;
          if (lastPersuasiveSent != null) {
            final lastSentTime = DateTime.parse(lastPersuasiveSent);
            if (now.difference(lastSentTime).inDays < 7) {
              shouldSend = false;
            }
          }

          if (shouldSend) {
            await NotificationService.notifyInactiveUser();
            await prefs.setString(_persuasiveNotificationSentKey, now.toIso8601String());
          }
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Update user's last active time (call this when user opens app or performs actions)
  static Future<void> updateLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());
  }
}
