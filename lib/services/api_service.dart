import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_service.dart';
import 'error_handler_service.dart';

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

  // Fetch all products with error handling
  static Future<Map<String, dynamic>> fetchProducts() async {
    try {
      // Check if online
      final isOnline = await ErrorHandlerService.isOnline();
      if (!isOnline) {
        throw Exception('No internet connection');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  // Fetch single product by ID
  static Future<Map<String, dynamic>> fetchProductById(String productId) async {
    try {
      // Check if online first
      final isOnline = await ErrorHandlerService.isOnline();
      if (!isOnline) {
        throw Exception('No internet connection');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/product/$productId'),
        headers: getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to load product: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Use ErrorHandlerService to get user-friendly error message
      final friendlyMessage = ErrorHandlerService.getErrorMessage(e);
      throw Exception(friendlyMessage);
    }
  }

  // Fetch products by category
  static Future<Map<String, dynamic>> fetchProductsByCategory(String category) async {
    try {
      // URL encode the category name to handle spaces and special characters
      final encodedCategory = Uri.encodeComponent(category.toLowerCase());
      final response = await http.get(
        Uri.parse('$baseUrl/products/$encodedCategory'),
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
      // Check if online first
      final isOnline = await ErrorHandlerService.isOnline();
      if (!isOnline) {
        throw Exception('No internet connection');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: getHeaders(),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Login failed. Please try again.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Use ErrorHandlerService to get user-friendly error message
      final friendlyMessage = ErrorHandlerService.getErrorMessage(e);
      throw Exception(friendlyMessage);
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
      // Check if online first
      final isOnline = await ErrorHandlerService.isOnline();
      if (!isOnline) {
        throw Exception('No internet connection');
      }

      // EXACT WEBAPP LOGIC: Send { productId, userId, quantity }
      final response = await http.post(
        Uri.parse('$baseUrl/product/cart'),
        headers: getHeaders(token: token),
        body: json.encode({
          'productId': productId, // Webapp sends productId first
          'userId': userId,
          'quantity': quantity,
        }),
      ).timeout(const Duration(seconds: 30));

      final responseBody = json.decode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if response indicates an error even with 200 status
        if (responseBody is Map && responseBody.containsKey('error')) {
          final errorMessage = responseBody['error']?.toString() ?? 
                              responseBody['message']?.toString() ?? 
                              'Failed to add to cart. Please try again.';
          throw Exception(errorMessage);
        }
        return responseBody;
      } else {
        final errorMessage = responseBody['message'] ?? 'Failed to add to cart. Please try again.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Use ErrorHandlerService to get user-friendly error message
      final friendlyMessage = ErrorHandlerService.getErrorMessage(e);
      throw Exception(friendlyMessage);
    }
  }

  static Future<Map<String, dynamic>> updateCartItem({
    required String cartId,
    required int quantity,
    String? userId,
    String? token,
  }) async {
    try {
      // Check if online first
      final isOnline = await ErrorHandlerService.isOnline();
      if (!isOnline) {
        throw Exception('No internet connection');
      }

      // Match webapp logic - include userId if available
      final body = <String, dynamic>{
        'quantity': quantity,
      };
      if (userId != null) {
        body['userId'] = userId;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/product/cart/$cartId'),
        headers: getHeaders(token: token),
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        // Check if response indicates an error even with 200 status
        if (responseBody is Map && responseBody.containsKey('error')) {
          final errorMessage = responseBody['error']?.toString() ?? 
                              responseBody['message']?.toString() ?? 
                              'Failed to update cart. Please try again.';
          throw Exception(errorMessage);
        }
        return responseBody;
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['message'] ?? 'Failed to update cart. Please try again.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Use ErrorHandlerService to get user-friendly error message
      final friendlyMessage = ErrorHandlerService.getErrorMessage(e);
      throw Exception(friendlyMessage);
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

  // Create cart checkout order - matches webapp createCartCheckout
  // Webapp endpoint: /products/cart/checkout (plural 'products')
  static Future<Map<String, dynamic>> createCartCheckout({
    required Map<String, dynamic> user,
    required String customerName,
    required List<Map<String, dynamic>> carts,
    required Map<String, dynamic> order,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/cart/checkout'), // EXACT WEBAPP ENDPOINT (plural 'products')
        headers: getHeaders(token: token),
        body: json.encode({
          'user': user,
          'customerName': customerName,
          'Carts': carts, // EXACT WEBAPP FORMAT (capital 'Carts')
          'order': order,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to create checkout: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
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

  // Subscriptions — matches webapp: GET /subscription/me (requires auth token)
  static Future<Map<String, dynamic>> fetchUserSubscriptions(String userId, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscription/me'),
        headers: getHeaders(token: token),
      ).timeout(const Duration(seconds: 30));

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
  // EXACT WEBAPP LOGIC: Backend route is /products/schedule
  static Future<Map<String, dynamic>> createSchedule({
    required Map<String, dynamic> scheduleData,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/schedule'),
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

  // Orders — matches webapp: GET /orders/me (requires auth token)
  static Future<Map<String, dynamic>> fetchUserOrders(String userId, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/me'),
        headers: getHeaders(token: token),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  // Fetch order by ID
  static Future<Map<String, dynamic>> fetchOrder(String orderId, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/order/$orderId'),
        headers: getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to fetch order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching order: $e');
    }
  }

  // Update order
  static Future<Map<String, dynamic>> updateOrder({
    required String orderId,
    required Map<String, dynamic> paymentData,
    String? token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/products/order'),
        headers: getHeaders(token: token),
        body: json.encode(paymentData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to update order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating order: $e');
    }
  }

  // Validate coupon
  static Future<Map<String, dynamic>> validateCoupon({
    required String couponCode,
    required String orderId,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/coupon/validate'),
        headers: getHeaders(token: token),
        body: json.encode({
          'couponCode': couponCode,
          'orderId': orderId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to validate coupon: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error validating coupon: $e');
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

  // Upload user avatar (profile picture)
  static Future<Map<String, dynamic>> uploadUserAvatar({
    required String userId,
    required String filePath,
    String? token,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/users/$userId/avatar'),
      );
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(await http.MultipartFile.fromPath('avatar', filePath));
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) return json.decode(response.body);
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Avatar upload failed');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
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

  // Fetch service comments/ratings - Use platform feedback endpoint
  static Future<Map<String, dynamic>> fetchServiceComments({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/platform'),
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

  // Create service comment/rating - Use platform feedback endpoint
  static Future<Map<String, dynamic>> createServiceComment({
    required String name,
    required String message,
    int? rating,
    String? token,
  }) async {
    try {
      // Determine platform: android, ios, or web
      // Ensure we always send a valid platform value
      String platform = 'web'; // Default to web
      
      if (!kIsWeb) {
        // Running on mobile (not web)
        if (Platform.isAndroid) {
          platform = 'android';
        } else if (Platform.isIOS) {
          platform = 'ios';
        }
        // If neither Android nor iOS, keep 'web' as fallback
      }
      
      // Ensure platform is lowercase and trimmed (backend requirement)
      platform = platform.toLowerCase().trim();
      
      // Validate platform value before sending
      if (platform != 'android' && platform != 'ios' && platform != 'web') {
        platform = 'android'; // Fallback to android for mobile apps
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/ratings/platform'),
        headers: getHeaders(token: token),
        body: json.encode({
          'name': name,
          'message': message,
          'platform': platform,
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

  // Save FCM token to webapp endpoint (synchronized with webapp)
  static Future<void> saveFCMTokenToWebapp({
    required String token,
    String? userId,
    String? email,
  }) async {
    try {
      // Use same endpoint as webapp: /admin/web_push
      // This ensures notifications are synchronized across web and mobile
      final backendUrl = 'https://yookatale-server.onrender.com';
      
      final response = await http.post(
        Uri.parse('$backendUrl/admin/web_push'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'token': token,
          'userId': userId,
          'email': email,
          'type': 'fcm',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Token saved successfully to webapp endpoint
        final responseBody = json.decode(response.body);
        print('✅ FCM token saved to webapp endpoint');
        print('📱 Response: $responseBody');
        print('📱 Token prefix: ${token.substring(0, 20)}...');
        print('📱 UserId: $userId');
        print('📱 Email: $email');
      } else {
        final errorBody = response.body;
        print('⚠️ Failed to save FCM token: ${response.statusCode}');
        print('⚠️ Error response: $errorBody');
      }
    } catch (e) {
      print('❌ Error saving FCM token to webapp: $e');
      print('❌ Token: ${token.substring(0, 20)}...');
      // Don't throw - allow app to continue
    }
  }

  // Update FCM token (legacy method - kept for backward compatibility)
  static Future<void> updateFCMToken(String token, String authToken) async {
    try {
      final userData = await AuthService.getUserData();
      if (userData == null) return;

      final userId = userData['_id']?.toString() ?? userData['id']?.toString();
      if (userId == null) return;

      // Also save to webapp endpoint for synchronization
      final email = userData['email']?.toString();
      await saveFCMTokenToWebapp(token: token, userId: userId, email: email);

      final response = await http.post(
        Uri.parse('$baseUrl/users/fcm-token'),
        headers: getHeaders(token: authToken),
        body: json.encode({
          'userId': userId,
          'fcmToken': token,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Token saved successfully
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Fetch notifications from server
  static Future<Map<String, dynamic>> fetchNotifications({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  // Fetch country cuisines - GET /country-cuisines
  static Future<Map<String, dynamic>> fetchCountryCuisines() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/country-cuisines'),
        headers: getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load country cuisines: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  // Fetch homepage config - GET /homepage-config (hero slides, side cards, promo banners)
  static Future<Map<String, dynamic>> fetchHomepageConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/homepage-config'),
        headers: getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load homepage config: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  // Fetch products filtered by budget (low/middle/high) - GET /products/filter/:data
  // data is JSON-encoded array e.g. ["low"], ["middle"], ["high"]
  static Future<Map<String, dynamic>> fetchProductsFiltered(List<String> filters) async {
    try {
      final encodedData = Uri.encodeComponent(json.encode(filters));
      final response = await http.get(
        Uri.parse('$baseUrl/products/filter/$encodedData'),
        headers: getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load filtered products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  // Search products — matches webapp: GET /products/search/:query
  static Future<Map<String, dynamic>> searchProducts(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query.trim());
      final response = await http.get(
        Uri.parse('$baseUrl/products/search/$encodedQuery'),
        headers: getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  // Fetch product categories - GET /categories
  static Future<Map<String, dynamic>> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  // Wishlist - Backend has NO wishlist routes; web uses localStorage (wishlistSlice).
  // These methods are kept for future backend support; mobile uses local storage (SharedPreferences).
  // When backend adds wishlist: GET /wishlist, POST /wishlist, DELETE /wishlist/:productId
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

  // Google Sign-In/Sign-Up - Register or login with Google
  static Future<Map<String, dynamic>> googleAuth({
    required String idToken,
    required String email,
    String? firstName,
    String? lastName,
    String? photoUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: getHeaders(),
        body: json.encode({
          'idToken': idToken,
          'email': email,
          'firstname': firstName,
          'lastname': lastName,
          'photoUrl': photoUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Google authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error with Google authentication: $e');
    }
  }

  // Update delivery partner location
  static Future<Map<String, dynamic>> updateDeliveryLocation({
    required String partnerId,
    required double lat,
    required double lng,
    String? address,
    String? orderId,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delivery/location'),
        headers: getHeaders(token: token),
        body: json.encode({
          'partnerId': partnerId,
          'lat': lat,
          'lng': lng,
          if (address != null) 'address': address,
          if (orderId != null) 'orderId': orderId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to update location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating delivery location: $e');
    }
  }

  // Get order delivery location
  static Future<Map<String, dynamic>> getOrderDeliveryLocation({
    required String orderId,
    String? token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/delivery/order/$orderId'),
        headers: getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to get delivery location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting delivery location: $e');
    }
  }

  // Cashout - requires auth
  static Future<Map<String, dynamic>> fetchCashoutStats({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cashout/stats'),
        headers: getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to load cashout stats: ${response.statusCode}');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  static Future<Map<String, dynamic>> fetchPayoutMethods({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payout-methods'),
        headers: getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to load payout methods: ${response.statusCode}');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  static Future<Map<String, dynamic>> fetchWithdrawals({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cashout/withdrawals'),
        headers: getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to load withdrawals: ${response.statusCode}');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  static Future<Map<String, dynamic>> withdrawFunds({
    required String token,
    required double amount,
    String? payoutMethodId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cashout/withdraw'),
        headers: getHeaders(token: token),
        body: json.encode({
          'amount': amount,
          if (payoutMethodId != null) 'payoutMethodId': payoutMethodId,
        }),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Withdraw failed: ${response.statusCode}');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  // Rewards - public list, authenticated for my rewards
  static Future<Map<String, dynamic>> fetchRewards() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rewards'),
        headers: getHeaders(),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to load rewards: ${response.statusCode}');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  static Future<Map<String, dynamic>> fetchMyRewards({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rewards/my'),
        headers: getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to load my rewards: ${response.statusCode}');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  static Future<Map<String, dynamic>> redeemReward({
    required String token,
    required String rewardId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rewards/redeem'),
        headers: getHeaders(token: token),
        body: json.encode({'rewardId': rewardId}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Redeem failed: ${response.statusCode}');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  // ── Driver Dashboard ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> fetchDriverStats({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/driver/stats'),
        headers: getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Failed to load driver stats');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  static Future<Map<String, dynamic>> fetchAvailableOrders({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/driver/orders/available'),
        headers: getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Failed to load available orders');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  static Future<Map<String, dynamic>> fetchActiveDelivery({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/driver/delivery/active'),
        headers: getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      return {'data': null};
    } catch (e) {
      return {'data': null};
    }
  }

  static Future<Map<String, dynamic>> toggleDriverAvailability({
    required String token,
    required bool isOnline,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/driver/availability'),
        headers: getHeaders(token: token),
        body: json.encode({'isOnline': isOnline}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Failed to toggle availability');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  static Future<Map<String, dynamic>> acceptDeliveryOrder({
    required String token,
    required String orderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/driver/orders/$orderId/accept'),
        headers: getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 || response.statusCode == 201) return json.decode(response.body);
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Failed to accept order');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  static Future<Map<String, dynamic>> updateDeliveryStatus({
    required String token,
    required String orderId,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/driver/orders/$orderId/status'),
        headers: getHeaders(token: token),
        body: json.encode({'status': status}),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Failed to update status');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  // ── Partner Registration ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> registerVendor({
    String? token,
    required String storeName,
    required String address,
    required String phone,
    required String email,
    required String category,
    bool isVegetarian = false,
    bool isVegan = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vendor/register'),
        headers: getHeaders(token: token),
        body: json.encode({
          'storeName': storeName,
          'address': address,
          'phone': phone,
          'email': email,
          'category': category,
          'isVegetarian': isVegetarian,
          'isVegan': isVegan,
        }),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 || response.statusCode == 201) return json.decode(response.body);
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Vendor registration failed');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  static Future<Map<String, dynamic>> registerDeliveryDriver({
    String? token,
    required String name,
    required String phone,
    required String email,
    String? location,
    required String vehicleType,
    String? numberPlate,
    bool hasPermit = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/driver/register'),
        headers: getHeaders(token: token),
        body: json.encode({
          'name': name,
          'phone': phone,
          'email': email,
          if (location != null) 'location': location,
          'vehicleType': vehicleType,
          if (numberPlate != null) 'numberPlate': numberPlate,
          'hasPermit': hasPermit,
        }),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 || response.statusCode == 201) return json.decode(response.body);
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Driver registration failed');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  // ── Job Applications ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> submitJobApplication({
    required String jobId,
    required String jobTitle,
    required String name,
    required String email,
    required String phone,
    String? coverLetter,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/careers/apply'),
        headers: getHeaders(),
        body: json.encode({
          'jobId': jobId,
          'jobTitle': jobTitle,
          'name': name,
          'email': email,
          'phone': phone,
          if (coverLetter != null && coverLetter.isNotEmpty) 'coverLetter': coverLetter,
        }),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 || response.statusCode == 201) return json.decode(response.body);
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Failed to submit application');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  // ── Gift Cards ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> purchaseGiftCard({
    String? token,
    required int amount,
    required String occasion,
    required String userId,
    bool sendToSomeone = false,
    String? recipientName,
    String? recipientEmail,
    String? message,
    String paymentMethod = 'mobile_money',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/gift-cards/purchase'),
        headers: getHeaders(token: token),
        body: json.encode({
          'amount': amount,
          'occasion': occasion,
          'userId': userId,
          'sendToSomeone': sendToSomeone,
          if (recipientName != null) 'recipientName': recipientName,
          if (recipientEmail != null) 'recipientEmail': recipientEmail,
          if (message != null) 'message': message,
          'paymentMethod': paymentMethod,
        }),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 || response.statusCode == 201) return json.decode(response.body);
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Failed to purchase gift card');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  static Future<Map<String, dynamic>> fetchMyGiftCards({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gift-cards/my'),
        headers: getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      return {'data': {'received': [], 'sent': []}};
    } catch (e) {
      return {'data': {'received': [], 'sent': []}};
    }
  }

  static Future<Map<String, dynamic>> redeemGiftCard({
    String? token,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/gift-cards/redeem'),
        headers: getHeaders(token: token),
        body: json.encode({'code': code}),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 || response.statusCode == 201) return json.decode(response.body);
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Failed to redeem gift card');
    } catch (e) {
      throw Exception(ErrorHandlerService.getErrorMessage(e));
    }
  }

  // ── Referrals ───────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> fetchReferralData({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/referrals/stats'),
        headers: getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      return {'data': null};
    } catch (e) {
      return {'data': null};
    }
  }

  static Future<Map<String, dynamic>> fetchReferralRewards({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cashout/referral-rewards'),
        headers: getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      return {'data': null};
    } catch (e) {
      return {'data': null};
    }
  }

  // ── Cashout history ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchCashoutHistory({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cashout/history'),
        headers: getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      return {'data': []};
    } catch (e) {
      return {'data': []};
    }
  }

  // ── User profile ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchUserProfile({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      return {'data': null};
    } catch (e) {
      return {'data': null};
    }
  }

  // ── Meal Calendar ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> fetchMealSlotsPublic({Map<String, String>? params}) async {
    try {
      final uri = Uri.parse('$baseUrl/meal-calendar/slots/public').replace(queryParameters: params);
      final response = await http.get(uri, headers: getHeaders()).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      return {'data': []};
    } catch (e) {
      return {'data': []};
    }
  }
}

