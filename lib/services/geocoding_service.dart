import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Geocoding via Nominatim (OpenStreetMap) for searching places by name, address, and landmarks.
class GeocodingService {
  static const _base = 'https://nominatim.openstreetmap.org';

  Future<GeocodingResult> search(String query) async {
    if (query.trim().isEmpty) {
      return GeocodingResult.error('Enter a location');
    }

    // Add retry mechanism for network issues
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final uri = Uri.parse('$_base/search').replace(
          queryParameters: {
            'q': query.trim(),
            'format': 'json',
            'limit': '10', // Increased to get more results
            'addressdetails': '1', // Get detailed address info
            'extratags': '1', // Get extra tags for place types
          },
        );

        debugPrint('Searching for: $query (attempt ${retryCount + 1})');
        debugPrint('Request URL: $uri');

        final response = await http
            .get(
              uri,
              headers: {'User-Agent': 'WslnyApp/1.0 (Flutter Transit App)'},
            )
            .timeout(
              const Duration(seconds: 15), // Increased timeout
            );

        if (response.statusCode != 200) {
          debugPrint('Search failed with status: ${response.statusCode}');
          return GeocodingResult.error(
            'Search failed: HTTP ${response.statusCode}',
          );
        }

        final list = json.decode(response.body) as List<dynamic>? ?? [];
        debugPrint('Found ${list.length} results');

        final results = <GeocodingPlace>[];
        for (final e in list) {
          final m = e as Map<String, dynamic>;
          final lat = double.tryParse(m['lat']?.toString() ?? '');
          final lon = double.tryParse(m['lon']?.toString() ?? '');
          final name = m['display_name']?.toString() ?? '';
          final importance =
              double.tryParse(m['importance']?.toString() ?? '') ?? 0.0;
          final type = m['type']?.toString() ?? '';
          final classType = m['class']?.toString() ?? '';

          if (lat != null && lon != null && !lat.isNaN && !lon.isNaN) {
            results.add(
              GeocodingPlace(
                position: LatLng(lat, lon),
                displayName: name,
                type: type,
                classType: classType,
                importance: importance,
              ),
            );
          }
        }

        // Sort by importance (most relevant first)
        results.sort((a, b) => b.importance.compareTo(a.importance));

        return GeocodingResult.success(results);
      } catch (e) {
        retryCount++;
        debugPrint('Search error (attempt $retryCount): $e');

        if (retryCount >= maxRetries) {
          return GeocodingResult.error('Search failed: $e');
        }

        // Wait before retry
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }

    return GeocodingResult.error('Search failed after $maxRetries attempts');
  }
}

class GeocodingPlace {
  final LatLng position;
  final String displayName;
  final String type;
  final String classType;
  final double importance;

  GeocodingPlace({
    required this.position,
    required this.displayName,
    this.type = '',
    this.classType = '',
    this.importance = 0.0,
  });
}

class GeocodingResult {
  final List<GeocodingPlace> places;
  final String? error;

  GeocodingResult._({this.places = const [], this.error});

  factory GeocodingResult.success(List<GeocodingPlace> places) {
    return GeocodingResult._(places: places);
  }

  factory GeocodingResult.error(String message) {
    return GeocodingResult._(error: message);
  }

  bool get isSuccess => error == null;
}
