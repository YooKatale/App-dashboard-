import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'auth_service.dart';
import '../app.dart';

class PushNotificationService {
  static FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Initialize push notifications - request permissions on first install
  static Future<void> initialize() async {
    // Initialize Awesome Notifications FIRST (required for local notifications)
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'yookatale_channel',
          channelName: 'YooKatale Notifications',
          channelDescription: 'Notifications for orders, offers, and updates',
          defaultColor: const Color(0xFF185F2D),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
      ],
    );

    // Request Awesome Notifications permissions (ALWAYS request on first install)
    bool isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
    if (kDebugMode) {
      print('Awesome Notifications permission: $isAllowed');
    }

    // Request FCM permissions (ALWAYS request on first install)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('🔔 FCM Permission Request Result:');
    print('   Authorization Status: ${settings.authorizationStatus}');
    print('   Alert: ${settings.alert}');
    print('   Badge: ${settings.badge}');
    print('   Sound: ${settings.sound}');
    // Note: provisional property may not be available in all Firebase versions
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ FCM permissions GRANTED');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ FCM permissions PROVISIONAL (limited)');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('❌ FCM permissions DENIED - notifications will NOT work!');
      print('❌ USER MUST GRANT PERMISSIONS IN SETTINGS!');
    } else {
      print('⚠️ FCM permissions UNKNOWN: ${settings.authorizationStatus}');
    }

    // Try to get FCM token even if permission is not yet fully authorized
    // (provisional or denied might still allow token generation)
    try {
      String? token = await messaging.getToken();
      if (token != null) {
        print('📱 FCM Token obtained: ${token.substring(0, 30)}...');
        print('📱 Full token length: ${token.length}');
        await _saveTokenToServer(token);
        if (kDebugMode) {
          print('✅ FCM token obtained and saved: ${token.substring(0, 20)}...');
        }
      } else {
        print('❌ FCM token is NULL - this is the problem!');
        print('❌ Permission status: ${settings.authorizationStatus}');
        if (kDebugMode) {
          print('⚠️ FCM token is null - permission may be denied');
        }
      }
    } catch (e) {
      print('❌ CRITICAL ERROR getting FCM token: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }

    // Listen for token refresh (works even if permission is later granted)
    messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToServer(newToken);
      if (kDebugMode) {
        print('🔄 FCM token refreshed and saved');
      }
    });

    // Handle foreground messages (works when app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Handle background messages (works when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // Check if app was opened from notification
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // Save FCM token to server - synchronized with webapp endpoint
  static Future<void> _saveTokenToServer(String token) async {
    try {
      final userData = await AuthService.getUserData();
      
      // Use same endpoint as webapp: /admin/web_push
      // This ensures notifications are synchronized across web and mobile
      // Save even if user is not logged in (for guest users)
      final userId = userData?['_id']?.toString() ?? userData?['id']?.toString();
      final email = userData?['email']?.toString();
      
      // Always save token - works for registered and non-registered users (like webapp)
      await ApiService.saveFCMTokenToWebapp(
        token: token,
        userId: userId,
        email: email,
      );
      
      if (kDebugMode) {
        print('✅ FCM token saved to server (synchronized with webapp)');
      }
    } catch (e) {
      // Handle error - but don't fail silently, log it
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
      // Retry on next app start
    }
  }

  // Handle foreground messages - synchronized with webapp
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Extract notification data (synchronized with webapp format)
    final notification = message.notification;
    final data = message.data;
    
    // Get title and body from notification or data (webapp sends both)
    final title = notification?.title ?? 
                  data['title']?.toString() ?? 
                  'YooKatale';
    final body = notification?.body ?? 
                 data['body']?.toString() ?? 
                 'You have a new notification';
    
    // Extract meal type and URL for navigation
    final mealType = data['mealType']?.toString();
    final url = data['url']?.toString();
    
    // Create local notification (synchronized with webapp)
    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'yookatale_channel',
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          payload: {
            'mealType': mealType ?? '',
            'url': url ?? 'https://www.yookatale.app/schedule',
            'type': data['type']?.toString() ?? 'meal_calendar',
          },
          category: NotificationCategory.Message,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'VIEW',
            label: 'View Schedule',
          ),
        ],
      );
      print('✅ Local notification created successfully');
    } catch (e) {
      print('❌ Error creating local notification: $e');
    }
    
    // IMPORTANT: Save notification to history (so it appears in notification tab)
    try {
      // Use public method to save notification
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('user_notifications');
      final notifications = notificationsJson != null 
          ? (json.decode(notificationsJson) as List).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      
      notifications.insert(0, {
        'id': message.messageId ?? notificationId.toString(),
        'title': title,
        'body': body,
        'type': data['type']?.toString() ?? 'meal_calendar',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
      });
      
      // Keep only last 100 notifications
      if (notifications.length > 100) {
        notifications.removeRange(100, notifications.length);
      }
      
      await prefs.setString('user_notifications', json.encode(notifications));
      
      // Update unread count
      final unreadCount = notifications.where((n) => n['read'] != true).length;
      await prefs.setInt('unread_notifications_count', unreadCount);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving foreground notification to history: $e');
      }
    }
  }

  // Handle notification tap - navigate to meal calendar for meal notifications
  static void _handleNotificationTap(RemoteMessage message) {
    // Navigate based on notification data
    final data = message.data;
    final mealType = data['mealType']?.toString();
    final url = data['url']?.toString();
    final notificationType = data['type']?.toString();
    
    // Navigate based on notification type
    if (mealType != null || url != null || notificationType == 'meal_calendar') {
      // Navigate to meal calendar/schedule page
      MyApp.navigatorKey.currentState?.pushNamed('/schedule');
    } else if (notificationType == 'order') {
      // Navigate to orders page
      MyApp.navigatorKey.currentState?.pushNamed('/orders');
    } else if (notificationType == 'subscription') {
      // Navigate to subscription page
      MyApp.navigatorKey.currentState?.pushNamed('/subscription');
    } else {
      // Default: navigate to home
      MyApp.navigatorKey.currentState?.pushNamed('/home');
    }
  }

  // Background message handler (must be top-level function)
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Handle background message
  }
}
