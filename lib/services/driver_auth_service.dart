import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages driver authentication independently from the general app user session.
/// Uses separate SharedPreferences keys so driver login/logout never affects
/// the main-app user and vice-versa.
class DriverAuthService {
  static const _kToken  = 'driver_token';
  static const _kData   = 'driver_data';
  static const _kId     = 'driver_id';

  // ── Save ─────────────────────────────────────────────────────────────────
  static Future<void> saveSession(String token, Map<String, dynamic> driver) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kData,  jsonEncode(driver));
    await prefs.setString(_kId,    driver['_id']?.toString() ?? driver['id']?.toString() ?? '');
  }

  // ── Read ──────────────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  static Future<String?> getDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kId);
  }

  static Future<Map<String, dynamic>?> getDriverData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kData);
    if (raw == null) return null;
    try { return jsonDecode(raw) as Map<String, dynamic>; } catch (_) { return null; }
  }

  // ── Auth check ────────────────────────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    final id    = await getDriverId();
    return token != null && token.isNotEmpty && id != null && id.isNotEmpty;
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kData);
    await prefs.remove(_kId);
  }
}
