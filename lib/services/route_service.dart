import 'package:flutter/foundation.dart';
import '../models/route_models.dart';
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
        currentLatitude: currentLatitude,
        currentLongitude: currentLongitude,
      );

      debugPrint('🚌 Route Request (Text): ${request.toJson()}');

      final response = await _apiService.post(
        '/route',
        body: request.toJson(),
        includeAuth: true,
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

      final requestBody = <String, dynamic>{
        'origin': {
          'lat': originLat,
          'lon': originLon,
        },
        'destination': {
          'lat': destinationLat,
          'lon': destinationLon,
        },
        'filter': filter.value,
      };

      // Add current location if provided (as optional query parameters)
      String endpoint = '/route';
      if (currentLatitude != null && currentLongitude != null) {
        endpoint += '?current_latitude=$currentLatitude&current_longitude=$currentLongitude';
      }

      debugPrint('🚌 Route Request (Coordinates): $requestBody');

      final response = await _apiService.post(
        endpoint,
        body: requestBody,
        includeAuth: true,
      );

      debugPrint('🚌 Route Response: $response');

      return RouteResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ Route request failed: $e');
      throw Exception('Failed to get route: $e');
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
            startLocation: RouteLocation(lat: 30.0444, lon: 31.2357, name: 'Start Point'),
            endLocation: RouteLocation(lat: 30.0500, lon: 31.2400, name: 'Bus Stop A'),
            method: 'walk',
            numStops: 0,
            distanceMeters: 400,
            durationSeconds: 300, // 5 minutes
          ),
          RouteSegment(
            startLocation: RouteLocation(lat: 30.0500, lon: 31.2400, name: 'Bus Stop A'),
            endLocation: RouteLocation(lat: 30.0600, lon: 31.2480, name: 'Bus Stop B'),
            method: filter == RouteFilter.metroOnly ? 'metro' : 'bus',
            numStops: 8,
            distanceMeters: 7500,
            durationSeconds: 1200, // 20 minutes
          ),
          RouteSegment(
            startLocation: RouteLocation(lat: 30.0600, lon: 31.2480, name: 'Bus Stop B'),
            endLocation: RouteLocation(lat: 30.0626, lon: 31.2497, name: 'Destination'),
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
        destination: RouteLocation(lat: destinationLat, lon: destinationLon, name: 'End'),
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
            startLocation: RouteLocation(lat: originLat, lon: originLon, name: 'Start Point'),
            endLocation: RouteLocation(lat: (originLat + destinationLat) / 2, lon: (originLon + destinationLon) / 2, name: 'Transfer Point'),
            method: filter == RouteFilter.metroOnly ? 'metro' : filter == RouteFilter.busOnly ? 'bus' : 'microbus',
            numStops: 12,
            distanceMeters: 8000,
            durationSeconds: 1800, // 30 minutes
          ),
          RouteSegment(
            startLocation: RouteLocation(lat: (originLat + destinationLat) / 2, lon: (originLon + destinationLon) / 2, name: 'Transfer Point'),
            endLocation: RouteLocation(lat: destinationLat, lon: destinationLon, name: 'End Point'),
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