import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../features/delivery_location/pages/delivery_locations.dart';

class DeliveryLocationsService {
  static Future<void> createMarkers(
      Set<Marker> markers, List<Map<String, dynamic>> deliveryLocations) async {
    deliveryLocations.forEach((location) async {
      final marker = await _createMarker(location);
      markers.add(marker);
    });
  }

  static Future<Marker> _createMarker(Map<String, dynamic> location) async {
    final BitmapDescriptor icon = await _getAssetIcon(location['marker']);
    return Marker(
      markerId: MarkerId(location['name']),
      position: location['position'],
      icon: icon,
      infoWindow: InfoWindow(
        title: location['name'],
        snippet: 'Delivery location',
      ),
    );
  }

  static Future<BitmapDescriptor> _getAssetIcon(String icon) async {
    BuildContext context = DeliveryLocations.navigatorKey.currentContext!;
    final Completer<BitmapDescriptor> bitmapIcon =
        Completer<BitmapDescriptor>();
    final ImageConfiguration config =
        createLocalImageConfiguration(context, size: const Size(5, 5));

    AssetImage(icon)
        .resolve(config)
        .addListener(ImageStreamListener((ImageInfo image, bool sync) async {
      final ByteData? bytes =
          await image.image.toByteData(format: ImageByteFormat.png);
      final BitmapDescriptor bitmap =
          BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
      bitmapIcon.complete(bitmap);
    }));

    return await bitmapIcon.future;
  }
}
