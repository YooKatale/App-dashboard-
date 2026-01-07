import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import '/app.dart';
import 'services/push_notification_service.dart';
import 'services/notification_service.dart';
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

  try {
    // Initialize local notifications (Awesome Notifications)
    await NotificationServices.initializeLocalNotifications();
    await NotificationServices.startListeningNotificationEvents();
  } catch (e) {
    if (kDebugMode) {
      print('Notification services initialization error (non-blocking): $e');
    }
  }

  try {
    // Initialize push notifications (Firebase Cloud Messaging)
    if (!kIsWeb) {
      await PushNotificationService.initialize();
      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      // Initialize notification service
      await NotificationService.initialize();
      
      // Note: Test notifications are handled by server scheduler
      // The server sends FCM push notifications every minute to all users
      // Mobile app will receive them via FirebaseMessaging.onMessage
      // No need for local test notifications - server handles it
      if (kDebugMode) {
        print('✅ Push notifications initialized - will receive from server every minute');
        print('✅ FCM token synchronized with webapp endpoint');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Push notification service initialization error (non-blocking): $e');
    }
  }
}

// Background message handler (must be top-level function)
// This handles notifications when app is closed or in background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  // Initialize Awesome Notifications for background messages
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
  
  // Show notification when app is in background
  final notification = message.notification;
  final data = message.data;
  
  if (notification != null || data.isNotEmpty) {
    final title = notification?.title ?? data['title']?.toString() ?? 'YooKatale';
    final body = notification?.body ?? data['body']?.toString() ?? 'You have a new notification';
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'yookatale_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        payload: {
          'mealType': data['mealType']?.toString() ?? '',
          'url': data['url']?.toString() ?? 'https://www.yookatale.app/schedule',
          'type': data['type']?.toString() ?? 'meal_calendar',
        },
      ),
    );
  }
}
