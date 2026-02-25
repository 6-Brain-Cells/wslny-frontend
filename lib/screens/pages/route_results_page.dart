import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/app_colors.dart';
import '../../models/route_models.dart';

class RouteResultsPage extends StatefulWidget {
  final RouteResponse routeResponse;

  const RouteResultsPage({
    super.key,
    required this.routeResponse,
  });

  @override
  State<RouteResultsPage> createState() => _RouteResultsPageState();
}

class _RouteResultsPageState extends State<RouteResultsPage> {
  GoogleMapController? _mapController;
  int _selectedSegmentIndex = 0;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _setupMapData();
  }

  void _setupMapData() {
    _markers.clear();
    _polylines.clear();

    final route = widget.routeResponse.route;
    final segments = route.segments;

    // Add start marker
    if (segments.isNotEmpty) {
      final startLocation = segments.first.startLocation;
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(startLocation.lat, startLocation.lon),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Start',
            snippet: startLocation.name ?? widget.routeResponse.fromName,
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
            snippet: endLocation.name ?? widget.routeResponse.toName,
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
            position: LatLng(segment.startLocation.lat, segment.startLocation.lon),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: 'Transfer Point',
              snippet: segment.startLocation.name ?? 'Transfer',
            ),
          ),
        );
      }
    }

    // Create polylines for each segment
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final color = _getSegmentColor(segment.method);
      
      _polylines.add(
        Polyline(
          polylineId: PolylineId('segment_$i'),
          points: [
            LatLng(segment.startLocation.lat, segment.startLocation.lon),
            LatLng(segment.endLocation.lat, segment.endLocation.lon),
          ],
          color: color,
          width: 4,
          patterns: segment.method == 'walk' ? [PatternItem.dash(10), PatternItem.gap(5)] : [],
        ),
      );
    }
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
    final segment = widget.routeResponse.route.segments[index];
    final bounds = LatLngBounds(
      southwest: LatLng(
        [segment.startLocation.lat, segment.endLocation.lat].reduce((a, b) => a < b ? a : b),
        [segment.startLocation.lon, segment.endLocation.lon].reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        [segment.startLocation.lat, segment.endLocation.lat].reduce((a, b) => a > b ? a : b),
        [segment.startLocation.lon, segment.endLocation.lon].reduce((a, b) => a > b ? a : b),
      ),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  void _fitAllSegments() {
    if (widget.routeResponse.route.segments.isEmpty) return;

    final segments = widget.routeResponse.route.segments;
    final allPoints = segments.expand((s) => [
      LatLng(s.startLocation.lat, s.startLocation.lon),
      LatLng(s.endLocation.lat, s.endLocation.lon),
    ]).toList();

    if (allPoints.isEmpty) return;

    final lats = allPoints.map((p) => p.latitude).toList();
    final lngs = allPoints.map((p) => p.longitude).toList();

    final bounds = LatLngBounds(
      southwest: LatLng(lats.reduce((a, b) => a < b ? a : b), lngs.reduce((a, b) => a < b ? a : b)),
      northeast: LatLng(lats.reduce((a, b) => a > b ? a : b), lngs.reduce((a, b) => a > b ? a : b)),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.routeResponse.route;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
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
                        Icon(Icons.route, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.routeResponse.fromName} → ${widget.routeResponse.toName}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                          value: route.totalDurationFormatted,
                        ),
                        _SummaryItem(
                          icon: Icons.straighten,
                          label: 'Distance',
                          value: route.totalDistanceFormatted,
                        ),
                        _SummaryItem(
                          icon: Icons.attach_money,
                          label: 'Fare',
                          value: route.estimatedFareFormatted,
                        ),
                        _SummaryItem(
                          icon: Icons.directions_walk,
                          label: 'Walking',
                          value: route.walkDistanceFormatted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Map
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Fit all segments after map is ready
                  Future.delayed(const Duration(milliseconds: 500), _fitAllSegments);
                },
                markers: _markers,
                polylines: _polylines,
                initialCameraPosition: CameraPosition(
                  target: route.segments.isNotEmpty
                      ? LatLng(
                          route.segments.first.startLocation.lat,
                          route.segments.first.startLocation.lon,
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
                          Icon(Icons.list, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Step-by-step Directions',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: route.segments.length,
                        itemBuilder: (context, index) {
                          final segment = route.segments[index];
                          final isSelected = index == _selectedSegmentIndex;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected ? Border.all(color: AppColors.primary) : null,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getSegmentColor(segment.method),
                                foregroundColor: Colors.white,
                                child: Icon(_getMethodIcon(segment.method), size: 20),
                              ),
                              title: Text(
                                _getSegmentTitle(segment, index),
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${segment.durationFormatted} • ${segment.distanceFormatted}'),
                                  if (segment.numStops > 0)
                                    Text('${segment.numStops} stops'),
                                ],
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.keyboard_arrow_right, color: AppColors.primary)
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
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getSegmentTitle(RouteSegment segment, int index) {
    final method = segment.method.toLowerCase();
    final start = segment.startLocation.name ?? 'Point ${index + 1}';
    final end = segment.endLocation.name ?? 'Point ${index + 2}';
    
    switch (method) {
      case 'walk':
        return 'Walk to $end';
      case 'bus':
        return 'Take bus from $start';
      case 'microbus':
        return 'Take microbus from $start';
      case 'metro':
      case 'subway':
        return 'Take metro from $start';
      default:
        return 'Travel from $start to $end';
    }
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
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}