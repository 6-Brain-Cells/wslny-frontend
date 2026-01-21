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
      // TODO: Replace with actual API call when backend is ready
      // final response = await _apiService.post(
      //   '/auth/login',
      //   body: {
      //     'email': email,
      //     'password': password,
      //   },
      // );
      
      // For now, simulate a successful login
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock user data
      final user = UserModel(
        id: '1',
        fullName: 'Test User',
        email: email,
        createdAt: DateTime.now(),
      );
      
      // Save auth token
      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(AppConstants.isLoggedInKey, true);
        await prefs.setString(AppConstants.userIdKey, user.id);
        // await prefs.setString(AppConstants.authTokenKey, response['token']);
      }
      
      return user;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }
  
  // Sign up with email and password
  Future<UserModel> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // final response = await _apiService.post(
      //   '/auth/register',
      //   body: {
      //     'full_name': fullName,
      //     'email': email,
      //     'password': password,
      //     'phone_number': phoneNumber,
      //   },
      // );
      
      // For now, simulate a successful registration
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock user data
      final user = UserModel(
        id: '1',
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
      );
      
      // Save auth token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.isLoggedInKey, true);
      await prefs.setString(AppConstants.userIdKey, user.id);
      // await prefs.setString(AppConstants.authTokenKey, response['token']);
      
      return user;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }
  
  // Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      // TODO: Implement Google Sign In when backend is ready
      // final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      // if (googleUser == null) throw Exception('Google sign in cancelled');
      
      // final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // final response = await _apiService.post(
      //   '/auth/google',
      //   body: {
      //     'id_token': googleAuth.idToken,
      //   },
      // );
      
      // For now, simulate a successful Google sign in
      await Future.delayed(const Duration(seconds: 1));
      
      throw Exception('Google Sign In not yet implemented');
      
      // Mock user data (uncomment when implementing)
      // final user = UserModel.fromJson(response['user']);
      // 
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.setBool(AppConstants.isLoggedInKey, true);
      // await prefs.setString(AppConstants.userIdKey, user.id);
      // await prefs.setString(AppConstants.authTokenKey, response['token']);
      // 
      // return user;
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      // TODO: Call API to invalidate token when backend is ready
      // await _apiService.post('/auth/logout');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.isLoggedInKey);
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.authTokenKey);
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
