import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:wslny/config/app_colors.dart';
import 'package:wslny/config/env.dart';
import 'package:wslny/models/transit_stop.dart';
import 'package:wslny/models/route_models.dart';
import 'package:wslny/services/geocoding_service.dart';
import 'package:wslny/services/location_service.dart';
import 'package:wslny/services/osrm_service.dart';
import 'package:wslny/services/route_service.dart';
import 'package:wslny/config/routes.dart';
import 'package:wslny/services/overpass_service.dart';

enum PointPickMode { start, end }

/// Green for start (matches map pin)
const Color _startColor = Color(0xFF43A047);

/// Red for end (matches map pin)
const Color _endColor = Color(0xFFE53935);

class MapHomePage extends StatefulWidget {
  const MapHomePage({super.key});

  @override
  State<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends State<MapHomePage> {
  GoogleMapController? _mapController;
  StreamSubscription<LatLng>? _locationSub;
  StreamSubscription<String>? _errorSub;

  final LocationService _locationService = LocationService();
  final OsrmService _osrmService = OsrmService();
  final OverpassService _overpassService = OverpassService();
  final GeocodingService _geocodingService = GeocodingService();
  final RouteService _routeService = RouteService();

  PointPickMode _pickMode = PointPickMode.start;
  LatLng? _myLocation;
  LatLng? _start;
  LatLng? _end;
  String? _locationError;
  bool _isRouting = false;
  String? _routeError;
  List<LatLng> _routePoints = [];
  double? _routeDistanceKm;
  bool _showTransit = false;
  bool _isLoadingTransit = false;
  String? _transitError;
  List<TransitStop> _transitStops = [];
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _searchingLocation = false;
  final _searchController = TextEditingController();
  List<GeocodingPlace> _searchResults = [];
  bool _isSearching = false;
  String? _startAddress;
  String? _endAddress;

  static const LatLng _defaultCenter = LatLng(30.0444, 31.2357); // Cairo

  @override
  void initState() {
    super.initState();
    _errorSub = _locationService.errorStream.listen((msg) {
      if (mounted) setState(() => _locationError = msg);
    });
    _locationSub = _locationService.locationStream.listen((latLng) {
      if (mounted) setState(() => _myLocation = latLng);
    });
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() {
      _locationError = null;
      _searchingLocation = true;
    });
    final pos = await _locationService.getCurrentPosition();
    if (mounted) {
      setState(() {
        _myLocation = pos;
        _searchingLocation = false;
        if (pos != null) _locationError = null;
      });
      if (pos != null) {
        _locationService.startLocationUpdates();
        _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
        _updateMarkers();
      }
    }
  }

  void _updateMarkers() {
    final Set<Marker> m = {};

    // My location marker
    if (_myLocation != null) {
      m.add(
        Marker(
          markerId: const MarkerId('me'),
          position: _myLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'My Location'),
        ),
      );
    }

