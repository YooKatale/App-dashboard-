import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Real-time synchronization service for orders, deliveries, and admin updates
/// Uses Firebase Realtime Database for cross-platform synchronization
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Listen to order status updates in real-time
  Stream<Map<String, dynamic>?> watchOrder(String orderId) {
    return _database.child('orders').child(orderId).onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>,
        );
      }
      return null;
    });
  }

  /// Listen to all user orders in real-time
  Stream<List<Map<String, dynamic>>> watchUserOrders(String userId) {
    return _database.child('user_orders').child(userId).onValue.map((event) {
      if (event.snapshot.value == null) return <Map<String, dynamic>>[];
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries.map((entry) {
        return Map<String, dynamic>.from({
          'id': entry.key,
          ...Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>),
        });
      }).toList();
    });
  }

  /// Listen to delivery partner location updates
  Stream<Map<String, dynamic>?> watchDeliveryLocation(String orderId) {
    return _database.child('orders').child(orderId).child('delivery').onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>,
        );
      }
      return null;
    });
  }

  /// Listen to notifications in real-time
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) {
    return _database.child('notifications').child(userId).onValue.map((event) {
      if (event.snapshot.value == null) return <Map<String, dynamic>>[];
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      // Filter out _unread count
      return data.entries
          .where((entry) => entry.key != '_unread')
          .map((entry) {
            return Map<String, dynamic>.from({
              'id': entry.key,
              ...Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>),
            });
          })
          .toList()
        ..sort((a, b) {
          final aTime = a['timestamp'] ?? 0;
          final bTime = b['timestamp'] ?? 0;
          return bTime.compareTo(aTime);
        });
    });
  }

  /// Get unread notification count
  Stream<int> watchUnreadCount(String userId) {
    return _database.child('notifications').child(userId).child('_unread').onValue.map((event) {
      return event.snapshot.value as int? ?? 0;
    });
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String userId, String notificationId) async {
    try {
      await _database
          .child('notifications')
          .child(userId)
          .child(notificationId)
          .update({'read': true});
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  /// Update delivery partner location
  Future<void> updateDeliveryLocation({
    required String partnerId,
    required double lat,
    required double lng,
    String? address,
    String? orderId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'updatedAt': DateTime.now().toIso8601String(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isOnline': true,
      };

      if (address != null) {
        updates['address'] = address;
      }

      if (orderId != null) {
        updates['orderId'] = orderId;
      }

      await _database.child('delivery_partners').child(partnerId).set(updates);

      if (orderId != null) {
        await _database.child('orders').child(orderId).child('delivery').set({
          'partnerId': partnerId,
          'location': {
            'lat': lat,
            'lng': lng,
            'address': address,
          },
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating delivery location: $e');
      }
    }
  }

  /// Track user activity
  Future<void> trackActivity({
    required String userId,
    required String activityType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _database.child('user_activity').child(userId).child(
        DateTime.now().millisecondsSinceEpoch.toString(),
      ).set({
        'type': activityType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        if (metadata != null) ...metadata,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking activity: $e');
      }
    }
  }

  /// Listen to product inventory updates
  Stream<Map<String, dynamic>?> watchProductInventory(String productId) {
    return _database
        .child('products')
        .child(productId)
        .child('inventory')
        .onValue
        .map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>,
        );
      }
      return null;
    });
  }

  /// Dispose resources
  void dispose() {
    // Firebase Realtime Database automatically handles cleanup
  }
}
