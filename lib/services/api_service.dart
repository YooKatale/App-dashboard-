import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Backend API base URL - update this with your production URL
  static const String baseUrl = 'https://yookatale-server.onrender.com/api';
  
  // For local development, use: 'http://localhost:8000/api'
  // static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000/api'; // iOS simulator

  // Headers for API requests
  static Map<String, String> getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Fetch all products
  static Future<Map<String, dynamic>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  // Fetch single product by ID
  static Future<Map<String, dynamic>> fetchProductById(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/product/$productId'),
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  // Fetch products by category
  static Future<Map<String, dynamic>> fetchProductsByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$category'),
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load products by category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products by category: $e');
    }
  }

  // Fetch product comments and ratings
  static Future<Map<String, dynamic>> fetchProductComments(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId/comments'),
        headers: getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching comments: $e');
    }
  }

  // Create product comment with rating
  static Future<Map<String, dynamic>> createProductComment({
    required String productId,
    required int rating,
    required String comment,
    String? userId,
    String? userName,
    String? userEmail,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/comment'),
        headers: getHeaders(token: token),
        body: json.encode({
          'productId': productId,
          'rating': rating,
          'comment': comment,
          'userId': userId,
          'userName': userName,
          'userEmail': userEmail,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to create comment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating comment: $e');
    }
  }

  // Platform feedback
  static Future<Map<String, dynamic>> createPlatformFeedback({
    required int rating,
    String? feedback,
    required String platform,
    String? userId,
    String? userEmail,
    String? userName,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ratings/platform'),
        headers: getHeaders(token: token),
        body: json.encode({
          'rating': rating,
          'feedback': feedback,
          'platform': platform,
          'userId': userId,
          'userEmail': userEmail,
          'userName': userName,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to submit feedback: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting feedback: $e');
    }
  }

  // App rating (for App Store/Play Store)
  static Future<Map<String, dynamic>> createAppRating({
    required int rating,
    required String platform,
    bool redirectedToStore = false,
    String? userId,
    String? userEmail,
    String? userName,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ratings/app'),
        headers: getHeaders(token: token),
        body: json.encode({
          'rating': rating,
          'platform': platform,
          'redirectedToStore': redirectedToStore,
          'userId': userId,
          'userEmail': userEmail,
          'userName': userName,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to submit rating: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting rating: $e');
    }
  }

  // User login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: getHeaders(),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Login failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error logging in: $e');
    }
  }

  // User registration
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? firstname,
    String? lastname,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: getHeaders(),
        body: json.encode({
          'email': email,
          'password': password,
          'firstname': firstname,
          'lastname': lastname,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error registering: $e');
    }
  }
}

