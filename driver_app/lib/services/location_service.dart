import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final int timestamp;
  final bool isStale;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.timestamp,
    required this.isStale,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  LocationData? _lastLocation;

  Future<bool> requestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[LocationService] Permission error: $e');
      return false;
    }
  }

  Future<LocationData?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestPermission();
      if (!hasPermission) return null;

      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );

      double speedKmh = pos.speed > 0 ? pos.speed * 3.6 : 0.0;
      double heading = pos.heading >= 0 ? pos.heading : 0.0;
      int now = DateTime.now().millisecondsSinceEpoch;

      final data = LocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        speed: double.parse(speedKmh.toStringAsFixed(1)),
        heading: double.parse(heading.toStringAsFixed(1)),
        timestamp: pos.timestamp.millisecondsSinceEpoch,
        isStale: (now - pos.timestamp.millisecondsSinceEpoch) > 5000,
      );

      _lastLocation = data;
      return data;
    } catch (e) {
      debugPrint('[LocationService] getCurrentLocation error: $e');
      return null;
    }
  }

  LocationData? getLastLocation() => _lastLocation;
}
