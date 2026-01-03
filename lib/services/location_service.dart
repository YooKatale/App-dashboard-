import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';

class LocationService {
  static const String _locationSetKey = 'location_set';
  static const String _latitudeKey = 'latitude';
  static const String _longitudeKey = 'longitude';
  static const String _addressKey = 'address';

  // Check if location has been set
  static Future<bool> isLocationSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationSetKey) ?? false;
  }

  // Get current location
  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      // Check permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks[0];
      String address = '${place.street}, ${place.locality}, ${place.country}';

      // Save location
      await saveLocation(
        position.latitude,
        position.longitude,
        address,
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
      };
    } catch (e) {
      return null;
    }
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
  }
}
