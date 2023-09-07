import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../backend/delivery_locations_service.dart';
import '../model/map_style.dart';

class DeliveryLocations extends StatefulWidget {
  const DeliveryLocations({Key? key}) : super(key: key);
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<DeliveryLocations> createState() => _DeliveryLocationsState();
}

class _DeliveryLocationsState extends State<DeliveryLocations> {
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  final Set<Marker> _markers = {};
  late GoogleMapController _controller;
  final DeliveryLocationsService _deliveryLocationsService =
      DeliveryLocationsService();

  final List<Map<String, dynamic>> _deliveryLocations = [
    {
      "name": "Home",
      "position": const LatLng(37.42796133580664, -122.085749655962),
      "marker": 'assets/markers/home_marker.png',
    },
    {
      "name": "Work",
      "position": const LatLng(37.42484642575639, -122.08309359848501),
      "marker": 'assets/markers/work_marker.png',
    },
    {
      "name": "Restaurant",
      "position": const LatLng(37.42381625902441, -122.0928531512618),
      "marker": 'assets/markers/restaurant_marker.png',
    },
    // Add more delivery locations as needed
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    DeliveryLocationsService.createMarkers(_markers, _deliveryLocations);

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _kGooglePlex,
            markers: _markers,
            myLocationButtonEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              _controller.setMapStyle(MapStyle().dark);
            },
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 120,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _deliveryLocations.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _controller.moveCamera(CameraUpdate.newLatLng(
                          _deliveryLocations[index]["position"]));
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            _deliveryLocations[index]['marker'],
                            width: 60,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            _deliveryLocations[index]["name"],
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
