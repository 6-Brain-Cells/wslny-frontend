import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/env.dart';

class OsrmService {
  static const int timeoutSeconds = 15;

  Future<OsrmResult> getRoute(LatLng start, LatLng end) async {
    final base = Env.osrmBaseUrl;
    final url =
        '$base/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url)).timeout(
            Duration(seconds: timeoutSeconds),
          );

      if (response.statusCode != 200) {
        return OsrmResult.error('Route request failed: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final code = data['code'] as String?;
      if (code != 'Ok') {
        return OsrmResult.error(data['message']?.toString() ?? 'No route found');
      }

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        return OsrmResult.error('No route found');
      }

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      if (geometry == null) return OsrmResult.error('Invalid route geometry');

      final coordinates = geometry['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.isEmpty) {
        return OsrmResult.error('Invalid route coordinates');
      }

      final points = coordinates
          .map((c) {
            final list = c as List<dynamic>;
            if (list.length >= 2) {
              return LatLng(
                (list[1] as num).toDouble(),
                (list[0] as num).toDouble(),
              );
            }
            return null;
          })
          .whereType<LatLng>()
          .toList();

      final distance = (route['distance'] as num?)?.toDouble() ?? 0.0;
      final distanceKm = distance / 1000.0;

      return OsrmResult.success(points, distanceKm);
    } catch (e) {
      return OsrmResult.error('Network error: $e');
    }
  }
}

class OsrmResult {
  final List<LatLng> points;
  final double distanceKm;
  final String? error;

  OsrmResult._({this.points = const [], this.distanceKm = 0, this.error});

  factory OsrmResult.success(List<LatLng> points, double distanceKm) {
    return OsrmResult._(points: points, distanceKm: distanceKm);
  }

  factory OsrmResult.error(String message) {
    return OsrmResult._(error: message);
  }

  bool get isSuccess => error == null;
}
