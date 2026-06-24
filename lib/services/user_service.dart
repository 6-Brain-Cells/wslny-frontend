import '../models/user_request_models.dart';
import '../config/app_constants.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getFavorites() async {
    try {
      if (AppConstants.useMockMode) return [];
      final response = await _apiService.get(
        '/api/v1/user/favorites',
        module: ApiService.moduleUser,
      );
      if (response is List) return response;
      return [];
    } catch (e) {
      throw Exception('Failed to get favorites: $e');
    }
  }

  Future<void> addFavorite(CreateFavoriteRouteRequest request) async {
    try {
      if (AppConstants.useMockMode) return;
      await _apiService.post(
        '/api/v1/user/favorites',
        body: request.toJson(),
        module: ApiService.moduleUser,
      );
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  Future<void> removeFavorite(int id) async {
    try {
      if (AppConstants.useMockMode) return;
      await _apiService.delete(
        '/api/v1/user/favorites/$id',
        module: ApiService.moduleUser,
      );
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  Future<Map<String, dynamic>> getPreferences() async {
    try {
      if (AppConstants.useMockMode) return {};
      final response = await _apiService.get(
        '/api/v1/user/preferences',
        module: ApiService.moduleUser,
      );
      if (response is Map<String, dynamic>) return response;
      return {};
    } catch (e) {
      throw Exception('Failed to get preferences: $e');
    }
  }

  Future<void> updatePreferences(UpdatePreferencesRequest request) async {
    try {
      if (AppConstants.useMockMode) return;
      await _apiService.put(
        '/api/v1/user/preferences',
        body: request.toJson(),
        module: ApiService.moduleUser,
      );
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }

  Future<List<dynamic>> getSavedLocations() async {
    try {
      if (AppConstants.useMockMode) return [];
      final response = await _apiService.get(
        '/api/v1/user/saved-locations',
        module: ApiService.moduleUser,
      );
      if (response is List) return response;
      return [];
    } catch (e) {
      throw Exception('Failed to get saved locations: $e');
    }
  }

  Future<void> addSavedLocation(CreateSavedLocationRequest request) async {
    try {
      if (AppConstants.useMockMode) return;
      await _apiService.post(
        '/api/v1/user/saved-locations',
        body: request.toJson(),
        module: ApiService.moduleUser,
      );
    } catch (e) {
      throw Exception('Failed to add saved location: $e');
    }
  }

  Future<void> updateSavedLocation(
    int id,
    UpdateSavedLocationRequest request,
  ) async {
    try {
      if (AppConstants.useMockMode) return;
      await _apiService.put(
        '/api/v1/user/saved-locations/$id',
        body: request.toJson(),
        module: ApiService.moduleUser,
      );
    } catch (e) {
      throw Exception('Failed to update saved location: $e');
    }
  }

  Future<void> deleteSavedLocation(int id) async {
    try {
      if (AppConstants.useMockMode) return;
      await _apiService.delete(
        '/api/v1/user/saved-locations/$id',
        module: ApiService.moduleUser,
      );
    } catch (e) {
      throw Exception('Failed to delete saved location: $e');
    }
  }
}
