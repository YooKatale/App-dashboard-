import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Glovo-style Location Search Picker for Flutter
/// Features search-based location entry with Google Places Autocomplete
class LocationSearchPicker extends StatefulWidget {
  final Function(Map<String, dynamic>) onLocationSelected;
  final String? initialAddress;
  final VoidCallback? onClose;
  final bool required;

  const LocationSearchPicker({
    Key? key,
    required this.onLocationSelected,
    this.initialAddress,
    this.onClose,
    this.required = true,
  }) : super(key: key);

  @override
  State<LocationSearchPicker> createState() => _LocationSearchPickerState();
}

class _LocationSearchPickerState extends State<LocationSearchPicker> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  Map<String, dynamic>? _selectedLocation;
  bool _isLoading = false;
  bool _isGettingCurrentLocation = false;
  List<Map<String, dynamic>> _recentLocations = [];
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialAddress ?? '';
    _loadRecentLocations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('yookatale_recent_locations');
      if (saved != null) {
        setState(() {
          _recentLocations = List<Map<String, dynamic>>.from(
            json.decode(saved).map((x) => x as Map<String, dynamic>),
          );
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _saveRecentLocation(Map<String, dynamic> location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updated = [
        location,
        ..._recentLocations.where((l) => l['address'] != location['address']),
      ].take(5).toList();
      
      await prefs.setString('yookatale_recent_locations', json.encode(updated));
      setState(() {
        _recentLocations = updated;
      });
    } catch (e) {
      // Ignore errors
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    // Use geocoding to search for places (like Glovo)
    _searchPlaces(query);
  }

  Future<void> _searchPlaces(String query) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Use geocoding package to search addresses
      final locations = await locationFromAddress(query);
      
      if (locations.isNotEmpty) {
        final placemarks = await placemarkFromCoordinates(
          locations.first.latitude,
          locations.first.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final address = [
            placemark.street,
            placemark.subLocality,
            placemark.locality,
            placemark.country,
          ].where((s) => s != null && s.isNotEmpty).join(', ');

          setState(() {
            _suggestions = [
              {
                'address': address,
                'lat': locations.first.latitude,
                'lng': locations.first.longitude,
              }
            ];
          });
        }
      }
    } catch (e) {
      // No results found or error
      setState(() {
        _suggestions = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isGettingCurrentLocation = true;
      });

      // Check permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permissions denied');
          return;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.street,
          placemark.subLocality,
          placemark.locality,
          placemark.country,
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        final location = {
          'lat': position.latitude,
          'lng': position.longitude,
          'address': address,
          'address1': address,
          'address2': '',
        };

        setState(() {
          _selectedLocation = location;
          _searchController.text = address;
        });

        // Update map
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );

        // Save to recent locations
        await _saveRecentLocation(location);
      }
    } catch (e) {
      _showError('Failed to get location: $e');
    } finally {
      setState(() {
        _isGettingCurrentLocation = false;
      });
    }
  }

  void _selectLocation(Map<String, dynamic> location) {
    setState(() {
      _selectedLocation = location;
      _searchController.text = location['address'] ?? '';
      _suggestions = [];
    });

    // Update map
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(location['lat'], location['lng']),
      ),
    );

    // Save to recent locations
    _saveRecentLocation(location);
  }

  void _confirmLocation() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    widget.onLocationSelected(_selectedLocation!);
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.required ? 'Where should we deliver?' : 'Select Delivery Location',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for an address or place...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _suggestions = [];
                                _selectedLocation = null;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color.fromRGBO(24, 95, 45, 1),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: _isGettingCurrentLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      _isGettingCurrentLocation
                          ? 'Getting location...'
                          : 'Use current location',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color.fromRGBO(24, 95, 45, 1),
                      side: const BorderSide(
                        color: Color.fromRGBO(24, 95, 45, 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Suggestions / Recent Locations
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _suggestions.isNotEmpty
                    ? ListView.builder(
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on, color: Colors.green),
                            title: Text(suggestion['address'] ?? ''),
                            onTap: () => _selectLocation(suggestion),
                          );
                        },
                      )
                    : _recentLocations.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'Recent Locations',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _recentLocations.length,
                                  itemBuilder: (context, index) {
                                    final location = _recentLocations[index];
                                    return ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Color.fromRGBO(24, 95, 45, 1),
                                        child: Icon(Icons.location_on, color: Colors.white, size: 20),
                                      ),
                                      title: Text(location['address'] ?? ''),
                                      subtitle: const Text('Tap to use'),
                                      onTap: () => _selectLocation(location),
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  widget.required
                                      ? 'Where should we deliver?'
                                      : 'Search for a location',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    'Enter your delivery address or use your current location',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
          ),

          // Confirm Button
          if (_selectedLocation != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color.fromRGBO(24, 95, 45, 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color.fromRGBO(24, 95, 45, 1),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedLocation!['address'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
