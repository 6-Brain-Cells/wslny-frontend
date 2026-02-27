import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/env.dart';
import '../models/transit_stop.dart';

/// Fetches nearby transit stops using the Google Places Nearby Search API.
/// Despite the class name being kept for compatibility, the implementation
/// now uses Google Places for accurate, well-named results.
class OverpassService {
  static const int _timeoutSeconds = 10;
  static const double _radiusMeters = 1500;

  /// Fetch transit stops near [center] using Google Places Nearby Search.
  /// Queries three place types and merges the results, deduplicating by place_id.
  Future<OverpassResult> getTransitStops(LatLng center) async {
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
          lastError = 'Places request failed (${response.statusCode})';
          continue;
        }

        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';

        if (status == 'REQUEST_DENIED' || status == 'INVALID_REQUEST') {
          return OverpassResult.error(
            'Google Places API error: $status. '
            '${data['error_message'] ?? ""}',
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
      return OverpassResult.error(lastError!);
    }
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
