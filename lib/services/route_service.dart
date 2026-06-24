import 'package:flutter/foundation.dart';
import '../models/route_models.dart';
import '../models/route_addon_models.dart';
import '../models/coordinate.dart';
import '../config/app_constants.dart';
import 'api_service.dart';

class RouteService {
  final ApiService _apiService = ApiService();

  /// Get route using text input (natural language)
  Future<RouteResponse> getRouteByText({
    required String text,
    required RouteFilter filter,
    double? currentLatitude,
    double? currentLongitude,
  }) async {
    try {
      if (AppConstants.useMockMode) {
        return _getMockRouteResponse(text, filter);
      }

      final request = RouteRequest(
        text: text,
        filter: filter,
        currentLocation: currentLatitude != null && currentLongitude != null
            ? Coordinate(lat: currentLatitude, lon: currentLongitude)
            : null,
      );

      debugPrint('🚌 Route Request (Text): ${request.toJson()}');

      final response = await _apiService.post(
        '/api/v1/route',
        body: request.toJson(),
        includeAuth: true,
        module: ApiService.moduleRouting,
      );

      debugPrint('🚌 Route Response: $response');

      return RouteResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ Route request failed: $e');
      throw Exception('Failed to get route: $e');
    }
  }

  /// Get route using coordinates (map pins)
  Future<RouteResponse> getRouteByCoordinates({
    required double originLat,
    required double originLon,
    required double destinationLat,
    required double destinationLon,
    required RouteFilter filter,
    double? currentLatitude,
    double? currentLongitude,
  }) async {
    try {
      if (AppConstants.useMockMode) {
        return _getMockRouteResponseFromCoordinates(
          originLat,
          originLon,
          destinationLat,
          destinationLon,
          filter,
        );
      }

      final request = RouteRequest(
        origin: Coordinate(lat: originLat, lon: originLon),
        destination: Coordinate(lat: destinationLat, lon: destinationLon),
        filter: filter,
        currentLocation: currentLatitude != null && currentLongitude != null
            ? Coordinate(lat: currentLatitude, lon: currentLongitude)
            : null,
      );

      debugPrint('🚌 Route Request (Coordinates): ${request.toJson()}');

      final response = await _apiService.post(
        '/api/v1/route',
        body: request.toJson(),
        includeAuth: true,
        module: ApiService.moduleRouting,
      );

      debugPrint('🚌 Route Response: $response');

      return RouteResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ Route request failed: $e');
      throw Exception('Failed to get route: $e');
    }
  }

