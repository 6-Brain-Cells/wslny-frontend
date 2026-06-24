import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/auth_models.dart';
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
        '/api/v1/auth/login',
        body: LoginRequest(email: email, password: password).toJson(),
        includeAuth: false,
        module: ApiService.moduleAuth,
      );

      final authResponse = AuthSuccessResponse.fromJson(
        response as Map<String, dynamic>,
      );
      final user = UserModel(
        firstName: authResponse.user.firstName,
        lastName: authResponse.user.lastName,
        email: authResponse.user.email,
      );

      // Save auth tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.isLoggedInKey, true);
      await prefs.setString(AppConstants.authTokenKey, authResponse.token);
      await prefs.setString(
        AppConstants.refreshTokenKey,
        authResponse.refreshToken,
      );

      if (user.id != null) {
        await prefs.setString(AppConstants.userIdKey, user.id!);
      } else if (user.email != null) {
        await prefs.setString(AppConstants.userIdKey, user.email!);
      }

      return user;
    } catch (e) {
      if (e.toString().contains('CORS') ||
          e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Network error: Unable to connect to server. This appears to be a CORS (Cross-Origin Resource Sharing) issue. Please ensure the backend server allows requests from ${Uri.base.origin}',
        );
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

      final response = await _apiService.post(
        '/api/v1/auth/register',
        body: RegisterRequest(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          mobileNumber: mobileNumber ?? '',
          gender: gender,
          address: address,
        ).toJson(),
        includeAuth: false,
        module: ApiService.moduleAuth,
      );

      final authResponse = AuthSuccessResponse.fromJson(
        response as Map<String, dynamic>,
      );
      final user = UserModel(
        firstName: authResponse.user.firstName,
        lastName: authResponse.user.lastName,
        email: authResponse.user.email,
        mobileNumber: mobileNumber,
        gender: gender,
        address: address,
      );

      // Save auth tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.isLoggedInKey, true);
      await prefs.setString(AppConstants.authTokenKey, authResponse.token);
      await prefs.setString(
        AppConstants.refreshTokenKey,
        authResponse.refreshToken,
      );

      if (user.id != null) {
        await prefs.setString(AppConstants.userIdKey, user.id!);
      } else if (user.email != null) {
        await prefs.setString(AppConstants.userIdKey, user.email!);
      }

      return user;
    } catch (e) {
      if (e.toString().contains('CORS') ||
          e.toString().contains('Failed to fetch')) {
        throw Exception(
          'Network error: Unable to connect to server. This appears to be a CORS (Cross-Origin Resource Sharing) issue. Please ensure the backend server allows requests from ${Uri.base.origin}',
        );
      }
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with Google
  Future<UserModel> signInWithGoogle({String? idToken}) async {
    try {
      if (AppConstants.useMockMode) {
        await Future.delayed(const Duration(seconds: 1));

        final user = UserModel(
          firstName: 'Google',
          lastName: 'User',
          email: 'google.user@example.com',
        );

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

      if (idToken == null) {
        throw Exception('Google Sign In requires ID token');
      }

      final response = await _apiService.post(
        '/api/v1/auth/google-login',
        body: GoogleLoginRequest(idToken: idToken).toJson(),
        includeAuth: false,
        module: ApiService.moduleAuth,
      );

      final authResponse = AuthSuccessResponse.fromJson(
        response as Map<String, dynamic>,
      );
      final user = UserModel(
        firstName: authResponse.user.firstName,
        lastName: authResponse.user.lastName,
        email: authResponse.user.email,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.isLoggedInKey, true);
      await prefs.setString(AppConstants.authTokenKey, authResponse.token);
      await prefs.setString(
        AppConstants.refreshTokenKey,
        authResponse.refreshToken,
      );

      if (user.email != null) {
        await prefs.setString(AppConstants.userIdKey, user.email!);
      }

      return user;
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

  // Update user profile
  Future<void> updateProfile(UpdateProfileRequest request) async {
    try {
      if (AppConstants.useMockMode) return;
      await _apiService.put(
        '/api/v1/auth/profile',
        body: request.toJson(),
        module: ApiService.moduleAuth,
      );
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Change password
  Future<void> changePassword(ChangePasswordRequest request) async {
    try {
      if (AppConstants.useMockMode) return;
      await _apiService.post(
        '/api/v1/auth/change-password',
        body: request.toJson(),
        module: ApiService.moduleAuth,
      );
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  // Refresh token
  Future<TokenRefresh> refreshToken(String refreshToken) async {
    try {
      final response = await _apiService.post(
        '/api/v1/auth/refresh',
        body: TokenRefresh(refresh: refreshToken).toJson(),
        includeAuth: true,
        module: ApiService.moduleAuth,
      );
      return TokenRefresh.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to refresh token: $e');
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
      final response = await _apiService.get(
        '/api/v1/auth/profile',
        module: ApiService.moduleAuth,
      );
      final authUser = AuthUser.fromJson(response as Map<String, dynamic>);
      return UserModel(
        firstName: authUser.firstName,
        lastName: authUser.lastName,
        email: authUser.email,
      );
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
