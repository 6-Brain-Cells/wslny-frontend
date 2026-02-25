import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/app_constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Sign in with email and password
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      if (AppConstants.useMockMode) {
        // Mock response for development
        await Future.delayed(const Duration(seconds: 1));

        final user = UserModel(
          firstName: 'Test',
          lastName: 'User',
          email: email,
        );

        // Save mock auth tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.isLoggedInKey, true);
        await prefs.setString(
          AppConstants.authTokenKey,
          'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        );
        await prefs.setString(
          AppConstants.refreshTokenKey,
          'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (user.email != null) {
          await prefs.setString(AppConstants.userIdKey, user.email!);
        }

        return user;
      }

      final response = await _apiService.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
        includeAuth: false,
      );

      // Extract user data from response
      final userData = response['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);

      // Save auth tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.isLoggedInKey, true);
      await prefs.setString(
        AppConstants.authTokenKey,
        response['token'] as String,
      );
      
      // Handle refresh token if provided
      if (response['refresh_token'] != null) {
        await prefs.setString(
          AppConstants.refreshTokenKey,
          response['refresh_token'] as String,
        );
      }

      if (user.id != null) {
        await prefs.setString(AppConstants.userIdKey, user.id!);
      } else if (user.email != null) {
        await prefs.setString(AppConstants.userIdKey, user.email!);
      }

      return user;
    } catch (e) {
      if (e.toString().contains('CORS') || e.toString().contains('Failed to fetch')) {
        throw Exception('Network error: Unable to connect to server. This appears to be a CORS (Cross-Origin Resource Sharing) issue. Please ensure the backend server allows requests from ${Uri.base.origin}');
      }
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign up with email and password
  Future<UserModel> signUpWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? mobileNumber,
    String? gender,
    String? address,
  }) async {
    try {
      if (AppConstants.useMockMode) {
        // Mock response for development
        await Future.delayed(const Duration(seconds: 1));

        final user = UserModel(
          firstName: firstName,
          lastName: lastName,
          email: email,
          mobileNumber: mobileNumber,
          gender: gender,
          address: address,
        );

        // Save mock auth tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.isLoggedInKey, true);
        await prefs.setString(
          AppConstants.authTokenKey,
          'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        );
        await prefs.setString(
          AppConstants.refreshTokenKey,
          'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (user.email != null) {
          await prefs.setString(AppConstants.userIdKey, user.email!);
        }

        return user;
      }

      final requestBody = <String, dynamic>{
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      };

      // Add optional fields only if they're not null and not empty
      if (mobileNumber != null && mobileNumber.isNotEmpty) {
        requestBody['mobile_number'] = mobileNumber;
      }
      if (gender != null && gender.isNotEmpty) {
        requestBody['gender'] = gender;
      }
      if (address != null && address.isNotEmpty) {
        requestBody['address'] = address;
      }

      final response = await _apiService.post(
        '/auth/register',
        body: requestBody,
        includeAuth: false,
      );

      // Extract user data from response
      final userData = response['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);

      // Save auth tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.isLoggedInKey, true);
      await prefs.setString(
        AppConstants.authTokenKey,
        response['token'] as String,
      );
      
      // Handle refresh token if provided
      if (response['refresh_token'] != null) {
        await prefs.setString(
          AppConstants.refreshTokenKey,
          response['refresh_token'] as String,
        );
      }

      if (user.id != null) {
        await prefs.setString(AppConstants.userIdKey, user.id!);
      } else if (user.email != null) {
        await prefs.setString(AppConstants.userIdKey, user.email!);
      }

      return user;
    } catch (e) {
      if (e.toString().contains('CORS') || e.toString().contains('Failed to fetch')) {
        throw Exception('Network error: Unable to connect to server. This appears to be a CORS (Cross-Origin Resource Sharing) issue. Please ensure the backend server allows requests from ${Uri.base.origin}');
      }
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with Google
  Future<UserModel> signInWithGoogle({String? idToken}) async {
    try {
      if (idToken != null) {
        // Use provided ID token (from Google Sign-In)
        final response = await _apiService.post(
          '/api/auth/google-login',
          body: {'id_token': idToken},
          includeAuth: false,
        );

        // Extract user data from response
        final userData = response['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);

        // Save auth tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.isLoggedInKey, true);
        await prefs.setString(
          AppConstants.authTokenKey,
          response['token'] as String,
        );
        await prefs.setString(
          AppConstants.refreshTokenKey,
          response['refresh_token'] as String,
        );

        if (user.email != null) {
          await prefs.setString(AppConstants.userIdKey, user.email!);
        }

        return user;
      } else {
        throw Exception('Google Sign In requires ID token');
      }
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.isLoggedInKey);
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.authTokenKey);
      await prefs.remove(AppConstants.refreshTokenKey);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(AppConstants.isLoggedInKey) ?? false;

      if (!isLoggedIn) return null;

      if (AppConstants.useMockMode) {
        // Return mock user for development
        return UserModel(
          firstName: 'Test',
          lastName: 'User',
          email: prefs.getString(AppConstants.userIdKey),
        );
      }

      // Fetch user profile from API
      final response = await _apiService.get('/auth/profile');
      return UserModel.fromJson(response['user'] as Map<String, dynamic>);
    } catch (e) {
      // If token is invalid, clear auth state
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.isLoggedInKey);
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.authTokenKey);
      await prefs.remove(AppConstants.refreshTokenKey);
      return null;
    }
  }
}
