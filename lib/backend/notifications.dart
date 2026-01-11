import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app.dart';
import '../widgets/notification_widget.dart';

class NotificationServices {
  static NotificationResponse? initialAction;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'alerts';
  static const String _channelName = 'YooKatale Notifications';
  static const String _channelDescription = 'YooKatale meal reminders and updates';

  static Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings = InitializationSettings(android: androidInit);

    await _localNotificationsPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (response) {
      // Handle taps from system tray
      onActionReceivedMethod(response);
    });

    // Create channel on Android
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

    // Initial notification response (if app opened from a notification)
    // Note: flutter_local_notifications provides getNotificationAppLaunchDetails for initial payload
    try {
      final details = await _localNotificationsPlugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        // Use the notificationResponse provided by the plugin if available
        initialAction = details?.notificationResponse;
      }
    } catch (_) {}
  }

  static Future<void> startListeningNotificationEvents() async {
    // Listener set during initialization via onDidReceiveNotificationResponse
  }

  static Future<void> onActionReceivedMethod(NotificationResponse? response) async {
    if (response == null) return;
    // Navigate to notifications page
    MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/notification-page',
      (route) => (route.settings.name != '/notification-page') || route.isFirst,
      arguments: response,
    );
  }

  static Future<bool> displayNotificationRationale() async {
    bool userAuthorized = false;
    BuildContext context = MyApp.navigatorKey.currentContext!;
    await showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return CustomAlertDialog(
          onDeny: () {
            Navigator.of(ctx).pop();
          },
          onAllow: () async {
            userAuthorized = true;
            Navigator.of(ctx).pop();
          },
        );
      },
    );
    return userAuthorized;
  }

  static Future<void> executeLongTaskInBackground() async {
    if (kDebugMode) {
      print("starting long task");
    }
    await Future.delayed(const Duration(seconds: 4));
    final url = Uri.parse("http://google.com");
    final re = await http.get(url);
    if (kDebugMode) {
      print(re.body);
    }
    if (kDebugMode) {
      print("long task done");
    }
  }

  static Future<void> createNewNotification() async {
    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );
    final platformDetails = NotificationDetails(android: androidDetails);
    await _localNotificationsPlugin.show(
      notificationId,
      'Huston! The eagle has landed!',
      "A small step for a man, but a giant leap to Flutter's community!",
      platformDetails,
      payload: json.encode({'notificationId': '1234567890'}),
    );
  }

  static Future<void> scheduleNewNotification() async {
    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );
    final platformDetails = NotificationDetails(android: androidDetails);

    // Fallback schedule implementation: trigger after 10s using a delayed Future
    Future.delayed(const Duration(seconds: 10), () async {
      await _localNotificationsPlugin.show(
        notificationId,
        "Huston! The eagle has landed!",
        "A small step for a man, but a giant leap to Flutter's community!",
        platformDetails,
        payload: json.encode({'notificationId': '1234567890'}),
      );
    });
  }

  static Future<void> resetBadgeCounter() async {
    // flutter_local_notifications does not directly manage badges across OEMs; cancel all as fallback
    await _localNotificationsPlugin.cancelAll();
  }

  static Future<void> cancelNotifications() async {
    await _localNotificationsPlugin.cancelAll();
  }
}
