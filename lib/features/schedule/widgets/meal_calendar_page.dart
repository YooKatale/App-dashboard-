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
  String _selectedDay = 'Monday';

  // Meal image keyword map
  static const Map<String, String> _mealImages = {
    'chapati': 'https://images.unsplash.com/photo-1626844400890-6498f80f3a55?w=200',
    'beans': 'https://images.unsplash.com/photo-1623428187969-5da2dcea5ebf?w=200',
    'rice': 'https://images.unsplash.com/photo-1536304993881-ff86e6cee51a?w=200',
    'matooke': 'https://images.unsplash.com/photo-1590779033100-9f60a05a013d?w=200',
    'bread': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200',
    'eggs': 'https://images.unsplash.com/photo-1551538827-9c037cb4f32a?w=200',
    'chicken': 'https://images.unsplash.com/photo-1598103442097-8b74394b95c3?w=200',
    'fish': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=200',
    'beef': 'https://images.unsplash.com/photo-1558030006-450675393462?w=200',
    'posho': 'https://images.unsplash.com/photo-1625944230945-1b7dd3b949ab?w=200',
    'porridge': 'https://images.unsplash.com/photo-1517673400267-0251440c45dc?w=200',
    'pancakes': 'https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=200',
    'groundnut': 'https://images.unsplash.com/photo-1607330289024-1535c6b4e1c1?w=200',
    'vegetables': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=200',
    'potatoes': 'https://images.unsplash.com/photo-1518977676405-d674f-a6d6-b58f-406974b29ab4?w=200',
    'mandazi': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=200',
    'peanut': 'https://images.unsplash.com/photo-1542990253-a781e04b4571?w=200',
  };

  String _getMealImage(String mealName) {
    final lower = mealName.toLowerCase();
    for (final entry in _mealImages.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200';
  }

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
    final dayKey = _selectedDay.toLowerCase();
    final dayMeals = _weeklyMenu[dayKey] ?? {};

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Meal Calendar'),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 1),
      body: Column(
        children: [
          // Day-selector pill row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _daysOfWeek.length,
                itemBuilder: (context, index) {
                  final day = _daysOfWeek[index];
                  final shortDay = day.substring(0, 3);
                  final isSelected = _selectedDay == day;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDay = day);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color.fromRGBO(24, 95, 45, 1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? const Color.fromRGBO(24, 95, 45, 1)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        shortDay,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                          fontFamily: 'Raleway',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Day content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day heading card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          '$_selectedDay — ${widget.planType ?? 'Premium'} Plan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Raleway',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

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

                  const SizedBox(height: 24),

                  // Delivery Information
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[50]!, Colors.blue[100]!],
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
                            const Flexible(
                              child: Text(
                                'Free Delivery',
                                style: TextStyle(
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
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
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(
      String mealType, List<Map<String, dynamic>> meals, String dayKey) {
    final mealKey = '${dayKey}_${mealType.toLowerCase()}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header pill
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
          final mealName = meal['meal'] as String? ?? '';
          final imageUrl = _getMealImage(mealName);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food image + meal name row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(24, 95, 45, 1)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            color: Color.fromRGBO(24, 95, 45, 1),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Meal info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mealName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.black87,
                              fontFamily: 'Raleway',
                            ),
                          ),
                          const SizedBox(height: 6),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
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

                // Payment Button
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleMealPayment(
                        meal, mealId, meal['type'] ?? 'ready-to-eat',
                        mealType, dayKey),
                    icon: const Icon(Icons.payment, size: 18),
                    label: Text('Pay for $mealName'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
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
                  final isSelected =
                      _mealAllergies[mealId]?.contains(allergy) ?? false;
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

  // Handle meal payment
  Future<void> _handleMealPayment(
    Map<String, dynamic> meal,
    String mealId,
    String prepType,
    String mealType,
    String dayKey,
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
            content: Text('Please login to purchase meal'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pushNamed(context, '/signin');
      }
      return;
    }

    const basePrice = 5000.0;
    final orderTotal = basePrice;

    setState(() => _isLoading = true);

    try {
      final scheduleData = {
        'user': userData,
        'products': {
          mealType.toLowerCase(): {
            'meal': meal['meal'],
            'type': prepType,
            'quantity': meal['quantity'],
            'allergies': _mealAllergies[mealId]?.toList() ?? [],
          },
        },
        'scheduleDays': [dayKey],
        'scheduleTime': mealType == 'Breakfast'
            ? '8:00 AM'
            : mealType == 'Lunch'
                ? '1:00 PM'
                : '7:00 PM',
        'repeatSchedule': false,
        'order': {
          'payment': {'paymentMethod': '', 'transactionId': ''},
          'deliveryAddress': userData?['address']?.toString() ?? 'NAN',
          'specialRequests':
              'Single ${mealType.toLowerCase()} order - ${meal['meal']}',
          'orderTotal': orderTotal,
        },
      };

      final response = await ApiService.createSchedule(
        scheduleData: scheduleData,
        token: token,
      );

      if (mounted) {
        String? orderId;
        if (response['data'] != null && response['data'] is Map) {
          final data = response['data'] as Map<String, dynamic>;
          orderId = data['Order']?.toString() ?? data['order']?.toString();
        }

        if (orderId != null && orderId.isNotEmpty) {
          final webappUrl = 'https://www.yookatale.app/payment/$orderId';
          final uri = Uri.parse(webappUrl);

          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Redirecting to payment page...'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            Navigator.pushNamed(context, '/payment/$orderId');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  response['message']?.toString() ?? 'Failed to create order'),
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

  // Handle quick breakfast payment (deprecated - use _handleMealPayment instead)
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
        'scheduleDays': [],
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
        if (response['status'] == 'Success' &&
            response['data']?['Order'] != null) {
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
              content: Text(
                  response['message']?.toString() ?? 'Failed to create order'),
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
    final userData = await AuthService.getUserData();
    final token = await AuthService.getToken();

    String? userId;

    if (userData != null && userData.isNotEmpty) {
      final id = userData['_id']?.toString() ?? userData['id']?.toString();
      if (id != null && id.isNotEmpty) {
        userId = id;
      }
    }

    if (userId == null) {
      final authState = ref.read(authStateProvider);
      if (authState.isLoggedIn && authState.userId != null) {
        userId = authState.userId;
      }
    }

    if (userId == null) {
      if (mounted) {
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

    String? finalToken = token;
    if (finalToken == null) {
      finalToken = await AuthService.getToken();
    }

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
      final userData = await AuthService.getUserData();

      const baseMealPrice = 5000;
      const orderTotal = 7 * 3 * baseMealPrice;

      final scheduleData = {
        'user': userData,
        'products': {
          'planType': widget.planType ?? 'premium',
          'vegetarianOptions': _vegetarianSauceOptions,
          'allergies': _mealAllergies,
        },
        'scheduleDays': [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday'
        ],
        'scheduleTime': '12:00',
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
        if (response['status'] == 'Success' &&
            response['data']?['Order'] != null) {
          final orderId = response['data']['Order'].toString();
          final webappUrl = 'https://yookatale.app/payment/$orderId';

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
            Navigator.pushNamed(
              context,
              '/payment/$orderId',
              arguments: {'amount': orderTotal.toDouble()},
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  response['message']?.toString() ?? 'Failed to create order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error: ${e.toString().replaceAll('Exception: ', '')}'),
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
