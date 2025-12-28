import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

/// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Handling background message: ${message.messageId}');
  log('Notification title: ${message.notification?.title}');
  log('Notification body: ${message.notification?.body}');
  log('Data: ${message.data}');
  
  // Show notification using Awesome Notifications for background
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: message.hashCode,
      channelKey: 'alerts',
      title: message.notification?.title ?? 'YooKatale',
      body: message.notification?.body ?? 'You have a new notification',
      bigPicture: message.notification?.android?.imageUrl,
      notificationLayout: message.notification?.android?.imageUrl != null
          ? NotificationLayout.BigPicture
          : NotificationLayout.Default,
      payload: message.data,
    ),
  );
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  /// Initialize push notifications
  static Future<void> initialize() async {
    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      log('User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        log('User granted provisional notification permission');
      } else {
        log('User declined or has not accepted notification permission');
        return;
      }

      // Get FCM token
      await getFCMToken();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (when app is in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle notification when app is opened from terminated state
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      log('Push notification service initialized successfully');
    } catch (e) {
      log('Error initializing push notifications: $e');
    }
  }

  /// Get FCM token
  static Future<String?> getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      log('FCM Token: $_fcmToken');
      
      // Token refresh listener
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        log('FCM Token refreshed: $newToken');
        // TODO: Send token to your backend server
      });

      return _fcmToken;
    } catch (e) {
      log('Error getting FCM token: $e');
      return null;
    }
  }

  /// Handle foreground messages (when app is open)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    log('Received foreground message: ${message.messageId}');
    log('Notification title: ${message.notification?.title}');
    log('Notification body: ${message.notification?.body}');
    log('Data: ${message.data}');

    // Show notification using Awesome Notifications for foreground
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: message.hashCode,
        channelKey: 'alerts',
        title: message.notification?.title ?? 'YooKatale',
        body: message.notification?.body ?? 'You have a new notification',
        bigPicture: message.notification?.android?.imageUrl ??
            message.notification?.apple?.imageUrl,
        notificationLayout: (message.notification?.android?.imageUrl != null ||
                message.notification?.apple?.imageUrl != null)
            ? NotificationLayout.BigPicture
            : NotificationLayout.Default,
        payload: message.data,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'OPEN',
          label: 'Open',
        ),
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Dismiss',
          actionType: ActionType.DismissAction,
        ),
      ],
    );
  }

  /// Handle message when app is opened from notification
  static void _handleMessageOpenedApp(RemoteMessage message) {
    log('Message opened app: ${message.messageId}');
    log('Notification title: ${message.notification?.title}');
    log('Notification body: ${message.notification?.body}');
    log('Data: ${message.data}');

    // Handle navigation based on message data
    // Example: Navigate to a specific screen based on message.data
    if (message.data.containsKey('screen')) {
      String screen = message.data['screen'];
      // TODO: Navigate to specific screen
      log('Navigate to screen: $screen');
    }
  }

  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      log('Subscribed to topic: $topic');
    } catch (e) {
      log('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      log('Unsubscribed from topic: $topic');
    } catch (e) {
      log('Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      log('FCM token deleted');
    } catch (e) {
      log('Error deleting FCM token: $e');
    }
  }
}

