import 'dart:async';

class LocationService {
  bool _locationEnabled = true;
  double _currentLat = 13.0827;
  double _currentLon = 80.2707;
  double _speed = 32.0;
  double _heading = 90.0;

  bool get isLocationEnabled => _locationEnabled;
  double get latitude => _currentLat;
  double get longitude => _currentLon;
  double get speed => _speed;
  double get heading => _heading;

  void toggleLocationPermission(bool enabled) {
    _locationEnabled = enabled;
  }

  void updatePosition(double lat, double lon, {double speed = 32.0, double heading = 90.0}) {
    _currentLat = lat;
    _currentLon = lon;
    _speed = speed;
    _heading = heading;
  }
}
