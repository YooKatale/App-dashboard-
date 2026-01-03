import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

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

  // Cart operations
  static Future<Map<String, dynamic>> fetchCart(String userId, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/product/cart/$userId'),
        headers: getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching cart: $e');
    }
  }

  static Future<Map<String, dynamic>> addToCart({
    required String userId,
    required String productId,
    required int quantity,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/product/cart'),
        headers: getHeaders(token: token),
        body: json.encode({
          'userId': userId,
          'productId': productId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to add to cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding to cart: $e');
    }
  }

  static Future<Map<String, dynamic>> updateCartItem({
    required String cartId,
    required int quantity,
    String? token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/product/cart/$cartId'),
        headers: getHeaders(token: token),
        body: json.encode({
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to update cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating cart: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteCartItem(String cartId, {String? token}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/product/cart/$cartId'),
        headers: getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to delete cart item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting cart item: $e');
    }
  }

  // Subscription operations
  static Future<Map<String, dynamic>> fetchSubscriptionPackages({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscription/package/get'),
        headers: getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load subscription packages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching subscription packages: $e');
    }
  }

  static Future<Map<String, dynamic>> createSubscription({
    required String userId,
    required String packageId,
    String? token,
  }) async {
    try {
      // EXACT WEBAPP LOGIC: Webapp sends { user: userInfo._id, packageId: ID }
      final response = await http.post(
        Uri.parse('$baseUrl/subscription'),
        headers: getHeaders(token: token),
        body: json.encode({
          'user': userId, // Webapp uses 'user' not 'userId'
          'packageId': packageId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to create subscription: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating subscription: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchUserSubscriptions(String userId, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/user/$userId'),
        headers: getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load subscriptions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching subscriptions: $e');
    }
  }

  // Schedule operations
  static Future<Map<String, dynamic>> createSchedule({
    required Map<String, dynamic> scheduleData,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/schedules'),
        headers: getHeaders(token: token),
        body: json.encode(scheduleData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to create schedule: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating schedule: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchUserSchedules(String userId, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schedules/user/$userId'),
        headers: getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load schedules: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching schedules: $e');
    }
  }

  // Orders
  static Future<Map<String, dynamic>> fetchUserOrders(String userId, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/user/$userId'),
        headers: getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? address,
    String? token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: getHeaders(token: token),
        body: json.encode({
          'firstname': firstName,
          'lastname': lastName,
          'email': email,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: getHeaders(token: token),
        body: json.encode({
          'userId': userId,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to change password: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error changing password: $e');
    }
  }

  // Fetch service comments/ratings
  static Future<Map<String, dynamic>> fetchServiceComments({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comments'),
        headers: getHeaders(token: token),
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

  // Create service comment/rating
  static Future<Map<String, dynamic>> createServiceComment({
    required String name,
    required String message,
    int? rating,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comments'),
        headers: getHeaders(token: token),
        body: json.encode({
          'name': name,
          'message': message,
          if (rating != null) 'rating': rating,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to submit comment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting comment: $e');
    }
  }

  // Update FCM token
  static Future<void> updateFCMToken(String token, String authToken) async {
    try {
      final userData = await AuthService.getUserData();
      if (userData == null) return;

      final userId = userData['_id']?.toString() ?? userData['id']?.toString();
      if (userId == null) return;

      await http.post(
        Uri.parse('$baseUrl/users/fcm-token'),
        headers: getHeaders(token: authToken),
        body: json.encode({
          'userId': userId,
          'fcmToken': token,
        }),
      );
    } catch (e) {
      // Handle error silently
    }
  }

  // Fetch wishlist
  static Future<Map<String, dynamic>> fetchWishlist({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wishlist'),
        headers: getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load wishlist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching wishlist: $e');
    }
  }

  // Add to wishlist
  static Future<bool> addToWishlist({
    required String userId,
    required String productId,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wishlist'),
        headers: getHeaders(token: token),
        body: json.encode({
          'userId': userId,
          'productId': productId,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Remove from wishlist
  static Future<bool> removeFromWishlist({
    required String productId,
    String? token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/wishlist/$productId'),
        headers: getHeaders(token: token),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}

