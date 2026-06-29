import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../models/route_models.dart';
import '../../models/transit_stop.dart';
import '../../services/osrm_service.dart';
import '../../services/chat_storage_service.dart';
import '../../services/overpass_service.dart';
import '../../widgets/common/route_feedback_dialog.dart';

class RouteResultsPage extends StatefulWidget {
  final RouteResponse routeResponse;

  const RouteResultsPage({super.key, required this.routeResponse});

  @override
  State<RouteResultsPage> createState() => _RouteResultsPageState();
}

class _RouteResultsPageState extends State<RouteResultsPage> {
  GoogleMapController? _mapController;
  int _selectedSegmentIndex = 0;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _setupMapData();
      _checkIfSaved();
    });
  }

  Future<void> _setupMapData() async {
    _markers.clear();
    _polylines.clear();

    final route = widget.routeResponse.route;
    final segments = route?.segments ?? [];

    // Add start marker
    if (segments.isNotEmpty) {
      final startLocation = segments.first.startLocation;
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(startLocation.lat, startLocation.lon),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: 'Start',
            snippet:
                startLocation.name ??
                widget.routeResponse.fromName ??
                'Start Point',
          ),
        ),
      );
    }

    // Add end marker
    if (segments.isNotEmpty) {
      final endLocation = segments.last.endLocation;
      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: LatLng(endLocation.lat, endLocation.lon),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet:
                endLocation.name ??
                widget.routeResponse.toName ??
                'Destination',
          ),
        ),
      );
    }

    // Add intermediate markers for each segment
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];

      // Add marker for segment start (except first segment)
      if (i > 0) {
        _markers.add(
          Marker(
            markerId: MarkerId('segment_start_$i'),
            position: LatLng(
              segment.startLocation.lat,
              segment.startLocation.lon,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(
              title: 'Transfer Point',
              snippet: segment.startLocation.name ?? 'Transfer',
            ),
          ),
        );
      }
    }

    // Create polylines for each segment using OSRM
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final color = _getSegmentColor(segment.method);

      // For metro segments, add intermediate station markers
      if (segment.method.toLowerCase() == 'metro' ||
          segment.method.toLowerCase() == 'subway') {
        await _addMetroStationMarkers(segment, i);
      }

      try {
        final osrmService = OsrmService();
        final osrmResult = await osrmService.getRoute(
          LatLng(segment.startLocation.lat, segment.startLocation.lon),
          LatLng(segment.endLocation.lat, segment.endLocation.lon),
        );

        if (osrmResult.isSuccess && osrmResult.points.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: PolylineId('segment_$i'),
              points: osrmResult.points,
              color: color,
              width: 4,
              patterns: segment.method == 'walk'
                  ? [PatternItem.dash(10), PatternItem.gap(5)]
                  : [],
            ),
          );
        } else {
          // Fallback to straight line if OSRM fails
          _polylines.add(
            Polyline(
              polylineId: PolylineId('segment_$i'),
              points: [
                LatLng(segment.startLocation.lat, segment.startLocation.lon),
                LatLng(segment.endLocation.lat, segment.endLocation.lon),
              ],
              color: color,
              width: 4,
              patterns: segment.method == 'walk'
                  ? [PatternItem.dash(10), PatternItem.gap(5)]
                  : [],
            ),
          );
        }
      } catch (e) {
        debugPrint("OSRM error for segment $i: $e");
        // Fallback to straight line if OSRM fails
        _polylines.add(
          Polyline(
            polylineId: PolylineId('segment_$i'),
            points: [
              LatLng(segment.startLocation.lat, segment.startLocation.lon),
              LatLng(segment.endLocation.lat, segment.endLocation.lon),
            ],
            color: color,
            width: 4,
            patterns: segment.method == 'walk'
                ? [PatternItem.dash(10), PatternItem.gap(5)]
                : [],
          ),
        );
      }
    }

    setState(() {});
  }

  Color _getSegmentColor(String method) {
    switch (method.toLowerCase()) {
      case 'walk':
        return Colors.orange;
      case 'bus':
        return Colors.blue;
      case 'microbus':
        return Colors.green;
      case 'metro':
      case 'subway':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'walk':
        return Icons.directions_walk;
      case 'bus':
        return Icons.directions_bus;
      case 'microbus':
        return Icons.airport_shuttle;
      case 'metro':
      case 'subway':
        return Icons.train;
      default:
        return Icons.directions;
    }
  }

  void _onSegmentTapped(int index) {
    setState(() {
      _selectedSegmentIndex = index;
    });

    // Focus map on selected segment
    final route = widget.routeResponse.route;
    final segments = route?.segments ?? [];
    if (index >= segments.length) return;
    final segment = segments[index];
    final bounds = LatLngBounds(
      southwest: LatLng(
        [
          segment.startLocation.lat,
          segment.endLocation.lat,
        ].reduce((a, b) => a < b ? a : b),
        [
          segment.startLocation.lon,
          segment.endLocation.lon,
        ].reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        [
          segment.startLocation.lat,
          segment.endLocation.lat,
        ].reduce((a, b) => a > b ? a : b),
        [
          segment.startLocation.lon,
          segment.endLocation.lon,
        ].reduce((a, b) => a > b ? a : b),
      ),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  Future<void> _addMetroStationMarkers(
    RouteSegment segment,
    int segmentIndex,
  ) async {
    try {
      final overpassService = OverpassService();

      // Calculate center point of the route segment for transit search
      final centerLat =
          (segment.startLocation.lat + segment.endLocation.lat) / 2;
      final centerLon =
          (segment.startLocation.lon + segment.endLocation.lon) / 2;
      final center = LatLng(centerLat, centerLon);

      // Fetch transit stops around the segment center
      final result = await overpassService.getTransitStops(center);

      if (!result.isSuccess) {
        debugPrint('Error fetching transit stops: ${result.error}');
        return;
      }

      // Filter to only include metro stations
      final metroStations = result.stops
          .where((stop) => stop.type == TransitStopType.metro)
          .toList();

      // Add markers for each station
      for (int i = 0; i < metroStations.length; i++) {
        final station = metroStations[i];
        _markers.add(
          Marker(
            markerId: MarkerId('metro_station_${segmentIndex}_$i'),
            position: station.position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
            infoWindow: InfoWindow(
              title: 'Metro Station',
              snippet: station.name,
            ),
          ),
        );
      }

      debugPrint(
        'Added ${metroStations.length} metro stations for segment $segmentIndex',
      );
    } catch (e) {
      debugPrint('Error fetching metro stations: $e');
    }
  }

  void _fitAllSegments() {
    final route = widget.routeResponse.route;
    final segments = route?.segments ?? [];
    if (segments.isEmpty) return;
    final allPoints = segments
        .expand(
          (s) => [
            LatLng(s.startLocation.lat, s.startLocation.lon),
            LatLng(s.endLocation.lat, s.endLocation.lon),
          ],
        )
        .toList();

    if (allPoints.isEmpty) return;

    final lats = allPoints.map((p) => p.latitude).toList();
    final lngs = allPoints.map((p) => p.longitude).toList();

    final bounds = LatLngBounds(
      southwest: LatLng(
        lats.reduce((a, b) => a < b ? a : b),
        lngs.reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        lats.reduce((a, b) => a > b ? a : b),
        lngs.reduce((a, b) => a > b ? a : b),
      ),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  Future<void> _showFeedbackDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (context) =>
          RouteFeedbackDialog(requestId: widget.routeResponse.requestId),
    );
  }

  Future<void> _checkIfSaved() async {
    try {
      final isFavorite = await ChatStorageService.isRouteFavorite(
        widget.routeResponse.requestId,
      );
      if (mounted) {
        setState(() {
          _isSaved = isFavorite;
        });
      }
    } catch (e) {
      debugPrint('Error checking saved routes: $e');
    }
  }

  Future<void> _toggleSaveRoute() async {
    try {
      final routeName =
          'from: ${widget.routeResponse.fromName ?? "Start"} to: ${widget.routeResponse.toName ?? "Destination"}';

      if (_isSaved) {
        // Remove from favorites
        await ChatStorageService.removeFavoriteRoute(
          widget.routeResponse.requestId,
        );

        if (mounted) {
          setState(() {
            _isSaved = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Route removed from favorites'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Add to favorites
        await ChatStorageService.saveFavoriteRoute(
          widget.routeResponse,
          routeName,
        );

        if (mounted) {
          setState(() {
            _isSaved = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Route saved to favorites'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorites'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getSegmentTitle(RouteSegment segment, int index) {
    final method = segment.method.toLowerCase();
    final start = segment.startLocation.name ?? 'Point ${index + 1}';
    final end = segment.endLocation.name ?? 'Point ${index + 2}';

    switch (method) {
      case 'walk':
        return 'Walk from $start to $end';
      case 'bus':
        return 'Bus from $start to $end';
      case 'microbus':
        return 'Microbus from $start to $end';
      case 'metro':
      case 'subway':
        return 'Metro from $start to $end';
      default:
        return '$method from $start to $end';
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.routeResponse.route;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleSaveRoute,
            tooltip: _isSaved ? 'Remove from favorites' : 'Save to favorites',
          ),
          IconButton(
            icon: const Icon(Icons.rate_review_outlined),
            onPressed: _showFeedbackDialog,
            tooltip: 'Rate this route',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: _fitAllSegments,
            tooltip: 'Fit all segments',
          ),
        ],
      ),
      body: Column(
        children: [
          // Route Summary Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.route, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'from: ${widget.routeResponse.fromName ?? "Origin"} to: ${widget.routeResponse.toName ?? "Destination"}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryItem(
                          icon: Icons.access_time,
                          label: 'Duration',
                          value: route?.totalDurationFormatted ?? 'N/A',
                        ),
                        _SummaryItem(
                          icon: Icons.straighten,
                          label: 'Distance',
                          value: route?.totalDistanceFormatted ?? 'N/A',
                        ),
                        _SummaryItem(
                          icon: Icons.attach_money,
                          label: 'Fare',
                          value: route?.estimatedFareFormatted ?? 'N/A',
                        ),
                        _SummaryItem(
                          icon: Icons.directions_walk,
                          label: 'Walking',
                          value: route?.walkDistanceFormatted ?? 'N/A',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Map
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Fit all segments after map is ready
                  Future.delayed(
                    const Duration(milliseconds: 500),
                    _fitAllSegments,
                  );
                },
                markers: _markers,
                polylines: _polylines,
                initialCameraPosition: CameraPosition(
                  target: (route?.segments.isNotEmpty ?? false)
                      ? LatLng(
                          route!.segments.first.startLocation.lat,
                          route!.segments.first.startLocation.lon,
                        )
                      : const LatLng(30.0444, 31.2357),
                  zoom: 12,
                ),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Step-by-step directions
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.list, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Step-by-step Directions',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: route?.segments.length ?? 0,
                        itemBuilder: (context, index) {
                          final segments = route?.segments ?? [];
                          if (index >= segments.length) {
                            return const SizedBox.shrink();
                          }
                          final segment = segments[index];
                          final isSelected = index == _selectedSegmentIndex;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: Theme.of(context).colorScheme.primary)
                                  : null,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getSegmentColor(
                                  segment.method,
                                ),
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                child: Icon(
                                  _getMethodIcon(segment.method),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                _getSegmentTitle(segment, index),
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${segment.durationFormatted} • ${segment.distanceFormatted}',
                                  ),
                                  if (segment.numStops > 0)
                                    Text('${segment.numStops} stops'),
                                ],
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.keyboard_arrow_right,
                                      color: Theme.of(context).colorScheme.primary,
                                    )
                                  : null,
                              onTap: () => _onSegmentTapped(index),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
