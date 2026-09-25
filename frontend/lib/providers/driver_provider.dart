import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/alert.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';

class DriverProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  String _vehicleId = "V102";
  bool _locationEnabled = true;
  double _lat = 13.0827;
  double _lon = 80.2707;
  double _speed = 32.0;
  double _heading = 90.0;

  CorridorAlert? _activeAlert;
  Timer? _pollingTimer;

  String get vehicleId => _vehicleId;
  bool get locationEnabled => _locationEnabled;
  double get latitude => _lat;
  double get longitude => _lon;
  double get speed => _speed;
  double get heading => _heading;
  CorridorAlert? get activeAlert => _activeAlert;

  DriverProvider() {
    _startPolling();
  }

  void toggleLocationPermission(bool enabled) {
    _locationEnabled = enabled;
    _apiService.updateVehicleLocation(
      vehicleId: _vehicleId,
      latitude: _lat,
      longitude: _lon,
      speed: _speed,
      heading: _heading,
      locationEnabled: _locationEnabled,
    );
    notifyListeners();
  }

  void setVehicleId(String id) {
    _vehicleId = id;
    notifyListeners();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      _apiService.updateVehicleLocation(
        vehicleId: _vehicleId,
        latitude: _lat,
        longitude: _lon,
        speed: _speed,
        heading: _heading,
        locationEnabled: _locationEnabled,
      );

      final alert = await _apiService.fetchAlertForVehicle(_vehicleId);
      if (alert != null) {
        if (_activeAlert?.timestamp != alert.timestamp) {
          FCMNotificationService.triggerAlertFeedback(alert);
        }
        _activeAlert = alert;
      } else {
        _activeAlert = null;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
