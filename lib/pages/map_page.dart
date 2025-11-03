// lib/pages/map_page.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/navigation.dart';
import 'camera_page.dart';

enum PlaceCategory {
  collectionPoint,
  dropzone,
  pickupService,
  ewasteShop,
  electronicsShop,
}

extension PlaceCategoryExt on PlaceCategory {
  String get label {
    switch (this) {
      case PlaceCategory.collectionPoint:
        return 'Collection';
      case PlaceCategory.dropzone:
        return 'Dropzone';
      case PlaceCategory.pickupService:
        return 'Pickup';
      case PlaceCategory.ewasteShop:
        return 'E-Waste Shop';
      case PlaceCategory.electronicsShop:
        return 'Electronics';
    }
  }

  Color get color {
    switch (this) {
      case PlaceCategory.collectionPoint:
        return Colors.green;
      case PlaceCategory.dropzone:
        return Colors.orange;
      case PlaceCategory.pickupService:
        return Colors.blue;
      case PlaceCategory.ewasteShop:
        return Colors.deepPurple;
      case PlaceCategory.electronicsShop:
        return Colors.redAccent;
    }
  }
}

class MapPlace {
  final String id;
  final String name;
  final LatLng location;
  final PlaceCategory category;
  final String? address;
  final String? phone;

  MapPlace({
    required this.id,
    required this.name,
    required this.location,
    required this.category,
    this.address,
    this.phone,
  });
}

/// Shared sample/default places. Edit/add to this list to provide more POIs.
final List<MapPlace> kDefaultPlaces = [
  MapPlace(
    id: 'p1',
    name: 'GreenCollect Center - Barangay Hall',
    location: LatLng(14.6578, 121.0178),
    category: PlaceCategory.collectionPoint,
    address: 'Barangay Hall, Sampalok',
  ),
  MapPlace(
    id: 'p2',
    name: 'E-Waste Dropzone A - Market',
    location: LatLng(14.6590, 121.0192),
    category: PlaceCategory.dropzone,
    address: 'Market compound, Block A',
  ),
  MapPlace(
    id: 'p3',
    name: 'Recycle Pickup Service (Local)',
    location: LatLng(14.6560, 121.0150),
    category: PlaceCategory.pickupService,
    address: 'Near Town Plaza',
    phone: '09170001111',
  ),
  MapPlace(
    id: 'p4',
    name: 'Fix & Reuse Electronics',
    location: LatLng(14.6580, 121.0130),
    category: PlaceCategory.electronicsShop,
    address: 'Main Street 12',
    phone: '09881234567',
  ),
  MapPlace(
    id: 'p5',
    name: 'E-Waste Specialist Depot',
    location: LatLng(14.6572, 121.0164),
    category: PlaceCategory.ewasteShop,
    address: 'District 3 Recycling Rd',
  ),
  MapPlace(
    id: 'p6',
    name: 'Battery Recycling Point',
    location: LatLng(14.6600, 121.0180),
    category: PlaceCategory.collectionPoint,
    address: 'Shop 5, Green Mall',
  ),
  MapPlace(
    id: 'p7',
    name: 'School Club Drop-off',
    location: LatLng(14.6550, 121.0142),
    category: PlaceCategory.dropzone,
    address: 'Community School',
  ),
  MapPlace(
    id: 'p8',
    name: 'Neighborhood Electronics Repair',
    location: LatLng(14.6595, 121.0128),
    category: PlaceCategory.electronicsShop,
    address: 'Corner 3rd & Rizal',
  ),
];

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _loading = false;
  String _status = 'Initializing...';
  final Map<PlaceCategory, bool> _filters = {
    for (var c in PlaceCategory.values) c: true,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  Future<void> _initLocation() async {
    setState(() => _status = 'Checking...');
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _status = 'Enable GPS';
      });
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied)
      perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied) {
      setState(() {
        _status = 'Location denied';
      });
      return;
    }
    if (perm == LocationPermission.deniedForever) {
      setState(() {
        _status = 'Permission blocked';
      });
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        14.0,
      );
      setState(() => _status = 'Ready');
    } catch (e) {
      setState(() => _status = 'Location error');
    }
  }

  LatLng _toLatLng(Position p) => LatLng(p.latitude, p.longitude);

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];
    for (final p in kDefaultPlaces) {
      if (!(_filters[p.category] ?? true)) continue;
      markers.add(
        Marker(
          width: 44,
          height: 44,
          point: p.location,
          builder: (ctx) => GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: ctx,
                builder: (c) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.place_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            p.category.label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      if (p.address != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          p.address!,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              if (_currentPosition == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Current location not available',
                                    ),
                                  ),
                                );
                                return;
                              }
                              final origin =
                                  '${_currentPosition!.latitude},${_currentPosition!.longitude}';
                              final dest =
                                  '${p.location.latitude},${p.location.longitude}';
                              final urlWeb =
                                  'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest&travelmode=driving';
                              if (await canLaunchUrl(Uri.parse(urlWeb)))
                                await launchUrl(Uri.parse(urlWeb));
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text('Navigate'),
                          ),
                          const SizedBox(width: 6),
                          TextButton.icon(
                            onPressed: p.phone != null
                                ? () async {
                                    final uri = Uri.parse('tel:${p.phone}');
                                    if (await canLaunchUrl(uri))
                                      await launchUrl(uri);
                                  }
                                : null,
                            icon: const Icon(Icons.phone),
                            label: Text(p.phone ?? 'No phone'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 4,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: p.category.color,
                child: const Icon(Icons.location_on, color: Colors.white),
              ),
            ),
          ),
        ),
      );
    }

    if (_currentPosition != null) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: _toLatLng(_currentPosition!),
          builder: (_) => const CircleAvatar(
            radius: 16,
            child: Icon(Icons.my_location, size: 18),
          ),
        ),
      );
    }

    return markers;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (c) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PlaceCategory.values.map((cat) {
                  final enabled = _filters[cat] ?? true;
                  return FilterChip(
                    avatar: CircleAvatar(
                      radius: 12,
                      backgroundColor: cat.color,
                      child: const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    label: Text(cat.label),
                    selected: enabled,
                    onSelected: (v) => setState(() => _filters[cat] = v),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _centerOnMe() async {
    try {
      setState(() => _loading = true);
      await _initLocation();
      if (_currentPosition != null) {
        _mapController.move(_toLatLng(_currentPosition!), 15.0);
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openScan() async {
    await Navigator.of(
      context,
    ).push<String?>(MaterialPageRoute(builder: (c) => const CameraPage()));
    // You can add post-scan logic here if needed.
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(14.6578, 121.0178);
    final markers = _buildMarkers();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Collection & E-Waste Map'),
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: center,
          zoom: 13.0,
          minZoom: 3,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.ewise',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openScan,
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.camera_alt, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const EwasteNavigationBar(selectedIndex: 1),
    );
  }
}
