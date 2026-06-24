// User request models

enum TypeEnum {
  home,
  work,
  custom;

  static TypeEnum fromString(String value) {
    return TypeEnum.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TypeEnum.custom,
    );
  }
}

class CreateFavoriteRouteRequest {
  final String name;
  final double originLat;
  final double originLon;
  final String originName;
  final double destinationLat;
  final double destinationLon;
  final String destinationName;
  final int filter;

  CreateFavoriteRouteRequest({
    required this.name,
    required this.originLat,
    required this.originLon,
    required this.originName,
    required this.destinationLat,
    required this.destinationLon,
    required this.destinationName,
    required this.filter,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'origin_lat': originLat,
      'origin_lon': originLon,
      'origin_name': originName,
      'destination_lat': destinationLat,
      'destination_lon': destinationLon,
      'destination_name': destinationName,
      'filter': filter,
    };
  }
}

class CreateSavedLocationRequest {
  final String name;
  final double lat;
  final double lon;
  final TypeEnum type;

  CreateSavedLocationRequest({
    required this.name,
    required this.lat,
    required this.lon,
    this.type = TypeEnum.custom,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'lat': lat, 'lon': lon, 'type': type.name};
  }
}

class UpdateSavedLocationRequest {
  final String? name;
  final double? lat;
  final double? lon;
  final TypeEnum? type;

  UpdateSavedLocationRequest({this.name, this.lat, this.lon, this.type});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (name != null) {
      json['name'] = name;
    }

    if (lat != null) {
      json['lat'] = lat;
    }

    if (lon != null) {
      json['lon'] = lon;
    }

    if (type != null) {
      json['type'] = type!.name;
    }

    return json;
  }
}

class UpdatePreferencesRequest {
  final int? defaultFilter;
  final int? maxWalkDistance;
  final bool? accessibilityMode;

  UpdatePreferencesRequest({
    this.defaultFilter,
    this.maxWalkDistance,
    this.accessibilityMode,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (defaultFilter != null) {
      json['default_filter'] = defaultFilter;
    }

    if (maxWalkDistance != null) {
      json['max_walk_distance'] = maxWalkDistance;
    }

    if (accessibilityMode != null) {
      json['accessibility_mode'] = accessibilityMode;
    }

    return json;
  }
}
