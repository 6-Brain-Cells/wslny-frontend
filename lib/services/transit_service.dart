import '../config/app_constants.dart';
import 'api_service.dart';

class TransitService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getLines() async {
    try {
      if (AppConstants.useMockMode) return [];
      final response = await _apiService.get(
        '/api/v1/lines',
        module: ApiService.moduleTransit,
      );
      if (response is List) return response;
      return [];
    } catch (e) {
      throw Exception('Failed to get lines: $e');
    }
  }

  Future<Map<String, dynamic>> getLineDetails(int routeId) async {
    try {
      if (AppConstants.useMockMode) return {};
      final response = await _apiService.get(
        '/api/v1/lines/$routeId',
        module: ApiService.moduleTransit,
      );
      if (response is Map<String, dynamic>) return response;
      return {};
    } catch (e) {
      throw Exception('Failed to get line details: $e');
    }
  }

  Future<Map<String, dynamic>> getStopDetails(int stopId) async {
    try {
      if (AppConstants.useMockMode) return {};
      final response = await _apiService.get(
        '/api/v1/stops/$stopId',
        module: ApiService.moduleTransit,
      );
      if (response is Map<String, dynamic>) return response;
      return {};
    } catch (e) {
      throw Exception('Failed to get stop details: $e');
    }
  }

  Future<List<dynamic>> getNearbyStops({
    required double lat,
    required double lon,
    int? radius,
  }) async {
    try {
      if (AppConstants.useMockMode) return [];
      final queryParams = <String, dynamic>{
        'lat': lat,
        'lon': lon,
      };
      if (radius != null) queryParams['radius'] = radius;
      final response = await _apiService.get(
        '/api/v1/stops/nearby',
        queryParams: queryParams,
        module: ApiService.moduleTransit,
      );
      if (response is List) return response;
      return [];
    } catch (e) {
      throw Exception('Failed to get nearby stops: $e');
    }
  }
}
