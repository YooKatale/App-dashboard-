import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/api_service.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../common/widgets/custom_button.dart';
import '../../payment/widgets/flutter_wave.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  String _scheduleFor = 'products'; // 'products' or 'appointment'
  String _appointmentType = 'online';
  List<dynamic> _products = [];
  final List<String> _selectedProducts = [];
  final List<String> _selectedDays = [];
  String _selectedTime = '';
  bool _repeatSchedule = false;
  bool _isLoading = false;
  bool _loadingProducts = true;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> _timeSlots = [
    '7 AM - 8 AM',
    '8 AM - 9 AM',
    '10 AM - 11 AM',
    '12 PM - 1 PM',
    '2 PM - 3 PM',
    '4 PM - 5 PM',
    '6 PM - 7 PM',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loadingProducts = true;
    });

    try {
      final response = await ApiService.fetchProducts();
      if (response['status'] == 'Success' && response['data'] != null) {
        setState(() {
          _products = response['data'] is List ? response['data'] : [];
          _loadingProducts = false;
        });
      } else {
        setState(() {
          _products = [];
          _loadingProducts = false;
        });
      }
    } catch (e) {
      setState(() {
        _products = [];
        _loadingProducts = false;
      });
    }
  }

  Future<void> _createSchedule() async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select days for delivery/appointment')),
      );
      return;
    }

    if (_scheduleFor == 'products' && _selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select products for delivery')),
      );
      return;
    }

    if (_selectedTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authStateProvider);
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || authState.userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to create schedule')),
          );
        }
        return;
      }

      // Calculate order total
      final orderTotal = _scheduleFor == 'appointment'
          ? (_appointmentType == 'online' ? 60000 : 120000) *
              (_selectedDays.length * (_repeatSchedule ? 4 : 1))
          : 0; // For products, calculate based on selected products

      final scheduleData = {
        'user': authState.userId,
        'products': _scheduleFor == 'products'
            ? _selectedProducts
            : {'appointmentType': _appointmentType},
        'scheduleDays': _selectedDays,
        'scheduleTime': _selectedTime,
        'repeatSchedule': _repeatSchedule,
        'scheduleFor': _scheduleFor == 'products' ? 'delivery' : 'appointment',
        'order': {
          'payment': {'paymentMethod': '', 'transactionId': ''},
          'deliveryAddress': 'NAN',
          'specialRequests': 'NAN',
          'orderTotal': orderTotal,
        },
      };

      final response = await ApiService.createSchedule(
        scheduleData: scheduleData,
        token: await user.getIdToken(),
      );

      if (response['status'] == 'Success' && response['data'] != null) {
        final orderId = response['data']['Order']?.toString();
        if (orderId != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _scheduleFor == 'appointment'
                    ? 'Your $_appointmentType appointment has been requested. Please proceed to checkout.'
                    : 'Schedule created successfully. Please proceed to checkout.',
              ),
            ),
          );
          // Navigate to payment
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlutterWavePayment(orderId: orderId),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(response['message'] ?? 'Failed to create schedule')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Schedule ${_scheduleFor == 'products' ? 'Delivery' : 'Appointment'}'),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Schedule Type Toggle
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _scheduleFor = 'products'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _scheduleFor == 'products'
                          ? const Color.fromRGBO(24, 95, 45, 1)
                          : Colors.white,
                      foregroundColor: _scheduleFor == 'products'
                          ? Colors.white
                          : Colors.black87,
                    ),
                    child: const Text('Schedule Delivery'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        setState(() => _scheduleFor = 'appointment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _scheduleFor == 'appointment'
                          ? const Color.fromRGBO(24, 95, 45, 1)
                          : Colors.white,
                      foregroundColor: _scheduleFor == 'appointment'
                          ? Colors.white
                          : Colors.black87,
                    ),
                    child: const Text('Schedule Appointment'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Appointment Type (if appointment selected)
            if (_scheduleFor == 'appointment') ...[
              const Text(
                'Appointment Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _appointmentType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'online',
                    child: Text('60 mins Online @ UGX 60,000'),
                  ),
                  DropdownMenuItem(
                    value: 'physical',
                    child: Text('60 mins Physical meet @ UGX 120,000'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _appointmentType = value);
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
            // Product Selection (if delivery selected)
            if (_scheduleFor == 'products') ...[
              const Text(
                'Select Products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _loadingProducts
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                      ? const Text('No products available')
                      : Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              final productId =
                                  product['_id']?.toString() ?? '';
                              final isSelected =
                                  _selectedProducts.contains(productId);
                              return CheckboxListTile(
                                title: Text(
                                    product['name']?.toString() ?? 'Product'),
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedProducts.add(productId);
                                    } else {
                                      _selectedProducts.remove(productId);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
              const SizedBox(height: 24),
            ],
            // Day Selection
            const Text(
              'Select Days',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _daysOfWeek.map((day) {
                final isSelected = _selectedDays.contains(day.toLowerCase());
                return FilterChip(
                  label: Text(day),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day.toLowerCase());
                      } else {
                        _selectedDays.remove(day.toLowerCase());
                      }
                    });
                  },
                  selectedColor: const Color.fromRGBO(24, 95, 45, 1),
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Time Selection
            const Text(
              'Select Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedTime.isEmpty ? null : _selectedTime,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose time',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _timeSlots.map((time) {
                return DropdownMenuItem(
                  value: time,
                  child: Text(time),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTime = value);
                }
              },
            ),
            const SizedBox(height: 24),
            // Repeat Schedule
            CheckboxListTile(
              title: const Text('Repeat Schedule'),
              subtitle: const Text('Every week'),
              value: _repeatSchedule,
              onChanged: (value) {
                setState(() => _repeatSchedule = value ?? false);
              },
            ),
            const SizedBox(height: 24),
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                title: 'Schedule',
                onPressed: _isLoading ? null : _createSchedule,
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
