import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://yookatale-server.onrender.com/api';
  
  // Save user token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  // Get user token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Save user data
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(userData));
  }
  
  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return json.decode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }
  
  // Clear user data (logout)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }
  
  // Login with email and password
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Save token FIRST (like webapp saves to localStorage)
        if (data['token'] != null) {
          await saveToken(data['token'] as String);
        }
        
        // Handle different response structures (like webapp saves { ...res } to localStorage)
        // The webapp does: dispatch(setCredentials({ ...res })) - saves entire response
        Map<String, dynamic>? userDataToSave;
        
        // Try response['user'] first (most common structure)
        if (data['user'] != null && data['user'] is Map) {
          userDataToSave = data['user'] as Map<String, dynamic>;
          // Also include token in user data for consistency
          if (data['token'] != null) {
            userDataToSave!['token'] = data['token'];
          }
        } 
        // Try response['data']
        else if (data['data'] != null) {
          if (data['data'] is Map<String, dynamic>) {
            userDataToSave = data['data'] as Map<String, dynamic>;
            // Check if it has user nested
            if (userDataToSave.containsKey('user') && userDataToSave['user'] is Map) {
              userDataToSave = userDataToSave['user'] as Map<String, dynamic>;
            }
            // Include token
            if (data['token'] != null) {
              userDataToSave!['token'] = data['token'];
            }
          }
        }
        // Response might be the user data itself (check for common user fields)
        else if (data['_id'] != null || data['id'] != null || data['email'] != null) {
          userDataToSave = Map<String, dynamic>.from(data);
        }
        
        // Save user data (like webapp saves entire response to localStorage)
        // ALWAYS save something - even if it's the entire response
        if (userDataToSave != null && userDataToSave.isNotEmpty) {
          await saveUserData(userDataToSave);
        } else if (data.isNotEmpty) {
          // Save entire response if no user data found (like webapp saves { ...res })
          await saveUserData(data);
        }
        
        // Ensure data is persisted
        await Future.delayed(const Duration(milliseconds: 100));
        
        return data;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Error logging in: $e');
    }
  }
  
  // Register new user
  static Future<Map<String, dynamic>> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    String? phone,
    String? gender,
    String? dob,
    String? address,
    bool vegan = false,
    String? referenceCode,
    Map<String, bool>? notificationPreferences,
  }) async {
    try {
      final body = <String, dynamic>{
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
        if (gender != null) 'gender': gender,
        if (dob != null) 'dob': dob,
        if (address != null) 'address': address,
        'vegan': vegan,
        if (referenceCode != null) 'referenceCode': referenceCode,
        if (notificationPreferences != null) 
          'notificationPreferences': notificationPreferences,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Save token and user data
        if (data['token'] != null) {
          await saveToken(data['token'] as String);
        }
        if (data['user'] != null || data['data'] != null) {
          await saveUserData(data['user'] ?? data['data'] ?? {});
        }
        
        return data;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Error registering: $e');
    }
  }
  
  // Login with phone number (OTP verification)
  static Future<Map<String, dynamic>> loginWithPhone({
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/phone/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Phone login failed');
      }
    } catch (e) {
      throw Exception('Error with phone login: $e');
    }
  }
  
  // Verify OTP
  static Future<Map<String, dynamic>> verifyOTP({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/phone/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'phone': phone,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Save token and user data
        if (data['token'] != null) {
          await saveToken(data['token'] as String);
        }
        if (data['user'] != null || data['data'] != null) {
          await saveUserData(data['user'] ?? data['data'] ?? {});
        }
        
        return data;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'OTP verification failed');
      }
    } catch (e) {
      throw Exception('Error verifying OTP: $e');
    }
  }
}
