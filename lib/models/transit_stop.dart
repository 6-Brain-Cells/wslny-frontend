import 'package:google_maps_flutter/google_maps_flutter.dart';

enum TransitStopType { bus, metro, platform }

class TransitStop {
  final String id;
  final LatLng position;
  final String name;
  final TransitStopType type;

  const TransitStop({
    required this.id,
    required this.position,
    required this.name,
    required this.type,
  });
}
