import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';
import '../config/env.dart';

class ApiService {
  final String baseUrl = Env.backendApiBaseUrl;

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.authTokenKey);

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl$endpoint',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeaders(includeAuth: includeAuth);

      final response = await http
          .get(uri, headers: headers)
          .timeout(Duration(milliseconds: AppConstants.apiTimeout));

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
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(includeAuth: includeAuth);

      debugPrint('🚀 POST Request Details:');
      debugPrint('URL: $uri');
      debugPrint('Headers: $headers');
      debugPrint('Body: ${body != null ? json.encode(body) : null}');

      final response = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(Duration(milliseconds: AppConstants.apiTimeout));

      debugPrint('✅ Response received - Status: ${response.statusCode}');
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      debugPrint('❌ ClientException (likely CORS or network): $e');
      throw Exception(
        'Network error: Unable to connect to server. This might be a CORS issue or the server is not reachable. Details: $e',
      );
    } on TimeoutException catch (e) {
      debugPrint('❌ TimeoutException: $e');
      throw Exception(
        'Request timeout: The server took too long to respond. Please try again.',
      );
    } catch (e) {
      debugPrint('❌ POST request error: $e');
      throw Exception('POST request failed: $e');
    }
  }

  // PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(includeAuth: includeAuth);

      final response = await http
          .put(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('PUT request failed: $e');
    }
  }

  // DELETE request
  Future<dynamic> delete(String endpoint, {bool includeAuth = true}) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(includeAuth: includeAuth);

      final response = await http
          .delete(uri, headers: headers)
          .timeout(Duration(milliseconds: AppConstants.apiTimeout));

      return _handleResponse(response);
    } catch (e) {
      throw Exception('DELETE request failed: $e');
    }
  }

  // Handle API response
  dynamic _handleResponse(http.Response response) {
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Try to extract the actual error message from the response body
      final errorMessage = _extractErrorMessage(response.body);
      if (errorMessage != null && errorMessage.isNotEmpty) {
        throw Exception(errorMessage);
      }
      throw Exception('Unauthorized. Please log in again.');
    } else if (response.statusCode == 404) {
      throw Exception('API endpoint not found. Please check the backend URL.');
    } else if (response.statusCode >= 500) {
      throw Exception('Server error. Please try again later.');
    } else {
      final errorMessage = _extractErrorMessage(response.body);
      throw Exception(
        errorMessage ?? 'Request failed with status: ${response.statusCode}',
      );
    }
  }

  // Extract error message from response
  String? _extractErrorMessage(String responseBody) {
    try {
      final data = json.decode(responseBody);

      // Handle the new error format with errors array
      if (data['errors'] is List && data['errors'].isNotEmpty) {
        final errors = data['errors'] as List;
        // Return the first error message or join all errors
        return errors.map((e) => e.toString()).join(', ');
      }

      // Handle single error message
      return data['message'] ?? data['error'] ?? data['detail'];
    } catch (e) {
      return null;
    }
  }
}
