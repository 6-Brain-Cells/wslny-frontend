// Additional route request/response models based on OpenAPI specification

class RouteAlternativesRequest {
  final double originLat;
  final double originLon;
  final double destinationLat;
  final double destinationLon;

  RouteAlternativesRequest({
    required this.originLat,
    required this.originLon,
    required this.destinationLat,
    required this.destinationLon,
  });

  Map<String, dynamic> toJson() {
    return {
      'origin_lat': originLat,
      'origin_lon': originLon,
      'destination_lat': destinationLat,
      'destination_lon': destinationLon,
    };
  }
}

class RouteFeedbackRequest {
  final String requestId;
  final int rating;
  final String? comment;

  RouteFeedbackRequest({
    required this.requestId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'request_id': requestId,
      'rating': rating,
    };
    if (comment != null) json['comment'] = comment;
    return json;
  }
}

class RouteSearchRequest {
  final String destinationText;
  final double? currentLat;
  final double? currentLon;
  final int? filter;

  RouteSearchRequest({
    required this.destinationText,
    this.currentLat,
    this.currentLon,
    this.filter,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'destination_text': destinationText,
    };
    if (currentLat != null && currentLon != null) {
      json['current_location'] = {
        'lat': currentLat,
        'lon': currentLon,
      };
    }
    if (filter != null) json['filter'] = filter;
    return json;
  }
}

class RouteSearchConfirmRequest {
  final double currentLat;
  final double currentLon;
  final String? destinationName;
  final double destinationLat;
  final double destinationLon;
  final int? filter;

  RouteSearchConfirmRequest({
    required this.currentLat,
    required this.currentLon,
    this.destinationName,
    required this.destinationLat,
    required this.destinationLon,
    this.filter,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'current_location': {
        'lat': currentLat,
        'lon': currentLon,
      },
      'destination': {
        if (destinationName != null) 'name': destinationName,
        'lat': destinationLat,
        'lon': destinationLon,
      },
    };
    if (filter != null) json['filter'] = filter;
    return json;
  }
}

class RouteHistoryItem {
  final String? requestId;
  final String sourceType;
  final String? inputText;
  final String filter;
  final String? selectedRouteType;
  final String? originName;
  final String? destinationName;
  final String status;
  final String? errorCode;
  final double? totalDistanceMeters;
  final double? totalDurationSeconds;
  final double? estimatedFare;
  final double? walkDistanceMeters;
  final DateTime createdAt;

  RouteHistoryItem({
    this.requestId,
    required this.sourceType,
    this.inputText,
    required this.filter,
    this.selectedRouteType,
    this.originName,
    this.destinationName,
    required this.status,
    this.errorCode,
    this.totalDistanceMeters,
    this.totalDurationSeconds,
    this.estimatedFare,
    this.walkDistanceMeters,
    required this.createdAt,
  });

  factory RouteHistoryItem.fromJson(Map<String, dynamic> json) {
    return RouteHistoryItem(
      requestId: json['request_id'] as String?,
      sourceType: json['source_type'] as String,
      inputText: json['input_text'] as String?,
      filter: json['filter'] as String,
      selectedRouteType: json['selected_route_type'] as String?,
      originName: json['origin_name'] as String?,
      destinationName: json['destination_name'] as String?,
      status: json['status'] as String,
      errorCode: json['error_code'] as String?,
      totalDistanceMeters: json['total_distance_meters'] != null
          ? (json['total_distance_meters'] as num).toDouble()
          : null,
      totalDurationSeconds: json['total_duration_seconds'] != null
          ? (json['total_duration_seconds'] as num).toDouble()
          : null,
      estimatedFare: json['estimated_fare'] != null
          ? (json['estimated_fare'] as num).toDouble()
          : null,
      walkDistanceMeters: json['walk_distance_meters'] != null
          ? (json['walk_distance_meters'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class RouteMetadataResponse {
  final List<dynamic> filters;
  final List<String> requestModes;
  final List<dynamic> queryParams;
  final Map<String, dynamic> coordinateBounds;
  final List<String> transportMethods;

  RouteMetadataResponse({
    required this.filters,
    required this.requestModes,
    required this.queryParams,
    required this.coordinateBounds,
    required this.transportMethods,
  });

  factory RouteMetadataResponse.fromJson(Map<String, dynamic> json) {
    return RouteMetadataResponse(
      filters: json['filters'] as List<dynamic>? ?? [],
      requestModes: (json['request_modes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      queryParams: json['query_params'] as List<dynamic>? ?? [],
      coordinateBounds:
          json['coordinate_bounds'] as Map<String, dynamic>? ?? {},
      transportMethods: (json['transport_methods'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class RouteSearchResponse {
  final String? status;
  final Map<String, dynamic>? route;
  final String? message;
  final Map<String, dynamic>? suggestedDestination;

  RouteSearchResponse({
    this.status,
    this.route,
    this.message,
    this.suggestedDestination,
  });

  factory RouteSearchResponse.fromJson(Map<String, dynamic> json) {
    return RouteSearchResponse(
      status: json['status'] as String?,
      route: json['route'] as Map<String, dynamic>?,
      message: json['message'] as String?,
      suggestedDestination: json['suggested_destination'] as Map<String, dynamic>?,
    );
  }
}
