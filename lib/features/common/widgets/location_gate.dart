import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'location_search_picker.dart';

/// Location Gate Widget (Like Glovo)
/// Requires location selection before accessing the app
/// Shows immediately on app start if location not set
class LocationGate extends StatefulWidget {
  final Widget child;

  const LocationGate({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<LocationGate> createState() => _LocationGateState();
}

class _LocationGateState extends State<LocationGate> {
  Map<String, dynamic>? _location;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocation = prefs.getString('yookatale_delivery_location');
      
      if (savedLocation != null) {
        final parsed = json.decode(savedLocation) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _location = parsed;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveLocation(Map<String, dynamic> location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('yookatale_delivery_location', json.encode(location));
      setState(() {
        _location = location;
      });
    } catch (e) {
      // Ignore errors
    }
  }

  void _showLocationPicker() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationSearchPicker(
          onLocationSelected: (location) async {
            await _saveLocation(location);
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          required: true,
          onClose: () {
            // Can't close if location is required
            if (_location == null && mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_location == null) {
      // Show location picker immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLocationPicker();
      });
      
      return Scaffold(
        body: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 64,
                  color: Color.fromRGBO(24, 95, 45, 1),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Where should we deliver?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please select your delivery location',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _showLocationPicker,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    'Select Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