    // Start location marker
    if (_start != null) {
      m.add(
        Marker(
          markerId: const MarkerId('start'),
          position: _start!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: 'Start Point',
            snippet: _startAddress ?? 'Selected location',
          ),
        ),
      );
    }

    // End location marker
    if (_end != null) {
      m.add(
        Marker(
          markerId: const MarkerId('end'),
          position: _end!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'End Point',
            snippet: _endAddress ?? 'Selected location',
          ),
        ),
      );
    }

    // Transit stop markers
    for (final s in _transitStops) {
      final hue = s.type == TransitStopType.bus
          ? BitmapDescriptor.hueOrange
          : BitmapDescriptor.hueViolet;
      m.add(
        Marker(
          markerId: MarkerId('transit_${s.id}'),
          position: s.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(title: s.name, snippet: '${s.type.name} stop'),
        ),
      );
    }

    setState(
      () => _markers
        ..clear()
        ..addAll(m),
    );
  }

  void _updatePolyline() {
    _polylines.clear();
    if (_routePoints.length >= 2) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: Colors.purple,
          width: 5,
        ),
      );
    }
    setState(() {});
  }

  void _onMapTap(LatLng pos) async {
    // Get place name using reverse geocoding
    String placeName = 'Selected location';
    try {
      debugPrint('Getting place name for: ${pos.latitude}, ${pos.longitude}');
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse')
          .replace(
            queryParameters: {
              'lat': pos.latitude.toString(),
              'lon': pos.longitude.toString(),
              'format': 'json',
              'addressdetails': '1',
            },
          );

      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>?;
        if (data != null && data['display_name'] != null) {
          placeName = data['display_name'].toString();
          debugPrint('Found place name: $placeName');
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
    }

    setState(() {
      if (_pickMode == PointPickMode.start) {
        _start = pos;
        _startAddress = placeName;
      } else {
        _end = pos;
        _endAddress = placeName;
      }
      _routeError = null;
      _routePoints = [];
      _routeDistanceKm = null;
    });
    _updateMarkers();
    if (_start != null && _end != null) _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    if (_start == null || _end == null) return;
    setState(() {
      _isRouting = true;
      _routeError = null;
    });
    final result = await _osrmService.getRoute(_start!, _end!);
    if (!mounted) return;
    setState(() {
      _isRouting = false;
      if (result.isSuccess) {
        _routePoints = result.points;
        _routeDistanceKm = result.distanceKm;
        _routeError = null;
        _updatePolyline();
        _fitRouteBounds();
      } else {
        _routeError = result.error;
        _routePoints = [];
        _routeDistanceKm = null;
        _updatePolyline();
      }
    });
  }

  void _fitRouteBounds() {
    if (_routePoints.isEmpty) return;
    double sLat = _routePoints.first.latitude, nLat = sLat;
    double wLng = _routePoints.first.longitude, eLng = wLng;
    for (final p in _routePoints) {
      if (p.latitude < sLat) sLat = p.latitude;
      if (p.latitude > nLat) nLat = p.latitude;
      if (p.longitude < wLng) wLng = p.longitude;
      if (p.longitude > eLng) eLng = p.longitude;
    }
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(sLat, wLng),
          northeast: LatLng(nLat, eLng),
        ),
        80,
      ),
    );
  }

  void _meToStart() async {
    final pos = _myLocation ?? await _locationService.getCurrentPosition();
    if (pos == null) {
      setState(() => _locationError = 'Location not available');
      return;
    }
    setState(() {
      _start = pos;
      _startAddress = 'My location';
      _routeError = null;
      _routePoints = [];
      _routeDistanceKm = null;
    });
    _updateMarkers();
    if (_end != null) _fetchRoute();
  }

  void _meToEnd() async {
    final pos = _myLocation ?? await _locationService.getCurrentPosition();
    if (pos == null) {
      setState(() => _locationError = 'Location not available');
      return;
    }
    setState(() {
      _end = pos;
      _endAddress = 'My location';
      _routeError = null;
      _routePoints = [];
      _routeDistanceKm = null;
    });
    _updateMarkers();
    if (_start != null) _fetchRoute();
  }

  void _centerOnMe() {
    final pos = _myLocation;
    if (pos != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
    } else {
      setState(() => _locationError = 'Location not available');
    }
  }

  void _clearPoints() {
    setState(() {
      _start = null;
      _end = null;
      _startAddress = null;
      _endAddress = null;
      _routePoints = [];
      _routeDistanceKm = null;
      _routeError = null;
    });
    _updateMarkers();
    _updatePolyline();
  }

  Future<void> _requestRoute() async {
    // Check if we have at least an end point
    if (_end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination point'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Use current location as start if no start point is selected
    LatLng? startPoint = _start;
    if (startPoint == null) {
      if (_myLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for location to be detected or select a start point'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      startPoint = _myLocation;
    }

    // Show route filter selection dialog
    final filter = await _showRouteFilterDialog();
    if (filter == null) return;

    try {
      setState(() {
        _isRouting = true;
        _routeError = null;
      });

      final routeResponse = await _routeService.getRouteByCoordinates(
        originLat: startPoint!.latitude,
        originLon: startPoint.longitude,
        destinationLat: _end!.latitude,
        destinationLon: _end!.longitude,
        filter: filter,
        currentLatitude: _myLocation?.latitude,
        currentLongitude: _myLocation?.longitude,
      );

      if (mounted) {
        // Navigate to route results screen
        Navigator.pushNamed(
          context,
          AppRoutes.routeResults,
          arguments: routeResponse,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _routeError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRouting = false;
        });
      }
    }
  }

  Future<RouteFilter?> _showRouteFilterDialog() async {
    return showDialog<RouteFilter>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Route Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RouteFilter.values.map((filter) {
            return ListTile(
              title: Text(filter.displayName),
              subtitle: Text(_getFilterDescription(filter)),
              onTap: () => Navigator.of(context).pop(filter),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _getFilterDescription(RouteFilter filter) {
    switch (filter) {
      case RouteFilter.optimal:
        return 'Best balance of time, cost, and comfort';
      case RouteFilter.fastest:
        return 'Shortest travel time';
      case RouteFilter.cheapest:
        return 'Lowest cost option';
      case RouteFilter.busOnly:
        return 'Use buses only';
      case RouteFilter.microbusOnly:
        return 'Use microbuses only';
      case RouteFilter.metroOnly:
        return 'Use metro/subway only';
    }
  }

  Future<void> _toggleTransit() async {
    if (_showTransit) {
      setState(() {
        _showTransit = false;
        _transitStops = [];
        _transitError = null;
      });
      _updateMarkers();
      return;
    }
    final center = _myLocation ?? _start ?? _end ?? _defaultCenter;
    const delta = 0.018;
    final sw = LatLng(center.latitude - delta, center.longitude - delta);
    final ne = LatLng(center.latitude + delta, center.longitude + delta);
    setState(() {
      _showTransit = true;
      _isLoadingTransit = true;
      _transitError = null;
    });
    final result = await _overpassService.getTransitStops(sw, ne);
    if (!mounted) return;
    setState(() {
      _isLoadingTransit = false;
      if (result.isSuccess) {
        _transitStops = result.stops;
        _transitError = null;
      } else {
        _transitError = result.error;
        _transitStops = [];
      }
    });
    _updateMarkers();
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _showSearchError('Please enter a location to search');
      return;
    }

    setState(() => _isSearching = true);

    try {
      debugPrint('Searching for: $query');
      final res = await _geocodingService.search(query);

      if (!mounted) return;

      setState(() {
        _isSearching = false;
        _searchResults = res.isSuccess ? res.places : [];
      });

      debugPrint('Search results: ${_searchResults.length} places found');

      if (!res.isSuccess) {
        _showSearchError(res.error ?? 'Search failed');
        return;
      }

      if (_searchResults.isEmpty) {
        _showSearchError('No places found for "$query"');
        return;
      }

      if (mounted) {
        final place = await showModalBottomSheet<GeocodingPlace>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _SearchResultsSheet(results: _searchResults),
        );

        if (place != null && mounted) {
          _onSearchResultTap(place);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        _showSearchError('Search error: $e');
      }
    }
  }

  void _showSearchError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onSearchResultTap(GeocodingPlace place) {
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_pickMode == PointPickMode.start ? 'Start' : 'End'} location selected',
              ),
            ),
          ],
        ),
        backgroundColor: _pickMode == PointPickMode.start
            ? _startColor
            : _endColor,
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() {
      if (_pickMode == PointPickMode.start) {
        _start = place.position;
        _startAddress = place.displayName;
      } else {
        _end = place.position;
        _endAddress = place.displayName;
      }
    });

    // Update markers to show the new pin
    _updateMarkers();

    // Animate camera to the selected location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(place.position, 15),
    );

    // Auto-switch pick mode for convenience
    if (_pickMode == PointPickMode.start && _end == null) {
      setState(() => _pickMode = PointPickMode.end);
    }

    // Fetch route if both points are set
    if (_start != null && _end != null) {
      _fetchRoute();
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _errorSub?.cancel();
    _searchController.dispose();
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = Env.hasGoogleMapsKey;
    final initialPos = _myLocation ?? _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.map_outlined,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Wslny'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.chatbot),
            tooltip: 'Chat',
          ),
          IconButton(
            icon: _searchingLocation
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            onPressed: _searchingLocation ? null : _initLocation,
            tooltip: 'Refresh location',
          ),
        ],
      ),
      body: hasKey
          ? Stack(
              children: [
                GestureDetector(
                  onTapUp: (details) {
                    // Only handle tap when not on overlay; map tap is via onTap on GoogleMap
                  },
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialPos,
                      zoom: 14,
                    ),
                    onMapCreated: (c) {
                      _mapController = c;
                      if (_myLocation != null) {
                        c.animateCamera(CameraUpdate.newLatLng(_myLocation!));
                      }
                      _updateMarkers();
                    },
                    onTap: _onMapTap,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    markers: _markers,
                    polylines: _polylines,
                    mapType: MapType.normal,
                    zoomControlsEnabled: false,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: _SearchBar(
                    controller: _searchController,
                    onSearch: _searchLocation,
                    isLoading: _isSearching,
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 220,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'center',
                        onPressed: _centerOnMe,
                        child: const Icon(Icons.center_focus_strong),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _ControlPanel(
                    pickMode: _pickMode,
                    onPickModeChanged: (m) => setState(() => _pickMode = m),
                    myLocation: _myLocation,
                    start: _start,
                    end: _end,
                    startAddress: _startAddress,
                    endAddress: _endAddress,
                    locationError: _locationError,
                    isRouting: _isRouting,
                    routeError: _routeError,
                    routeDistanceKm: _routeDistanceKm,
                    showTransit: _showTransit,
                    isLoadingTransit: _isLoadingTransit,
                    transitError: _transitError,
                    onMeToStart: _meToStart,
                    onMeToEnd: _meToEnd,
                    onShowTransit: _toggleTransit,
                    onClear: _clearPoints,
                    onRequestRoute: _requestRoute,
                  ),
                ),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Add GOOGLE_MAPS_API_KEY to .env and configure Android/iOS. See .env.example.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool isLoading;

  const _SearchBar({
    required this.controller,
    required this.onSearch,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.search,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Search for a place...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 14),
                onSubmitted: (_) => onSearch(),
                textInputAction: TextInputAction.search,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isLoading ? Colors.grey[300] : AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey[600]!,
                          ),
                        ),
                      )
                    : const Icon(Icons.search, color: Colors.white, size: 20),
                onPressed: isLoading ? null : onSearch,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultsSheet extends StatelessWidget {
  final List<GeocodingPlace> results;

  const _SearchResultsSheet({required this.results});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Search Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${results.length} places',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const Divider(),

          // Results list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: results.length,
              itemBuilder: (context, i) {
                final place = results[i];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getPlaceTypeColor(place.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPlaceTypeIcon(place.type, place.classType),
                      color: _getPlaceTypeColor(place.type),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    place.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        _getPlaceTypeLabel(place.type, place.classType),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (place.importance > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Relevance: ${(place.importance * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.of(context).pop(place),
                );
              },
            ),
          ),

          // Bottom padding
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getPlaceTypeIcon(String type, String classType) {
    switch (type.toLowerCase()) {
      case 'amenity':
        switch (classType.toLowerCase()) {
          case 'restaurant':
          case 'cafe':
          case 'fast_food':
            return Icons.restaurant;
          case 'hotel':
            return Icons.hotel;
          case 'hospital':
            return Icons.local_hospital;
          case 'school':
          case 'university':
            return Icons.school;
          case 'bank':
            return Icons.account_balance;
          case 'pharmacy':
            return Icons.local_pharmacy;
          case 'supermarket':
            return Icons.local_grocery_store;
          case 'parking':
            return Icons.local_parking;
          default:
            return Icons.place;
        }
      case 'shop':
        return Icons.shopping_cart;
      case 'tourism':
        switch (classType.toLowerCase()) {
          case 'hotel':
            return Icons.hotel;
          case 'museum':
            return Icons.museum;
          case 'attraction':
            return Icons.attractions;
          default:
            return Icons.tour;
        }
      case 'highway':
        return Icons.directions_car;
      case 'building':
        return Icons.business;
      case 'leisure':
        return Icons.park;
      case 'natural':
        return Icons.terrain;
      default:
        return Icons.place;
    }
  }

  Color _getPlaceTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'amenity':
        return Colors.blue;
      case 'shop':
        return Colors.purple;
      case 'tourism':
        return Colors.green;
      case 'highway':
        return Colors.orange;
      case 'building':
        return Colors.grey;
      case 'leisure':
        return Colors.teal;
      case 'natural':
        return Colors.brown;
      default:
        return AppColors.primary;
    }
  }

  String _getPlaceTypeLabel(String type, String classType) {
    switch (type.toLowerCase()) {
      case 'amenity':
        switch (classType.toLowerCase()) {
          case 'restaurant':
            return 'Restaurant';
          case 'cafe':
            return 'Café';
          case 'fast_food':
            return 'Fast Food';
          case 'hotel':
            return 'Hotel';
          case 'hospital':
            return 'Hospital';
          case 'school':
            return 'School';
          case 'university':
            return 'University';
          case 'bank':
            return 'Bank';
          case 'pharmacy':
            return 'Pharmacy';
          case 'supermarket':
            return 'Supermarket';
          case 'parking':
            return 'Parking';
          default:
            return 'Amenity';
        }
      case 'shop':
        return 'Shop';
      case 'tourism':
        switch (classType.toLowerCase()) {
          case 'hotel':
            return 'Hotel';
          case 'museum':
            return 'Museum';
          case 'attraction':
            return 'Attraction';
          default:
            return 'Tourist Place';
        }
      case 'highway':
        return 'Road';
      case 'building':
        return 'Building';
      case 'leisure':
        return 'Leisure';
      case 'natural':
        return 'Natural Feature';
      default:
        return 'Place';
    }
  }
}

