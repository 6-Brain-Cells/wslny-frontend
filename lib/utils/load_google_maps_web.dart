import 'dart:async';
import 'dart:html' as html;

import '../config/env.dart';

/// Injects Google Maps JS script with key from .env and async loading.
/// Call before runApp() on web so the map has a valid key and no "loaded without async" warning.
Future<void> loadGoogleMapsScript() async {
  final key = Env.googleMapsApiKey;
  if (key.isEmpty) return;

  final completer = Completer<void>();
  final script = html.ScriptElement()
    ..src =
        'https://maps.googleapis.com/maps/api/js?key=$key&loading=async'
    ..type = 'text/javascript';

  script.onLoad.listen((_) {
    if (!completer.isCompleted) completer.complete();
  });
  script.onError.listen((_) {
    if (!completer.isCompleted) completer.completeError(Exception('Maps script failed to load'));
  });

  html.document.head?.append(script);
  return completer.future;
}
