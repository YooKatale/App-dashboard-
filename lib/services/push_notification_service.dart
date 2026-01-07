import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

    if (kDebugMode) {
      print('FCM permission status: ${settings.authorizationStatus}');
    }

    // Try to get FCM token even if permission is not yet fully authorized
    // (provisional or denied might still allow token generation)
    try {
      String? token = await messaging.getToken();
      if (token != null) {
        await _saveTokenToServer(token);
        if (kDebugMode) {
          print('✅ FCM token obtained and saved: ${token.substring(0, 20)}...');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ FCM token is null - permission may be denied');
        }
      }
    } catch (e) {
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
  static void _handleForegroundMessage(RemoteMessage message) {
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
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
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
