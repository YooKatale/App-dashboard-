import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../authentication/providers/redirect_provider.dart';
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

  // Common food allergies
  final List<String> _commonAllergies = [
    'Nuts',
    'Dairy',
    'Gluten',
    'Eggs',
    'Seafood',
    'Soy',
    'Shellfish',
  ];

  // Track allergies for each meal
  final Map<String, Set<String>> _mealAllergies = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Meal Calendar'),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromRGBO(24, 95, 45, 1),
                    Color.fromRGBO(40, 120, 60, 1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Weekly Meal Plan',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Raleway',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Plan Type: ${widget.planType ?? 'Premium'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Meal Calendar Table
            ..._daysOfWeek.map((day) {
              final dayKey = day.toLowerCase();
              final dayMeals = _weeklyMenu[dayKey] ?? {};
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(24, 95, 45, 1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Color.fromRGBO(24, 95, 45, 1),
                    ),
                  ),
                  title: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
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
                            _buildMealSection('Breakfast', dayMeals['breakfast']!, dayKey),
                            const SizedBox(height: 16),
                          ],
                          
                          // Lunch
                          if (dayMeals['lunch'] != null) ...[
                            _buildMealSection('Lunch', dayMeals['lunch']!, dayKey),
                            const SizedBox(height: 16),
                          ],
                          
                          // Supper
                          if (dayMeals['supper'] != null) ...[
                            _buildMealSection('Supper', dayMeals['supper']!, dayKey),
                            const SizedBox(height: 16),
                          ],
                          
                          // Vegetarian Sauce Option
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
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
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[50]!,
                    Colors.blue[100]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Free Delivery',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 44),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, 
                              color: Colors.blue[700], size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'Within 3km distance',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.info_outline, 
                              color: Colors.blue[700], size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'Extra: 950 UGX per additional kilometer',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildMealSection(String mealType, List<Map<String, dynamic>> meals, String dayKey) {
    final mealKey = '${dayKey}_${mealType.toLowerCase()}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(24, 95, 45, 1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                mealType == 'Breakfast' 
                    ? Icons.wb_sunny
                    : mealType == 'Lunch'
                        ? Icons.lunch_dining
                        : Icons.dinner_dining,
                color: const Color.fromRGBO(24, 95, 45, 1),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                mealType,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(24, 95, 45, 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...meals.map((meal) {
          final mealId = '${mealKey}_${meal['meal']}_${meal['type']}';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: meal['type'] == 'ready-to-eat'
                            ? Colors.green[50]
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        meal['type'] == 'ready-to-eat'
                            ? Icons.restaurant
                            : Icons.restaurant_menu,
                        color: meal['type'] == 'ready-to-eat'
                            ? Colors.green[700]
                            : Colors.blue[700],
                        size: 20,
                      ),
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
                              fontSize: 15,
                              color: Colors.black87,
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
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  meal['type'] == 'ready-to-eat'
                                      ? 'Ready to Eat'
                                      : 'Ready to Cook',
                                  style: TextStyle(
                                    fontSize: 11,
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
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // Allergy Dropdown with Multi-Select
                const Text(
                  'Food Allergies/Preferences:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showAllergyDialog(mealId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _mealAllergies[mealId]?.isEmpty ?? true
                                ? 'Select allergies (optional)'
                                : '${_mealAllergies[mealId]!.length} selected',
                            style: TextStyle(
                              fontSize: 14,
                              color: (_mealAllergies[mealId]?.isEmpty ?? true)
                                  ? Colors.grey[600]
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
                if (_mealAllergies[mealId]?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _mealAllergies[mealId]!.map((allergy) {
                      return Chip(
                        label: Text(
                          allergy,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.orange[100],
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _mealAllergies[mealId]!.remove(allergy);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                // Breakfast Selection Feature - Quick Pay
                if (mealType == 'Breakfast') ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleQuickBreakfastPayment(meal, mealId, 'ready-to-eat'),
                          icon: const Icon(Icons.restaurant, size: 18),
                          label: const Text('Pay Ready-to-Eat'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green[700],
                            side: BorderSide(color: Colors.green[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleQuickBreakfastPayment(meal, mealId, 'ready-to-cook'),
                          icon: const Icon(Icons.restaurant_menu, size: 18),
                          label: const Text('Pay Ready-to-Cook'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            side: BorderSide(color: Colors.blue[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // Show allergy selection dialog
  void _showAllergyDialog(String mealId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Allergies'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _commonAllergies.map((allergy) {
                  final isSelected = _mealAllergies[mealId]?.contains(allergy) ?? false;
                  return CheckboxListTile(
                    title: Text(allergy),
                    value: isSelected,
                    onChanged: (value) {
                      setDialogState(() {
                        _mealAllergies.putIfAbsent(mealId, () => <String>{});
                        if (value == true) {
                          _mealAllergies[mealId]!.add(allergy);
                        } else {
                          _mealAllergies[mealId]!.remove(allergy);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    ).then((_) {
      setState(() {}); // Refresh UI after dialog closes
    });
  }

  // Handle quick breakfast payment
  Future<void> _handleQuickBreakfastPayment(
    Map<String, dynamic> meal,
    String mealId,
    String mealType,
  ) async {
    final userData = await AuthService.getUserData();
    final token = await AuthService.getToken();
    final authState = ref.read(authStateProvider);
    
    String? userId;
    if (authState.isLoggedIn && authState.userId != null) {
      userId = authState.userId;
    } else if (userData != null && userData.isNotEmpty) {
      userId = userData['_id']?.toString() ?? userData['id']?.toString();
    }

    if (userId == null) {
      if (mounted) {
        ref.read(redirectRouteProvider.notifier).state = '/schedule';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to purchase breakfast'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pushNamed(context, '/signin');
      }
      return;
    }

    // Calculate price (example: 5000 UGX per breakfast)
    const basePrice = 5000.0;
    final orderTotal = basePrice;

    setState(() => _isLoading = true);

    try {
      final scheduleData = {
        'user': userData,
        'products': {
          'breakfast': {
            'meal': meal['meal'],
            'type': mealType,
            'quantity': meal['quantity'],
            'allergies': _mealAllergies[mealId]?.toList() ?? [],
          },
        },
        'scheduleDays': [], // Single breakfast order
        'scheduleTime': '8:00 AM',
        'repeatSchedule': false,
        'order': {
          'payment': {'paymentMethod': '', 'transactionId': ''},
          'deliveryAddress': userData?['address']?.toString() ?? 'NAN',
          'specialRequests': 'Single breakfast order',
          'orderTotal': orderTotal,
        },
      };

      final response = await ApiService.createSchedule(
        scheduleData: scheduleData,
        token: token,
      );

      if (mounted) {
        if (response['status'] == 'Success' && response['data']?['Order'] != null) {
          final orderId = response['data']['Order'].toString();
          final webappUrl = 'https://yookatale.app/payment/$orderId';
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_payment_url', webappUrl);
          
          final uri = Uri.parse(webappUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Redirecting to complete payment...'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            Navigator.pushNamed(context, '/payment/$orderId');
          }
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
            content: Text('Error: ${e.toString()}'),
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
        // Save redirect route for after login
        ref.read(redirectRouteProvider.notifier).state = '/schedule';
        
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
          'allergies': _mealAllergies, // Include allergy preferences
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
          // Redirect to webapp for payment (as requested)
          final orderId = response['data']['Order'].toString();
          final webappUrl = 'https://yookatale.app/payment/$orderId';
          
          // Save payment URL for redirect after login if needed
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_payment_url', webappUrl);
          
          final uri = Uri.parse(webappUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Redirecting to webapp to complete payment...'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Fallback to in-app payment
            Navigator.pushNamed(
              context,
              '/payment/$orderId',
              arguments: {'amount': orderTotal.toDouble()},
            );
          }
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