class _ControlPanel extends StatelessWidget {
  final PointPickMode pickMode;
  final ValueChanged<PointPickMode> onPickModeChanged;
  final LatLng? myLocation;
  final LatLng? start;
  final LatLng? end;
  final String? startAddress;
  final String? endAddress;
  final String? locationError;
  final bool isRouting;
  final String? routeError;
  final double? routeDistanceKm;
  final bool showTransit;
  final bool isLoadingTransit;
  final String? transitError;
  final VoidCallback onMeToStart;
  final VoidCallback onMeToEnd;
  final VoidCallback onShowTransit;
  final VoidCallback onClear;
  final VoidCallback onRequestRoute;

  const _ControlPanel({
    required this.pickMode,
    required this.onPickModeChanged,
    required this.myLocation,
    required this.start,
    required this.end,
    this.startAddress,
    this.endAddress,
    required this.locationError,
    required this.isRouting,
    required this.routeError,
    required this.routeDistanceKm,
    required this.showTransit,
    required this.isLoadingTransit,
    required this.transitError,
    required this.onMeToStart,
    required this.onMeToEnd,
    required this.onShowTransit,
    required this.onClear,
    required this.onRequestRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<PointPickMode>(
              segments: [
                ButtonSegment(
                  value: PointPickMode.start,
                  label: const Text('Pick Start'),
                  icon: const Icon(Icons.trip_origin, color: _startColor),
                ),
                ButtonSegment(
                  value: PointPickMode.end,
                  label: const Text('Pick End'),
                  icon: const Icon(Icons.flag, color: _endColor),
                ),
              ],
              selected: {pickMode},
              onSelectionChanged: (s) => onPickModeChanged(s.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return pickMode == PointPickMode.start
                        ? _startColor.withOpacity(0.2)
                        : _endColor.withOpacity(0.2);
                  }
                  return null;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return pickMode == PointPickMode.start
                        ? _startColor
                        : _endColor;
                  }
                  return null;
                }),
              ),
            ),
            if (startAddress != null || endAddress != null) ...[
              const SizedBox(height: 10),
              if (startAddress != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.trip_origin, size: 18, color: _startColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        startAddress!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _startColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (startAddress != null && endAddress != null)
                const SizedBox(height: 4),
              if (endAddress != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.flag, size: 18, color: _endColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        endAddress!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _endColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onMeToStart,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Me → Start'),
                ),
                FilledButton.icon(
                  onPressed: onMeToEnd,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Me → End'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isLoadingTransit ? null : onShowTransit,
                  icon: showTransit
                      ? const Icon(Icons.directions_transit, size: 18)
                      : const Icon(Icons.directions_transit_outlined, size: 18),
                  label: Text(showTransit ? 'Hide transit' : 'Show transit'),
                ),
                OutlinedButton(
                  onPressed: (start != null || end != null) ? onClear : null,
                  child: const Text('Clear'),
                ),
              ],
            ),
            // Route Request Button (show if we have at least an end point)
            if (end != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isRouting ? null : onRequestRoute,
                  icon: isRouting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.directions, size: 18),
                  label: Text(isRouting 
                      ? 'Getting Route...' 
                      : start != null 
                          ? 'Get Route' 
                          : 'Get Route from My Location'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            if (locationError != null) ...[
              const SizedBox(height: 8),
              Text(
                locationError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (isRouting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
            if (routeError != null)
              Text(
                routeError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (routeDistanceKm != null)
              Text(
                'Distance: ${routeDistanceKm!.toStringAsFixed(2)} km',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            if (transitError != null)
              Text(
                transitError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            if (myLocation != null)
              Text(
                'Lat: ${myLocation!.latitude.toStringAsFixed(4)}, Lng: ${myLocation!.longitude.toStringAsFixed(4)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 4),
            Text(
              'Tap map to set point • Or type above and search',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
