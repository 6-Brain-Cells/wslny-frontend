class AppConstants {
  // API Configuration
  static const String apiBaseUrl =
      'https://wslny-backend-service.agreeablebush-4a28df70.uaenorth.azurecontainerapps.io';
  static const int apiTimeout = 30000; // 30 seconds

  // Development mode - set to true to use mock data when backend is not available
  static const bool useMockMode = true;

  // Storage Keys
  static const String languageKey = 'selected_language';
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String isLoggedInKey = 'is_logged_in';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 32;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // Regular Expressions
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');

  // Supported Languages
  static const String englishCode = 'en';
  static const String arabicCode = 'ar';
}
