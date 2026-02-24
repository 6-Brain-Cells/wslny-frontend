import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<LatLng>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<LatLng> get locationStream => _locationController.stream;
  Stream<String> get errorStream => _errorController.stream;

  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorController.add('Location services are disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorController.add('Location permission denied.');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _errorController.add(
        'Location permission permanently denied. Enable in settings.',
      );
      return false;
    }
    return true;
  }

  Future<LatLng?> getCurrentPosition() async {
    final ok = await checkAndRequestPermission();
    if (!ok) return null;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      _errorController.add(e.toString());
      return null;
    }
  }

  void startLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position position) {
        _locationController.add(LatLng(position.latitude, position.longitude));
      },
      onError: (Object e) => _errorController.add(e.toString()),
    );
  }

  void stopLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    stopLocationUpdates();
    _locationController.close();
    _errorController.close();
  }
}
