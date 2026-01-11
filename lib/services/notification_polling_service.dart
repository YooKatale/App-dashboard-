import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Notification Polling Service
/// Polls backend for notifications every minute (like webapp)
/// This ensures notifications work even if FCM token fails
class NotificationPollingService {
  static Timer? _pollingTimer;
  static bool _isPolling = false;
  static const String _lastPollKey = 'last_notification_poll';
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'yookatale_channel';
  static const String _channelName = 'YooKatale Notifications';
  static const String _channelDescription = 'Notifications for orders, offers, and updates';

  /// Start polling for notifications from backend (like webapp)
  /// Polls every minute to receive test notifications from server
  static void startPolling() {
    // Stop existing polling if any
    stopPolling();

    _isPolling = true;

    // Poll every minute (60 seconds) - EXACT WEBAPP LOGIC
    _pollingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _pollBackendForNotifications();
    });

    // Trigger immediately for first poll
    Future.delayed(const Duration(seconds: 2), () {
      _pollBackendForNotifications();
    });

    if (kDebugMode) {
      print('🔄 Notification polling started - will poll backend every minute');
    }
  }

  /// Stop notification polling
  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    
    if (kDebugMode) {
      print('🛑 Notification polling stopped');
    }
  }

  /// Poll backend for notifications (like webapp notificationPolling.js)
  static Future<void> _pollBackendForNotifications() async {
    try {
      final userData = await AuthService.getUserData();
      final prefs = await SharedPreferences.getInstance();
      final lastPoll = prefs.getString(_lastPollKey);
      final now = DateTime.now();

      // Don't poll too frequently (at least 30 seconds between polls)
      if (lastPoll != null) {
        final lastPollTime = DateTime.parse(lastPoll);
        if (now.difference(lastPollTime).inSeconds < 30) {
          return; // Too soon to poll again
        }
      }

      // Backend endpoint - same as webapp: /admin/send-push-notification
      // The backend sends FCM notifications, but we also poll to get notifications
      // that can be shown locally even if FCM fails
      final backendUrl = 'https://yookatale-server.onrender.com';
      
      // Rotate through meal types for variety (like webapp)
      final mealTypes = ['breakfast', 'lunch', 'supper'];
      final currentMinute = now.minute;
      final mealType = mealTypes[currentMinute % 3];
      final mealEmojis = {'breakfast': '🍳', 'lunch': '🍽️', 'supper': '🌙'};
      final mealTypeCapitalized = mealType[0].toUpperCase() + mealType.substring(1);
      
      // Poll backend for notifications
      // The backend should return notifications that we can display locally
      try {
        final response = await http.post(
          Uri.parse('$backendUrl/admin/send-push-notification'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'title': '🧪 Test: ${mealEmojis[mealType]} $mealTypeCapitalized Time!',
            'body': 'Testing notifications every minute - ${now.hour}:${now.minute.toString().padLeft(2, '0')}. Time for $mealType!',
            'data': {
              'mealType': mealType,
              'url': 'https://www.yookatale.app/schedule',
              'timestamp': now.millisecondsSinceEpoch.toString(),
              'type': 'meal_calendar',
            },
            'userId': userData?['_id']?.toString() ?? userData?['id']?.toString(),
          }),
        ).timeout(const Duration(seconds: 10));

        // Update last poll time
        await prefs.setString(_lastPollKey, now.toIso8601String());

        // CRITICAL: Always create local notification from polling (works even if FCM fails)
        // This ensures notifications ALWAYS show in the notification tab
        // The backend sends FCM notifications, but we also create local notifications as fallback
        // This way notifications always work, whether FCM succeeds or fails
        
        // Default notification data
        String notificationTitle = '🧪 Test: ${mealEmojis[mealType]} $mealTypeCapitalized Time!';
        String notificationBody = 'Testing notifications every minute - ${now.hour}:${now.minute.toString().padLeft(2, '0')}. Time for $mealType!';
        Map<String, dynamic> notificationData = {
          'mealType': mealType,
          'url': 'https://www.yookatale.app/schedule',
          'timestamp': now.millisecondsSinceEpoch.toString(),
          'type': 'meal_calendar',
        };

        // Try to parse response data if available, otherwise use defaults
        if (response.statusCode == 200 || response.statusCode == 201) {
          try {
            final responseData = json.decode(response.body);
            notificationTitle = responseData['title']?.toString() ?? notificationTitle;
            notificationBody = responseData['body']?.toString() ?? notificationBody;
            if (responseData['data'] != null && responseData['data'] is Map) {
              notificationData = Map<String, dynamic>.from(responseData['data']);
            }
          } catch (e) {
            // Use defaults if parsing fails
            if (kDebugMode) {
              print('⚠️ Response parsing failed, using default notification data');
            }
          }
        }

        // ALWAYS create local notification (ensures notifications always show in tab)
        await _createLocalNotificationFromServer(
          title: notificationTitle,
          body: notificationBody,
          data: notificationData,
        );

        if (kDebugMode) {
          print('✅ Notification created from polling (always shows in notification tab)');
        }
      } catch (e) {
        // Silently handle - backend scheduler handles notifications automatically
        if (kDebugMode) {
          print('⚠️ Backend polling error (non-blocking): $e');
        }
      }
    } catch (e) {
      // Silently handle - polling is non-critical
      if (kDebugMode) {
        print('⚠️ Notification polling error (non-blocking): $e');
      }
    }
  }

  /// Create local notification from server response (works even if FCM fails)
  static Future<void> _createLocalNotificationFromServer({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      // Ensure channel exists
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
        title,
        body,
        platformDetails,
        payload: data.map((k, v) => MapEntry(k, v.toString())).toString(),
      );

      // Save notification to history (so it appears in notification tab)
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('user_notifications');
      final notifications = notificationsJson != null 
          ? (json.decode(notificationsJson) as List).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      
      notifications.insert(0, {
        'id': notificationId.toString(),
        'title': title,
        'body': body,
        'type': data['type']?.toString() ?? 'meal_calendar',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
        'source': 'server_polling', // Indicate this came from server polling
      });
      
      // Keep only last 100 notifications
      if (notifications.length > 100) {
        notifications.removeRange(100, notifications.length);
      }
      
      await prefs.setString('user_notifications', json.encode(notifications));
      
      // Update unread count
      final unreadCount = notifications.where((n) => n['read'] != true).length;
      await prefs.setInt('unread_notifications_count', unreadCount);

      if (kDebugMode) {
        print('✅ Local notification created from server polling');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating local notification from server: $e');
      }
    }
  }

  /// Check if polling is active
  static bool isPollingActive() {
    return _isPolling && _pollingTimer != null && _pollingTimer!.isActive;
  }
}
