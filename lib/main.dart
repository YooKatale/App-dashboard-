import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      // CRITICAL: Register background message handler FIRST (before initialization)
      // This ensures notifications work when app is closed (like WhatsApp)
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Initialize push notification service
      await PushNotificationService.initialize();
      
      // Initialize local notification service
      await NotificationService.initialize();
      
      // Note: Test notifications are handled by server scheduler
      // The server sends FCM push notifications every minute to all users
      // Mobile app will receive them via FirebaseMessaging.onMessage (foreground)
      // and _firebaseMessagingBackgroundHandler (background/closed)
      if (kDebugMode) {
        print('✅ Push notifications initialized - will receive from server every minute');
        print('✅ FCM token synchronized with webapp endpoint');
        print('✅ Background handler registered - notifications work when app is closed');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Push notification service initialization error (non-blocking): $e');
    }
  }
}

// Background message handler (must be top-level function)
// This handles notifications when app is closed or in background (like WhatsApp)
// CRITICAL: This function MUST be top-level (not a class method) for Flutter to call it
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase (required for background handler)
  await Firebase.initializeApp();
  
  // Initialize Awesome Notifications for background messages
  // This allows notifications to show even when app is completely closed
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
        playSound: true,
        enableVibration: true,
      ),
    ],
  );
  
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
  
  // Create and show notification (works even when app is closed)
  final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: notificationId,
      channelKey: 'yookatale_channel',
      title: title,
      body: body,
      notificationLayout: NotificationLayout.Default,
      payload: {
        'mealType': data['mealType']?.toString() ?? '',
        'url': data['url']?.toString() ?? 'https://www.yookatale.app/schedule',
        'type': data['type']?.toString() ?? 'meal_calendar',
      },
      category: NotificationCategory.Message,
      wakeUpScreen: true, // Wake screen when notification arrives
      criticalAlert: false,
    ),
    actionButtons: [
      NotificationActionButton(
        key: 'VIEW',
        label: 'View Schedule',
      ),
    ],
  );
  
  // IMPORTANT: Save notification to history (so it appears in notification tab)
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
    
    // Keep only last 100 notifications
    if (notifications.length > 100) {
      notifications.removeRange(100, notifications.length);
    }
    
    await prefs.setString('user_notifications', json.encode(notifications));
    
    // Update unread count
    final unreadCount = notifications.where((n) => n['read'] != true).length;
    await prefs.setInt('unread_notifications_count', unreadCount);
  } catch (saveError) {
    if (kDebugMode) {
      print('Error saving background notification to history: $saveError');
    }
  }
  
  // Log for debugging (ALWAYS log in background handler for troubleshooting)
  print('📱 ========================================');
  print('📱 BACKGROUND NOTIFICATION RECEIVED');
  print('📱 App was CLOSED when notification arrived');
  print('📱 Title: $title');
  print('📱 Body: $body');
  print('📱 Message ID: ${message.messageId}');
  print('📱 Data: $data');
  print('📱 Saved to notification history: YES');
  print('📱 ========================================');
}
