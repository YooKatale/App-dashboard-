import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'auth_service.dart';
import '../app.dart';

class PushNotificationService {
  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'yookatale_channel';
  static const String _channelName = 'YooKatale Notifications';
  static const String _channelDescription = 'Notifications for orders, offers, and updates';

  // Initialize push notifications - request permissions on first install
  static Future<void> initialize() async {
    // Initialize local notifications plugin
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings = InitializationSettings(android: androidInit);
    await _localNotificationsPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (response) {
      // Handle notification tap from system tray
      try {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          final data = json.decode(payload) as Map<String, dynamic>;
          // Navigate based on data if needed
          MyApp.navigatorKey.currentState?.pushNamed('/schedule');
        }
      } catch (_) {}
    });

    // Create Android notification channel
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

    // Request FCM permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('🔔 FCM Permission: ${settings.authorizationStatus}');
    }

    // Try to obtain token
    try {
      String? token = await messaging.getToken().timeout(const Duration(seconds: 10), onTimeout: () => null);
      if (token != null && token.isNotEmpty) {
        await _saveTokenToServer(token);
      }
    } catch (e) {
      if (kDebugMode) print('FCM token error: $e');
    }

    messaging.onTokenRefresh.listen((newToken) => _saveTokenToServer(newToken));

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // Check initial message
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
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title']?.toString() ?? 'YooKatale';
    final body = notification?.body ?? data['body']?.toString() ?? 'You have a new notification';

    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    try {
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );
      final platformDetails = NotificationDetails(android: androidDetails);
      await _localNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: json.encode(data.isNotEmpty ? data : {'title': title, 'body': body}),
      );
    } catch (e) {
      if (kDebugMode) print('Error showing local notification: $e');
    }

    // Save notification to history
    try {
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

      if (notifications.length > 100) {
        notifications.removeRange(100, notifications.length);
      }

      await prefs.setString('user_notifications', json.encode(notifications));
      final unreadCount = notifications.where((n) => n['read'] != true).length;
      await prefs.setInt('unread_notifications_count', unreadCount);
    } catch (e) {
      if (kDebugMode) print('Error saving foreground notification to history: $e');
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

  // Background message handler - This is registered in main.dart as top-level function
  // This static method is kept for reference but the actual handler is in main.dart
}
