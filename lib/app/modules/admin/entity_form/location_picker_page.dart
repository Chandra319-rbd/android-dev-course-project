import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';

class LocationPickerPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _currentCenter;
  bool _isLoading = true;
  String _selectedAddress = '';
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _currentCenter = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      setState(() {
        _isLoading = false;
      });
      _getAddressFromLatLng(widget.initialLatitude!, widget.initialLongitude!);
    } else {
      await _getCurrentLocation();
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _selectedAddress =
              '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _searchLocation() async {
    if (_searchController.text.isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(
        _searchController.text,
      );
      if (locations.isNotEmpty) {
        Location location = locations[0];
        _currentCenter = LatLng(location.latitude, location.longitude);
        _mapController.move(_currentCenter!, 15.0);
        _getAddressFromLatLng(location.latitude, location.longitude);
      }
    } catch (e) {
      Get.snackbar('Error', 'Location not found');
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Error', 'Location services are disabled.');
      setState(() {
        _isLoading = false;
        _currentCenter = const LatLng(0, 0);
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Error', 'Location permissions are denied');
        setState(() {
          _isLoading = false;
          _currentCenter = const LatLng(0, 0);
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('Error', 'Location permissions are permanently denied.');
      setState(() {
        _isLoading = false;
        _currentCenter = const LatLng(0, 0);
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      _getAddressFromLatLng(position.latitude, position.longitude);
    } catch (e) {
      Get.snackbar('Error', 'Failed to get current location: $e');
      setState(() {
        _isLoading = false;
        _currentCenter = const LatLng(0, 0);
      });
    }
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    setState(() {
      _currentCenter = camera.center;
    });
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_currentCenter != null) {
        _getAddressFromLatLng(
          _currentCenter!.latitude,
          _currentCenter!.longitude,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppColors.chineseRed,
        foregroundColor: Colors.white,
        title: Card(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search location...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: AppColors.chineseRed),
                onPressed: _searchLocation,
              ),
            ),
            onSubmitted: (_) => _searchLocation(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_currentCenter != null) {
                Get.back(result: _currentCenter);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.chineseRed),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentCenter ?? const LatLng(0, 0),
                    initialZoom: 15.0,
                    onPositionChanged: _onMapPositionChanged,
                    onTap: (tapPosition, point) {
                      _mapController.move(point, _mapController.camera.zoom);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.jvapp',
                    ),
                  ],
                ),
                const Center(
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.chineseRed,
                    size: 40,
                  ),
                ),
                Positioned(
                  bottom: 80,
                  left: 10,
                  right: 10,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Selected Location:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedAddress.isNotEmpty
                                ? _selectedAddress
                                : 'Fetching address...',
                            style: const TextStyle(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor: AppColors.chineseRed,
                    child: const Icon(Icons.my_location, color: Colors.white),
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      await _getCurrentLocation();
                      if (_currentCenter != null) {
                        _mapController.move(_currentCenter!, 15.0);
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
