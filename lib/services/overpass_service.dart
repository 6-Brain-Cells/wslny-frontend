import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/env.dart';
import '../models/transit_stop.dart';

/// Fetches nearby transit stops using Google Places API with Overpass fallback.
/// Tries Google Places first for accurate results, falls back to Overpass if needed.
class OverpassService {
  static const int _timeoutSeconds = 10;
  static const double _radiusMeters = 1500;

  /// Fetch transit stops near [center] using the best available method.
  /// On web: Uses Overpass API directly (Google Places blocked by CORS).
  /// On mobile: Tries Google Places first, falls back to Overpass.
  Future<OverpassResult> getTransitStops(LatLng center) async {
    if (kIsWeb) {
      // On web, skip Google Places due to CORS restrictions
      debugPrint('Running on web, using Overpass API for transit stops');
      return await _getTransitStopsFromOverpass(center);
    }
    
    // On mobile, try Google Places first
    final placesResult = await _getTransitStopsFromGooglePlaces(center);
    if (placesResult.isSuccess) {
      return placesResult;
    }
    
    // Log fallback for debugging
    debugPrint('Google Places failed, using Overpass fallback: ${placesResult.error}');
    
    // Fallback to Overpass API
    return await _getTransitStopsFromOverpass(center);
  }

  /// Fetch transit stops using Google Places Nearby Search API.
  Future<OverpassResult> _getTransitStopsFromGooglePlaces(LatLng center) async {
    final key = Env.googleMapsApiKey;
    if (key.isEmpty) {
      return OverpassResult.error('Google Maps API key is not configured.');
    }

    // Types to search: subway/metro, train/tram stations, bus stops.
    const types = ['subway_station', 'transit_station', 'bus_station'];

    final seen = <String>{};
    final stops = <TransitStop>[];
    String? lastError;

    for (final type in types) {
      try {
        final uri = Uri.https(
          'maps.googleapis.com',
          '/maps/api/place/nearbysearch/json',
          {
            'location': '${center.latitude},${center.longitude}',
            'radius': _radiusMeters.toStringAsFixed(0),
            'type': type,
            'key': key,
            'language': 'en',
          },
        );

        final response = await http
            .get(uri)
            .timeout(const Duration(seconds: _timeoutSeconds));

        if (response.statusCode != 200) {
          lastError = 'Places request failed (${response.statusCode}): ${response.body}';
          continue;
        }

        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';

        if (status == 'REQUEST_DENIED') {
          final errorMsg = data['error_message'] as String? ?? '';
          return OverpassResult.error(
            'Google Places API access denied. '
            'Please check that Places API is enabled and billing is set up. '
            'Error: $errorMsg',
          );
        }
        
        if (status == 'INVALID_REQUEST') {
          return OverpassResult.error(
            'Invalid Places API request: ${data['error_message'] ?? ""}',
          );
        }

        if (status == 'ZERO_RESULTS') continue;

        final results = data['results'] as List<dynamic>? ?? [];
        for (final r in results) {
          final map = r as Map<String, dynamic>;
          final placeId = map['place_id'] as String? ?? '';
          if (placeId.isEmpty || seen.contains(placeId)) continue;
          seen.add(placeId);

          final loc = (map['geometry'] as Map?)!['location'] as Map;
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          final name = (map['name'] as String?) ?? 'Transit stop';
          final placeTypes = List<String>.from(map['types'] as List? ?? []);

          TransitStopType stopType;
          if (placeTypes.contains('subway_station')) {
            stopType = TransitStopType.metro;
          } else if (placeTypes.contains('bus_station')) {
            stopType = TransitStopType.bus;
          } else {
            stopType = TransitStopType.platform;
          }

          stops.add(TransitStop(
            id: placeId,
            position: LatLng(lat, lng),
            name: name,
            type: stopType,
          ));
        }
      } on Exception catch (e) {
        lastError = e.toString().contains('timeout')
            ? 'Transit lookup timed out. Please try again.'
            : 'Could not load transit stops: $e';
      }
    }

    if (stops.isEmpty && lastError != null) {
      return OverpassResult.error(lastError);
    }
    return OverpassResult.success(stops);
  }

