import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/env.dart';
import '../models/transit_stop.dart';

class OverpassService {
  static const int timeoutSeconds = 25;

  /// Fetch transit stops (bus, metro, platform) in a bounding box.
  /// [southWest] and [northEast] define the box; ~2km from center is typical.
  Future<OverpassResult> getTransitStops(
    LatLng southWest,
    LatLng northEast,
  ) async {
    final base = Env.overpassBaseUrl;
    final bbox =
        '${southWest.latitude},${southWest.longitude},${northEast.latitude},${northEast.longitude}';

    final query = '''
[out:json][timeout:$timeoutSeconds];
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
      final response = await http.post(
        Uri.parse(base),
        body: {'data': query},
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      ).timeout(Duration(seconds: timeoutSeconds + 5));

      if (response.statusCode != 200) {
        return OverpassResult.error(
          'Transit request failed: ${response.statusCode}',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List<dynamic>? ?? [];
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

      return OverpassResult.success(stops);
    } catch (e) {
      return OverpassResult.error('Transit error: $e');
    }
  }
}

class OverpassResult {
  final List<TransitStop> stops;
  final String? error;

  OverpassResult._({this.stops = const [], this.error});

  factory OverpassResult.success(List<TransitStop> stops) {
    return OverpassResult._(stops: stops);
  }

  factory OverpassResult.error(String message) {
    return OverpassResult._(error: message);
  }

  bool get isSuccess => error == null;
}
