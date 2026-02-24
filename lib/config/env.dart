import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App environment variables loaded from .env.
/// Ensure [dotenv.load()] is called in main() before using.
class Env {
  Env._();

  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static String get osrmBaseUrl =>
      dotenv.env['OSRM_BASE_URL']?.trim().replaceAll(RegExp(r'/$'), '') ??
      'https://router.project-osrm.org';

  static String get overpassBaseUrl =>
      dotenv.env['OVERPASS_BASE_URL']?.trim().replaceAll(RegExp(r'/$'), '') ??
      'https://overpass-api.de/api/interpreter';

  static bool get hasGoogleMapsKey => googleMapsApiKey.isNotEmpty;
}
