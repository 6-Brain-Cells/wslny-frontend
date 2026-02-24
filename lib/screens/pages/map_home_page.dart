import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wslny/config/app_colors.dart';
import 'package:wslny/config/env.dart';
import 'package:wslny/models/transit_stop.dart';
import 'package:wslny/services/geocoding_service.dart';
import 'package:wslny/services/location_service.dart';
import 'package:wslny/services/osrm_service.dart';
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
    if (_myLocation != null) {
      m.add(Marker(
        markerId: const MarkerId('me'),
        position: _myLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'My location'),
      ));
    }
    if (_start != null) {
      m.add(Marker(
        markerId: const MarkerId('start'),
        position: _start!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Start'),
      ));
    }
    if (_end != null) {
      m.add(Marker(
        markerId: const MarkerId('end'),
        position: _end!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'End'),
      ));
    }
    for (final s in _transitStops) {
      final hue = s.type == TransitStopType.bus
          ? BitmapDescriptor.hueOrange
          : BitmapDescriptor.hueViolet;
      m.add(Marker(
        markerId: MarkerId('transit_${s.id}'),
        position: s.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(title: s.name),
      ));
    }
    setState(() => _markers
      ..clear()
      ..addAll(m));
  }

  void _updatePolyline() {
    _polylines.clear();
    if (_routePoints.length >= 2) {
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: Colors.purple,
        width: 5,
      ));
    }
    setState(() {});
  }

  void _onMapTap(LatLng pos) {
    setState(() {
      if (_pickMode == PointPickMode.start) {
        _start = pos;
        _startAddress = 'Dropped pin';
      } else {
        _end = pos;
        _endAddress = 'Dropped pin';
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
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    final res = await _geocodingService.search(query);
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _searchResults = res.isSuccess ? res.places : [];
    });
    if (res.isSuccess && _searchResults.isNotEmpty && mounted) {
      final place = await showModalBottomSheet<GeocodingPlace>(
        context: context,
        builder: (ctx) => _SearchResultsSheet(results: _searchResults),
      );
      if (place != null && mounted) _onSearchResultTap(place);
    }
  }

  void _onSearchResultTap(GeocodingPlace place) {
    setState(() {
      if (_pickMode == PointPickMode.start) {
        _start = place.position;
        _startAddress = place.displayName;
      } else {
        _end = place.position;
        _endAddress = place.displayName;
      }
    });
    _updateMarkers();
    if (_start != null && _end != null) _fetchRoute();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(place.position, 14),
    );
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
              child: const Icon(Icons.map_outlined, size: 20, color: Colors.white),
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
                        c.animateCamera(
                          CameraUpdate.newLatLng(_myLocation!),
                        );
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
                    onPickModeChanged: (m) =>
                        setState(() => _pickMode = m),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Type location or tap map',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => onSearch(),
              ),
            ),
            IconButton(
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              onPressed: isLoading ? null : onSearch,
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
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      maxChildSize: 0.7,
      minChildSize: 0.2,
      expand: false,
      builder: (context, scrollController) {
        if (results.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No results'),
          );
        }
        return ListView.builder(
          controller: scrollController,
          itemCount: results.length,
          itemBuilder: (context, i) {
            final p = results[i];
            return ListTile(
              leading: const Icon(Icons.place),
              title: Text(
                p.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(context).pop(p),
            );
          },
        );
      },
    );
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
