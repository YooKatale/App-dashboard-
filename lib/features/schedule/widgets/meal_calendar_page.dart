import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../common/widgets/bottom_navigation_bar.dart';
import '../../payment/widgets/flutter_wave.dart';

class MealCalendarPage extends ConsumerStatefulWidget {
  final String? planType;
  
  const MealCalendarPage({super.key, this.planType});

  @override
  ConsumerState<MealCalendarPage> createState() => _MealCalendarPageState();
}

class _MealCalendarPageState extends ConsumerState<MealCalendarPage> {
  final Map<String, bool> _vegetarianSauceOptions = {
    'monday': false,
    'tuesday': false,
    'wednesday': false,
    'thursday': false,
    'friday': false,
    'saturday': false,
    'sunday': false,
  };
  
  bool _isLoading = false;

  // Sample meal data - in production, this would come from API
  final Map<String, Map<String, List<Map<String, dynamic>>>> _weeklyMenu = {
    'monday': {
      'breakfast': [
        {'meal': 'Chapati & Beans', 'type': 'ready-to-eat', 'quantity': '2 pieces'},
        {'meal': 'Chapati & Beans', 'type': 'ready-to-cook', 'quantity': '2 pieces'},
      ],
      'lunch': [
        {'meal': 'Rice & Matooke', 'type': 'ready-to-eat', 'quantity': '1 plate'},
        {'meal': 'Rice & Matooke', 'type': 'ready-to-cook', 'quantity': '1 plate'},
      ],
      'supper': [
        {'meal': 'Posho & Beans', 'type': 'ready-to-eat', 'quantity': '1 plate'},
        {'meal': 'Posho & Beans', 'type': 'ready-to-cook', 'quantity': '1 plate'},
      ],
    },
    'tuesday': {
      'breakfast': [
        {'meal': 'Bread & Eggs', 'type': 'ready-to-eat', 'quantity': '2 slices'},
        {'meal': 'Bread & Eggs', 'type': 'ready-to-cook', 'quantity': '2 slices'},
      ],
      'lunch': [
        {'meal': 'Matooke & Groundnut Sauce', 'type': 'ready-to-eat', 'quantity': '1 plate'},
        {'meal': 'Matooke & Groundnut Sauce', 'type': 'ready-to-cook', 'quantity': '1 plate'},
      ],
      'supper': [
        {'meal': 'Rice & Chicken', 'type': 'ready-to-eat', 'quantity': '1 plate'},
        {'meal': 'Rice & Chicken', 'type': 'ready-to-cook', 'quantity': '1 plate'},
      ],
    },
    'wednesday': {
      'breakfast': [
        {'meal': 'Porridge & Mandazi', 'type': 'ready-to-eat', 'quantity': '1 cup'},
        {'meal': 'Porridge & Mandazi', 'type': 'ready-to-cook', 'quantity': '1 cup'},
      ],
      'lunch': [
        {'meal': 'Sweet Potatoes & Beans', 'type': 'ready-to-eat', 'quantity': '1 plate'},
        {'meal': 'Sweet Potatoes & Beans', 'type': 'ready-to-cook', 'quantity': '1 plate'},
      ],
      'supper': [
        {'meal': 'Matooke & Fish', 'type': 'ready-to-eat', 'quantity': '1 plate'},
        {'meal': 'Matooke & Fish', 'type': 'ready-to-cook', 'quantity': '1 plate'},
      ],
    },
    'thursday': {
      'breakfast': [
        {'meal': 'Chapati & Tea', 'type': 'ready-to-eat', 'quantity': '2 pieces'},
        {'meal': 'Chapati & Tea', 'type': 'ready-to-cook', 'quantity': '2 pieces'},
      ],
      'lunch': [
        {'meal': 'Rice & Beef', 'type': 'ready-to-eat', 'quantity': '1 plate'},
        {'meal': 'Rice & Beef', 'type': 'ready-to-cook', 'quantity': '1 plate'},
      ],
      'supper': [
        {'meal': 'Posho & Beans', 'type': 'ready-to-eat', 'quantity': '1 plate'},
        {'meal': 'Posho & Beans', 'type': 'ready-to-cook', 'quantity': '1 plate'},
      ],
    },
    'friday': {
      'breakfast': [
        {'meal': 'Bread & Peanut Butter', 'type': 'ready-to-eat', 'quantity': '2 slices'},
        {'meal': 'Bread & Peanut Butter', 'type': 'ready-to-cook', 'quantity': '2 slices'},
      ],
      'lunch': [
        {'meal': 'Matooke & Chicken', 'type': 'ready-to-eat', 'quantity': '1 plate'},
        {'meal': 'Matooke & Chicken', 'type': 'ready-to-cook', 'quantity': '1 plate'},
      ],
      'supper': [
        {'meal': 'Rice & Vegetables', 'type': 'ready-to-eat', 'quantity': '1 plate'},
        {'meal': 'Rice & Vegetables', 'type': 'ready-to-cook', 'quantity': '1 plate'},
      ],
    },
    'saturday': {
      'breakfast': [
        {'meal': 'Pancakes & Honey', 'type': 'ready-to-eat', 'quantity': '3 pieces'},
        {'meal': 'Pancakes & Honey', 'type': 'ready-to-cook', 'quantity': '3 pieces'},
      ],
      'lunch': [
        {'meal': 'Rice & Fish', 'type': 'ready-to-eat', 'quantity': '1 plate'},
        {'meal': 'Rice & Fish', 'type': 'ready-to-cook', 'quantity': '1 plate'},
      ],
      'supper': [
        {'meal': 'Matooke & Groundnut Sauce', 'type': 'ready-to-eat', 'quantity': '1 plate'},
        {'meal': 'Matooke & Groundnut Sauce', 'type': 'ready-to-cook', 'quantity': '1 plate'},
      ],
    },
    'sunday': {
      'breakfast': [
        {'meal': 'Chapati & Beans', 'type': 'ready-to-eat', 'quantity': '2 pieces'},
        {'meal': 'Chapati & Beans', 'type': 'ready-to-cook', 'quantity': '2 pieces'},
      ],
      'lunch': [
        {'meal': 'Rice & Chicken', 'type': 'ready-to-eat', 'quantity': '1 plate'},
        {'meal': 'Rice & Chicken', 'type': 'ready-to-cook', 'quantity': '1 plate'},
      ],
      'supper': [
        {'meal': 'Posho & Beans', 'type': 'ready-to-eat', 'quantity': '1 plate'},
        {'meal': 'Posho & Beans', 'type': 'ready-to-cook', 'quantity': '1 plate'},
      ],
    },
  };

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Calendar'),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Weekly Meal Plan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Raleway',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plan Type: ${widget.planType ?? 'Premium'}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Meal Calendar Table
            ..._daysOfWeek.map((day) {
              final dayKey = day.toLowerCase();
              final dayMeals = _weeklyMenu[dayKey] ?? {};
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    '${dayMeals.length} meal types',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Breakfast
                          if (dayMeals['breakfast'] != null) ...[
                            _buildMealSection('Breakfast', dayMeals['breakfast']!),
                            const SizedBox(height: 16),
                          ],
                          
                          // Lunch
                          if (dayMeals['lunch'] != null) ...[
                            _buildMealSection('Lunch', dayMeals['lunch']!),
                            const SizedBox(height: 16),
                          ],
                          
                          // Supper
                          if (dayMeals['supper'] != null) ...[
                            _buildMealSection('Supper', dayMeals['supper']!),
                            const SizedBox(height: 16),
                          ],
                          
                          // Vegetarian Sauce Option
                          Row(
                            children: [
                              Checkbox(
                                value: _vegetarianSauceOptions[dayKey] ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    _vegetarianSauceOptions[dayKey] = value ?? false;
                                  });
                                },
                                activeColor: const Color.fromRGBO(24, 95, 45, 1),
                              ),
                              const Expanded(
                                child: Text(
                                  'Vegetarian Sauce Option',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            
            // Delivery Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_shipping, 
                        color: Colors.blue[700], size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Free Delivery:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.only(left: 32),
                    child: Text(
                      'Within 3km distance.\nExtra: 950 UGX per additional kilometer.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Checkout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleCheckout,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.shopping_cart),
                label: Text(
                  _isLoading ? 'Processing...' : 'Checkout Meal Plan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(String mealType, List<Map<String, dynamic>> meals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mealType,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(24, 95, 45, 1),
          ),
        ),
        const SizedBox(height: 8),
        ...meals.map((meal) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  meal['type'] == 'ready-to-eat'
                      ? Icons.restaurant
                      : Icons.restaurant_menu,
                  color: const Color.fromRGBO(24, 95, 45, 1),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal['meal'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: meal['type'] == 'ready-to-eat'
                                  ? Colors.green[100]
                                  : Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              meal['type'] == 'ready-to-eat'
                                  ? 'Ready to Eat'
                                  : 'Ready to Cook',
                              style: TextStyle(
                                fontSize: 10,
                                color: meal['type'] == 'ready-to-eat'
                                    ? Colors.green[800]
                                    : Colors.blue[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            meal['quantity'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
  
  Future<void> _handleCheckout() async {
    // EXACT WEBAPP LOGIC: const { userInfo } = useSelector((state) => state.auth)
    // Webapp checks: if (!userInfo || userInfo == {} || userInfo == "") then redirect
    final userData = await AuthService.getUserData();
    final token = await AuthService.getToken();
    
    // EXACT webapp check: if (!userInfo || userInfo == {} || userInfo == "")
    String? userId;
    
    if (userData != null && userData.isNotEmpty) {
      // Ensure we have a valid _id or id (like webapp checks userInfo?._id)
      final id = userData['_id']?.toString() ?? userData['id']?.toString();
      if (id != null && id.isNotEmpty) {
        userId = id;
      }
    }
    
    // If no userId from stored data, check auth state
    if (userId == null) {
      final authState = ref.read(authStateProvider);
      if (authState.isLoggedIn && authState.userId != null) {
        userId = authState.userId;
      }
    }
    
    // EXACT WEBAPP LOGIC: Only check userId, token is optional
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to checkout'),
            backgroundColor: Colors.orange,
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushNamed(context, '/signin');
          }
        });
      }
      return;
    }
    
    // Token is optional - try to get it but don't block
    String? finalToken = token;
    if (finalToken == null) {
      finalToken = await AuthService.getToken();
    }
    
    // Update auth state if not already set (sync with stored data)
    final authState = ref.read(authStateProvider);
    if (!authState.isLoggedIn && userData != null) {
      ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
        userId: userId,
        email: userData['email']?.toString(),
        firstName: userData['firstname']?.toString(),
        lastName: userData['lastname']?.toString(),
      );
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Get user data
      final userData = await AuthService.getUserData();
      
      // Calculate order total (example: 7 days * 3 meals * base price)
      // This should match webapp logic
      const baseMealPrice = 5000; // UGX per meal
      const orderTotal = 7 * 3 * baseMealPrice; // Weekly plan
      
      // Create schedule/order data (similar to webapp)
      final scheduleData = {
        'user': userData,
        'products': {
          'planType': widget.planType ?? 'premium',
          'vegetarianOptions': _vegetarianSauceOptions,
        },
        'scheduleDays': ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
        'scheduleTime': '12:00', // Default lunch time
        'repeatSchedule': true,
        'order': {
          'payment': {'paymentMethod': '', 'transactionId': ''},
          'deliveryAddress': userData?['address']?.toString() ?? 'NAN',
          'specialRequests': 'Weekly meal subscription',
          'orderTotal': orderTotal,
        },
      };
      
      final response = await ApiService.createSchedule(
        scheduleData: scheduleData,
        token: finalToken,
      );
      
      if (mounted) {
        if (response['status'] == 'Success' && response['data']?['Order'] != null) {
          // Navigate to payment page (EXACT WEBAPP LOGIC: router.push(`/payment/${res.data.Order}`))
          final orderId = response['data']['Order'].toString();
          Navigator.pushNamed(
            context,
            '/payment/$orderId',
            arguments: {'amount': orderTotal.toDouble()},
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']?.toString() ?? 'Failed to create order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
