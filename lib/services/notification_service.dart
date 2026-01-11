import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Comprehensive notification service with sync across devices
class NotificationService {
  static const String _notificationsKey = 'user_notifications';
  static const String _unreadCountKey = 'unread_notifications_count';
  static const String _lastSyncKey = 'last_notification_sync';
  
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'yookatale_channel';
  static const String _channelName = 'YooKatale Notifications';
  static const String _channelDescription = 'Notifications for orders, offers, and updates';
  
  // Test notification timer
  static Timer? _testNotificationTimer;
  static int _testNotificationCount = 0;

  /// Initialize notification service
  static Future<void> initialize() async {
    try {
      // Request notification permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token and save to server
        String? token = await _messaging.getToken();
        if (token != null) {
          await _saveTokenToServer(token);
        }


        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _saveTokenToServer(newToken);
        });

        // Initialize local notifications plugin and channel - Use YooKatale logo (ic_launcher is already logo1)
        const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
        final InitializationSettings initSettings = InitializationSettings(android: androidInit);
        await _localNotificationsPlugin.initialize(initSettings);
        final androidPlugin = _localNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          const AndroidNotificationChannel channel = AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.max,
          );
          await androidPlugin.createNotificationChannel(channel);
        }

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _handleForegroundMessage(message);
        });

        // Handle background messages when app is opened
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleNotificationTap(message);
        });

        // Check if app was opened from notification
        RemoteMessage? initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }

        // Sync notifications from server
        await syncNotificationsFromServer();

        // Start test notification scheduler (for emulator testing - every minute)
        // This sends notifications every minute that appear in the notification tab
        startTestNotifications();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Notification service initialization error: $e');
      }
    }
  }


  /// Save FCM token to server for cross-device sync
  static Future<void> _saveTokenToServer(String token) async {
    try {
      final userData = await AuthService.getUserData();
      final authToken = await AuthService.getToken();
      
      if (userData != null && authToken != null) {
        await ApiService.updateFCMToken(token, authToken);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
    }
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? 'YooKatale';
    final body = notification?.body ?? '';

    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    try {
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher', // Use YooKatale logo (set as launcher icon - logo1)
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), // Large icon for rich notifications
      );
      final platformDetails = NotificationDetails(android: androidDetails);
      _localNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: data.isNotEmpty ? json.encode(data) : null,
      );
    } catch (e) {
      if (kDebugMode) print('Error showing local notification: $e');
    }

    // Save notification locally
    _saveNotificationLocally({
      'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'type': data['type'] ?? 'general',
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
    });
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    // Mark as read
    if (message.messageId != null) {
      markAsRead(message.messageId!);
    }

    // Navigate based on notification type
    // This will be handled by the app router
  }

  /// Sync notifications from server (when user logs in from any device)
  static Future<void> syncNotificationsFromServer() async {
    try {
      final userData = await AuthService.getUserData();
      final token = await AuthService.getToken();
      
      if (userData == null || token == null) return;

      // Fetch notifications from server
      try {
        final response = await ApiService.fetchNotifications(token: token);

        if (response['status'] == 'Success' && response['data'] != null) {
          final notifications = response['data'] is List ? response['data'] : [];
          
          // Save notifications locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_notificationsKey, json.encode(notifications));
          await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
          
          // Update unread count
          final unreadCount = notifications.where((n) => n['read'] != true).length;
          await prefs.setInt(_unreadCountKey, unreadCount);
        }
      } catch (e) {
        // API endpoint might not exist yet, continue silently
        if (kDebugMode) {
          print('Notifications API not available: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing notifications: $e');
      }
    }
  }

  /// Get all notifications
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_notificationsKey);
      
      if (notificationsJson != null) {
        final List<dynamic> notifications = json.decode(notificationsJson);
        return notifications.map((n) => n as Map<String, dynamic>).toList()
          ..sort((a, b) {
            final aTime = DateTime.parse(a['timestamp'] ?? DateTime.now().toIso8601String());
            final bTime = DateTime.parse(b['timestamp'] ?? DateTime.now().toIso8601String());
            return bTime.compareTo(aTime); // Newest first
          });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notifications: $e');
      }
    }
    return [];
  }

  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_unreadCountKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final notifications = await getNotifications();
      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      
      if (index != -1) {
        notifications[index]['read'] = true;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_notificationsKey, json.encode(notifications));
        
        // Update unread count
        final unreadCount = notifications.where((n) => n['read'] != true).length;
        await prefs.setInt(_unreadCountKey, unreadCount);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  /// Mark all as read
  static Future<void> markAllAsRead() async {
    try {
      final notifications = await getNotifications();
      for (var notification in notifications) {
        notification['read'] = true;
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notificationsKey, json.encode(notifications));
      await prefs.setInt(_unreadCountKey, 0);
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all as read: $e');
      }
    }
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final notifications = await getNotifications();
      notifications.removeWhere((n) => n['id'] == notificationId);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notificationsKey, json.encode(notifications));
      
      // Update unread count
      final unreadCount = notifications.where((n) => n['read'] != true).length;
      await prefs.setInt(_unreadCountKey, unreadCount);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
    }
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
      await prefs.setInt(_unreadCountKey, 0);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing notifications: $e');
      }
    }
  }

  /// Save notification locally
  static Future<void> _saveNotificationLocally(Map<String, dynamic> notification) async {
    try {
      final notifications = await getNotifications();
      notifications.insert(0, notification);
      
      // Keep only last 100 notifications
      if (notifications.length > 100) {
        notifications.removeRange(100, notifications.length);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notificationsKey, json.encode(notifications));
      
      // Update unread count
      final unreadCount = notifications.where((n) => n['read'] != true).length;
      await prefs.setInt(_unreadCountKey, unreadCount);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving notification locally: $e');
      }
    }
  }

  /// Send notification for payment completion
  static Future<void> notifyPaymentCompleted({
    required String orderId,
    required double amount,
  }) async {
    await _createNotification(
      title: 'Payment Successful! 🎉',
      body: 'Your payment of UGX ${_formatAmount(amount)} has been completed successfully.',
      type: 'payment',
      data: {'orderId': orderId, 'amount': amount},
    );
  }

  /// Send notification for subscription completion
  static Future<void> notifySubscriptionCompleted({
    required String subscriptionId,
    required String packageName,
  }) async {
    await _createNotification(
      title: 'Subscription Activated! ✨',
      body: 'Your $packageName subscription is now active. Enjoy your meals!',
      type: 'subscription',
      data: {'subscriptionId': subscriptionId, 'packageName': packageName},
    );
  }

  /// Send notification for meal calendar
  static Future<void> notifyMealCalendar({
    required String mealType,
    required String mealName,
    required DateTime scheduledTime,
  }) async {
    await _createNotification(
      title: 'Meal Time! 🍽️',
      body: 'Your $mealType ($mealName) is scheduled for ${_formatTime(scheduledTime)}',
      type: 'meal_calendar',
      data: {
        'mealType': mealType,
        'mealName': mealName,
        'scheduledTime': scheduledTime.toIso8601String(),
      },
    );
  }

  /// Send notification for new products
  static Future<void> notifyNewProducts({
    required int productCount,
    required List<String> productNames,
  }) async {
    final productList = productNames.take(3).join(', ');
    final moreText = productNames.length > 3 ? ' and ${productNames.length - 3} more' : '';
    
    await _createNotification(
      title: 'New Products Available! 🛒',
      body: '$productList$moreText are now available. Check them out!',
      type: 'new_products',
      data: {'productCount': productCount, 'productNames': productNames},
    );
  }

  /// Send persuasive notification for inactive users
  static Future<void> notifyInactiveUser() async {
    await _createNotification(
      title: 'We Miss You! 👋',
      body: 'Haven\'t seen you in a while. Check out our latest deals and fresh products!',
      type: 'persuasive',
      data: {'action': 'browse_products'},
    );
  }

  /// Create notification (public method for creating notifications programmatically)
  static Future<void> createNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await _createNotification(
      title: title,
      body: body,
      type: type,
      data: data,
    );
  }

  /// Create notification (internal method)
  static Future<void> _createNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Create local notification using flutter_local_notifications
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher', // Use YooKatale logo (set as launcher icon - logo1)
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), // Large icon
      );
      final platformDetails = NotificationDetails(android: androidDetails);
      await _localNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: data != null ? json.encode(data) : null,
      );

      // Save notification locally
      await _saveNotificationLocally({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error creating notification: $e');
      }
    }
  }

  static String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Start test notifications (sends every minute)
  /// For testing purposes only
  static void startTestNotifications() {
    // Cancel any existing timer
    stopTestNotifications();
    
    _testNotificationCount = 0;
    
    // Send first notification immediately
    _sendTestNotification();
    
    // Then send every minute
    _testNotificationTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _sendTestNotification();
    });
    
    if (kDebugMode) {
      print('🧪 Test notifications started - sending every minute');
    }
  }

  /// Stop test notifications
  static void stopTestNotifications() {
    _testNotificationTimer?.cancel();
    _testNotificationTimer = null;
    if (kDebugMode) {
      print('🛑 Test notifications stopped');
    }
  }

  /// Send a test notification
  static Future<void> _sendTestNotification() async {
    _testNotificationCount++;
    final now = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    
    // Rotate through meal types for variety
    final mealTypes = ['breakfast', 'lunch', 'supper'];
    final mealType = mealTypes[_testNotificationCount % 3];
    final mealEmojis = {'breakfast': '🍳', 'lunch': '🍽️', 'supper': '🌙'};
    
    await _createNotification(
      title: '🧪 Test: ${mealEmojis[mealType]} ${mealType.toUpperCase()} Time!',
      body: 'Test notification #$_testNotificationCount at $timeString. This is a $mealType reminder notification.',
      type: 'meal_calendar',
      data: {
        'mealType': mealType,
        'testMode': true,
        'count': _testNotificationCount,
        'timestamp': now.toIso8601String(),
      },
    );
    
    if (kDebugMode) {
      print('🧪 Test notification #$_testNotificationCount sent at $timeString');
    }
  }

  /// Check if test notifications are running
  static bool isTestNotificationsRunning() {
    return _testNotificationTimer != null && _testNotificationTimer!.isActive;
  }
}
