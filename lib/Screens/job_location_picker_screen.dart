import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:job_seeker_app/widgets/app_ui.dart';

class JobLocationSelection {
  const JobLocationSelection({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;

  LatLng get point => LatLng(latitude, longitude);
}

class JobLocationPickerScreen extends StatefulWidget {
  const JobLocationPickerScreen({
    super.key,
    this.initialSelection,
  });

  final JobLocationSelection? initialSelection;

  @override
  State<JobLocationPickerScreen> createState() =>
      _JobLocationPickerScreenState();
}

class _JobLocationPickerScreenState extends State<JobLocationPickerScreen> {
  static const LatLng _fallbackCenter = LatLng(6.9271, 79.8612);
  static const double _defaultZoom = 16.0;

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _addressDebounce;
  late LatLng _selectedPoint;
  String? _resolvedAddress;
  bool _isResolvingAddress = false;
  bool _isFetchingCurrentLocation = false;
  bool _isSearchingLocation = false;
  bool _hasExplicitSelection = false;

  @override
  void initState() {
    super.initState();

    final selection = widget.initialSelection;
    _selectedPoint = selection?.point ?? _fallbackCenter;
    final initialAddress = selection?.address.trim();
    _resolvedAddress =
        initialAddress?.isNotEmpty == true ? initialAddress : null;
    if (_resolvedAddress != null) {
      _searchController.text = _resolvedAddress!;
    }
    _hasExplicitSelection = selection != null;
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _handlePositionChanged(MapCamera camera, bool hasGesture) {
    _selectedPoint = camera.center;

    if (hasGesture && !_hasExplicitSelection) {
      setState(() {
        _hasExplicitSelection = true;
      });
    }

    if (hasGesture) {
      _scheduleAddressLookup(camera.center);
    }
  }

  Future<void> _searchLocation() async {
    if (_isSearchingLocation) return;

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _showSnackBar('Enter a place or address to search.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSearchingLocation = true;
    });

    try {
      final matches = await locationFromAddress(query);
      if (matches.isEmpty) {
        _showSnackBar('No location found for "$query".');
        return;
      }

      final match = matches.first;
      final point = LatLng(match.latitude, match.longitude);

      setState(() {
        _selectedPoint = point;
        _hasExplicitSelection = true;
        _resolvedAddress = null;
      });

      _mapController.move(point, _defaultZoom);
      _scheduleAddressLookup(point);
    } catch (_) {
      _showSnackBar('Unable to search that location. Try another place name.');
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingLocation = false;
        });
      }
    }
  }

  void _scheduleAddressLookup(LatLng point) {
    _addressDebounce?.cancel();

    if (mounted) {
      if (!_isResolvingAddress) {
        setState(() {
          _isResolvingAddress = true;
        });
      } else {
        _isResolvingAddress = true;
      }
    } else {
      _isResolvingAddress = true;
    }

    _addressDebounce = Timer(const Duration(milliseconds: 450), () async {
      final resolvedAddress = await _resolveAddress(point);

      if (!mounted || !_isSamePoint(_selectedPoint, point)) {
        return;
      }

      setState(() {
        _resolvedAddress = resolvedAddress?.trim().isNotEmpty == true
            ? resolvedAddress!.trim()
            : _formatCoordinates(point);
        _isResolvingAddress = false;
      });
    });
  }

  Future<String?> _resolveAddress(LatLng point) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      if (placemarks.isEmpty) {
        return null;
      }

      final place = placemarks.first;
      final addressParts = <String>[
        if (place.subThoroughfare?.trim().isNotEmpty ?? false)
          place.subThoroughfare!.trim(),
        if (place.thoroughfare?.trim().isNotEmpty ?? false)
          place.thoroughfare!.trim(),
        if (place.subLocality?.trim().isNotEmpty ?? false)
          place.subLocality!.trim(),
        if (place.locality?.trim().isNotEmpty ?? false) place.locality!.trim(),
        if (place.administrativeArea?.trim().isNotEmpty ?? false)
          place.administrativeArea!.trim(),
        if (place.country?.trim().isNotEmpty ?? false) place.country!.trim(),
      ];

      if (addressParts.isEmpty) {
        return null;
      }

      return addressParts.join(', ');
    } catch (_) {
      return null;
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_isFetchingCurrentLocation) return;

    setState(() {
      _isFetchingCurrentLocation = true;
    });

    try {
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        _showSnackBar(
          'Location services are disabled. Please enable them first.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permission denied.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
          'Location permission is permanently denied. Open app settings to continue.',
        );
        await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final point = LatLng(position.latitude, position.longitude);
      _mapController.move(point, _defaultZoom);

      _selectedPoint = point;
      if (!_hasExplicitSelection) {
        setState(() {
          _hasExplicitSelection = true;
        });
      }
      _scheduleAddressLookup(point);
    } catch (_) {
      _showSnackBar('Unable to fetch your current location.');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCurrentLocation = false;
        });
      }
    }
  }

  void _confirmSelection() {
    final address =
        !_isResolvingAddress && _resolvedAddress?.trim().isNotEmpty == true
            ? _resolvedAddress!.trim()
            : _formatCoordinates(_selectedPoint);

    Navigator.of(context).pop(
      JobLocationSelection(
        address: address,
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isSamePoint(LatLng a, LatLng b) {
    const epsilon = 0.000001;
    return (a.latitude - b.latitude).abs() < epsilon &&
        (a.longitude - b.longitude).abs() < epsilon;
  }

  String _formatCoordinates(LatLng point) {
    return '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final addressText = _isResolvingAddress
        ? 'Resolving the new location...'
        : _resolvedAddress?.trim().isNotEmpty == true
            ? _resolvedAddress!.trim()
            : _hasExplicitSelection
                ? _formatCoordinates(_selectedPoint)
                : 'Move the map to choose the exact job site.';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Pick Exact Location'),
      ),
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedPoint,
                        initialZoom: _defaultZoom,
                        minZoom: 4,
                        maxZoom: 19,
                        onPositionChanged: _handlePositionChanged,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'job_seeker_app',
                        ),
                      ],
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 16,
                      child: AppGlassCard(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _searchLocation(),
                          decoration: InputDecoration(
                            hintText: 'Search place or address',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: IconButton(
                              tooltip: 'Search',
                              onPressed:
                                  _isSearchingLocation ? null : _searchLocation,
                              icon: _isSearchingLocation
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_forward_rounded),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.75),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.88),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.14),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.location_pin,
                                size: 40,
                                color: scheme.error,
                              ),
                            ),
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: scheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: AppGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppDecoratedIcon(
                            icon: Icons.place_outlined,
                            color: scheme.primary,
                            backgroundColor:
                                scheme.primary.withValues(alpha: 0.14),
                            size: 50,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isResolvingAddress) ...[
                        const LinearProgressIndicator(minHeight: 2),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        addressText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isFetchingCurrentLocation
                                  ? null
                                  : _useCurrentLocation,
                              icon: _isFetchingCurrentLocation
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.my_location_outlined),
                              label: const Text('Current'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _hasExplicitSelection
                                  ? _confirmSelection
                                  : null,
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Confirm location'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
