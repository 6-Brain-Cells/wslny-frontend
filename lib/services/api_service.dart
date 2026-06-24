import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';
import '../config/env.dart';

class ApiService {
  final String baseUrl = Env.backendApiBaseUrl;
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: AppConstants.apiTimeout),
        receiveTimeout: Duration(milliseconds: AppConstants.apiTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if needed
          if (options.headers['requireAuth'] != false) {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString(AppConstants.authTokenKey);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          // Remove the custom header
          options.headers.remove('requireAuth');

          debugPrint('🚀 ${options.method} Request: ${options.uri}');
          debugPrint('Headers: ${options.headers}');
          if (options.data != null) {
            debugPrint('Body: ${json.encode(options.data)}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ Response received - Status: ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('❌ Error: ${error.message}');
          debugPrint('Response: ${error.response}');
          handler.next(error);
        },
      ),
    );
  }

  /// Module types for X-Module header
  static const String moduleAuth = 'Auth';
  static const String moduleRouting = 'Routing';
  static const String moduleTransit = 'Transit';
  static const String moduleUser = 'User';

  // GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
    String? module,
  }) async {
    try {
      final headers = <String, dynamic>{'requireAuth': includeAuth};
      if (module != null) {
        headers['X-Module'] = module;
      }
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET request failed: $e');
    }
  }

  // POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    String? module,
  }) async {
    try {
      final headers = <String, dynamic>{'requireAuth': includeAuth};
      if (module != null) {
        headers['X-Module'] = module;
      }
      final response = await _dio.post(
        endpoint,
        data: body,
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('POST request failed: $e');
    }
  }

  // PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    String? module,
  }) async {
    try {
      final headers = <String, dynamic>{'requireAuth': includeAuth};
      if (module != null) {
        headers['X-Module'] = module;
      }
      final response = await _dio.put(
        endpoint,
        data: body,
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('PUT request failed: $e');
    }
  }

  // DELETE request
  Future<dynamic> delete(
    String endpoint, {
    bool includeAuth = true,
    String? module,
  }) async {
    try {
      final headers = <String, dynamic>{'requireAuth': includeAuth};
      if (module != null) {
        headers['X-Module'] = module;
      }
      final response = await _dio.delete(
        endpoint,
        options: Options(headers: headers),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('DELETE request failed: $e');
    }
  }

  // Handle API response
  dynamic _handleResponse(Response response) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      if (response.data == null) return null;
      return response.data;
    } else if (response.statusCode == 401) {
      final errorMessage = _extractErrorMessage(response.data);
      if (errorMessage != null && errorMessage.isNotEmpty) {
        throw Exception(errorMessage);
      }
      throw Exception('Unauthorized. Please log in again.');
    } else if (response.statusCode == 404) {
      final errorMessage = _extractErrorMessage(response.data);
      if (errorMessage != null && errorMessage.isNotEmpty) {
        throw Exception(errorMessage);
      }
      throw Exception('API endpoint not found. Please check the backend URL.');
    } else if (response.statusCode! >= 500) {
      throw Exception('Server error. Please try again later.');
    } else {
      final errorMessage = _extractErrorMessage(response.data);
      throw Exception(
        errorMessage ?? 'Request failed with status: ${response.statusCode}',
      );
    }
  }

  // Extract error message from response
  String? _extractErrorMessage(dynamic responseData) {
    try {
      if (responseData == null) return null;

      final data = responseData is String
          ? json.decode(responseData)
          : responseData as Map<String, dynamic>;

      // Handle the new error format with errors array
      if (data['errors'] is List && data['errors'].isNotEmpty) {
        final errors = data['errors'] as List;
        return errors.map((e) => e.toString()).join(', ');
      }

      // Handle route API and similar: { "error": { "code": "...", "message": "..." } }
      if (data['error'] is Map<String, dynamic>) {
        final err = data['error'] as Map<String, dynamic>;
        final msg = err['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }

      // Handle single error message
      return data['message']?.toString() ??
          data['error']?.toString() ??
          data['detail']?.toString();
    } catch (e) {
      return null;
    }
  }
}
