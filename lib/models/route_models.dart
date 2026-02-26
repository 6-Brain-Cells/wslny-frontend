// Route request and response models

enum RouteFilter {
  optimal(1),
  fastest(2),
  cheapest(3),
  busOnly(4),
  microbusOnly(5),
  metroOnly(6);

  const RouteFilter(this.value);
  final int value;

  static RouteFilter fromValue(int value) {
    return RouteFilter.values.firstWhere((e) => e.value == value);
  }

  String get displayName {
    switch (this) {
      case RouteFilter.optimal:
        return 'Optimal';
      case RouteFilter.fastest:
        return 'Fastest';
      case RouteFilter.cheapest:
        return 'Cheapest';
      case RouteFilter.busOnly:
        return 'Bus Only';
      case RouteFilter.microbusOnly:
        return 'Microbus Only';
      case RouteFilter.metroOnly:
        return 'Metro Only';
    }
  }
}

class RouteLocation {
  final double lat;
  final double lon;
  final String? name;

  RouteLocation({required this.lat, required this.lon, this.name});

  factory RouteLocation.fromJson(Map<String, dynamic> json) {
    return RouteLocation(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lon': lon, if (name != null) 'name': name};
  }
}

class RouteQuery {
  final RouteLocation origin;
  final RouteLocation destination;

  RouteQuery({required this.origin, required this.destination});

  factory RouteQuery.fromJson(Map<String, dynamic> json) {
    return RouteQuery(
      origin: RouteLocation.fromJson(json['origin'] as Map<String, dynamic>),
      destination: RouteLocation.fromJson(
        json['destination'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'origin': origin.toJson(), 'destination': destination.toJson()};
  }
}

class RouteRequest {
  final String? text;
  final RouteFilter? filter;
  final double? currentLatitude;
  final double? currentLongitude;

  RouteRequest({
    this.text,
    this.filter,
    this.currentLatitude,
    this.currentLongitude,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (text != null) {
      json['text'] = text;
    }

    if (filter != null) {
      json['filter'] = filter!.value;
    }

    if (currentLatitude != null) {
      json['current_latitude'] = currentLatitude;
    }

    if (currentLongitude != null) {
      json['current_longitude'] = currentLongitude;
    }

    return json;
  }
}

class RouteSegment {
  final RouteLocation startLocation;
  final RouteLocation endLocation;
  final String method;
  final int numStops;
  final int distanceMeters;
  final int durationSeconds;

  RouteSegment({
    required this.startLocation,
    required this.endLocation,
    required this.method,
    required this.numStops,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      startLocation: RouteLocation.fromJson(
        json['startLocation'] as Map<String, dynamic>,
      ),
      endLocation: RouteLocation.fromJson(
        json['endLocation'] as Map<String, dynamic>,
      ),
      method: json['method'] as String,
      numStops: json['numStops'] as int,
      distanceMeters: (json['distanceMeters'] as num).toInt(),
      durationSeconds: json['durationSeconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startLocation': startLocation.toJson(),
      'endLocation': endLocation.toJson(),
      'method': method,
      'numStops': numStops,
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
    };
  }

  String get durationFormatted {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }

  String get distanceFormatted {
    if (distanceMeters < 1000) {
      return '${distanceMeters}m';
    } else {
      final km = (distanceMeters / 1000).toStringAsFixed(1);
      return '${km}km';
    }
  }
}

class RouteInfo {
  final String type;
  final bool found;
  final int totalDurationSeconds;
  final String totalDurationFormatted;
  final int totalSegments;
  final int totalDistanceMeters;
  final List<RouteSegment> segments;
  final double estimatedFare;
  final int walkDistanceMeters;

  RouteInfo({
    required this.type,
    required this.found,
    required this.totalDurationSeconds,
    required this.totalDurationFormatted,
    required this.totalSegments,
    required this.totalDistanceMeters,
    required this.segments,
    required this.estimatedFare,
    required this.walkDistanceMeters,
  });

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      type: json['type'] as String,
      found: json['found'] as bool,
      totalDurationSeconds: json['totalDurationSeconds'] as int,
      totalDurationFormatted: json['totalDurationFormatted'] as String,
      totalSegments: json['totalSegments'] as int,
      totalDistanceMeters: (json['totalDistanceMeters'] as num).toInt(),
      segments: (json['segments'] as List)
          .map((e) => RouteSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedFare: (json['estimatedFare'] as num).toDouble(),
      walkDistanceMeters: (json['walkDistanceMeters'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'found': found,
      'totalDurationSeconds': totalDurationSeconds,
      'totalDurationFormatted': totalDurationFormatted,
      'totalSegments': totalSegments,
      'totalDistanceMeters': totalDistanceMeters,
      'segments': segments.map((s) => s.toJson()).toList(),
      'estimatedFare': estimatedFare,
      'walkDistanceMeters': walkDistanceMeters,
    };
  }

  String get totalDistanceFormatted {
    if (totalDistanceMeters < 1000) {
      return '${totalDistanceMeters}m';
    } else {
      final km = (totalDistanceMeters / 1000).toStringAsFixed(1);
      return '${km}km';
    }
  }

  String get walkDistanceFormatted {
    if (walkDistanceMeters < 1000) {
      return '${walkDistanceMeters}m';
    } else {
      final km = (walkDistanceMeters / 1000).toStringAsFixed(1);
      return '${km}km';
    }
  }

  String get estimatedFareFormatted {
    return '${estimatedFare.toStringAsFixed(2)} EGP';
  }
}

class RouteResponse {
  final String requestId;
  final String source;
  final String intent;
  final int filter;
  final String? fromName;
  final String? toName;
  final RouteQuery query;
  final RouteInfo route;

  RouteResponse({
    required this.requestId,
    required this.source,
    required this.intent,
    required this.filter,
    this.fromName,
    this.toName,
    required this.query,
    required this.route,
  });

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    return RouteResponse(
      requestId: json['request_id'] as String,
      source: json['source'] as String,
      intent: json['intent'] as String,
      filter: json['filter'] as int,
      fromName: json['from_name'] as String?,
      toName: json['to_name'] as String?,
      query: RouteQuery.fromJson(json['query'] as Map<String, dynamic>),
      route: RouteInfo.fromJson(json['route'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'source': source,
      'intent': intent,
      'filter': filter,
      'from_name': fromName,
      'to_name': toName,
      'query': query.toJson(),
      'route': route.toJson(),
    };
  }
}
