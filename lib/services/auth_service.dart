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
        '/api/auth/login',
        body: {'email': email, 'password': password},
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
    } catch (e) {
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
        '/api/auth/register',
        body: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'mobile_number': mobileNumber,
          'gender': gender,
          'address': address,
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
      await prefs.setString(
        AppConstants.refreshTokenKey,
        response['refresh_token'] as String,
      );

      if (user.email != null) {
        await prefs.setString(AppConstants.userIdKey, user.email!);
      }

      return user;
    } catch (e) {
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

      // TODO: Fetch user from API when backend is ready
      // final userId = prefs.getString(AppConstants.userIdKey);
      // final response = await _apiService.get('/users/$userId');
      // return UserModel.fromJson(response);

      return null;
    } catch (e) {
      return null;
    }
  }
}
