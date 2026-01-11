import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/app.dart';
import 'services/push_notification_service.dart';
import 'services/notification_service.dart';
import 'services/notification_polling_service.dart';
import 'backend/notifications.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

FirebaseAnalytics? analytics;
FirebaseAnalyticsObserver? observer;

late final FirebaseApp app;
late final FirebaseAuth? auth;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await preInitialize();

  runApp(const ProviderScope(child: MyApp()));
}

Future preInitialize() async {
  try {
    app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    auth = FirebaseAuth.instanceFor(app: app);
    analytics = FirebaseAnalytics.instance;
    observer = FirebaseAnalyticsObserver(analytics: analytics!);
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization error: $e');
    }
    // Continue even if Firebase initialization fails
  }

  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    // Default settings
    // await remoteConfig.setDefaults(const {
    //   "sitewide_discount": 10,
    //   "first_purchase_discount": 20,
    //   "referral_bonus": 5
    // });

    // Fetch and activate the remote settings - wrapped in try-catch to prevent blocking
    try {
      await remoteConfig.fetchAndActivate();
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Remote Config fetch error (non-blocking): $e');
      }
      // Set defaults if fetch fails
      await remoteConfig.setDefaults(const {
        "sitewide_discount": 10,
        "first_purchase_discount": 20,
        "referral_bonus": 5
      });
    }

    // Listen to real time update on remote config
    if (!kIsWeb) {
      remoteConfig.onConfigUpdated.listen((event) async {
        try {
          await remoteConfig.activate();
        } catch (e) {
          if (kDebugMode) {
            print('Remote Config activate error: $e');
          }
        }
      });
    }
  } catch (e) {
    if (kDebugMode) {
      print('Firebase Remote Config setup error (non-blocking): $e');
    }
  }

  // Local notification initialization handled in services using flutter_local_notifications

  try {
    // Initialize push notifications (Firebase Cloud Messaging)
    if (!kIsWeb) {
      // CRITICAL: Register background message handler FIRST (before initialization)
      // This ensures notifications work when app is closed (like WhatsApp)
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Initialize push notification service
      await PushNotificationService.initialize();
      
      // Initialize local notification service
      await NotificationService.initialize();
      
      // CRITICAL: Start notification polling service (like webapp does)
      // This ensures notifications work even if FCM token fails
      // Polls backend every minute to receive notifications from server
      NotificationPollingService.startPolling();
      
      // Note: Notifications are handled by both:
      // 1. FCM push notifications (if FCM token works) - sent by backend scheduler
      // 2. Polling service (fallback) - polls backend every minute like webapp
      // Both methods ensure notifications work even if one fails
      if (kDebugMode) {
        print('✅ Push notifications initialized - will receive from server every minute');
        print('✅ FCM token synchronized with webapp endpoint (if token obtained)');
        print('✅ Background handler registered - notifications work when app is closed');
        print('✅ Notification polling started - will poll backend every minute (like webapp)');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Push notification service initialization error (non-blocking): $e');
    }
  }
}

// Background message handler (must be top-level function)
// When app is terminated, system notifications will be shown if backend sends
// a notification payload. Here we persist message history for sync.
// CRITICAL: This handler runs when app is closed (like WhatsApp notifications)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final notification = message.notification;
  final data = message.data;

  final title = notification?.title ?? data['title']?.toString() ?? 'YooKatale';
  final body = notification?.body ?? data['body']?.toString() ?? 'You have a new notification';

  // IMPORTANT: If backend sends notification payload, Android automatically shows system notification
  // If backend sends only data payload, we need to show local notification
  // For now, backend should send proper notification payload for system notifications to appear
  
  try {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString('user_notifications');
    final notifications = notificationsJson != null
        ? (json.decode(notificationsJson) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    notifications.insert(0, {
      'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
    if (kDebugMode) print('Error saving background notification: $e');
  }

  if (kDebugMode) {
    print('📱 BACKGROUND NOTIFICATION (app closed) - saved to history: $title | $body');
    print('📱 System notification will show automatically if backend sends notification payload');
  }
}
