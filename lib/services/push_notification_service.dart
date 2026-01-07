import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'auth_service.dart';
import '../app.dart';

class PushNotificationService {
  static FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Initialize push notifications
  static Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      String? token = await messaging.getToken();
      if (token != null) {
        await _saveTokenToServer(token);
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToServer(newToken);
      });

      // Initialize Awesome Notifications
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

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      // Check if app was opened from notification
      RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    }
  }

  // Save FCM token to server - synchronized with webapp endpoint
  static Future<void> _saveTokenToServer(String token) async {
    try {
      final userData = await AuthService.getUserData();
      final authToken = await AuthService.getToken();
      
      // Use same endpoint as webapp: /admin/web_push
      // This ensures notifications are synchronized across web and mobile
      if (userData != null) {
        final userId = userData['_id']?.toString() ?? userData['id']?.toString();
        final email = userData['email']?.toString();
        
        // Save to webapp endpoint for synchronization
        await ApiService.saveFCMTokenToWebapp(
          token: token,
          userId: userId,
          email: email,
        );
      }
    } catch (e) {
      // Handle error silently - token will be retried on next app start
      print('Error saving FCM token: $e');
    }
  }

  // Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'yookatale_channel',
        title: message.notification?.title ?? 'YooKatale',
        body: message.notification?.body ?? '',
        notificationLayout: NotificationLayout.Default,
      ),
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
