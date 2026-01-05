import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class LocationService {
  static const String _locationSetKey = 'location_set';
  static const String _latitudeKey = 'latitude';
  static const String _longitudeKey = 'longitude';
  static const String _addressKey = 'address';
  static const String _userIdKey = 'location_user_id';

  // Check if location has been set
  static Future<bool> isLocationSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationSetKey) ?? false;
  }

  // Get current location with enhanced error handling
  static Future<Map<String, dynamic>?> getCurrentLocation({bool requestPermission = true}) async {
    try {
      // Check permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {
          'error': 'Location services are disabled. Please enable location services in your device settings.',
          'errorType': 'service_disabled',
        };
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {
            'error': 'Location permission denied. Please enable location permissions to use delivery services.',
            'errorType': 'permission_denied',
          };
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {
          'error': 'Location permission permanently denied. Please enable it in app settings.',
          'errorType': 'permission_denied_forever',
        };
      }

      // Get position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Location request timed out', const Duration(seconds: 15));
        },
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      Placemark place = placemarks[0];
      String address = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'.trim();
      if (address.isEmpty || address == ',') {
        address = '${position.latitude}, ${position.longitude}';
      }

      // Save location
      await saveLocation(
        position.latitude,
        position.longitude,
        address,
      );

      // Share location with backend for delivery tracking
      await shareLocationWithBackend(position.latitude, position.longitude, address);

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (e is TimeoutException) {
        return {
          'error': 'Location request timed out. Please try again.',
          'errorType': 'timeout',
        };
      }
      return {
        'error': 'Failed to get location: ${e.toString()}',
        'errorType': 'unknown',
      };
    }
  }

  // Share location with backend for delivery tracking
  static Future<void> shareLocationWithBackend(
    double latitude,
    double longitude,
    String address,
  ) async {
    try {
      final userData = await AuthService.getUserData();
      if (userData == null) return;

      final userId = userData['_id']?.toString() ?? userData['id']?.toString();
      if (userId == null) return;

      final token = await AuthService.getToken();
      
      // Update user location in backend (if endpoint exists)
      // This allows delivery guys to track user location
      // Note: You may need to create this endpoint in your backend
      // For now, we'll save it locally and it can be sent when order is placed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
    } catch (e) {
      // Silently fail - location sharing is not critical
      debugPrint('Failed to share location with backend: $e');
    }
  }

  // Get location for delivery sharing
  static Future<Map<String, dynamic>?> getLocationForDelivery() async {
    final location = await getSavedLocation();
    if (location != null) {
      return {
        ...location,
        'shareable': true,
        'googleMapsUrl': 'https://www.google.com/maps?q=${location['latitude']},${location['longitude']}',
      };
    }
    return null;
  }

  // Save location
  static Future<void> saveLocation(
    double latitude,
    double longitude,
    String address,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationSetKey, true);
    await prefs.setDouble(_latitudeKey, latitude);
    await prefs.setDouble(_longitudeKey, longitude);
    await prefs.setString(_addressKey, address);
  }

  // Get saved location
  static Future<Map<String, dynamic>?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_latitudeKey);
    final longitude = prefs.getDouble(_longitudeKey);
    final address = prefs.getString(_addressKey);

    if (latitude != null && longitude != null && address != null) {
      return {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };
    }

    return null;
  }

  // Clear location
  static Future<void> clearLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_locationSetKey);
    await prefs.remove(_latitudeKey);
    await prefs.remove(_longitudeKey);
    await prefs.remove(_addressKey);
    await prefs.remove(_userIdKey);
  }

  // Stream location updates for real-time tracking
  static Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  final Duration timeout;
  TimeoutException(this.message, this.timeout);
  @override
  String toString() => message;
}