  /// Get route history
  Future<List<RouteHistoryItem>> getRouteHistory() async {
    try {
      if (AppConstants.useMockMode) return [];
      final response = await _apiService.get(
        '/api/v1/route/history',
        module: ApiService.moduleRouting,
      );
      if (response is List) {
        return response
            .map((e) =>
                RouteHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Route history failed: $e');
      throw Exception('Failed to get route history: $e');
    }
  }

  /// Get route alternatives
  Future<List<dynamic>> getRouteAlternatives(
    RouteAlternativesRequest request,
  ) async {
    try {
      if (AppConstants.useMockMode) return [];
      final response = await _apiService.post(
        '/api/v1/routes/alternatives',
        body: request.toJson(),
        module: ApiService.moduleRouting,
      );
      if (response is List) return response;
      return [];
    } catch (e) {
      debugPrint('❌ Route alternatives failed: $e');
      throw Exception('Failed to get route alternatives: $e');
    }
  }

  /// Submit route feedback
  Future<void> submitRouteFeedback(RouteFeedbackRequest request) async {
    try {
      if (AppConstants.useMockMode) return;
      await _apiService.post(
        '/api/v1/routes/feedback',
        body: request.toJson(),
        module: ApiService.moduleRouting,
      );
    } catch (e) {
      debugPrint('❌ Route feedback failed: $e');
      throw Exception('Failed to submit route feedback: $e');
    }
  }

  /// Get route metadata
  Future<RouteMetadataResponse> getRouteMetadata() async {
    try {
      if (AppConstants.useMockMode) {
        return RouteMetadataResponse(
          filters: [],
          requestModes: ['text', 'map'],
          queryParams: [],
          coordinateBounds: {},
          transportMethods: ['walk', 'bus', 'metro', 'microbus'],
        );
      }
      final response = await _apiService.get(
        '/api/v1/routes/metadata',
        module: ApiService.moduleRouting,
      );
      return RouteMetadataResponse.fromJson(
        response as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Route metadata failed: $e');
      throw Exception('Failed to get route metadata: $e');
    }
  }

  /// Search route by destination text
  Future<RouteSearchResponse> searchRoute(RouteSearchRequest request) async {
    try {
      if (AppConstants.useMockMode) {
        return RouteSearchResponse(status: 'found');
      }
      final response = await _apiService.post(
        '/api/v1/routes/search',
        body: request.toJson(),
        module: ApiService.moduleRouting,
      );
      return RouteSearchResponse.fromJson(
        response as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Route search failed: $e');
      throw Exception('Failed to search route: $e');
    }
  }

  /// Confirm search result and get route
  Future<RouteResponse> confirmSearch(
    RouteSearchConfirmRequest request,
  ) async {
    try {
      if (AppConstants.useMockMode) {
        return _getMockRouteResponse(
          request.destinationName ?? 'Searched Destination',
          RouteFilter.fromValue(request.filter ?? 1),
        );
      }
      final response = await _apiService.post(
        '/api/v1/routes/search/confirm',
        body: request.toJson(),
        module: ApiService.moduleRouting,
      );
      return RouteResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ Route search confirm failed: $e');
      throw Exception('Failed to confirm search: $e');
    }
  }

  // Mock response for development/testing
  RouteResponse _getMockRouteResponse(String text, RouteFilter filter) {
    return RouteResponse(
      requestId: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      source: 'text',
      intent: text,
      filter: filter.value,
      fromName: 'Current Location',
      toName: 'Destination',
      query: RouteQuery(
        origin: RouteLocation(lat: 30.0444, lon: 31.2357, name: 'Cairo'),
        destination: RouteLocation(lat: 30.0626, lon: 31.2497, name: 'Zamalek'),
      ),
      route: RouteInfo(
        type: 'public_transport',
        found: true,
        totalDurationSeconds: 1800, // 30 minutes
        totalDurationFormatted: '30m',
        totalSegments: 3,
        totalDistanceMeters: 8500,
        segments: [
          RouteSegment(
            startLocation: RouteLocation(
              lat: 30.0444,
              lon: 31.2357,
              name: 'Start Point',
            ),
            endLocation: RouteLocation(
              lat: 30.0500,
              lon: 31.2400,
              name: 'Bus Stop A',
            ),
            method: 'walk',
            numStops: 0,
            distanceMeters: 400,
            durationSeconds: 300, // 5 minutes
          ),
          RouteSegment(
            startLocation: RouteLocation(
              lat: 30.0500,
              lon: 31.2400,
              name: 'Bus Stop A',
            ),
            endLocation: RouteLocation(
              lat: 30.0600,
              lon: 31.2480,
              name: 'Bus Stop B',
            ),
            method: filter == RouteFilter.metroOnly ? 'metro' : 'bus',
            numStops: 8,
            distanceMeters: 7500,
            durationSeconds: 1200, // 20 minutes
          ),
          RouteSegment(
            startLocation: RouteLocation(
              lat: 30.0600,
              lon: 31.2480,
              name: 'Bus Stop B',
            ),
            endLocation: RouteLocation(
              lat: 30.0626,
              lon: 31.2497,
              name: 'Destination',
            ),
            method: 'walk',
            numStops: 0,
            distanceMeters: 600,
            durationSeconds: 300, // 5 minutes
          ),
        ],
        estimatedFare: filter == RouteFilter.metroOnly ? 7.0 : 5.0,
        walkDistanceMeters: 1000,
      ),
    );
  }

  RouteResponse _getMockRouteResponseFromCoordinates(
    double originLat,
    double originLon,
    double destinationLat,
    double destinationLon,
    RouteFilter filter,
  ) {
    return RouteResponse(
      requestId: 'mock-coords-${DateTime.now().millisecondsSinceEpoch}',
      source: 'map',
      intent: 'Route from coordinates',
      filter: filter.value,
      fromName: 'Selected Start Point',
      toName: 'Selected End Point',
      query: RouteQuery(
        origin: RouteLocation(lat: originLat, lon: originLon, name: 'Start'),
        destination: RouteLocation(
          lat: destinationLat,
          lon: destinationLon,
          name: 'End',
        ),
      ),
      route: RouteInfo(
        type: 'public_transport',
        found: true,
        totalDurationSeconds: 2400, // 40 minutes
        totalDurationFormatted: '40m',
        totalSegments: 2,
        totalDistanceMeters: 12000,
        segments: [
          RouteSegment(
            startLocation: RouteLocation(
              lat: originLat,
              lon: originLon,
              name: 'Start Point',
            ),
            endLocation: RouteLocation(
              lat: (originLat + destinationLat) / 2,
              lon: (originLon + destinationLon) / 2,
              name: 'Transfer Point',
            ),
            method: filter == RouteFilter.metroOnly
                ? 'metro'
                : filter == RouteFilter.busOnly
                ? 'bus'
                : 'microbus',
            numStops: 12,
            distanceMeters: 8000,
            durationSeconds: 1800, // 30 minutes
          ),
          RouteSegment(
            startLocation: RouteLocation(
              lat: (originLat + destinationLat) / 2,
              lon: (originLon + destinationLon) / 2,
              name: 'Transfer Point',
            ),
            endLocation: RouteLocation(
              lat: destinationLat,
              lon: destinationLon,
              name: 'End Point',
            ),
            method: 'walk',
            numStops: 0,
            distanceMeters: 4000,
            durationSeconds: 600, // 10 minutes
          ),
        ],
        estimatedFare: _calculateMockFare(filter),
        walkDistanceMeters: 4000,
      ),
    );
  }

  double _calculateMockFare(RouteFilter filter) {
    switch (filter) {
      case RouteFilter.cheapest:
        return 3.0;
      case RouteFilter.busOnly:
        return 5.0;
      case RouteFilter.microbusOnly:
        return 8.0;
      case RouteFilter.metroOnly:
        return 7.0;
      case RouteFilter.fastest:
        return 15.0; // Might include taxi segments
      case RouteFilter.optimal:
        return 6.0;
    }
  }
}