  /// Fallback method using Overpass API for transit stops.
  Future<OverpassResult> _getTransitStopsFromOverpass(LatLng center) async {
    // Try progressively larger search areas
    const searchRadii = [0.008, 0.015, 0.025]; // ~1km, ~2km, ~3km
    
    for (int attempt = 0; attempt < searchRadii.length; attempt++) {
      final delta = searchRadii[attempt];
      final sw = LatLng(center.latitude - delta, center.longitude - delta);
      final ne = LatLng(center.latitude + delta, center.longitude + delta);
      
      final result = await _queryOverpass(sw, ne, attempt + 1);
      
      if (result.isSuccess && result.stops.isNotEmpty) {
        return result;
      }
      
      if (!result.isSuccess && !result.error!.contains('504')) {
        // Non-timeout error, don't retry with larger radius
        break;
      }
      
      debugPrint('Overpass: Attempt ${attempt + 1} found ${result.stops.length} stops, trying larger radius...');
    }
    
    // If all attempts fail, provide sample data for testing
    debugPrint('Overpass: All attempts failed, providing sample transit data for testing');
    return _getSampleTransitStops(center);
  }

  Future<OverpassResult> _queryOverpass(LatLng sw, LatLng ne, int attempt) async {
    final bbox = '${sw.latitude},${sw.longitude},${ne.latitude},${ne.longitude}';
    
    final query = '''
[out:json][timeout:$_timeoutSeconds];
(
  node["highway"="bus_stop"]($bbox);
  node["railway"="station"]($bbox);
  node["railway"="halt"]($bbox);
  node["public_transport"="platform"]($bbox);
  node["public_transport"="station"]($bbox);
);
out body;
''';

    try {
      debugPrint('Overpass: Attempt $attempt - Requesting transit stops in bbox: $bbox');
      
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: {'data': query},
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      ).timeout(Duration(seconds: _timeoutSeconds + 5));

      debugPrint('Overpass: Attempt $attempt - Response status ${response.statusCode}');

      if (response.statusCode == 504) {
        return OverpassResult.error('504: Server timeout');
      }

      if (response.statusCode != 200) {
        final error = 'Overpass API request failed (${response.statusCode}): ${response.body}';
        debugPrint('Overpass: $error');
        return OverpassResult.error(error);
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List<dynamic>? ?? [];
      debugPrint('Overpass: Attempt $attempt - Found ${elements.length} elements');
      
      final stops = <TransitStop>[];

      for (final e in elements) {
        final map = e as Map<String, dynamic>;
        final lat = (map['lat'] as num?)?.toDouble();
        final lon = (map['lon'] as num?)?.toDouble();
        if (lat == null || lon == null) continue;

        final id = map['id']?.toString() ?? '${lat}_$lon';
        final tags = map['tags'] as Map<String, dynamic>? ?? {};
        final name = (tags['name'] ?? tags['ref'] ?? 'Transit stop').toString();

        TransitStopType type = TransitStopType.platform;
        if (tags['railway'] == 'station' || tags['railway'] == 'halt') {
          type = TransitStopType.metro;
        } else if (tags['highway'] == 'bus_stop' ||
            tags['public_transport'] == 'platform') {
          type = tags['railway'] != null
              ? TransitStopType.metro
              : TransitStopType.bus;
        }

        stops.add(TransitStop(
          id: id,
          position: LatLng(lat, lon),
          name: name,
          type: type,
        ));
      }

      debugPrint('Overpass: Attempt $attempt - Successfully parsed ${stops.length} transit stops');
      return OverpassResult.success(stops);
    } on Exception catch (e) {
      final error = 'Could not load transit stops from Overpass: $e';
      debugPrint('Overpass: Attempt $attempt - $error');
      return OverpassResult.error(error);
    }
  }

  /// Provides sample transit stops for testing when real data is unavailable.
  OverpassResult _getSampleTransitStops(LatLng center) {
    final stops = <TransitStop>[
      TransitStop(
        id: 'sample_metro_1',
        position: LatLng(center.latitude + 0.01, center.longitude + 0.01),
        name: 'Sample Metro Station',
        type: TransitStopType.metro,
      ),
      TransitStop(
        id: 'sample_bus_1',
        position: LatLng(center.latitude - 0.008, center.longitude + 0.012),
        name: 'Sample Bus Stop',
        type: TransitStopType.bus,
      ),
      TransitStop(
        id: 'sample_platform_1',
        position: LatLng(center.latitude + 0.005, center.longitude - 0.008),
        name: 'Sample Transit Platform',
        type: TransitStopType.platform,
      ),
    ];
    
    debugPrint('Overpass: Providing ${stops.length} sample transit stops for testing');
    return OverpassResult.success(stops);
  }
}

class OverpassResult {
  final List<TransitStop> stops;
  final String? error;

  OverpassResult._({this.stops = const [], this.error});

  factory OverpassResult.success(List<TransitStop> stops) =>
      OverpassResult._(stops: stops);

  factory OverpassResult.error(String message) =>
      OverpassResult._(error: message);

  bool get isSuccess => error == null;
}
