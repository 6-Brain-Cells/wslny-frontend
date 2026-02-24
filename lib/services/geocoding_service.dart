import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Geocoding via Nominatim (OpenStreetMap) for "type location and search".
class GeocodingService {
  static const _base = 'https://nominatim.openstreetmap.org';

  Future<GeocodingResult> search(String query) async {
    if (query.trim().isEmpty) {
      return GeocodingResult.error('Enter a location');
    }
    try {
      final uri = Uri.parse('$_base/search').replace(
        queryParameters: {
          'q': query.trim(),
          'format': 'json',
          'limit': '5',
        },
      );
      final response = await http.get(uri).timeout(
            const Duration(seconds: 10),
          );
      if (response.statusCode != 200) {
        return GeocodingResult.error('Search failed');
      }
      final list = json.decode(response.body) as List<dynamic>? ?? [];
      final results = <GeocodingPlace>[];
      for (final e in list) {
        final m = e as Map<String, dynamic>;
        final lat = (m['lat'] as num?)?.toDouble();
        final lon = (m['lon'] as num?)?.toDouble();
        final name = m['display_name']?.toString() ?? '';
        if (lat != null && lon != null) {
          results.add(GeocodingPlace(
            position: LatLng(lat, lon),
            displayName: name,
          ));
        }
      }
      return GeocodingResult.success(results);
    } catch (e) {
      return GeocodingResult.error('Search failed: $e');
    }
  }
}

class GeocodingPlace {
  final LatLng position;
  final String displayName;

  GeocodingPlace({required this.position, required this.displayName});
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
