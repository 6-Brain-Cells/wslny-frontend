import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Sign in with email and password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    setLoading(true);
    clearError();

    try {
      // TODO: Implement actual API call when backend is ready
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      _user = user;
      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  // Sign up with email and password
  Future<bool> signUpWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? mobileNumber,
    String? gender,
    String? address,
  }) async {
    setLoading(true);
    clearError();

    try {
      final user = await _authService.signUpWithEmail(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        mobileNumber: mobileNumber,
        gender: gender,
        address: address,
      );

      _user = user;
      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle({String? idToken}) async {
    setLoading(true);
    clearError();

    try {
      final user = await _authService.signInWithGoogle(idToken: idToken);

      _user = user;
      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    setLoading(true);

    try {
      await _authService.signOut();
      _user = null;
      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
    }
  }

  // Check if user is already signed in
  Future<void> checkAuthStatus() async {
    setLoading(true);

    try {
      final user = await _authService.getCurrentUser();
      _user = user;
      setLoading(false);
    } catch (e) {
      setError(e.toString());
      setLoading(false);
    }
  }
}
